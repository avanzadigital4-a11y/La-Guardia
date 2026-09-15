# La Guardia — Documento de diseño

## Premisa

Sos el último cuidador nocturno de una estación de investigación remota en la Antártida (ficticia, no basada en ninguna base real) que va a cerrar definitivamente en cinco días. Tu trabajo en el papel es simple: hacer rondas, revisar el generador, monitorear sensores, y sobrevivir al aislamiento hasta que llegue el vehículo de evacuación. El juego nunca confirma si lo que empieza a pasar es real o si es la mente del protagonista rompiéndose por el aislamiento extremo. Esa ambigüedad es el eje central de la experiencia.

## Género y referencias

Terror psicológico, exploración en primera persona, sin combate. Estética visual low-poly tipo PS1 (referencias: *Crow Country*, *Iron Lung*, *Amnesia: The Dark Descent*, *SOMA*).

**Duración objetivo: 60-90 minutos.** (Revisado. El objetivo original era 2-3 horas; para un desarrollador solo eso no se termina. *Iron Lung*, una de las referencias, dura cerca de una hora.) El estado medido está en el README, sección "Ritmo medido": `tests/pacing.tscn` camina las cinco noches y da el número real. Hoy: 15.9 minutos de recorrido directo, 32 a 48 explorando, más 9.4 de audio.

## Loop central

`tarea → recorrido → anomalía → registro → volver a la base → siguiente noche`

**El terror va adentro de la tarea, no entre las tareas.** Es la corrección más
importante que recibió el diseño. Purgar una válvula y alinear una antena son
tareas neutras: si lo raro pasa en el pasillo mientras vas de una a otra, el
bucle se lee como trabajo administrativo con sustos alrededor. Cuando la
válvula ya estaba cerrada, cuando la planilla del generador tiene la revisión
de esta noche firmada a una hora que todavía no pasó, cuando contás tres
balizas cuatro veces — ahí el trabajo **es** el terror. Toda tarea de toda
noche tiene su beat, y `tests/content.tscn` falla si alguna queda sin uno.

**Mirar es un verbo, y se enseña temprano.** Las 82 anomalías solo pagan si el
jugador compara una sala con su recuerdo de la sala, y eso no se aprende solo:
hay que pedirlo. La tarea de recuento aparece en la Noche 2 con dos salas, en
la 3 con tres y en la 4 con cuatro. La de la Noche 4 ya existía; las otras dos
son la lección que faltaba.

**Y no todas se miran.** Es el riesgo que tiene pedirle al jugador que compare
salas: si todas las anomalías son un objeto que cambió de estado, aprende que
el juego consiste en buscar el objeto distinto y el terror se vuelve un juego
de las siete diferencias. Durante mucho tiempo los cinco tipos que había
—mover, faltar, aparecer, puerta, luz— eran exactamente eso.

Ahora hay tres que no se miran:

- **sonido** — algo quedó andando donde no hay nada que pueda andar: un goteo
  en el dormitorio, un motor en el almacén, las bombas del B2 en marcha con el
  equipo apagado. No hay objeto que buscar; hay que notar que algo se escucha,
  y eso es mucho más difícil de descartar como "me pareció".
- **espacio** — una pared se corrió. La sala es la misma sala y todo está en
  su lugar; lo que cambió son las proporciones. Es lo que este documento pedía
  desde el primer día ("proporciones que ya no coinciden del todo") y nunca
  había tenido con qué hacerse.
- **reloj** — la hora del turno no es la que era. Es la única anomalía que el
  jugador no puede atribuir a la estación mirando un objeto, porque el objeto
  es la hora.

Están repartidas a propósito: la primera sonora en la Noche 2, la espacial en
la Noche 3 (que se llama "el espacio interfiere"), y el reloj en la Noche 4,
que es la noche de no confiar en uno mismo.

Simple y repetible, pero **debe evolucionar noche a noche** — nunca debe sentirse como la misma secuencia ejecutada cinco veces, o el jugador cae en piloto automático.

## El protagonista

