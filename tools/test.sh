#!/usr/bin/env bash
# Corre una suite (o todas) en headless y falla si algo no pasa.
#
#   ./tools/test.sh                 todas
#   ./tools/test.sh playthrough     una sola
#
# Busca el binario de Godot en $GODOT, en ~/godot o en el PATH.
#
# Cada suite corre con limite de tiempo: si una escena no compila, el quit()
# de la prueba nunca se ejecuta y Godot headless se queda esperando para
# siempre. Se ajusta con TIMEOUT (segundos).
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

TIMEOUT="${TIMEOUT:-420}"

# Las clases con class_name se registran al importar: sin esto, un archivo
# nuevo no existe para el parser y la suite falla sin decir por que.
"$GODOT" --headless --path . --import >/dev/null 2>&1

if [[ $# -gt 0 ]]; then
	SUITES=("$@")
else
	SUITES=(content playthrough ui_smoke)
fi

status=0
for suite in "${SUITES[@]}"; do
	echo "== $suite"
	out="$(timeout --kill-after=10 "$TIMEOUT" "$GODOT" --headless --path . "res://tests/${suite}.tscn" 2>&1)"
	code=$?
	echo "$out" | grep -vE "mesh_get_surface_count|Parameter \"m\" is null|ObjectDB instances leaked|core/object/object.cpp|servers/rendering"
	if [[ $code -eq 124 || $code -eq 137 ]]; then
		echo "-- $suite SE COLGO (mas de ${TIMEOUT}s). Suele ser un error de compilacion:"
		echo "$out" | grep -E "SCRIPT ERROR|Parse Error" | head -5
		status=1
		continue
	fi
	if [[ $code -ne 0 ]] || echo "$out" | grep -q "FALLA"; then
		echo "-- $suite FALLO (codigo $code)"
		status=1
	fi
done
exit $status
