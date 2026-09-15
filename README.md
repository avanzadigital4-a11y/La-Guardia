# La Guardia

Terror psicologico en primera persona, sin combate, en una estacion antartica
ficticia que cierra en cinco dias. Godot 4 (renderizador **Compatibility**),
estetica low-poly tipo PS1.

El documento de diseno completo esta en [`docs/diseno.md`](docs/diseno.md).

## Estado actual

Las cinco noches se juegan de punta a punta, cada una con sus propias tareas,
beats y variaciones de la estacion, y con dos finales. El giro central del
diseno — que las anomalias las causo el propio protagonista — ya no vive solo
en el texto de la bitacora: el parte del turno se lo muestra al jugador con
lo que paso en su partida. La Noche 1 es la que esta mas pulida; las demas ya
no son un esqueleto, pero les falta densidad de props y detalle ambiental.

Cada noche tiene cuatro, cinco o seis tareas y ninguna se resuelve toda de la misma
forma: apretar `[E]`, recorrer varios puntos, escuchar una senal entera,
llegar caminando a un lugar que se mueve, contar objetos, releer la bitacora,
dejar la estacion en cierto estado, y decidir.

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
- **Catalogo de 61 anomalias** fuera de camara: el estado de un objeto cambia
  mientras el jugador no esta en la sala, sin animacion ni jumpscare. Objetos
  que se mueven, que faltan, que aparecen, puertas que quedan abiertas, salas
  que se apagan. Cada noche arma su propio lote, mas unas cuantas al azar del
  catalogo: dos partidas no traen exactamente los mismos cambios.
- **32 registros de radio** (98 lineas, unos 7 minutos de audio) repartidos
  por la estacion, el subnivel y el patio, con su noche de aparicion escrita
  en la misma tabla.
- **El parte del turno**: la hoja sobre la mesa de control. Las tres primeras
  noches esta en blanco. La Noche 4 la levantas y ya esta escrita, con tu
  letra, y lo que lista es lo que de verdad cambio en **esta** partida
  (incluidas las anomalias que salieron al azar), con la hora del pie
  anterior a que pasara nada. La Noche 5 la cierra juntando las cinco noches.
  Es el unico lugar donde el juego dice en limpio que las anomalias las
  causaste vos, y no es texto guionado: sale de lo que jugaste.
- **Objetos para mirar de cerca**: se levantan, se giran con el mouse, y lo
  que dicen cambia noche a noche (la chapa con tu numero de turno, la foto del
  equipo a la que le van faltando personas). Verificado por la suite: al
  soltarlos vuelven exactamente a donde estaban.
- **El recorrido deja de llevar a donde deberia**: el pasillo sur se muerde
  la cola (caminas hasta el fondo y salis por la entrada, dos veces, hasta
  que deja de pasar) y la puerta del dormitorio da al almacen. Sin cortes ni
  pantallas de carga: se conserva la posicion relativa y hacia donde camina
  el jugador.
- Tareas que no se resuelven apretando `[E]`: llegar caminando a un lugar,
  escuchar un registro entero, releer la bitacora.
- Tareas de varios pasos: los dos generadores, los tres puntos de la ronda
  exterior. El HUD muestra el progreso (`2/3`).
- Tareas por condicion: "dejar todas las puertas cerradas" no se aprieta en
  ningun lado, se cumple dejando la estacion como tiene que quedar — y las
  anomalias abren puertas.
- Contar los trajes de la esclusa como tarea del turno: el numero cambia solo
  y la bitacora lo anota.
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
- Menu de inicio con tres ranuras de guardado (con la noche, la fecha y si
  quedo a mitad de noche), borrado con confirmacion, creditos y opciones.
- Opciones que persisten entre sesiones: sensibilidad, volumen, pixelado,
  efectos PS1, pantalla completa, invertir eje Y, cabeceo al caminar, campo de
  vision, tamano de subtitulos y **reasignacion de teclas**.
