# Cómo se hace lo que falta

El código llegó donde podía llegar solo. Lo que queda necesita una persona
haciendo cosas fuera de Godot. Esta es la parte práctica: qué herramienta,
qué proceso, y qué es lo mínimo aceptable en cada rubro.

Está ordenado por cuánto cambia el juego, no por dificultad.

---

## 1. Las voces de radio

**Es el rubro más grande que falta.** El documento de diseño dice que el audio
pesa más que lo visual y que los registros son el principal vehículo de
historia. Hoy son subtítulos sobre una portadora sintetizada.

### Lo que ya está resuelto

- **La lista completa**: [`docs/lineas_de_voz.md`](lineas_de_voz.md) tiene las
  107 líneas con el nombre de archivo exacto, la duración objetivo y el texto.
  Se regenera con
  `godot --headless --path . res://tools/exportar_lineas.tscn`.
- **El mecanismo de reemplazo**: dejás `audio/voz/rl_02_2.ogg` y esa línea deja
  de ser sintética. **No hay que tocar código.** Si el archivo no está, sigue
  sonando la voz sintetizada, así que se puede grabar de a poco y probar cada
  tanto.

### El descubrimiento que te ahorra la mitad del trabajo

Los registros están firmados por gente distinta: jefe de base, técnicos, "sin
firmar". La reacción natural es pensar que hacen falta varios actores.

**No hacen falta.** El final del juego dice, textualmente:

> *"Y las grabaciones que dejaron ahí son todas de la misma voz."*

Grabar los 35 registros con una sola voz no es una limitación de presupuesto:
**es el remate.** Si conseguís varias voces, ese remate se rompe y hay que
reescribirlo. Grabalo vos, o conseguí una sola persona.

Lo que sí conviene variar entre registros es el *estado*: distancia al
micrófono, cansancio, si está leyendo un parte o hablando solo. Que se note
que es la misma garganta en momentos distintos es exactamente el efecto.

### Equipo: el teléfono alcanza, y no es un parche

**No hace falta comprar nada.** Grabás con el teléfono.

No es una solución de emergencia, hay una razón técnica: el paso que hace que
esto suene a radio es el **pasa-banda de 300 Hz a 3 kHz**, que tira todo lo que
está por debajo y por encima. El cuerpo grave de la voz y el aire de los
agudos — todo lo que justifica un micrófono caro — se borra justo después.
Un micrófono de teléfono está *más cerca* de un micrófono de radio que un
condensador de estudio.

Lo que sí cambia el resultado, y es gratis:

- **El cuarto, más que el micrófono.** Grabá adentro de un placard con ropa, o
  armá una carpa con frazadas sobre una mesa. Un auto estacionado también sirve
  muy bien: tapizado por todos lados y sin superficies duras paralelas. Lo que
  buscás es que no haya eco. La radio perdona el ruido de fondo; no perdona la
  reverberación de una habitación vacía.
- **La distancia.** Unos 15 cm, y hablale *pasando por al lado* del teléfono,
  no de frente. Así las "p" y las "t" no golpean el micrófono.
- **La hora.** De madrugada. Es cuando no hay tránsito ni vecinos.
- **Modo avión**, para que no entre una notificación en la mejor toma.
- Si la app de grabación tiene opción de calidad, ponela en la más alta, y si
  tiene "reducción de ruido" o "mejora de voz", **apagala**: esos algoritmos
  hacen bombear la voz y se nota más después de comprimir.

