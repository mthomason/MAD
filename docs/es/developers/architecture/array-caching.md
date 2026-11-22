---
layout: default
title: "MADArrayCaching"
description: "El arreglo de solo adición respaldado por disco detrás de la caché de renderizado de informes."
lang: es-419
---

# `MADArrayCaching`

Esta página describe `MADArrayCaching`, el arreglo de solo adición respaldado por disco usado como caché de renderizado de informes.

*Escrito en la fecha original; los hechos del estado actual se conciliaron el 2026-11-22.*

Un arreglo ordenado de solo adición respaldado por disco, usado como **caché de renderizado** del informe. Escrito
el 2026-10-01 contra `master` en `7ebe82f89`.

---

## Qué es

`MADArrayCaching<ObjectType>` (en `MADSqlite3`) es una subclase de `NSEnumerator` que se comporta como
un `NSMutableArray` cuyos elementos viven en disco en lugar de en memoria. Cada elemento se serializa
con `NSKeyedArchiver` y se almacena como un BLOB en un archivo SQLite. Es la clase detrás de los
archivos complementarios `.madac` en `MAD_FORMAT.md` §5.

Dos instancias por documento, ambas propiedad de `MADReportFormatter`:

| Sufijo del identificador | Contiene | Tipo de elemento |
|---|---|---|
| `…ih{w,h}` | los **índices** de página (qué filas caen en cada página) | `NSArray<NSNumber *>` |
| `…lh{w,h}` | los **diseños** de página (representaciones de sección por página) | `NSArray<MADSectionRepresentation *>` |

`MADReportFormatter` los llena con `beginBulkInserts` / `addObject:` / `endBulkInserts` y
los vuelve a leer con `objectAtIndex:` / `objectAtIndexedSubscript:`. Esta es la caché de renderizado —
los ~15 MB de archivos `.madac` en una caché de Music — y es lo que permite que un re-render omita el recálculo
del diseño de página.

## Formato en disco

`<identifier>.madac` es un archivo SQLite ordinario con una tabla:

| Columna | Tipo | Significado |
|---|---|---|
| `ci` | INTEGER, clave primaria | el índice del elemento (0, 1, 2, …) |
| `ck` | BLOB | el elemento serializado con `NSKeyedArchiver` |

El archivo vive en el directorio de caché del documento, nombrado por
`[self.identifier stringByAppendingPathExtension:@"madac"]` (`MADArrayCaching.m:269-274`), donde
`identifier` es el `layoutIdentifier` del formateador + `ih`/`lh` + el tamaño de página.

## API

`initWithIdentifier:cachedDelegate:types:` — `cachedDelegate` suministra el directorio de caché mediante
`MADCacheProtocol`, `types` es el conjunto de clases que `NSKeyedUnarchiver` puede decodificar.

Luego: `initializeDatabase` (abrir, crear la tabla si no existe), `addObject:` (añadir),
`objectAtIndex:` / `objectAtIndexedSubscript:` (leer), `beginBulkInserts` / `endBulkInserts`
(transacción alrededor de muchas adiciones), `removeAllObjects`, `finalizeDatabase`, y los accesores
`count` / `state` / `identifier`.

## Por qué es rápido (el diseño es correcto)

- **Sentencias preparadas.** Las sentencias de inserción, selección y conteo se compilan una vez
  (`prepareStatement*`) y se vuelven a enlazar en cada llamada — sin reanálisis.
- **Búsquedas indexadas.** `ci` es la clave primaria, así que `objectAtIndex:` es un `SELECT ck WHERE ci = ?`
  — una sonda de índice O(1), no un escaneo.
- **Inserciones masivas en una transacción.** `beginBulkInserts` / `endBulkInserts` envuelven las adiciones, así que
  un renderizado completo es un commit en lugar de un fsync por página.
- **Una caché de memoria por elemento.** `objectAtIndex:` cachea cada elemento que desarchiva (con clave por
  índice), así que una lectura repetida — el patrón normal del renderizador — es una búsqueda en `NSDictionary` sin
  viaje de ida y vuelta a SQLite y sin desarchivar. `lastObjectSelected` permanece para `nextObject`.
