---
layout: default
lang: es-419
---

## 1. Qué es un documento, en una frase

Un archivo `.mad` es un **archivo tar comprimido con bzip2** cuyos miembros son un
almacén persistente de Core Data, una pequeña lista de propiedades que describe el documento
y un directorio opcional de miniaturas.

Los datos de fila que muestra un informe **no** están en el documento. Son una caché
derivada, regenerada en cada actualización, y viven fuera del archivo. Esa distinción es lo
más importante de este documento y se explica en la §5.