Software: [Audacity](https://www.audacityteam.org/) es gratis y alcanza para
todo. Y si tenés `ffmpeg`, el procesamiento está automatizado (abajo).

### El procesamiento, hecho por vos o automático

**Automático** (recomendado). Copiá las grabaciones a una carpeta, con el
nombre que dice [`lineas_de_voz.md`](lineas_de_voz.md), y:

```bash
./tools/procesar_voces.sh ~/grabaciones
```

Aplica la cadena entera, recorta los silencios de los extremos, deja todos los
registros al mismo volumen y los exporta a `audio/voz/` en OGG mono 44.1 kHz,
que es lo que el juego espera. Acepta `.m4a`, `.wav`, `.mp3` y lo que sea que
grabe tu teléfono. Con `-s` procesa uno solo, para escuchar antes de largar
todo.

`ffmpeg` es gratis y está en los repositorios de cualquier distro
(`sudo apt install ffmpeg`).

**A mano en Audacity**, si preferís. El orden importa:

1. **Filtro pasa-altos** en 100 Hz — saca el retumbe del cuarto.
2. **Compresor**, ratio 4:1 — las radios comprimen mucho.
3. **Pasa-altos en 300 Hz y pasa-bajos en 3 kHz.** Esto es lo que hace el
   efecto, más que ningún otro paso.
4. **Compresor otra vez**, suave.
5. **Normalizar** todos los archivos al mismo volumen. Si falta este paso se
   nota muchísimo: un registro más fuerte que otro rompe la ilusión.
6. **No agregues siseo ni ruido de portadora.** El juego ya suma el suyo
   encima y se duplica.
7. Exportar **OGG Vorbis, mono, 44.1 kHz**.

### ¿Se puede sacar de algún lado en vez de grabarlo?

Hay tres caminos, y conviene saber qué da cada uno.

**1. Bancos de sonido (freesound, etc.): no sirve para esto.** No existe una
biblioteca que tenga *estas* 107 líneas: son diálogo escrito para este juego.
De un banco podés sacar estática, tono de cuarto o pitidos de radio, y eso el
juego ya se lo sintetiza solo. Para el contenido hablado no hay de dónde
sacarlo.

**2. Voz sintética (TTS): tenés las 107 líneas hoy.** Es el camino realista si
no vas a grabar ahora. Hay motores gratis y offline, y hay una herramienta en
el repo que hace todo el trabajo:

```bash
export TTS_CMD='echo {texto} | piper -m ~/voces/es_AR-daniela-high.onnx -f {salida}'
./tools/generar_voces_tts.sh -d          # ver qué haría
./tools/generar_voces_tts.sh -f rl_03    # probar con un registro
./tools/generar_voces_tts.sh             # las 107
```

Lee el texto de la misma tabla que usarías para grabar, así que los nombres y
el orden salen bien solos, y le aplica la misma cadena de radio que a una
grabación real — una línea sintética y una grabada suenan igual de procesadas.

Motores, todos gratis:

- **Piper** (`pip install piper-tts`), offline, con voces en `es_AR`, `es_ES` y
  `es_MX` en [huggingface.co/rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices).
  Bajás el `.onnx` y su `.onnx.json`.
- **macOS**: ya lo tenés. `export TTS_CMD='say -v Monica -o {salida} --data-format=LEF32@22050 {texto}'`
- **Windows**: ya lo tenés, con PowerShell. Guardá esto como `tts.ps1` y usá
  `export TTS_CMD='powershell -File tts.ps1 {texto} {salida}'`:

  ```powershell
  param($texto, $salida)
  Add-Type -AssemblyName System.Speech
  $v = New-Object System.Speech.Synthesis.SpeechSynthesizer
  $v.SelectVoice((($v.GetInstalledVoices() | Where-Object {
      $_.VoiceInfo.Culture.Name -like "es-*" })[0]).VoiceInfo.Name)
  $v.SetOutputToWaveFile($salida); $v.Speak($texto); $v.Dispose()
  ```

**Dos advertencias sobre el TTS, y son importantes:**

- **Licencias.** Las voces de Piper vienen de datasets distintos y **no todas
  permiten uso comercial**. Si el juego se vende, revisá el MODEL_CARD de la
  voz puntual antes de publicar. Las voces del sistema en Windows y macOS
  tampoco son libres de redistribuir como archivos de audio dentro de un
  producto: para publicar conviene una voz con licencia clara.
- **Un TTS no actúa.** No se cansa, no duda, no se le quiebra la voz. Este
  juego se apoya justamente en eso: el terror de los registros está en que se
  escucha a alguien deteriorándose. Una voz sintética plana los convierte en
  información.

**3. Otra persona, gratis.** Si no querés poner tu voz: un amigo, un familiar,
o comunidades donde hay gente haciendo voces gratis por portfolio
(r/RecordThisForFree, Casting Call Club). No cuesta plata, cuesta pedirlo y
esperar. Acordate de que tiene que ser **una sola** persona para los 35
registros.

### La recomendación

Generá las 107 con TTS **ahora**. Con eso podés jugar el juego completo con
audio y hacer un playtest de verdad, que es lo que más falta.

Después grabá encima las que más pesan. El juego levanta cada línea por
separado, así que reemplazar de a una no rompe nada ni obliga a rehacer el
resto. Diez líneas bien grabadas sobre 97 sintéticas ya cambia el juego.

### Por dónde empezar

No empieces por `rl_01`. Grabá primero **`rl_03`** (la señal desconocida de la
Noche 2) y **`rl_35`** (el del fondo del B2, que termina con "Son yo"). Son los
dos que más dependen de la voz. Si esos dos funcionan, el resto es trabajo; si
no funcionan, conviene saberlo antes de grabar 107 líneas.

---

## 2. El arte

Hoy la estación son cajas de color plano. El objetivo del documento es PS1:
geometría simple, sin suavizado, poca resolución de textura.

### El orden correcto es texturas primero, modelos después

Una caja con una textura de chapa sucia lee como una pared de estación. Una
caja gris lee como una caja gris. **Texturar lo que ya existe cambia más el
juego que modelar props nuevos**, y es muchísimo menos trabajo.

- Resolución: **64×64 o 128×128 píxeles**. En serio. Más resolución rompe la
  estética, y además es el objetivo de hardware.
- Necesitás unas seis: chapa de pared, piso metálico, piso de rejilla, nieve,
  óxido, pintura descascarada.
- De dónde sacarlas: fotos propias bajadas a 128px y con los colores
  reducidos, o bancos con licencia permisiva (ambientCG, Poly Haven). Bajarle
  la resolución a una foto es un método legítimo y es cómo se hacía.
- En Godot: importar con filtro **Nearest** (no lineal) y sin mipmaps. Eso es
  lo que da el aliasing característico.

### Props

El documento pide **máximo 2-3 props únicos por habitación**. Respetalo: es la
regla que hace el proyecto terminable.

Si vas a modelar, Blender alcanza con saber extruir y biselar. Un prop PS1
tiene entre 50 y 300 triángulos. Si no querés modelar, buscá packs low-poly
con licencia CC0 y sacales detalle en vez de agregarles.

### Tipografía

Es lo más barato de todo y se nota mucho: hoy usa la fuente por defecto de
Godot. Una monoespaciada de aspecto técnico (hay varias con licencia SIL, como
las de la familia DOS/terminal) cambia el carácter de toda la interfaz. Se
configura en Proyecto → Configuración → GUI → Theme → Default Font.

---

## 3. Jugarlo vos

Antes de cualquier playtest con gente: **caminá las cinco noches una vez, sin
apurarte.** Nadie lo hizo nunca. Todo lo que sabemos del ritmo sale de un bot
que va derecho a cada tarea.

Lo que hay que mirar, y anotar mientras jugás (no después):

- **Dónde te aburriste.** El B2 se diseñó en coordenadas y nunca se caminó. Es
  probable que los pasillos se sientan largos y muertos.
- **Dónde no supiste qué hacer** más de treinta segundos.
- **Si la linterna te importó alguna vez.** Hoy el medidor dice que hay
  batería para once noches: casi seguro que no.
- **Si el parte del turno de la Noche 4 te pegó.** Es el giro central. Si se
  lee como un texto más, hay que trabajarlo.

---

## 4. El playtest con gente

Tres a cinco personas alcanzan para encontrar casi todo. Más no aporta mucho.

**La regla difícil: no expliques nada y no ayudes.** Cuando alguien se traba,
lo que querés saber es cuánto tarda en destrabarse solo. Si intervenís,
perdiste el dato. Anotá y aguantate.

Qué medir mientras miran:

- Dónde se traban más de treinta segundos.
- En qué momento dejan de mirar alrededor y empiezan a caminar derecho. Ahí
  se terminó la exploración y empezó el trámite.
- **En qué noche abandonarían si pudieran.** Es el número más importante.

Qué preguntar después, en este orden (de abierta a específica, para no
contaminar la respuesta):

1. ¿Qué pasó en el juego? (contado por ellos)
2. ¿De quién eran las anomalías?
3. ¿Hubo algún momento en que dudaras del protagonista?
4. ¿Te quedó claro por qué estabas solo?

Si nadie contesta bien la 2, el giro central no está llegando.

---

## 5. Medir en la máquina objetivo

El objetivo declarado es CPU dual-core con 2 GB de VRAM. **Nunca se corrió en
un equipo así.** De este dato depende una decisión de diseño que quedó
abierta (la iluminación horneada, ver `diseno.md`).

En la máquina de gama baja:

```bash
godot --path . res://tools/benchmark.tscn
```

Recorre la estación girando la cámara todo el tiempo (el peor caso para el
culling) e imprime FPS promedio, mínimo y percentil 1 %. También podés usar
`[F3]` dentro del juego.

**Corré tres veces y compará medianas.** Una sola corrida no dice nada: la
dispersión medida es de más o menos 1.3 FPS. Ya hubo una "mejora del 6 %" que
resultó ser ruido.

El número que importa no es el promedio, es el **percentil 1 %**: son los
tirones que se sienten.

---

## 6. La licencia

No hay archivo `LICENSE`, y hasta que lo haya, por defecto nadie puede usar
nada de esto legalmente — lo cual puede estar bien, pero conviene que sea a
propósito.

Un juego tiene dos cosas con licencias que suelen ser distintas:

- **El código.** Si querés que alguien pueda aprender de él, MIT es lo más
  simple y permisivo.
- **Los assets y el contenido** (texto, audio, arte, el diseño). Si pensás
  vender el juego, esto queda con todos los derechos reservados.

La combinación "código MIT + contenido reservado" es común y se escribe en un
solo archivo `LICENSE` con dos secciones. Si no pensás publicar el código, un
`LICENSE` que diga "todos los derechos reservados" y listo también es una
respuesta válida.

**No es una decisión técnica y nadie la puede tomar por vos.**

---

## 7. Las decisiones de diseño que faltan

Están listadas al final de [`diseno.md`](diseno.md). La que bloquea más cosas:

**El protagonista.** No tiene nombre, ni voz, ni una razón de estar solo, ni
relación con las cinco personas de la foto. Todo el terror depende de que el
jugador dude de él. Y además bloquea las voces: no se puede actuar a alguien
que no existe.

Tres preguntas que lo resuelven casi entero:

1. ¿Por qué se quedó él y no otro?
2. ¿Qué relación tenía con las cinco personas de la foto?
3. ¿El jugador tiene que quererlo, tenerle lástima, o desconfiar de él desde
   el principio?

La tercera es la que define el tono de todas las líneas grabadas.
