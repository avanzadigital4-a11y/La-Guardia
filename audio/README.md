# Audio

El juego funciona sin ningún archivo acá: todo el sonido está sintetizado en
runtime (`scripts/audio/audio_director.gd`). Estas carpetas son el lugar donde
dejar grabaciones reales para que reemplacen a la síntesis, sin tocar código.

## Voces de los registros de radio

```
audio/voz/<id_del_registro>_<numero_de_linea>.ogg
```

Por ejemplo, la segunda línea del registro `rl_02` va en `audio/voz/rl_02_2.ogg`.

La lista completa de líneas a grabar, con su texto y su duración objetivo,
está en [`docs/lineas_de_voz.md`](../docs/lineas_de_voz.md), y se regenera con:

```bash
godot --headless --path . res://tools/exportar_lineas.tscn
```

Si un archivo no está, esa línea suena con la voz sintetizada. Se pueden ir
grabando de a poco.

## Efectos

```
audio/efectos/<id>.ogg
```

Los ids son los que usa `AudioDirector.play_cue`: `step`, `step_snow`, `click`,
`door`, `door_locked`, `task`, `panel`, `pickup`, `creak`, `radio_on`, `hiss`.

## Ambiente

```
audio/ambiente/viento.ogg
```

Si está, reemplaza al generador de viento procedural. Conviene que sea un loop
largo (60 s o más) para que no se note la repetición.

## Procesar las grabaciones

No hace falta comprar un microfono: el telefono alcanza, porque el pasa-banda
de radio (300 Hz a 3 kHz) tira justo todo lo que un microfono caro captura de
mas. Lo que cambia el resultado es el cuarto (un placard con ropa, no una
habitacion vacia) y la distancia.

Para convertir las grabaciones crudas en archivos listos para el juego:

```bash
./tools/procesar_voces.sh ~/grabaciones
```

Aplica la cadena de radio entera, recorta los silencios de los extremos,
empareja el volumen entre registros y exporta al formato de abajo. Los detalles
y la version a mano en Audacity estan en
[`docs/produccion.md`](../docs/produccion.md).

## Formato

OGG Vorbis, mono, 44.1 kHz. Para las voces: grabadas de cerca, con la
compresión y el ruido de portadora agregados en la edición (el juego ya suma
su propio siseo encima).
