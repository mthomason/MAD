---
layout: default
lang: es-419
---

## 9. Verificación

Las afirmaciones de las §§2-5 son reproducibles (ejecute estos comandos desde la raíz del repositorio):

```sh
tar tjf MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad
mkdir -p /tmp/mad && tar xjf … -C /tmp/mad
plutil -p /tmp/mad/meta.plist
file /tmp/mad/StoreContent/analyitics
```

Las afirmaciones de la §5 son reproducibles desde un contenedor de dispositivo o simulador:

```sh
ls -la ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Library/Caches/<dataTableIdHash>/
```

Cualquier cambio en el formato debe ampliar las fixtures de ida y vuelta descritas en
`docs/project/MAD_CLI.md` §6, para que la definición de este archivo quede fijada por una prueba y no
por esta prosa. La fixture del contenedor existe desde el 2026-10-16
(`../Linux/Tests/MADArchiveManagerTests.m`: descomprimir, recomprimir, descomprimir de nuevo, lista de miembros y
bytes sin cambios), y el bit de checkpoint de la §7.2 está fijado por el escritor que lo establece (`mad
write`). El *modo reproducible* del escritor —hora fija de los miembros, propietario 0, recorrido ordenado—
es lo que hace iguales los documentos de dos plataformas; es opcional, así que un archivo
ordinario todavía registra los metadatos del sistema de archivos, y no es una versión del formato (el
archivo es v1 en ambos casos). La §5 es la parte que hoy no tiene esa fixture: los archivos complementarios se
describen aquí a partir de mediciones, y nada falla si la medición deja de ser
cierta.
