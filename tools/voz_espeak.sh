#!/usr/bin/env bash
# Motor de voz para generar_voces_tts.sh, usando espeak-ng.
#
#   export TTS_CMD='./tools/voz_espeak.sh {texto} {salida}'
#   ./tools/generar_voces_tts.sh
#
# Por que espeak-ng y no una voz mejor: es la unica opcion gratis cuya
# licencia permite vender el juego con el audio adentro. Las voces de mbrola
# suenan bastante mejor pero su licencia dice, textualmente, que la base "may
# not be sold or incorporated into any product which is sold". Mientras no
# este decidido si La Guardia se vende, meter mbrola seria cerrar esa puerta
# sin avisar.
#
# Suena a maquina, y eso es parte del trato: esto es un piso para poder jugar
# el juego entero con audio y hacer un playtest, no el audio final.
#
# --- La misma voz, en distintos estados ------------------------------------
#
# El final del juego dice que las grabaciones son todas de la misma voz, asi
# que la voz NO cambia entre registros. Lo que cambia es el estado: cada
# registro tiene su velocidad y su tono, derivados de su id, dentro de un
# rango chico. Es siempre la misma garganta en momentos distintos, que es lo
# que pide el documento de diseno. Al ser derivado del id, regenerar da
# exactamente el mismo resultado.

set -uo pipefail

TEXTO="${1:-}"
SALIDA="${2:-}"

if [[ -z "$TEXTO" || -z "$SALIDA" ]]; then
	echo "Uso: $0 <texto> <salida.wav>" >&2
	exit 2
fi

if ! command -v espeak-ng >/dev/null 2>&1; then
	echo "Falta espeak-ng. Instalalo:" >&2
	echo "  Debian/Ubuntu:  sudo apt install espeak-ng" >&2
	echo "  macOS:          brew install espeak-ng" >&2
	exit 127
fi

# El id del registro sale del nombre del archivo: rl_07_2.wav -> rl_07
BASE="$(basename "$SALIDA")"
LOG_ID="$(echo "$BASE" | sed -E 's/^(rl_[0-9]+).*/\1/')"

# Numero estable a partir del id, para que la variacion sea reproducible.
SEMILLA=$(echo -n "$LOG_ID" | cksum | cut -d' ' -f1)

# Rangos chicos a proposito: tiene que leerse como la misma persona.
#   velocidad 128-147 palabras/min (lento: alguien dictando un parte de noche)
#   tono      28-43            (grave: hombre cansado, y ademas la radio
#                               recorta los graves, asi que conviene empezar bajo)
VELOCIDAD=$((128 + SEMILLA % 20))
TONO=$((28 + SEMILLA % 16))

exec espeak-ng -v es-419 -s "$VELOCIDAD" -p "$TONO" -g 4 -w "$SALIDA" -- "$TEXTO"
