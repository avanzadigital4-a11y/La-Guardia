# La Guardia — Documento de diseño

## Premisa

Sos el último cuidador nocturno de una estación de investigación remota en la Antártida (ficticia, no basada en ninguna base real) que va a cerrar definitivamente en cinco días. Tu trabajo en el papel es simple: hacer rondas, revisar el generador, monitorear sensores, y sobrevivir al aislamiento hasta que llegue el vehículo de evacuación. El juego nunca confirma si lo que empieza a pasar es real o si es la mente del protagonista rompiéndose por el aislamiento extremo. Esa ambigüedad es el eje central de la experiencia.

## Género y referencias

Terror psicológico, exploración en primera persona, sin combate. Estética visual low-poly tipo PS1 (referencias: *Crow Country*, *Iron Lung*, *Amnesia: The Dark Descent*, *SOMA*).

**Duración objetivo: 60-90 minutos.** (Revisado. El objetivo original era 2-3 horas; para un desarrollador solo, y con el arte y el audio todavía por hacer, 60-90 minutos es lo que se termina. *Iron Lung*, una de las referencias, dura cerca de una hora.) El estado medido está en el README, sección "Ritmo medido": `tests/pacing.tscn` camina las cinco noches y da el número real.

## Loop central

`tarea → recorrido → anomalía → registro → volver a la base → siguiente noche`

Simple y repetible, pero **debe evolucionar noche a noche** — nunca debe sentirse como la misma secuencia ejecutada cinco veces, o el jugador cae en piloto automático.

## Estructura narrativa (5 noches, con evolución del loop)

- **Noche 1 — Rutina.** Tarea → recorrido → un evento extraño aislado. El jugador aprende el layout y los sistemas. Todo parece tranquilo.
- **Noche 2 — Primera desviación.** Tarea → recorrido → anomalía → el jugador elige investigarla por su cuenta, saliéndose de la rutina establecida.
- **Noche 3 — El espacio interfiere.** Tarea → anomalía → el recorrido planeado ya no lleva a donde debería (una ruta cambia, aparece un pasillo que no estaba en los planos).
- **Noche 4 — Pérdida de confianza.** Objetivo → recuerdos contradictorios (bitácora) → investigar → el jugador ya no sabe si puede confiar en lo que ve o recuerda.
- **Noche 5 — Cierre.** Decisión → exploración final → desenlace. No debe sentirse como "otra ronda más", sino como la noche que rompe todo.

**Las noches crecen.** No duran lo mismo: la rutina de la Noche 1 se aprende rápido y aburre si se estira, y la última tiene que pesar. La curva medida hoy va de 107 s a 221 s de recorrido directo, sin pozos en el medio. El B2 es el que hace crecer las noches 3 y 5; la Noche 4 crece en superficie, porque esa noche el subnivel no está.

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

   **Qué se pierde: el apagón.** Doce segundos sin linterna en una sala apagada y hay fundido a negro. Se despierta en la cucheta, sin acordarse de haber vuelto, con dos a cuatro horas del turno de menos. No hay game over: el peligro nunca es físico. Lo que cuesta es concreto — las pilas de repuesto que llevaba encima desaparecen, la linterna vuelve con poca carga, y **se aplican dos anomalías que quedan registradas como propias**, o sea que aparecen después en el parte del turno con su letra. El apagón no es un castigo agregado: es la vía más directa al giro del final. El final acusa cuántas horas del turno no figuran.
6. **Sin combate, sin monstruo que persigue activamente** — el peligro es ambiental y psicológico, nunca una amenaza física directa.

## Final (el más fuerte narrativamente)

El jugador descubre que algunas de las anomalías las causó él mismo, en estados que no recuerda. Al llegar el vehículo de evacuación, una transmisión de radio revela: *"No hay personal asignado a esa estación desde hace 11 meses."* No se explica qué fue exactamente lo que pasó — la ambigüedad final es intencional y es el gancho memorable del juego. (Pueden existir 1-2 finales alternativos más cerrados como variantes de menor peso, pero este es el final principal a diseñar primero.)

## Estética visual

Low-poly estilo PS1: geometría simple (pocas caras, sin suavizado), una sola fuente de luz dura por escena, niebla espesa para limitar la distancia de dibujado, shader de post-proceso con grano tipo VHS/scanlines y viñeta en los bordes. Máximo 2-3 props únicos por habitación para mantener el alcance realista para un desarrollador solo.

## Audio

Tiene más peso narrativo que lo visual: viento constante, crujidos estructurales, silencios largos interrumpidos por sonidos puntuales, y los registros de radio como principal vehículo de historia.

### Pendiente de decisión: la iluminación horneada

El documento pedía "iluminación mayormente horneada". **No es compatible con la decisión de producción que sostiene todo el proyecto:** la estación se genera por código en tiempo de ejecución, y hornear lightmaps necesita UV2 desplegadas y un bake hecho en el editor sobre geometría que existe de antemano. Una de las dos cosas tiene que ceder:

- **Dejar la iluminación dinámica** (lo que hay hoy) y aceptar que el objetivo de gama baja se sostiene por otro lado: resolución interna al 55 %, sin sombras, niebla espesa y pocas luces. Se midió que limitar las luces dinámicas a cuatro **no** mejora nada (ver README, "Medir el rendimiento").
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

- **El protagonista.** No tiene nombre, ni voz, ni una razón de estar solo,
  ni relación con las cinco personas de la foto del equipo. Todo el terror
  depende de que el jugador dude de él, y hoy es un hueco.
- **Los finales alternativos.** El principal está definido y construido, y hay
  una variante implementada (quedarse abajo). El documento dice "1-2
  alternativos más cerrados" pero no los especifica.
- **El plano de la estación.** La técnica central es "el mismo espacio con
  variaciones sutiles", y el plano vive solo como tabla de rectángulos en
  `station_builder.gd`. Debería estar dibujado acá.
- **Presupuesto y cronograma.** "Un desarrollador solo" aparece como
  restricción de alcance, pero no hay horas estimadas ni fechas.
- **Publicación.** Plataforma, precio, demo, fecha. Nada.
- **Licencia.** No hay archivo `LICENSE` en el repositorio.
- **Accesibilidad.** No hay sección, aunque el juego ya tiene más de lo que
  el documento pide: remapeo de teclas, tamaño de subtítulos, invertir el eje
  Y, quitar el cabeceo, campo de visión ajustable.

## Lo que falta producir (no es diseño, es trabajo)

- **Las voces de los registros de radio.** 35 registros escritos, ninguno
  grabado; hoy son subtítulos sobre una portadora sintetizada. El documento
  dice que el audio pesa más que lo visual y que los registros son el
  principal vehículo de historia, así que este es el rubro más grande que
  falta.
- **Arte.** Texturas, props modelados, tipografía propia. Hoy la estación son
  cajas de color plano.
- **Contenido.** Falta aproximadamente la mitad otra vez para llegar a los
  60-90 minutos. Medir con `tests/pacing.tscn` en cada paso.
- **Playtest con personas.** Todo lo que se sabe del ritmo sale de un bot que
  camina derecho a cada tarea.
- **Medir en la máquina objetivo.** Nunca se corrió en un equipo de gama baja
  real. De eso depende la decisión sobre la iluminación.