- **Guardado a mitad de noche**: se autoguarda con cada tarea completada y al
  pausar. Continuar devuelve las tareas hechas, la bateria, la posicion del
  jugador, las puertas, las anomalias ya aplicadas y las que estaban armadas.
- Voz de radio sintetizada: no dice palabras, imita la cadencia del habla
  detras de la portadora mientras corren los subtitulos.
- Sonido ambiente posicional: los crujidos y los golpes salen de una sala
  concreta, siempre lejos de donde esta el jugador, y los pasos cambian
  adentro (chapa) y afuera (nieve).

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
| `ESC` | pausa / cerrar lo que este abierto |

## Pruebas automaticas

Una prueba de integracion juega la Noche 1 sola y verifica la anomalia fuera
de camara, el cierre de noche, el desvio de rutas de la Noche 3, las tareas
que no se resuelven con `[E]`, la decision de la Noche 5 y el final:

```bash
godot --headless --path . res://tests/playthrough.tscn   # PLAYTHROUGH OK
godot --headless --path . res://tests/content.tscn       # CONTENIDO OK
godot --headless --path . res://tests/ui_smoke.tscn      # UI SMOKE OK
godot --headless --path . res://tests/pacing.tscn        # medicion de ritmo
```

O todas juntas, con el runner que usa tambien el CI:

```bash
./tools/test.sh              # content + playthrough + ui_smoke
./tools/test.sh playthrough  # una sola
```

Busca el binario en `$GODOT`, en `~/godot` o en el `PATH`, reimporta el
proyecto antes de empezar (sin eso una clase nueva no existe todavia para el
parser) y falla si alguna suite devuelve error o imprime `FALLA`. Cada suite
corre con limite de tiempo (`TIMEOUT`, 420 s por defecto): si una escena no
compila, el `quit()` de la prueba nunca se ejecuta y Godot headless se
quedaria esperando para siempre. Cada push las corre en GitHub Actions
(`.github/workflows/pruebas.yml`).

Las tres primeras salen con codigo 0 si todo pasa. `content` es la red de
seguridad para seguir agregando contenido: verifica que cada anomalia apunte
a un objeto, puerta o luz que exista, que las cinco noches no nombren nada
que no este, que toda tarea tenga como resolverse, que los registros esten
colocados, que cada anomalia tenga su linea para el parte del turno, y que
aplicar las 61 anomalias juntas y revertirlas deje la estacion como estaba.

## Ritmo medido

`tests/pacing.tscn` camina **las cinco noches** como las caminaria alguien que
va derecho a cada tarea, acelerado con `Engine.time_scale`. No hay rutas
escritas a mano: resuelve cada tarea buscando su punto en la estacion y arma
el camino pasando por el pasillo, asi la medicion sigue valiendo cuando se
agregan tareas nuevas (que es justamente para lo que se usa). Si una tarea
queda sin punto en el mundo, lo dice.

```
  noche   duracion   distancia   bateria   tareas   registros   anomalias
      1    106.6 s     175.9 m       27 %        4           6           2
      2     98.4 s     135.4 m       25 %        4          13           7
      3    128.3 s     207.1 m       32 %        5          20          11
      4    129.6 s     172.4 m       32 %        6          26          14
      5    129.0 s     210.4 m       32 %        5          32          18

  total directo       591.7 s   (9.9 min)
  distancia total     901.2 m
  bateria: la peor noche gasta 32 % de una carga; hay 4 cargas
  explorando (x2-x3)   19.7 a 29.6 min, mas 6.2 min de audio
  objetivo del diseno  120 a 180 min
```

Antes esto media solo la Noche 1 y el total salia de extrapolar. Ahora esta
medido: **10 minutos de recorrido directo y entre 20 y 30 explorando, contra
las 2-3 horas que pide el diseno.** Falta entre cuatro y seis veces el
contenido actual, y la diferencia es de contenido, no de ritmo.

Dos cosas que el numero deja ver:

- Las cinco noches duran casi lo mismo (98 a 130 s). La Noche 5 deberia ser
  la mas larga y no lo es.
