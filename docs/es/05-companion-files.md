---
layout: default
lang: es-419
---

## 5. Lo que *no* está en el documento: los archivos complementarios

Un `.mad` es una definición, no un conjunto de datos. Todo lo que un informe *muestra* es derivado,
regenerable y, deliberadamente, está fuera del archivo. Junto a él se construyen tres tipos de archivo:

| Archivo | Lo escribe | Qué contiene |
|---|---|---|
| `<hash>.maddb` | `MADDataTableFast` | los datos de fila del informe |
| `<hash>.mdcache` | `MADDataTable` (`:354`) | una lista de propiedades que describe las tablas virtuales sobre esos datos |
| `<hash>{ih,lh}{w, h}.madac` | `MADArrayCaching`, alimentado por `MADReportFormatter` (`:179`, `:183`) | el contenido de página renderizado —una base de datos **SQLite**, indexada por identificador de diseño y tamaño de página. `ih` es la caché del *índice* del informe, `lh` la caché del *diseño* del informe |

Los tres viven juntos en un directorio por documento, nombrado con `dataTableIdHash`.
`MADocument.m:286-300` construye la tabla a partir de un directorio proporcionado por
`MADURLFactory newURLCacheFilesDirectoryForFilename:` (`MADURLFactory.m:47-49`), que
se resuelve en una ubicación por usuario y por dispositivo fuera del documento:

```objc
MADDataTableFast *datatable = [[MADDataTableFast alloc] initWithId:dataTableIdHash];
...
NSURL *cacheUrl = [self newUrlCacheForFilename:cacheName];
self.urlDataTableCache = cacheUrl;
[datatable loadFromCacheWithUrl:cacheUrl error:&error];
```

### 5.1 Los tamaños no son los que sugiere el nombre

Medidos en un directorio de caché real bajo `Library/Caches/`:

| Tipo | Archivos | Total |
|---|---|---|
| `<hash>.maddb` | 1 | 816 KB |
| `<hash>.mdcache` | 1 | 1.7 KB |
| `<hash>{ih,lh}{...}.madac` | 6 | **~15 MB** |

Los archivos `.madac` son la caché de páginas del formateador. Las claves `ih` y `lh` provienen de
`MADReportFormatter.m:179` y `:183`, que construyen `<layoutIdentifier>ih<CGSize>` y
`<layoutIdentifier>lh<CGSize>`; `{612, 792}` es el tamaño US Letter en puntos. Así que la caché está
indexada por *identidad de diseño y geometría de página*, que es lo que hace reales los dos riesgos
de la §5.3.

Frente a un documento de menos de 80 KB, la caché de renderizado es aproximadamente **200 veces el documento**. Los
datos de fila, que uno esperaría que dominaran, ocupan menos del 6 % del directorio.

**Por qué es deliberadamente así de grande.** El tamaño es una consecuencia del diseño, no un
accidente que haya que optimizar. Dos razones, ambas en palabras del propio usuario (2026-10-01):

1. **Renderizado en dos pasadas.** El número de páginas y las agrupaciones no se conocen hasta
   tener el conjunto completo de filas. Una agrupación de recuento en el pie de informe se puede sumar al final, pero una
   en el encabezado del informe debe conocerse antes de maquetar la primera página —y las páginas
   no se pueden numerar hasta conocer el número de filas—, así que todo el conjunto de resultados se extrae
   una vez y se mantiene en el dispositivo.
2. **La caché es la plataforma para futuras vistas.** Una vez que las filas son locales, distintas
   vistas de los mismos datos se pueden construir desde esa única caché sin volver a consultar la
   fuente, lo contrario de un sitio web que consulta la base de datos de nuevo en cada página. Hay
   más cosas previstas sobre esta misma caché, así que tratarla como espacio temporal sería
   un error.

La caché podría comprimirse, pero no es lo más urgente que cambiar.

### 5.2 Las consecuencias

- Un `.mad` es **pequeño y autocontenido**: es una definición, no un conjunto de datos. Ambas
  muestras distribuidas ocupan menos de 80 KB.
- Todo lo del directorio de caché es **desechable**. Borrarlo cuesta una actualización,
  nunca un documento.
