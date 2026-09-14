# La Guardia — Documento de diseño

## Premisa

Sos el último cuidador nocturno de una estación de investigación remota en la Antártida (ficticia, no basada en ninguna base real) que va a cerrar definitivamente en cinco días. Tu trabajo en el papel es simple: hacer rondas, revisar el generador, monitorear sensores, y sobrevivir al aislamiento hasta que llegue el vehículo de evacuación. El juego nunca confirma si lo que empieza a pasar es real o si es la mente del protagonista rompiéndose por el aislamiento extremo. Esa ambigüedad es el eje central de la experiencia.

## Género y referencias

Terror psicológico, exploración en primera persona, sin combate. Estética visual low-poly tipo PS1 (referencias: *Crow Country*, *Iron Lung*, *Amnesia: The Dark Descent*, *SOMA*). Duración objetivo: 2-3 horas.

## Loop central

`tarea → recorrido → anomalía → registro → volver a la base → siguiente noche`

Simple y repetible, pero **debe evolucionar noche a noche** — nunca debe sentirse como la misma secuencia ejecutada cinco veces, o el jugador cae en piloto automático.

## Estructura narrativa (5 noches, con evolución del loop)

- **Noche 1 — Rutina.** Tarea → recorrido → un evento extraño aislado. El jugador aprende el layout y los sistemas. Todo parece tranquilo.
- **Noche 2 — Primera desviación.** Tarea → recorrido → anomalía → el jugador elige investigarla por su cuenta, saliéndose de la rutina establecida.
- **Noche 3 — El espacio interfiere.** Tarea → anomalía → el recorrido planeado ya no lleva a donde debería (una ruta cambia, aparece un pasillo que no estaba en los planos).
- **Noche 4 — Pérdida de confianza.** Objetivo → recuerdos contradictorios (bitácora) → investigar → el jugador ya no sabe si puede confiar en lo que ve o recuerda.
- **Noche 5 — Cierre.** Decisión → exploración final → desenlace. No debe sentirse como "otra ronda más", sino como la noche que rompe todo.

## Técnica de producción: mismo espacio, variaciones sutiles

En vez de construir escenarios nuevos cada noche, se reutiliza la misma estación y se altera su estado entre noches: puertas que antes estaban cerradas ahora abiertas, un pasillo que antes no existía, proporciones que ya no coinciden del todo. Se implementa con **una sola escena base en Godot**, controlando qué objetos están visibles y qué materiales se usan según una variable de "noche actual" (`current_night`). No se modela nada nuevo por noche — es la decisión de producción más importante del proyecto, porque multiplica el contenido percibido sin multiplicar el trabajo real.

## Anomalías fuera de cámara

No todo lo raro ocurre frente al jugador. Algunos cambios pasan mientras no está mirando: sale de un cuarto, vuelve, y algo cambió sin que viera la transición (una puerta que se abrió sola, una silla que ahora mira hacia otro lado, una cama ligeramente desplazada). Se implementa con un `Area3D` que detecta cuándo el jugador sale de una habitación; mientras no está presente, se cambia el estado del objeto. Es más barato de producir que una secuencia animada y genera más inquietud que un jumpscare.

**Evitar el jumpscare como recurso principal.** El juego funciona mejor generando duda ("¿siempre estuvo así? ¿cuándo cambió? ¿lo vi cambiar y no me di cuenta?") que con sustos directos.

## Mecánicas jugables

1. **Lista de tareas por noche** — checklist simple (ej. "revisar generador", "ronda exterior", "verificar sensores nivel 1"). Da estructura sin necesitar objetivos complejos.
2. **Panel de sensores** — pantalla de control con temperatura, viento, presión, radiación y un mapa de niveles de la estación. Implementado como una lista de datos en código (fácil de modificar). Gancho narrativo clave: un "subnivel" (ej. `SUBNIVEL B2`) aparece en el mapa una noche sin figurar en los planos oficiales, y en otra visita ya no está.
3. **Registros de radio reproducibles** — audios encontrados en el mundo, algunos marcados "desconocido". Barato de producir (solo audio, sin animación) y muy efectivo narrativamente.
4. **Bitácora que se autoactualiza y contradice al jugador** — en vez de una sola entrada nueva por noche, algunas noches revelan una secuencia corta de 2-3 anotaciones que el protagonista escribió esa misma noche, admitiendo acciones que el jugador nunca realizó en el gameplay. Ejemplo:
   - `23:41 — Abrí la puerta del generador.`
   - `23:43 — No debí abrirla.`
   - `23:47 — Él todavía no sabe que fui yo.`

   Esto convierte al propio sistema de registro en una fuente de terror, no solo en una pista informativa.
5. **Linterna con batería limitada** — fuente de luz principal, obliga a gestión de recursos sin necesitar combate.
6. **Sin combate, sin monstruo que persigue activamente** — el peligro es ambiental y psicológico, nunca una amenaza física directa.

## Final (el más fuerte narrativamente)

El jugador descubre que algunas de las anomalías las causó él mismo, en estados que no recuerda. Al llegar el vehículo de evacuación, una transmisión de radio revela: *"No hay personal asignado a esa estación desde hace 11 meses."* No se explica qué fue exactamente lo que pasó — la ambigüedad final es intencional y es el gancho memorable del juego. (Pueden existir 1-2 finales alternativos más cerrados como variantes de menor peso, pero este es el final principal a diseñar primero.)

## Estética visual

Low-poly estilo PS1: geometría simple (pocas caras, sin suavizado), iluminación mayormente horneada, una sola fuente de luz dura por escena, niebla espesa para limitar la distancia de dibujado, shader de post-proceso con grano tipo VHS/scanlines y viñeta en los bordes. Máximo 2-3 props únicos por habitación para mantener el alcance realista para un desarrollador solo.

## Audio

Tiene más peso narrativo que lo visual: viento constante, crujidos estructurales, silencios largos interrumpidos por sonidos puntuales, y los registros de radio como principal vehículo de historia.

## Alcance técnico

- **Motor:** Godot 4, renderizador **Compatibility** (no Forward+), sin luces dinámicas complejas.
- **Espacios:** interior con 5-6 ambientes (pasillo central, sala de control, sala de generador, dormitorio, un espacio adicional) más un patio exterior pequeño para las rondas nocturnas.
- **Hardware objetivo:** equipos de gama baja (CPU dual-core, GPU con 2GB VRAM) — la estética PS1 es una decisión de diseño, no solo una limitación técnica.

## Plan de desarrollo

Construir una **sola noche jugable de punta a punta** (vertical slice) antes de tocar las otras cuatro, para validar que el loop se siente bien con contenido real:

1. Controlador del jugador (movimiento, cámara, linterna, interacción)
2. Un espacio jugable (pasillo + 1-2 salas conectadas)
3. Loop completo de la Noche 1 (lista de tareas → recorrido → evento extraño → fin de noche)
4. Recién después: primera anomalía real (equivalente a la Noche 2-3 del diseño)

**Riesgo a vigilar durante el prototipo:** que el loop se sienta mecánico o repetitivo si no se nota la evolución descrita arriba entre noche y noche.
