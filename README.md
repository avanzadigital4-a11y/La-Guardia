# La Guardia

Terror psicologico en primera persona, sin combate, en una estacion antartica
ficticia que cierra en cinco dias. Godot 4 (renderizador **Compatibility**),
estetica low-poly tipo PS1.

El documento de diseno completo esta en [`docs/diseno.md`](docs/diseno.md).

## Estado actual

Las cinco noches se juegan de punta a punta, cada una con sus propias tareas,
beats y variaciones de la estacion, y con dos finales. La Noche 1 es la que
esta mas pulida; las demas ya no son un esqueleto, pero les falta densidad de
props y detalle ambiental.

Cada noche pide un verbo distinto para que el loop no se sienta ejecutado
cinco veces: la 1 se resuelve recorriendo y apretando, la 2 escuchando una
senal entera, la 3 caminando hasta un lugar que se mueve, la 4 leyendo la
bitacora, y la 5 decidiendo.

Lo que ya funciona:

- Controlador del jugador: caminar, correr, mirar, cabeceo, pasos.
- Linterna con bateria limitada, parpadeo al agotarse y pilas de repuesto.
- Interaccion por raycast con prompt en pantalla (`[E]`).
- Lista de tareas por noche, con una tarea final que aparece al terminar.
- Panel de sensores con lecturas y mapa de niveles (donde aparece y
  desaparece el `SUBNIVEL B2`).
- Bitacora que acumula entradas, incluyendo las que el protagonista escribio
  esa misma noche admitiendo cosas que el jugador nunca hizo (marcadas en
  rojo).
- Registros de radio con subtitulos y ruido de portadora.
- Anomalias **fuera de camara**: el estado de un objeto cambia mientras el
  jugador no esta en la sala, sin animacion ni jumpscare.
- **El recorrido deja de llevar a donde deberia**: el pasillo sur se muerde
  la cola (caminas hasta el fondo y salis por la entrada, dos veces, hasta
  que deja de pasar) y la puerta del dormitorio da al almacen. Sin cortes ni
  pantallas de carga: se conserva la posicion relativa y hacia donde camina
  el jugador.
- Tareas que no se resuelven apretando `[E]`: llegar caminando a un lugar,
  escuchar un registro entero, releer la bitacora.
- Variaciones de la estacion por noche: un pasillo sur que no esta en los
  planos, el subnivel B2, la iluminacion, la niebla y el tinte de las
  paredes.
- Ciclo completo de cinco noches, con una decision en la ultima y dos
  finales: el principal del diseno y una variante mas cerrada.
- Beats guionados por noche (subtitulos, avisos, cortes de luz, entradas de
  bitacora que se escriben solas, anomalias) escritos como datos, no como
  codigo.
- Audio sintetizado en runtime (viento continuo, crujidos, puertas, pasos):
  el proyecto no depende de ningun asset externo.
- Post-proceso PS1: cuantizacion de color, grano, scanlines, vineta y
  aberracion cromatica, mas temblor de vertices en la geometria.

## Correr el juego

Con Godot 4.3 o posterior:

```bash
godot --path .            # o abrir el proyecto en el editor y darle Play
```

El renderizador es Compatibility y el viewport 3D corre al 55% de la
resolucion de ventana a proposito: es parte de la estetica y del objetivo de
hardware de gama baja.

### Controles

| Tecla | Accion |
|---|---|
| `WASD` / flechas | moverse |
| `Shift` | apurar el paso |
| mouse | mirar |
| `E` | interactuar |
| `F` | linterna |
| `TAB` | bitacora |
| `ESC` | soltar el mouse |

## Prueba automatica

Hay una prueba de integracion que juega la Noche 1 sola, verifica la anomalia
fuera de camara, el cierre de noche, las variaciones de la Noche 3 y el final
de la Noche 5:

```bash
godot --headless --path . res://tests/playthrough.tscn
```

Imprime `PLAYTHROUGH OK` y sale con codigo 0 si todo pasa.

Para revisar la estetica sin jugar, `godot --path . -- --capture` guarda una
captura de cada ambiente en el directorio `user://` del proyecto.

## Como esta armado

```
scenes/          main.tscn (entrada) y player.tscn
scripts/
  autoload/      GameState: noche actual, tareas, banderas, bitacora, guardado
  data/          night_data.gd: TODO el contenido por noche vive aca
                 (tareas, beats, variaciones, registros de radio)
  player/        controlador en primera persona
  world/         construccion de la estacion, interactuables y NightDirector
  ui/            HUD, bitacora, panel de sensores, fundidos, subtitulos
  audio/         AudioDirector: sintesis de viento, crujidos y golpes
shaders/         ps1_surface (temblor de vertices) y ps1_post (grano/scanlines)
tests/           recorrido automatico
docs/            documento de diseno
```

Dos decisiones que sostienen todo lo demas:

**Una sola escena base.** La estacion se construye por codigo en
`station_builder.gd` a partir de una tabla de salas. Ninguna noche agrega
geometria nueva: `night_director.gd` enciende o apaga tramos, cambia
materiales, niebla y luces segun `current_night`. Agregar una variacion de
noche es editar un diccionario en `night_data.gd`, no modelar nada.

**Las anomalias son cambios de estado, no secuencias.** Cada sala tiene un
`RoomWatcher` (Area3D). Cuando el jugador sale, el director aplica los
cambios que estaban armados para ese cuarto: la silla mira para otro lado, la
cama esta corrida, una puerta quedo abierta. Es mas barato que animar y
genera mas duda que un susto.

**Los beats son datos.** Cada noche define listas de acciones
(`{"subtitulo": ...}`, `{"parpadeo": 2.4}`, `{"armar": "dorm_chair",
"sala": "dormitorio"}`) que dispara el inicio de la noche o el fin de una
tarea. `night_director.gd` solo las interpreta, asi que escribir una noche
nueva no implica tocar codigo.

## Proximos pasos

1. Reemplazar o complementar el audio sintetizado con grabaciones reales,
   sobre todo las voces de los registros de radio: hoy son subtitulos sobre
   ruido de portadora y es lo que mas le falta al juego.
2. Densidad ambiental: props y detalle sala por sala (el maximo de diseno son
   2-3 por ambiente) y trabajo en el patio, que es el espacio mas vacio.
3. Pulir el ritmo de las noches 2 y 4, que hoy dependen mas del texto que de
   lo que pasa en el espacio.
4. Una pasada de balance de la linterna: cuanta bateria dura una noche
   completa y donde conviene dejar las pilas.
5. Menu de inicio, continuar partida (el guardado ya existe) y opciones.
