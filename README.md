# La Guardia

Terror psicologico en primera persona, sin combate, en una estacion antartica
ficticia que cierra en cinco dias. Godot 4 (renderizador **Compatibility**),
estetica low-poly tipo PS1.

El documento de diseno completo esta en [`docs/diseno.md`](docs/diseno.md), y
lo que falta hacer fuera de Godot (voces, arte, playtest, licencia) esta en
[`docs/produccion.md`](docs/produccion.md).

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
- **Catalogo de 71 anomalias** fuera de camara: el estado de un objeto cambia
  mientras el jugador no esta en la sala, sin animacion ni jumpscare. Objetos
  que se mueven, que faltan, que aparecen, puertas que quedan abiertas, salas
  que se apagan. Cada noche arma su propio lote, mas unas cuantas al azar del
  catalogo: dos partidas no traen exactamente los mismos cambios.
- **Audio provisorio para las 107 lineas** de los registros, generado con
  espeak-ng (`tools/generar_voces_tts.sh`). Suena a maquina: es un piso para
  poder jugar el juego entero con audio y hacer un playtest, no el audio
  final. Se reemplaza de a una grabando encima, sin tocar codigo. El por que
  de espeak y no una voz mejor (licencia) esta en
  [`docs/produccion.md`](docs/produccion.md).
- **35 registros de radio** (107 lineas, unos 7 minutos de audio) repartidos
  por la estacion, el subnivel y el patio, con su noche de aparicion escrita
  en la misma tabla.
- **El parte del turno**: la hoja sobre la mesa de control. Las tres primeras
  noches esta en blanco. La Noche 4 la levantas y ya esta escrita, con tu
  letra, y lo que lista es lo que de verdad cambio en **esta** partida
  (incluidas las anomalias que salieron al azar), con la hora del pie
  anterior a que pasara nada. La Noche 5 la cierra juntando las cinco noches.
  Es el unico lugar donde el juego dice en limpio que las anomalias las
  causaste vos, y no es texto guionado: sale de lo que jugaste.
- **El apagon**: quedarte sin luz no te mata ni corta la partida. Fundido a
  negro, y despertas en la cucheta sin acordarte de haber vuelto, con horas
  de menos. Lo que cuesta: las pilas de repuesto que llevabas encima no
  estan, la linterna vuelve con poca carga, y **lo que paso mientras estabas
  a oscuras queda anotado a tu nombre** -- o sea que aparece despues en el
  parte del turno, con tu letra. Es la forma mas directa que tiene el juego
  de convertirte en el autor de las anomalias sin que lo recuerdes. El final
  cuenta cuantas horas del turno no figuran.
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
- **Luz y sombra.** Hasta ahora ninguna luz de la estacion proyectaba sombra
  (las catorce con `shadow_enabled = false`) y `Build.box` ademas apagaba el
  proyectado en cada malla: la estacion entera era transparente a la luz y
  cada sala quedaba banada pareja. Ahora hay sombras, con presupuesto: solo
  las tres luces mas cercanas al jugador proyectan, que son las unicas cuya
  sombra se distingue. La luz ambiente bajo de 0.55 a 0.10 y la atenuacion
  subio, asi que la luz forma charcos en vez de banar. **Es lo mas caro del
  cuadro y se puede apagar desde Opciones.**
- **Silueta**: canos, bandejas de cable, abrazaderas y rejillas de
  ventilacion. No son props en el sentido del documento (que limita props
  unicos por habitacion): son arquitectura, todas cajas del mismo primitivo,
  sin un asset nuevo. Una sala que es una caja vacia se lee como una caja
  vacia por buena que sea la textura. Y ahora que hay sombras, un cano
  cruzado sobre una lampara raya el piso.
- **Mapeo afin de texturas**: la otra mitad de la firma PS1. La consola no
  corregia la perspectiva al interpolar coordenadas de textura, y por eso las
  texturas se retuercen al mirar en diagonal. El temblor de vertices ya
  estaba; esto es lo que faltaba para que se lea PS1 y no low-poly moderno.