**Por qué se quedó solo: no se fue.** Los demás salieron en el último relevo y
él no subió al vehículo. Eso es todo. No hay una explicación heroica ni una
orden: simplemente no subió.

Nadie lo dice en voz alta durante el juego. No hay una línea que lo confiese.
Se deduce de lo que ya está puesto en el mundo: los cinco trajes de la esclusa
que van faltando, la foto del equipo a la que le van sacando gente, su legajo
archivado en el B2 con fecha de cierre. El punto de partida ya es una
anomalía, y el jugador no tiene por qué notarlo hasta el final.

Es lo que hace funcionar el remate. Si nunca subió al vehículo, que la radio
diga que hace once meses no hay personal asignado a esa estación deja de ser
un dato suelto: es la única lectura posible de todo lo anterior.

**Qué tiene que sentir el jugador, y desde cuándo.** Al principio *sos* él, sin
distancia: hacés sus tareas, leés su bitácora, aceptás su versión. La duda no
se siembra antes de tiempo — llega de golpe en la Noche 4, cuando el parte del
turno ya está escrito con tu letra y con la hora del pie anterior a que pasara
nada.

Esto tiene una consecuencia concreta para escribir: **las noches 1 a 3 no
pueden insinuar que el protagonista es poco confiable.** Todo lo raro de esas
noches tiene que poder leerse como que la estación es la que está mal, no él.
El golpe de la Noche 4 solo existe si antes hubo identificación sin reservas.

### La tensión con la planilla de la Noche 1

La Noche 1 termina en *"es mi letra"*, y eso roza la regla de arriba. Queda
anotado acá en vez de disimulado, porque es una decisión discutible y el autor
puede querer revertirla.

**Por qué se cree que funciona igual.** En la Noche 1 el jugador no tiene
todavía ninguna base de comparación: no vio nunca su propia letra en el juego,
no escribió ninguna entrada, no firmó nada. Sin esa base, *"es mi letra"* se
lee como **alguien me está falsificando** — o sea, la estación está mal —, que
es exactamente la lectura que las noches 1 a 3 necesitan. La lectura de "el
poco confiable soy yo" solo se vuelve disponible en la Noche 4, cuando el
jugador ya tiene tres noches de bitácora propia contra las cuales comparar y
el parte del turno ya está firmado.

O sea: el mismo hecho se lee de dos maneras distintas según cuándo, y la
segunda lectura llega justo cuando tiene que llegar. Si eso no se sostiene en
un playtest, el arreglo es chico: sacar la línea *"Es mi letra"* del beat de
`generator` en la Noche 1 y dejar solo la hora imposible.

**Por qué se puso igual, aun sabiendo el riesgo.** La Noche 1 estaba diseñada
como "todo normal" y tenía dos anomalías en ocho minutos. Los primeros diez
minutos son los que deciden si alguien sigue jugando o si un streamer sigue
grabando. Un documento de diseño puede permitirse una primera noche tranquila;
un juego publicado sin nombre, no.

**Se llama Olmedo. El jugador no lo lee nunca.**

El nombre existe en la ficción y gobierna cómo se escribe, pero no aparece en
ninguna línea que el jugador pueda leer. No es un olvido: es la regla. Sos él,
y uno no lee su propio nombre.

Eso el juego ya lo venía haciendo sin que estuviera escrito acá. La chapa de
identificación dice *"tu nombre y el número de turno: 14"* en la Noche 1, y
*"el nombre está frotado hasta casi borrarse"* en la Noche 5. La chapa que se
gasta es la identidad que se gasta, y funciona sin explicarse.

**Consecuencia para escribir, y es una regla dura: ninguna línea nueva puede
nombrarlo.** Ni un registro de radio, ni una entrada de bitácora, ni el parte
del turno. Si alguna vez tuviera que figurar en un papel institucional —un
legajo, una planilla— va solo el apellido, nunca el nombre de pila: esos
papeles usan apellido, y el nombre de pila lo usa la gente que te conoce. No
queda nadie que lo conozca.

**Es uno de los cinco de la foto.** El equipo eran cinco, y un registro ya lo
dice al pasar: *"Tres de los cinco reportan haber despertado de pie en el
pasillo."* Los otros cuatro salieron en el último relevo.

