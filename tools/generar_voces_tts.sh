#!/usr/bin/env bash
# Genera las 107 lineas de radio con voz sintetica (TTS), en vez de grabarlas.
#
#   ./tools/generar_voces_tts.sh                    todas
#   ./tools/generar_voces_tts.sh -f rl_03           solo un registro
#   ./tools/generar_voces_tts.sh -d                 ver que haria, sin hacerlo
#
# Para que sirve: tener las 107 lineas hoy, con una sola voz, y poder jugar el
# juego entero con audio. NO reemplaza grabar. Un TTS no actua: no se cansa,
# no duda, no se le quiebra la voz, y este juego se apoya justamente en eso.
# Lo razonable es generar todo con TTS ahora, jugarlo, y despues ir grabando
# encima las lineas que mas pesan. El juego levanta cada archivo por separado,
# asi que reemplazar de a una no cuesta nada.
#
# --- El motor de voz -------------------------------------------------------
#
# Esto no trae un TTS adentro: usa el que tengas. Se configura con TTS_CMD,
# donde {texto} es el texto y {salida} el .wav a escribir.
#
#   Piper (gratis, offline, Linux/Mac/Windows):
#     pip install piper-tts
#     # bajar una voz de https://huggingface.co/rhasspy/piper-voices (es_AR,
#     # es_ES, es_MX) -- el .onnx y el .onnx.json juntos
#     export TTS_CMD='echo {texto} | piper -m ~/voces/es_AR-daniela-high.onnx -f {salida}'
#
#   macOS (ya lo tenes instalado):
#     export TTS_CMD='say -v Monica -o {salida} --data-format=LEF32@22050 {texto}'
#
#   Windows (PowerShell, ya lo tenes instalado):
#     ver docs/produccion.md
#
# IMPORTANTE, licencias: las voces de Piper salen de datasets distintos y no
# todas permiten uso comercial. Antes de publicar el juego con una voz,
# revisa el MODEL_CARD de esa voz puntual. Si el juego se vende, esto importa.
#
# Requiere ffmpeg para el procesamiento (igual que procesar_voces.sh).

set -uo pipefail

LISTA="docs/lineas_de_voz.md"
SALIDA="audio/voz"
FILTRO=""
DRY=0
LIMITE=0

while getopts "f:o:l:dh" opt; do
	case "$opt" in
		f) FILTRO="$OPTARG" ;;
		o) SALIDA="$OPTARG" ;;
		l) LIMITE="$OPTARG" ;;
		d) DRY=1 ;;
		h|*)
			sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'
			exit 0 ;;
	esac
done

if [[ ! -f "$LISTA" ]]; then
	echo "No encuentro $LISTA. Generalo con:" >&2
	echo "  godot --headless --path . res://tools/exportar_lineas.tscn" >&2
	exit 1
fi

if [[ -z "${TTS_CMD:-}" && $DRY -eq 0 ]]; then
	echo "Falta TTS_CMD: no se que motor de voz usar." >&2
	echo "Mira los ejemplos en la cabecera de este archivo ($0 -h)." >&2
	echo "Para ver que lineas se generarian sin generarlas: $0 -d" >&2
	exit 2
fi

FFMPEG="${FFMPEG:-$(command -v ffmpeg || true)}"
if [[ -z "$FFMPEG" && $DRY -eq 0 ]]; then
	echo "No encuentro ffmpeg. Instalalo, o poné la ruta en la variable FFMPEG." >&2
	exit 127
fi

# Misma cadena de radio que procesar_voces.sh, para que una linea grabada y
# una sintetizada suenen igual de procesadas y no se note el parche.
# El TTS ya viene sin ruido de cuarto, asi que no hace falta recortar silencios.
CADENA="highpass=f=100"
CADENA="$CADENA,acompressor=threshold=-18dB:ratio=4:attack=5:release=100:makeup=2"
CADENA="$CADENA,highpass=f=300,lowpass=f=3000"
CADENA="$CADENA,acompressor=threshold=-12dB:ratio=2:attack=10:release=150"
CADENA="$CADENA,loudnorm=I=-16:TP=-1.5:LRA=11"