- **Texturas generadas por codigo** (`scripts/world/textures.gd`): chapa con
  juntas y remaches, placas de piso, rejilla, metal rayado, oxido, nieve y
  hormigon para el B2. Ningun archivo de imagen, ninguna licencia que revisar.
  64x64 pixeles, filtro Nearest y sin mipmaps, porque el aliasing es parte del
  look. Se mapean triplanar desde coordenadas de mundo, asi que no hay que
  desplegar UV en geometria generada por codigo, y una pared de 8 metros y una
  de 3 se leen iguales. Son grises y multiplican al color, asi que el tinte
  por noche sigue funcionando igual.
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

## Licencia

Todos los derechos reservados. Ver [`LICENSE`](LICENSE). Es la opcion
reversible mientras no este publicado: se puede abrir mas adelante, no se
puede cerrar lo ya abierto. El plan de publicacion (itch.io con pago
voluntario, Steam despues si hay traccion) esta en
[`docs/diseno.md`](docs/diseno.md).

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
      2    114.4 s     158.5 m       29 %        5          13           7
      3    192.0 s     327.0 m       48 %        7          20          11
      4    205.5 s     300.3 m       51 %        8          26          14
      5    221.2 s     390.5 m       55 %        6          32          18

  total directo       839.3 s   (14.0 min)
  distancia total    1352.3 m
  bateria: la peor noche gasta 55 % de una carga; hay 6 cargas
           alcanzan para 10.9 noches asi -> sobra demasiado, rebalancear
  explorando (x2-x3)   28.0 a 42.0 min, mas 6.8 min de audio
  objetivo del diseno   60 a 90 min
```

**El objetivo dejo de ser 2-3 horas.** Para una persona sola, y sin arte ni
audio todavia, 60 a 90 minutos es lo que se puede terminar; *Iron Lung*, una
de las referencias, dura alrededor de una hora. Hoy estamos en 14 minutos de
recorrido directo y entre 28 y 42 explorando, mas 6 de audio: **falta mas o
menos la mitad otra vez.**

La curva ya es creciente, que es como tiene que ser: la rutina de la Noche 1
se aprende rapido y aburre si dura, y la ultima noche tiene que pesar. De
107 s a 221 s, sin pozos en el medio.

La bateria empezo a significar algo: la peor noche gasta un 55 % de una
carga contra el 32 % de antes. Pero **sobra demasiado y hay que rebalancear**,
y el medidor ahora lo dice solo. Al poner dos pilas en el B2 (sin ellas, el
que explora la zona mas profunda y oscura se queda sin luz y sin forma de
recuperarla) el total subio a seis cargas para una noche que gasta media:
alcanza para once noches. La linterna no puede importar con ese margen. El
numero correcto sale de un playtest, no de una cuenta, asi que queda anotado
en vez de tocado a ojo.

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

**Cuidado con una sola corrida, y con comparar entre sesiones.** Entre
corridas seguidas la dispersion es de mas o menos 1.3 FPS, asi que una
diferencia menor a eso es ruido. Pero entre sesiones distintas la diferencia
es muchisimo mayor: el mismo codigo midio 26 FPS una vez y 43 otra, segun lo
ocupada que estuviera la maquina. **Los numeros absolutos de este README no
sirven para comparar contra una medicion de otro dia.** La unica comparacion
que vale es A/B pareado: medir las dos variantes una atras de otra, en la
misma corrida de condiciones.

Las **texturas procedurales salen gratis**: A/B pareado de dos corridas cada
uno dio 42.6 FPS con textura contra 43.2 sin, o sea nada. El triplanar cuesta
mas por fragmento en teoria, pero el cuello de botella esta en otro lado.

Las **sombras no salen gratis**, y es el unico cambio de arte que costo algo
medible. A/B pareado:

```
  sin sombras            42.6 FPS promedio, 36 en percentil 1%
  con sombras            33.6                26
  + atlas 1024 y duro    36.2                29.5
```

Achicar el atlas de sombras a 1024 recupero un tercio del costo **y ademas
mejora el look**: sombras mas duras y escalonadas es lo que pide la estetica.

**Cuidado al leer ese numero.** llvmpipe rasteriza en CPU, asi que penaliza
el relleno de los mapas de sombra mucho mas que una GPU real, por debil que
sea. Es muy probable que en hardware de verdad el costo sea bastante menor.
Esto no se sabe hasta medirlo en la maquina objetivo, y es la razon mas
concreta que hay hoy para hacerlo. Mientras tanto, las sombras se apagan
desde Opciones.

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

Eso escribe `localizacion/la-guardia.pot` con los 353 textos del juego (los de
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