Eso resuelve algo que estaba suelto. La foto del equipo pierde gente noche a
noche: cinco, cuatro, tres, y en la Noche 5 *"una sola persona, de espaldas"*.
**La foto no está registrando que se fueron: la están recortando.** Y el que
queda es él. Es la misma mano que mueve las sillas y escribe el parte, y es la
lectura que el juego quiere que el jugador arme solo, sin que nadie se la
diga.

## Estructura narrativa (5 noches, con evolución del loop)

- **Noche 1 — Rutina.** Tarea → recorrido → un evento extraño aislado. El jugador aprende el layout y los sistemas. Todo parece tranquilo.

  **Salvo una cosa, y va en la primera tarea.** La planilla de GEN-A ya tiene
  la revisión de esta noche firmada, a una hora que todavía no pasó, con tu
  letra. No es un susto: es una incorrección administrativa, que es peor,
  porque no se puede atribuir al viento ni a los nervios. Va en el minuto
  cuatro de la partida a propósito — es cuando el jugador (o el streamer)
  decide si sigue. Y siembra el giro entero sin nombrarlo: en la Noche 4 el
  parte del turno va a estar completo por exactamente la misma razón.
- **Noche 2 — Primera desviación.** Tarea → recorrido → anomalía → el jugador elige investigarla por su cuenta, saliéndose de la rutina establecida.
- **Noche 3 — El espacio interfiere.** Tarea → anomalía → el recorrido planeado ya no lleva a donde debería (una ruta cambia, aparece un pasillo que no estaba en los planos).
- **Noche 4 — Pérdida de confianza.** Objetivo → recuerdos contradictorios (bitácora) → investigar → el jugador ya no sabe si puede confiar en lo que ve o recuerda.
- **Noche 5 — Cierre.** Decisión → exploración final → desenlace. No debe sentirse como "otra ronda más", sino como la noche que rompe todo.

**Las noches crecen.** No duran lo mismo: la rutina de la Noche 1 se aprende rápido y aburre si se estira, y la última tiene que pesar. La curva medida hoy va de 107 s (Noche 1) a 248 s (Noche 3) de recorrido directo, con la 4 y la 5 sostenidas arriba de 200, sin pozos en el medio. El B2 es el que hace crecer las noches 3 y 5; la Noche 4 crece en superficie, porque esa noche el subnivel no está.

## Técnica de producción: mismo espacio, variaciones sutiles

En vez de construir escenarios nuevos cada noche, se reutiliza la misma estación y se altera su estado entre noches: puertas que antes estaban cerradas ahora abiertas, un pasillo que antes no existía, proporciones que ya no coinciden del todo. Se implementa con **una sola escena base en Godot**, controlando qué objetos están visibles y qué materiales se usan según una variable de "noche actual" (`current_night`). No se modela nada nuevo por noche — es la decisión de producción más importante del proyecto, porque multiplica el contenido percibido sin multiplicar el trabajo real.

## Anomalías fuera de cámara

No todo lo raro ocurre frente al jugador. Algunos cambios pasan mientras no está mirando: sale de un cuarto, vuelve, y algo cambió sin que viera la transición (una puerta que se abrió sola, una silla que ahora mira hacia otro lado, una cama ligeramente desplazada). Se implementa con un `Area3D` que detecta cuándo el jugador sale de una habitación; mientras no está presente, se cambia el estado del objeto. Es más barato de producir que una secuencia animada y genera más inquietud que un jumpscare.

**Evitar el jumpscare como recurso principal.** El juego funciona mejor generando duda ("¿siempre estuvo así? ¿cuándo cambió? ¿lo vi cambiar y no me di cuenta?") que con sustos directos.

## Mecánicas jugables