- **Dos colas seriales** (`archivingQueue`, `unarchiveQueue`) mantienen la única conexión SQLite
  con un escritor y un lector.

El costo dominante es la serialización con `NSKeyedArchiver` / `NSKeyedUnarchiver`, no SQLite — la
caché de renderizado pasa su tiempo marshalling gráficos de `MADSectionRepresentation`, que es el mismo
trabajo que el formateador haría de todos modos.

## Problemas encontrados

Los puntos 1–4 se corrigieron el 2026-10-01; los puntos 5–6 siguen abiertos y se registran en lugar de corregirse (el
enumerador es código muerto, y la trampa de concurrencia es latente mientras el formateador es
de un solo hilo).

1. **`-isEmpty` está invertido.** `MADArrayCaching.m:440` es
   `return _numberOfRows > 0;` — devuelve YES cuando la caché *tiene* filas. Es código muerto
   (ningún llamador), así que es una trampa latente, no un error activo. **Corregido**, y expuesto como propiedad
   de solo lectura.
2. **`-count` devuelve 1 para una caché vacía.** `MADArrayCaching.m:424-438` calcula el conteo como
   `max(ci) + 1`, pero cuando la tabla está vacía el `SELECT … ORDER BY ci DESC LIMIT 1` devuelve
   `SQLITE_DONE`, y `sqlite3_column_int64` sobre una sentencia terminada lee basura; el resultado es 1
   en lugar de 0. **Corregido.**
3. **`-readDataAtIndex:` y `-writeData:` están muertos.** No están en el encabezado, no tienen llamadores. Son un
   resto de una ruta cruda de `NSData` reemplazada por `addObject:`. `readDataAtIndex:` además mezcla tipos:
   en un acierto de `lastObjectSelected` devuelve el objeto *desarchivado*, no `NSData`. **Eliminados.**
4. **Las constantes de tabla/columna están duplicadas.** `MTArrayCachedTableName` / `…ColumnKey` /
   `…ColumnValue` / `…Extension` se declaran `static` en `MADArrayCaching.m` y se vuelven a declarar
   globales en `MADArrayCachingEnumerator.m`. Un solo encabezado debería poseerlas. **Corregido** — las
   declaraciones `extern` ahora viven en `MADArrayCaching.h` con las definiciones en
   `MADArrayCaching.m`.
5. **`MADArrayCachingEnumerator` usa el desarchivador antiguo.** Llama al
   `unarchiveObjectWithData:` obsoleto (no seguro) donde `MADArrayCaching` usa
   `unarchivedObjectOfClasses:`. Y su `nextObject` reinicia la sentencia después de cada paso, así que
   la iteración manual nunca avanza (la enumeración rápida mediante `countByEnumeratingWithState:` no se
   ve afectada). **Sigue abierto** — la clase no tiene llamadores.
6. **`_numberOfRows` se lee fuera de la cola.** `addObject:` lee `_numberOfRows` antes del
   `dispatch_*`, así que las adiciones concurrentes colisionarían en un índice. El formateador los llama
   de un solo hilo hoy, así que es latente. **Sigue abierto.**

## Mejoras sugeridas

En orden de valor:

1. Corrige `-isEmpty` y `-count` (dos correcciones de una línea), y elimina el par muerto
   `readDataAtIndex:` / `writeData:`. Seguro para el comportamiento: los dos primeros son correcciones de errores,
   el segundo es código muerto con un error de tipos.
2. Mueve las constantes `MTArrayCached*` a un único encabezado que ambos archivos importen.
3. Lleva `MADArrayCachingEnumerator` al mismo desarchivador que `MADArrayCaching`, y corrige o
   elimina su `nextObject` roto.
4. Solo si el perfilado lo muestra: reemplaza `NSKeyedArchiver` con un serializador más ligero y
   específico de caché, y/o elimina el `dispatch_sync` por lectura en favor de una llamada directa cuando la cola
   ya es propiedad. Estas son las palancas de "realmente rápido"; los puntos de corrección anteriores van primero.