- La bateria sobra por goleada: la peor noche gasta un tercio de una carga y
  hay cuatro. El balance actual solo se sostiene porque las noches son
  cortas, y hay que rehacerlo cuando crezcan.

## Medir el rendimiento

`[F3]` dentro del juego muestra FPS, draw calls, primitivas, VRAM y escala 3D.

Para medir con un recorrido fijo y comparable (pensado para correrlo en la
maquina objetivo, no en la de desarrollo):

```bash
godot --path . res://tools/benchmark.tscn    # sin --headless: mide el render
```

Recorre la estacion girando la camara todo el tiempo (el caso peor para el
culling) e imprime FPS promedio, minimo y percentil 1%.

Sin GPU a mano se puede medir por software. Los numeros absolutos no son los
de la maquina objetivo, pero sirven para comparar un cambio contra si mismo:

```bash
xvfb-run -a -s "-screen 0 1152x648x24" env LIBGL_ALWAYS_SOFTWARE=1 \
  godot --path . --rendering-driver opengl3 res://tools/benchmark.tscn
```

**Cuidado con una sola corrida.** La dispersion entre corridas identicas es de
mas o menos 1.3 FPS sobre unos 26, asi que una diferencia de menos de eso no
es una mejora, es ruido. Hay que medir varias veces y comparar medianas.

Ya se probo una cosa que **no** funciono: apagar las luces lejanas para dejar
como maximo cuatro prendidas a la vez. Tres corridas pareadas dieron 26.1
contra 25.7 FPS de promedio, o sea nada frente al ruido. Godot ya descarta por
alcance las luces que no tocan un objeto, asi que el cuello de botella esta en
otro lado. Si alguien lo vuelve a intentar, que mida primero en la maquina
objetivo.

## Exportar

Hay presets para Linux y Windows en `export_presets.cfg` (excluyen `tests/`,
`docs/` y `tools/` del build):

```bash
godot --headless --path . --export-release "Linux"   build/linux/la-guardia.x86_64
godot --headless --path . --export-release "Windows" build/windows/la-guardia.exe
```

Requiere tener instaladas las export templates de Godot 4.3.

El workflow `.github/workflows/build.yml` hace lo mismo en GitHub Actions al
publicar un tag `v*` (o a mano desde la pestana Actions) y sube los dos builds
como artefactos.

## Traducir

Todo el texto que ve el jugador pasa por `tr()` en los puntos donde sale a
pantalla, asi que las tablas de contenido siguen escritas en castellano
normal. La plantilla se genera con:

```bash
godot --headless --path . res://tools/exportar_traduccion.tscn
```

Eso escribe `localizacion/la-guardia.pot` con los 314 textos del juego (los de
las tablas y los de la interfaz, cada uno con una nota de donde sale). Para
agregar un idioma: copiar el `.pot` a `localizacion/en.po`, completar los
`msgstr` y registrarlo en Proyecto > Configuracion > Localizacion.

## Como esta armado

```
scenes/          main.tscn (entrada) y player.tscn
scripts/
  autoload/      GameState: noche actual, tareas, banderas, bitacora, guardado
  data/          night_data.gd (tareas, beats, variaciones, registros) y
                 anomaly_data.gd (catalogo de anomalias y objetos extra)
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
2. Arte: texturas (aunque sean chicas), props modelados y una tipografia
   propia. Hoy la estacion son cajas de color plano.
3. Iluminacion horneada, que es lo que pide el diseno y lo que falta para
   cumplir el objetivo de hardware de gama baja. Nunca se midio un FPS en un
   equipo asi.
4. Playtest con personas. Todo lo que sabemos del ritmo sale de un bot que
   camina derecho.
5. Seguir subiendo el contenido por noche hasta acercarse a las 2-3 horas del
   diseno, midiendo con `tests/pacing.tscn` cada vez: mas tareas por noche y
   mas para encontrar, no mas texto.
6. Definir la licencia del proyecto: todavia no hay archivo `LICENSE`, y esa
   decision es del autor.