1. **Lista de tareas por noche** — checklist simple (ej. "revisar generador", "ronda exterior", "verificar sensores nivel 1"). Da estructura sin necesitar objetivos complejos.
2. **Panel de sensores** — pantalla de control con temperatura, viento, presión, radiación y un mapa de niveles de la estación. Implementado como una lista de datos en código (fácil de modificar). Gancho narrativo clave: un "subnivel" (ej. `SUBNIVEL B2`) aparece en el mapa una noche sin figurar en los planos oficiales, y en otra visita ya no está.

   **El B2 es una zona, no una sala.** Cinco espacios encadenados hacia abajo: entrada (baja por una rampa desde el pasillo sur), un pasillo, sala de bombas al oeste, archivo al este, y el fondo con las marcas en la pared y la decisión de la última noche. Existe solo las noches que la tabla lo enciende. Tiene tareas propias (purgar las dos bombas, buscar el propio legajo — archivado con fecha de cierre de hace once meses—, cerrar las tres llaves de paso), sus propias anomalías, sus propios registros de radio y sus propias pilas. La **Noche 4 lo apaga a propósito**: bajar y encontrar pared donde estaba la rampa es una tarea de esa noche.
3. **Registros de radio reproducibles** — audios encontrados en el mundo, algunos marcados "desconocido". Barato de producir (solo audio, sin animación) y muy efectivo narrativamente.
4. **Bitácora que se autoactualiza y contradice al jugador** — en vez de una sola entrada nueva por noche, algunas noches revelan una secuencia corta de 2-3 anotaciones que el protagonista escribió esa misma noche, admitiendo acciones que el jugador nunca realizó en el gameplay. Ejemplo:
   - `23:41 — Abrí la puerta del generador.`
   - `23:43 — No debí abrirla.`
   - `23:47 — Él todavía no sabe que fui yo.`

   Esto convierte al propio sistema de registro en una fuente de terror, no solo en una pista informativa.
5. **Linterna con batería limitada** — fuente de luz principal, obliga a gestión de recursos sin necesitar combate.

   **Las pilas no se reponen entre noches.** Las seis de la estación más la
   carga inicial son para las cinco noches: el turno entero es un solo
   presupuesto de luz. Durante mucho tiempo `start_night` las reponía todas
   las noches, así que había seis cargas por turno contra una noche que
   gastaba media, y la linterna no podía significar nada. Medido hoy: 1.18x
   de lo que consume explorar (banda objetivo 1.1 a 2.0, ver README).

   **Qué se pierde: el apagón.** Doce segundos sin linterna en una sala apagada y hay fundido a negro. Se despierta en la cucheta, sin acordarse de haber vuelto, con dos a cuatro horas del turno de menos. No hay game over: el peligro nunca es físico. Lo que cuesta es concreto — las pilas de repuesto que llevaba encima desaparecen, la linterna vuelve con poca carga, y **se aplican dos anomalías que quedan registradas como propias**, o sea que aparecen después en el parte del turno con su letra. El apagón no es un castigo agregado: es la vía más directa al giro del final. El final acusa cuántas horas del turno no figuran.
6. **Sin combate, sin monstruo que persigue activamente** — el peligro es ambiental y psicológico, nunca una amenaza física directa.

## Final (el más fuerte narrativamente)

El jugador descubre que algunas de las anomalías las causó él mismo, en estados que no recuerda. Al llegar el vehículo de evacuación, una transmisión de radio revela: *"No hay personal asignado a esa estación desde hace 11 meses."*

**Pero esa línea no es el remate: es el permiso para releer.** Un dato que se
agota en sí mismo es un giro; lo que hace memorable a un final de este tipo es
que obligue a repasar las cinco noches y descubrir que cada cosa que el jugador
le atribuyó a la estación tenía otra explicación, y la tuvo desde el principio.

Por eso, después de la radio, el juego nombra tres momentos de **esta** partida
—uno temprano, uno del medio y uno del final— en primera persona y en pasado, y
cierra con *"nada de eso lo hizo la estación"* y con la planilla de la Noche 1.
No es texto escrito de antemano: sale de `GameState.anomalies_seen`, el
historial real, así que dos partidas dan dos remates distintos y ninguno
menciona nada que no haya pasado. No se explica qué fue exactamente lo que pasó — la ambigüedad final es intencional y es el gancho memorable del juego. **Decidido: dos finales, y no más.** El principal (salir al patio y esperar el
vehículo) y una variante (cerrar la escotilla del B2 desde adentro y quedarse).
Los dos están construidos. No se agregan más: la ambigüedad del final principal
es el gancho, y cada final extra la diluye además de competir por el contenido
que falta para llegar a los 60-90 minutos.