- **No se comparte** entre dispositivos, y no está en iCloud, aunque el documento sí lo esté.
  Cada dispositivo vuelve a obtener los datos la primera vez que abre el documento.
- Por lo tanto, `.mad` **no** es el «archivo SQLite comprimido con los datos dentro» que podría
  parecer. Es un archivo SQLite comprimido con la *definición* dentro.

### 5.3 Lo que los archivos complementarios aún no definen

El directorio se nombra y se llena, pero no está especificado. Tres carencias, cada una de las cuales una
segunda plataforma tendría que adivinar:

1. **La caché de renderizado se indexa por nombre de archivo, no por contenido — confirmado el 2026-10-01.**
   `MADReportFormatter -layoutIdentifier` (`MADReportFormatter.m:186`) devuelve
   `_overrideIdentifier ? _overrideIdentifier.hash : _filename.hash`. Así que la clave es el
   *nombre* del documento más el tamaño de página, y nada en la ruta de carga comprueba el contenido:
   `MADArrayCaching -initializeDatabase` (`MADArrayCaching.m:141`) reutiliza el archivo
   SQLite existente siempre que su tabla `ac` esté presente, sin versión, marca de tiempo ni hash
   de contenido en la clave ni en la carga. **Editar un documento con el mismo nombre de archivo
   no invalida sus archivos `.madac`**: se sirve una página obsoleta hasta que se eliminan los archivos
   o se renderiza un tamaño de página distinto.

   **Medido el 2026-10-01, en consonancia con lo anterior.** Se ejecutaron una actualización y una exportación
   sin interfaz gráfica sobre el documento London a las 15:22. En su directorio de caché, después:

   | Archivo | Tamaño | mtime |
   |---|---|---|
   | `<hash>.maddb` | 835,584 | 15:22 |
   | `<hash>.mdcache` | 1,644 | 15:22 |
   | `<layoutId>ih{612, 792}.madac` | 81,920 | 15:22 |
   | `<layoutId>lh{612, 792}.madac` | 737,280 | 15:22 |
   | `<layoutId>ih{0, 0}.madac` | 1,867,776 | **10:52** |
   | `<layoutId>lh{0, 0}.madac` | 4,333,568 | **10:52** |

   Una actualización reescribe solo los archivos que necesita —las entradas `{612, 792}` (US Letter, la
   geometría de página del PDF)— y deja el resto. Las entradas `{0, 0}` no se tocaron, y
   juntas suman 6.0 MB de los 15 MB del directorio. `{0, 0}` es el tamaño de página antes de que se conozca
   una geometría real, así que esos dos archivos son casi con certeza una pasada de medición;
   también son, con el esquema indexado por nombre de archivo, algo que nada invalida salvo
   borrarlos.
2. **Nada dice qué se puede borrar.** Los tres tipos son regenerables, así que los tres
   deberían ser seguros —pero un `.maddb` de 0 bytes en un directorio por lo demás intacto muestra que
   el directorio se crea antes de llenarse, y nada establece si ese directorio
   tiene sentido.
3. **El esquema de la lista de propiedades `.mdcache`.** Ahora conocido: es el esquema serializado de la tabla
   de resultados, escrito por `MADDataTableFast -copyPlist` y leído por `-loadWithPlist:`. Claves de
   nivel superior: `name`, `columnKeys` (arreglo ordenado de identificadores `c<hash>`), `columns` (un diccionario indexado por
   `c<hash>`, cada uno una lista de propiedades `MADDataColumn`: `caption`, `fieldName`, `identifier`, `type`,
   `nativeType`, `dataLength`, `dataPercision`, `isPrimaryKey`, `isNotNull`,
   `isAutoIncrement`, `defaultValue`), `rowCounter`, `sortDescriptors`, y el
   `bulkInsertLoop` de la tabla rápida. `defaultValue` es el centinela `~MTNull~`
   (`MADDataColumnNullSentinel`, `MADDataColumn.m:23`). Observe las dos rarezas persistentes:
   `dataPercision` está mal escrito en el formato, y el centinela `~MTNull~` es un tercer marcador de nulo
   distinto de la familia `"<null>"` / `"(null)"` del Track 1.5 de `docs/project/BUGS.md`.