mkdir -p "$SALIDA"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

hechos=0
saltados=0
fallados=0

# El texto sale de la tabla generada por Godot, que a su vez sale de
# night_data.gd: una sola fuente de verdad para el nombre y el texto.
while IFS=$'\t' read -r archivo texto; do
	[[ -z "$archivo" ]] && continue
	nombre="${archivo%.ogg}"
	if [[ -n "$FILTRO" && "$nombre" != $FILTRO* ]]; then
		continue
	fi
	if [[ $LIMITE -gt 0 && $hechos -ge $LIMITE ]]; then
		break
	fi

	if [[ $DRY -eq 1 ]]; then
		printf "  %-14s %s\n" "$nombre" "$texto"
		hechos=$((hechos + 1))
		continue
	fi

	# Hay lineas que son acotacion, no dialogo: "[ruido de portadora, doce
	# segundos]". Leerlas en voz alta seria absurdo. Van como un lecho muy
	# bajo de ruido, del largo que les corresponde, y el subtitulo las muestra
	# igual. Tampoco pasan por la cadena: loudnorm le subiria el volumen a un
	# silencio hasta hacerlo sonar.
	if [[ "$texto" == \[* || "$texto" == \(* ]]; then
		dur=$(awk -v n=${#texto} 'BEGIN { d = n / 14.0; print (d < 2.0 ? 2.0 : d) }')
		if "$FFMPEG" -hide_banner -loglevel error -y \
			-f lavfi -i "anoisesrc=d=$dur:c=pink:a=0.006" \
			-af "highpass=f=300,lowpass=f=3000" \
			-ac 1 -ar 44100 -c:a libvorbis -q:a 4 "$SALIDA/$nombre.ogg" 2>/dev/null; then
			printf "  %-14s ok (acotacion: lecho de ruido, %.1fs)\n" "$nombre" "$dur"
			hechos=$((hechos + 1))
		else
			printf "  %-14s FALLO (acotacion)\n" "$nombre"
			fallados=$((fallados + 1))
		fi
		continue
	fi

	crudo="$TMP/$nombre.wav"
	# {texto} y {salida} se reemplazan en el comando que configuro el usuario.
	cmd="${TTS_CMD//\{salida\}/$crudo}"
	cmd="${cmd//\{texto\}/$(printf '%q' "$texto")}"
	if ! eval "$cmd" >/dev/null 2>&1 || [[ ! -s "$crudo" ]]; then
		printf "  %-14s TTS FALLO\n" "$nombre"
		fallados=$((fallados + 1))
		continue
	fi

	destino="$SALIDA/$nombre.ogg"
	if "$FFMPEG" -hide_banner -loglevel error -y -i "$crudo" \
		-af "$CADENA" -ac 1 -ar 44100 -c:a libvorbis -q:a 4 "$destino" 2>/dev/null; then
		printf "  %-14s ok\n" "$nombre"
		hechos=$((hechos + 1))
	else
		printf "  %-14s ffmpeg FALLO\n" "$nombre"
		fallados=$((fallados + 1))
	fi
	rm -f "$crudo"
done < <(awk -F'|' '/^\| `rl_/ {
	gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/`/, "", $2);
	gsub(/^[ \t]+|[ \t]+$/, "", $4);
	if ($4 != "") print $2 "\t" $4
}' "$LISTA")

echo ""
if [[ $DRY -eq 1 ]]; then
	echo "$hechos lineas se generarian en $SALIDA/ (esto fue una prueba en seco)"
	exit 0
fi
echo "$hechos generadas en $SALIDA/${saltados:+, $saltados salteadas}${fallados:+, $fallados fallaron}"
echo ""
echo "Escuchalas en el juego antes de generar las 107. Y acordate: esto es un"
echo "piso, no el techo. Las lineas que mas pesan conviene grabarlas."