## Estética visual

Low-poly estilo PS1: geometría simple (pocas caras, sin suavizado), niebla espesa para limitar la distancia de dibujado, shader de post-proceso con grano tipo VHS/scanlines y viñeta en los bordes.

**Lo que se construyó, que es más de lo que este párrafo pedía.** Cuatro capas,
todas por código y sin un solo archivo de imagen:

- **Textura.** Ocho texturas procedurales de 64 px (chapa, piso, rejilla,
  metal, óxido, nieve, hormigón, tubo de rayos catódicos), mapeadas triplanar
  por coordenada de mundo para no tener que desplegar UV sobre geometría
  generada. Son grises y multiplican al color, así que el teñido por noche
  sigue funcionando sin regenerar nada.
- **Luz y sombra.** El documento pedía "una sola fuente de luz dura por
  escena". Lo que hay es mejor y cuesta parecido: catorce luces, de las
  cuales **las tres más cercanas al jugador proyectan sombra** y el resto solo
  ilumina (`shadow_budget.gd`). Ambiente en 0.10 y atenuación en 1.6, así que
  la luz forma charcos en vez de bañar. Se apaga entero desde Opciones,
  porque es lo más caro del cuadro.
- **Silueta.** Caños, bandejas de cable, abrazaderas y rejillas de
  ventilación: arquitectura, no props. Una sala que es una caja vacía se lee
  como una caja vacía por buena que sea la textura.
- **Mapeo afín.** La otra mitad de la firma PS1, la que hace que las texturas
  se retuerzan al mirar en diagonal. El temblor de vértices ya estaba.

**Sobre "máximo 2-3 props únicos por habitación":** esa restricción existía
para acotar el trabajo de modelado a mano, y dejó de aplicar. Los props se
arman con primitivas compuestas (`modelos.gd`) y lo que los hace legibles es
la silueta, que se escribe. Un matafuego es cilindro, cuello, manguera y
boquilla; una válvula tiene volante. La restricción real hoy es el
presupuesto de polígonos, no el de horas.

**Tipografía:** IBM Plex Mono para documentos y HUD, Sans Condensed para
títulos (OFL, uso comercial permitido). Sin suavizado y sin posicionamiento
subpixel: el mundo se filtra con NEAREST y corre al 55 % de resolución, así
que un texto suavizado flotaría por encima como si fuera de otro juego.

**Documentos en papel.** El parte del turno y la bitácora no se dibujan en
verde fósforo como el resto de la interfaz: son hojas con tinta oscura. Son
objetos del mundo, no menús. En la bitácora, las entradas que el protagonista
escribió sin que el jugador las viviera van en lapicera roja.

## Audio

Tiene más peso narrativo que lo visual: viento constante, crujidos estructurales, silencios largos interrumpidos por sonidos puntuales, y los registros de radio como principal vehículo de historia.

### Pendiente de decisión: la iluminación horneada

El documento pedía "iluminación mayormente horneada". **No es compatible con la decisión de producción que sostiene todo el proyecto:** la estación se genera por código en tiempo de ejecución, y hornear lightmaps necesita UV2 desplegadas y un bake hecho en el editor sobre geometría que existe de antemano. Una de las dos cosas tiene que ceder:

- **Dejar la iluminación dinámica** (lo que hay hoy) y aceptar que el objetivo de gama baja se sostiene por otro lado: resolución interna al 55 %, niebla espesa, y un presupuesto de sombras de tres luces con interruptor en Opciones. Se midió que limitar las luces dinámicas a cuatro **no** mejora nada (ver README, "Medir el rendimiento").

  Desde que hay sombras esta decisión pesa más, no menos: medidas en llvmpipe
  cuestan entre 6 y 9 FPS, aunque llvmpipe rasteriza en CPU y casi seguro las
  penaliza mucho más que una GPU real. Cuál de las dos cosas es cierta no se
  sabe hasta medir en la máquina objetivo, y es la razón más concreta que hay
  hoy para hacer esa medición.
