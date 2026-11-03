---
layout: default
lang: es-419
---

## 6. Riesgos que debe afrontar un segundo lector

Estos son defectos del formato actual, no opiniones. Cada uno se expone con lo que
rompería.

| # | Riesgo | Consecuencia |
|---|---|---|
| H1 | **Sin bytes mágicos.** El archivo se detecta solo por su extensión (`MADocument.m:459`). | Windows no tiene una asociación significativa con `.mad`, y un archivo renombrado es irreconocible. Véase la §7. |
| H2 | **Se distribuyen WAL y SHM.** `analyitics-wal` ocupa 313 KB frente a una base de datos de 516 KB. | Un lector que ignore el WAL lee datos obsoletos. Una CLI debe reproducir el WAL o exigir un checkpoint antes de archivar. |
| H3 | **Esquema de Core Data dentro.** | Ata a todos los lectores a Core Data, que no existe fuera de las plataformas de Apple. El formato no puede llamarse portátil hasta que esto se resuelva. |
| H4 | **Se omiten los archivos ocultos** (`MADArchiveManager.m:111`). | Cualquier futuro miembro oculto se descarta silenciosamente del archivo. |
| H5 | **`analyitics` está mal escrito** en disco. | No se puede corregir sin romper los documentos existentes. |
| H6 | **`version` es double en el escritor y entero en las muestras.** | Los consumidores deben aceptar ambas formas. |
| H7 | **No están fijados los indicadores de compilación de SQLite.** `build_sqlite3.sh` declara 20 defines; el objetivo `MADSqlite3` aplica uno. | El motor que escribe `.maddb` usa un tamaño de página de 4096 bytes donde el script pide 8192, y le faltan FTS5 y STAT4. El tamaño de página se escribe en la cabecera del archivo, así que el formato queda definido por accidente. **Ya corregido**: los defines viven en `Compressor/sqlite3.xcconfig`, que tanto el objetivo como el script leen. Las cachés escritas desde entonces tienen páginas de 8192 bytes; las antiguas siguen abriéndose, porque SQLite lee el tamaño de página de la cabecera. Véase `docs/project/LIBRARIES.md` §4. |
