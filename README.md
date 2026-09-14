# La Guardia

Terror psicologico en primera persona, sin combate, en una estacion antartica
ficticia que cierra en cinco dias. Godot 4 (renderizador **Compatibility**),
estetica low-poly tipo PS1.

El documento de diseno completo esta en [`docs/diseno.md`](docs/diseno.md).

## Estado actual

Vertical slice jugable: la **Noche 1 completa de punta a punta** (lista de
tareas -> recorrido -> evento extrano -> cierre de noche) sobre el framework
que maneja las cinco noches. Las noches 2 a 5 ya corren con sus variaciones
de mundo y sus beats definidos en datos, con menos contenido propio: son la
base para iterar, no el contenido final.

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
- Variaciones de la estacion por noche: un pasillo sur que no esta en los
  planos, el subnivel B2, la iluminacion, la niebla y el tinte de las
  paredes.
- Ciclo completo de cinco noches con el final principal del diseno.
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

## Proximos pasos

En orden de prioridad, siguiendo el riesgo que marca el documento de diseno
(que el loop se sienta mecanico):

1. Darle a las noches 2 a 4 el mismo nivel de contenido que la 1: mas beats
   propios, mas registros de radio, y que la tarea del medio cambie de forma
   (no siempre "ir y apretar").
2. Que el recorrido de la Noche 3 realmente no lleve a donde deberia: hoy el
   pasillo sur aparece, pero falta que una ruta conocida cambie de destino.
3. Mas props por sala (el maximo de diseno son 2-3) y detalle en el patio.
4. Reemplazar o complementar el audio sintetizado con grabaciones reales,
   sobre todo las voces de los registros de radio.
5. Los 1-2 finales alternativos mas cerrados como variantes menores.