- **Hornear**, y para eso construir la estación como escena guardada en vez de por código — lo que anula "no se modela nada nuevo por noche" como técnica de producción.

Sin haber medido nunca en la máquina objetivo (CPU dual-core, 2 GB de VRAM), no hay dato para elegir. **Decisión del autor, después de medir.**

## Alcance técnico

- **Motor:** Godot 4, renderizador **Compatibility** (no Forward+), sin luces dinámicas complejas.
- **Espacios:** interior con 6 ambientes (pasillo central, sala de control, sala de generador, dormitorio, almacén, esclusa) más un patio exterior para las rondas nocturnas, un pasillo sur que solo existe algunas noches, y los cinco espacios del subnivel B2. Todo se construye por código desde una tabla de salas: agregar un ambiente es agregar un rectángulo, no modelar.
- **Hardware objetivo:** equipos de gama baja (CPU dual-core, GPU con 2GB VRAM) — la estética PS1 es una decisión de diseño, no solo una limitación técnica.

## Plan de desarrollo

Construir una **sola noche jugable de punta a punta** (vertical slice) antes de tocar las otras cuatro, para validar que el loop se siente bien con contenido real:

1. Controlador del jugador (movimiento, cámara, linterna, interacción)
2. Un espacio jugable (pasillo + 1-2 salas conectadas)
3. Loop completo de la Noche 1 (lista de tareas → recorrido → evento extraño → fin de noche)
4. Recién después: primera anomalía real (equivalente a la Noche 2-3 del diseño)

**Riesgo a vigilar durante el prototipo:** que el loop se sienta mecánico o repetitivo si no se nota la evolución descrita arriba entre noche y noche.

## Lo que este documento todavía no define

Cosas que el juego necesita y que acá no están decididas. No son tareas de
implementación: son decisiones del autor, y hasta que existan, cualquiera que
las escriba las está inventando.

- **El plano de la estación.** La técnica central es "el mismo espacio con
  variaciones sutiles", y el plano vive solo como tabla de rectángulos en
  `station_builder.gd`. Debería estar dibujado acá.
- **Presupuesto y cronograma.** "Un desarrollador solo" aparece como
  restricción de alcance, pero no hay horas estimadas ni fechas.
- **Accesibilidad.** No hay sección, aunque el juego ya tiene más de lo que
  el documento pide: remapeo de teclas, tamaño de subtítulos, invertir el eje
  Y, quitar el cabeceo, campo de visión ajustable, y ahora también apagar las
  sombras y los efectos PS1. Falta escribir qué se promete y qué no.

## Publicación: decidido

El objetivo declarado del autor es que el juego tenga éxito **y** que deje
dinero. "Gratis" y "vender" parecen las dos únicas opciones y no lo son:
mezclan dos decisiones distintas que conviene separar.

- **El precio** del juego (gratis, pago, o el que quiera pagar el jugador).
- **La licencia** del código y de los assets (abierto o reservado).

Son independientes. Se puede vender un juego con el código abierto, y se puede
regalar un juego con todo reservado.

### La restricción que decide el primer paso

**Publicar en Steam cuesta 100 dólares por juego, pagados antes de publicar.**
Se recuperan después de vender 1000 dólares, pero hay que ponerlos primero. En
este proyecto el presupuesto no alcanzó para un micrófono de 60: los 100 de
Steam no están hoy.

**itch.io no cobra nada por publicar**, y permite "pagá lo que quieras" con
mínimo cero: el jugador descarga gratis y puede dejar plata si quiere.

Eso resuelve la tensión: **alcance de juego gratis, con la puerta abierta a que
entre dinero, y sin costo de entrada.**

### Lo decidido

1. **`LICENSE` con todos los derechos reservados.** Hecho, está en la raíz
   del repositorio. Es la opción
   Es la opción reversible: siempre se puede abrir más adelante, nunca se
   puede cerrar lo que ya se abrió.
