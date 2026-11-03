---
layout: default
lang: es-419
---

## 4. Lectura y escritura, tal como está implementado

```
write:  document model ──▶ UIManagedDocument ──▶ ~/tmp/<name>.mada/ ──▶ tar.bz2 ──▶ <name>.mad
read:   <name>.mad ──▶ tar.bz2 ──▶ ~/tmp/<name>.mada/ ──▶ UIManagedDocument
```

El directorio intermedio se llama **guts** (entrañas). Su extensión es `.mada`
(`MADConstants.m:12`, `MADFileExtentionMobleApplicationDocumentArchive`), se nombra
a partir del documento y se coloca en un directorio temporal
(`MADURLFactory.m:51-56`, `newURLLocalTemporaryDirectory` → `~/tmp`).

- Guardar — `MADocument.m:497-514`: escribir el modelo en los guts y después archivar los guts
  sobre la URL del documento.
- Abrir — `MADocument.m:456-476`: desarchivar el documento en los guts y después leer
  el almacén desde allí.

El comentario sobre `-readFromURL:` (`MADocument.m:452-455`) lo expone con las
palabras del propio autor:

> 1. Desarchivar el archivo MAD; es un archivo zip (quizá tar.bz2).
> 2. Leer el archivo desarchivado. Actualmente es un archivo de Core Data.

«Actualmente es un archivo de Core Data» resume toda la migración en cinco palabras.
