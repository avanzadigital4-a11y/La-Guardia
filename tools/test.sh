#!/usr/bin/env bash
# Corre una suite (o todas) en headless y falla si algo no pasa.
#
#   ./tools/test.sh                 todas
#   ./tools/test.sh playthrough     una sola
#
# Busca el binario de Godot en $GODOT, en ~/godot o en el PATH.
set -uo pipefail

GODOT="${GODOT:-}"
if [[ -z "$GODOT" ]]; then
	if [[ -x "$HOME/godot/Godot_v4.3-stable_linux.x86_64" ]]; then
		GODOT="$HOME/godot/Godot_v4.3-stable_linux.x86_64"
	elif command -v godot >/dev/null 2>&1; then
		GODOT="$(command -v godot)"
	else
		echo "No encuentro Godot. Poné la ruta en la variable GODOT." >&2
		exit 127
	fi
fi

if [[ $# -gt 0 ]]; then
	SUITES=("$@")
else
	SUITES=(content playthrough ui_smoke)
fi

status=0
for suite in "${SUITES[@]}"; do
	echo "== $suite"
	out="$("$GODOT" --headless --path . "res://tests/${suite}.tscn" 2>&1)"
	code=$?
	echo "$out" | grep -vE "mesh_get_surface_count|Parameter \"m\" is null|ObjectDB instances leaked|core/object/object.cpp|servers/rendering"
	if [[ $code -ne 0 ]] || echo "$out" | grep -q "FALLA"; then
		echo "-- $suite FALLO (codigo $code)"
		status=1
	fi
done
exit $status