2. **itch.io, "pagá lo que quieras", mínimo cero.** Gratis para publicar,
   gratis para descargar, con donación opcional.
3. **Steam después**, si consigue tracción. Para entonces los 100 dólares
   salen de lo recaudado o de un público que ya existe.
4. **Nada de assets con licencia no comercial.** Esto confirma que usar
   espeak-ng en vez de mbrola fue la decisión correcta, y la regla vale para
   todo lo que entre de acá en adelante: cada textura, cada fuente, cada
   sonido.

### Qué esperar, con honestidad

Un primer juego rara vez deja dinero significativo. Lo que deja es público y
oficio, y eso es lo que financia al segundo.

Dicho eso, el género elegido es de los pocos donde alguien solo y sin
presupuesto puede romper: el terror corto en estética PS1 tiene un público que
lo busca activamente, los streamers cazan justamente esto, y la estética es
alcanzable sin un equipo de arte. Es una ventaja real de la decisión de diseño
original, no una casualidad.

La forma de aprovecharla es que el juego sea **corto, raro y terminable de una
sentada**, que es exactamente lo que dice el objetivo de 60-90 minutos.

## Lo que falta producir (no es diseño, es trabajo)

- **Las voces de los registros de radio.** Hay 107 líneas generadas con
  espeak-ng y pasadas por la cadena de radio (pasabanda 300-3000 Hz), o sea
  que el juego ya se escucha entero. Pero son un provisorio: una voz
  sintetizada no actúa, y el documento dice que el audio pesa más que lo
  visual y que los registros son el principal vehículo de historia. Grabarlas
  con voz humana sigue siendo la mejora más grande disponible, y el giro
  ayuda: son todas la misma voz, así que alcanza con una persona.
- ~~**Arte.**~~ Cerrado en lo que se puede cerrar sin dibujar a mano. Las
  cuatro capas están: texturas procedurales (paredes, pisos, props y pantallas
  de tubo), luz y sombra con presupuesto, silueta (caños, bandejas, rejillas) y
  mapeo afín. La tipografía es IBM Plex Mono y Sans Condensed (OFL, uso
  comercial permitido), sin suavizado para que no flote por encima del mundo.
  Los documentos —el parte del turno y la bitácora— se dibujan en papel, no en
  verde fósforo: son objetos, no menús.

  Los props tampoco son cajas ya: se arman con primitivas compuestas
  (`scripts/world/modelos.gd`). El matafuego es cilindro, cuello, manguera y
  boquilla; la válvula tiene volante; la antena tiene mástil y brazos. Lo que
  los hace legibles no es la cantidad de polígonos, es la silueta, y la
  silueta se puede escribir. Costo medido en A/B pareado: 0.35 FPS, dentro
  del ruido.

  Lo único que sigue abierto es arte **dibujado a mano**: mallas modeladas en
  Blender, texturas pintadas, una tipografía propia. Ninguna hace falta para
  publicar, y una tipografía propia sería *peor* que IBM Plex salvo que la
  dibuje alguien que sepa diseñar tipos.
- **Contenido.** Medido hoy: 32 a 48 minutos explorando más 9.4 de audio,
  contra un objetivo de 60 a 90. Medir con `tests/pacing.tscn` en cada paso.

  **Los 60-90 son un piso, no una cuota.** El objetivo existe para que el
  juego no se sienta una demo, no para que haya que rellenarlo. Cincuenta
  minutos densos le ganan a noventa de caminar por pasillos, y el riesgo real
  de un número es que empuje a alargar en vez de a profundizar. La regla: no
  agregar salas ni tareas para llenar minutos. Agregar significado a lo que ya
  existe — más registros de radio, más lecturas de los mismos objetos, más
  beats adentro de las tareas que ya están.
- **Playtest con personas.** Todo lo que se sabe del ritmo sale de un bot que
  camina derecho a cada tarea.
- **Medir en la máquina objetivo.** Nunca se corrió en un equipo de gama baja
  real. De eso depende la decisión sobre la iluminación.
