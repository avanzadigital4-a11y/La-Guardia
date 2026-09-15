#!/usr/bin/env bash
# Convierte grabaciones crudas en registros de radio listos para el juego.
#
#   ./tools/procesar_voces.sh crudos/
#
# Toma cada archivo de audio de la carpeta, le aplica la cadena de radio y lo
# deja en audio/voz/ con el mismo nombre pero en .ogg. O sea: grabás con el
# telefono, copiás los archivos con el nombre que dice docs/lineas_de_voz.md
# (rl_01_1, rl_01_2, ...), corrés esto, y ya esta.
#
# Opciones:
#   -o CARPETA   donde dejar los .ogg      (default: audio/voz)
#   -s           solo escuchar la prueba: procesa el primero y sale
#   -n           no recortar los silencios de los extremos
#
# Requiere ffmpeg (gratis, esta en los repos de cualquier distro; en Windows,
# https://ffmpeg.org/download.html). Si no lo tenes, se puede hacer lo mismo a
# mano en Audacity: los pasos estan en docs/produccion.md.

set -uo pipefail

SALIDA="audio/voz"
SOLO_UNA=0
RECORTAR=1

while getopts "o:sn" opt; do
	case "$opt" in
		o) SALIDA="$OPTARG" ;;
		s) SOLO_UNA=1 ;;
		n) RECORTAR=0 ;;
		*) echo "Uso: $0 [-o carpeta] [-s] [-n] <carpeta_con_grabaciones>" >&2; exit 2 ;;
	esac
done
shift $((OPTIND - 1))

if [[ $# -lt 1 ]]; then
	echo "Uso: $0 [-o carpeta] [-s] [-n] <carpeta_con_grabaciones>" >&2
	echo "Ejemplo: $0 ~/grabaciones" >&2
	exit 2
fi
ENTRADA="$1"

if [[ ! -d "$ENTRADA" ]]; then
	echo "No encuentro la carpeta '$ENTRADA'." >&2
	exit 1
fi

FFMPEG="${FFMPEG:-$(command -v ffmpeg || true)}"
if [[ -z "$FFMPEG" ]]; then
	echo "No encuentro ffmpeg. Instalalo, o poné la ruta en la variable FFMPEG." >&2
	echo "  Debian/Ubuntu:  sudo apt install ffmpeg" >&2
	echo "  Windows:        https://ffmpeg.org/download.html" >&2
	echo "Alternativa sin ffmpeg: hacer los mismos pasos en Audacity (docs/produccion.md)." >&2
	exit 127
fi

# --- La cadena de radio ---------------------------------------------------
#
# El orden importa. Cada paso esta para algo:
#
#   highpass 100    saca el retumbe del cuarto y el golpe de aire de las "p".
#   acompressor     las radios comprimen mucho: deja todo al mismo volumen,
#                   lo gritado y lo susurrado.
#   highpass 300    \ el pasa-banda. ESTO es lo que hace que suene a radio,
#   lowpass  3000   / mas que ningun otro paso. Tambien es el motivo de que
#                   no haga falta un microfono caro: todo lo que un micro
#                   bueno captura de mas, aca se tira.
#   acompressor 2   segunda pasada suave, ya con la banda recortada.
#   loudnorm        deja todos los registros al mismo volumen entre si, que
#                   es lo que mas se nota si falta.
#
# No se agrega siseo ni ruido de portadora: el juego ya suma el suyo encima
# (AudioDirector), y si se agrega aca queda duplicado y suena a cassette.
CADENA="highpass=f=100"
CADENA="$CADENA,acompressor=threshold=-18dB:ratio=4:attack=5:release=100:makeup=2"
CADENA="$CADENA,highpass=f=300,lowpass=f=3000"
CADENA="$CADENA,acompressor=threshold=-12dB:ratio=2:attack=10:release=150"
if [[ $RECORTAR -eq 1 ]]; then
	# Recorta el silencio del principio y del final, no el del medio: las
	# pausas adentro de una linea son actuacion.
	CADENA="$CADENA,silenceremove=start_periods=1:start_silence=0.1:start_threshold=-50dB"
	CADENA="$CADENA,areverse,silenceremove=start_periods=1:start_silence=0.1:start_threshold=-50dB,areverse"
fi
CADENA="$CADENA,loudnorm=I=-16:TP=-1.5:LRA=11"

mkdir -p "$SALIDA"

hechos=0
fallados=0
shopt -s nullglob nocaseglob
for f in "$ENTRADA"/*.{wav,mp3,m4a,ogg,flac,aac,opus,wma,mp4}; do
	nombre="$(basename "${f%.*}")"
	destino="$SALIDA/${nombre}.ogg"
	if "$FFMPEG" -hide_banner -loglevel error -y -i "$f" \
		-af "$CADENA" -ac 1 -ar 44100 -c:a libvorbis -q:a 4 "$destino" 2>/dev/null; then
		dur="$("$FFMPEG" -hide_banner -i "$destino" 2>&1 | grep -oE "Duration: [0-9:.]+" | cut -d' ' -f2)"
		printf "  %-22s -> %s  (%s)\n" "$(basename "$f")" "$destino" "${dur:-?}"
		hechos=$((hechos + 1))
	else
		printf "  %-22s -> FALLO\n" "$(basename "$f")"
		fallados=$((fallados + 1))
	fi
	if [[ $SOLO_UNA -eq 1 ]]; then
		echo ""
		echo "Prueba de uno solo. Escuchalo antes de procesar el resto."
		exit 0
	fi
done
shopt -u nullglob nocaseglob

echo ""
if [[ $hechos -eq 0 ]]; then
	echo "No proces ningun archivo. Hay grabaciones en '$ENTRADA'?"
	exit 1
fi
echo "$hechos listos en $SALIDA/${fallados:+, $fallados fallaron}"
echo ""
echo "Los nombres tienen que coincidir con docs/lineas_de_voz.md (rl_01_1.ogg,"
echo "rl_01_2.ogg, ...). Si falta alguno, esa linea sigue con la voz sintetizada,"
echo "asi que se puede ir grabando de a poco."
