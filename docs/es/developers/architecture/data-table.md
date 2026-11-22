---
layout: default
title: "La arquitectura de MADDataTable"
description: "El clúster de clases de tabla de datos a través de los frameworks y su plan de desacoplamiento."
lang: es-419
---

# MADDataTable — informe de arquitectura y desacoplamiento

Esta página es el informe de arquitectura de `MADDataTable` y cada implementación a través de `MADFoundation`, `MAD`, `MADSqlite3`, `MADMySQL` y `MADTdsClient`. Registra el clúster de clases y el trabajo de desacoplamiento.

*Escrito en la fecha original; los hechos del estado actual se conciliaron el 2026-11-22.*

**Alcance:** `MADDataTable` y cada implementación, subclase, protocolo y sitio de llamada a través de
`MADFoundation`, `MAD`, `MADSqlite3`, `MADMySQL` y `MADTdsClient`.
**Rama:** `refactor/mad-database-decouple`
**Fecha:** 2026-10-01
**Verificación:** `xcodebuild test` — los 11 esquemas, 809 pruebas, 0 fallos; sin advertencias de ningún
archivo dentro del alcance (las dos advertencias `-Warc-repeated-use-of-weak` en `MADDatabaseMySQL.m` son
preexistentes y no se tocan). (798 en la Revisión 2; 804 en la Revisión 3; 807 en la Revisión 4.)

Todas las referencias `file:line` de abajo se leyeron de primera mano durante este análisis, no se infirieron.

> **Revisión 5 — 2026-10-01.** Las fases 3 y 5 están cerradas y el paso 7 de la fase 1 está probado.
> `-dropTable`, `-dropTableName:`, `-deleteAll` y `-vacuumCacheDb` ahora dejan `rowCounter`
> describiendo el archivo (§2.5), que era todo el paso 10/11; las tres constantes en riesgo
> están cubiertas por cuatro pruebas nuevas. Impulsar el bucle de filas de sqlite con un simple
> conformador `<MADDataTableWriting>` — sin `MADDataTable` detrás, sin `.maddb` — es el paso 7 y ahora es una prueba
> (`MADWritePortRecorder`). El paso 14 está hecho: `MADDataTableLocation` se elimina. Los pasos 13 y 15
> se evalúan en lugar de hacerse, con razones, en sus entradas de abajo.
>
> Dos defectos activos surgieron al escribir esas pruebas, ambos corregidos ahora. `-deleteAll` entregaba una
> *cadena* a `-[MADQueryCacheDeleteAllFromTable initWithObject:]`, que la usa como subíndice del
> diccionario de parámetros y lanza una excepción en la primera fila — el método no tiene llamadores, que es por lo que
> nada lo había alcanzado nunca; ahora usa `-initWithTableName:`. Y `MTTableController` leía
> `datatable.count` como cursor de página en su ruta de fallo, donde la tabla todavía contiene la
> página anterior, así que una obtención fallida informaba `hasMore = YES` y reintentaba para siempre.
>
> Los comentarios del contador desplazaron `MADDataTableFast.m` 13 líneas desde `-deleteAll` en adelante, así que cada
> referencia `file:line` más allá de ese punto se volvió a derivar en lugar de ajustarse; `MTTableController.m`
> también se movió, y sus referencias se volvieron a derivar con él.
>
> **Revisión 4 — 2026-10-01.** El obstáculo de MySQL de la Revisión 3 desapareció. Los metadatos de columna
> que `MADMySQLFetch+DataTable.m` lee a mitad de la obtención ahora los declara `<MADDataTableWriting>`
> mismo, así que los tres controladores — incluidos `MADDatabaseMySQL`, `MADDatabase.m` y el
> protocolo `MADDatabaseDataSource` — toman `id <MADDataTableWriting>` y los parámetros de salida de la
> obtención son por valor (`&` eliminado en todos los sitios de llamada). La fase 2 ("almacenar `urlFastCache`;
> inyectar el directorio de caché") y el paso 12 de la fase 4 (serializar la tubería de escritura) están hechos, y
> la fase 3 está hecha solo para la ruta de rehidratación. §2.1 y §2.3–§2.5 y §4.2 lo marcan. Se añadieron tres pruebas;
> la suite pasa de 804 → 807. Debido a que las correcciones desplazaron `MADDataTableFast.m` 87 líneas,
> cada referencia `file:line` a él en este informe se volvió a derivar en lugar de ajustarse, y
> los recuentos de líneas del apéndice se refrescaron con ellas.
>
> **Revisión — 2026-09-30.** Las secciones §2.5, §3.3, §3.5 y §4.2 se reescribieron después de que la primera
> revisión se encontrara errónea en tres puntos: el diagnóstico de `-dataForRow:error:` (se malinterpretó una firma
> de método de dos líneas — el método *sí* está implementado en `MADDataTableFast`), el
> "error activo" de `-allObjects` (sin llamador de producción) y el planteamiento de la deriva del `rowCounter` (inalcanzable).
> §4.5 es nueva. El texto corregido se marca como **Corregido** / **Arreglado**; las afirmaciones originales se dejan
> visibles donde eran instructivas. Tres correcciones de código aterrizaron con esta revisión — véase §3.5.
>
> **Revisión 3 — 2026-10-01.** El paso 5 de la fase 1 ha aterrizado: `<MADDataTableWriting>`,
> `<MADDataTableReading>` y `<MADDataTableCursoring>` están declarados en `MADDataTable.h` y la
> clase adopta los tres. El paso 6 aterrizó para dos controladores de tres — `MADDatabaseSQLServer` y
> `MADDatabaseSqlite3` ahora están tipados como puerto de escritura. El paso 6 **no pudo** aterrizar para `MADDatabaseMySQL`,
> y el "eliminar el bloque stub ahora redundante" del paso 5 se rechazó; §4.2 registra por qué para cada uno.
> La pasada entera es aditiva: no cambió ningún comportamiento, y los 11 esquemas pasan (804 pruebas).
>
> **Revisión 2 — 2026-09-30.** Los ocho sitios de cadena de formato `sqlite3_mprintf` de §4.5 están ahora
> corregidos, y la fase 0 ha aterrizado: las operaciones no implementadas en `MADDataTable.m` aseveran en lugar
> de fallar en silencio (§3.2, §4.2). La tabla de §3.1 y los recuentos de líneas del apéndice se volvieron a derivar
> contra los archivos cambiados. También se corrigieron dos errores de la revisión anterior: el
> total de pruebas del espacio de trabajo se declaraba como 799 y es 798, y §3.6 había citado cuatro sitios de `_database`
> donde hay quince.

---

## 1. Arquitectura actual y jerarquía de clases

### 1.1 La familia de clases

`MADDataTable` **no** es una sola clase — es un pequeño clúster de clases dividido entre tres
frameworks a lo largo de un eje de almacenamiento, más un eje de cursor implementado como objetos enumeradores separados.

```
MADFoundation
└── MADDataTable                          NSObject <NSCoding, NSFastEnumeration>
        │                                 "abstract": declares the full surface,
        │                                 implements metadata + plist persistence
        │
        ├── MADDataTableVirtual            MADFoundation/Source/MADDataTableVirtual.m (240 ln)
        │       In-memory. Rows live in per-column MADDataColumn arrays plus a
        │       `sortIndex` NSMutableArray of row NSDictionaries.
        │
        └── MADDataTableFast               MADSqlite3/Source/MADDataTableFast.m (1368 ln)
                sqlite3-backed. Rows live in a `.maddb` file; the object holds two
                MADDatabaseSqlite3 handles (one for writes, one for reads).

MADSqlite3 (private — NOT exported from the framework)
├── MADDataTableObjectEnumerator          173 ln — wraps a live sqlite3_stmt, yields row dicts
└── MADDataTableSingleColumnEnumerator    149 ln — same, yields a single column (row-ids)

MAD
└── MADDataTable+Constructor              the ONLY place that maps type -> concrete class
                                            (`MADDataTableLocation`, the other class here at
                                            Revision 4, was deleted — see §3.7)
```

Superficie de exportación verificada (de los `.framework/Headers` compilados):

| Framework | Encabezados de tabla de datos exportados públicamente |
|---|---|
| `MADFoundation` | `MADDataTable.h`, `MADDataTableType.h`, `MADDataTableVirtual.h` |
| `MADSqlite3` | `MADDataTableFast.h` **solo** |
| `MADMySQL` | ninguno |
| `MADTdsClient` | ninguno |

Esa división es deliberada y sana: los nombres de las clases enumeradoras nunca se filtran. Los consumidores solo
ven `NSEnumerator *`, que es lo que devuelve `MADDataTable.h`.

### 1.2 Dos ejes ortogonales, un enum

`MADDataTableType` (`MADFoundation/Source/MADDataTableType.h`) codifica solo el eje de **almacenamiento**:

```objc
typedef NS_ENUM(short, MADDataTableType) {
    MADDataTableTypeVirtual,    // -> MADDataTableVirtual
    MADDataTableTypePhysical,   // -> MADDataTableFast
};
```

El eje de **acceso** — fila por fila vs. cursor — es ortogonal y se expresa devolviendo un
enumerador en lugar de por un tipo. No hay `MADDataTableTypeCursor`. Esto importa para el
refactor: la costura del cursor ya existe y está correctamente oculta.

### 1.3 El único punto de selección de subclase

`MAD/Source/MADDataTable+Constructor.m:51-69` es el único lugar del código base que nombra una
subclase concreta:

```objc
+ (instancetype)newDataTableOfType:(MADDataTableType)type withObjectID:(NSUInteger)objectID {
	switch (type) {
		case MADDataTableTypeVirtual:  result = [[MADDataTableVirtual alloc] initWithId:objectID]; break;
		case MADDataTableTypePhysical: result = [[MADDataTableFast alloc] initWithId:objectID];    break;
		default: NSAssert(NO, @"Not implemented."); break;
	}
	return result;
}
```

Confirmé que **no** hay `isKindOfClass:`, `NSClassFromString`, comparación de cadenas de nombre de clase,
ni sondeo `respondsToSelector:` sobre una tabla de datos en ninguna parte del código base. Esta es la propiedad
más valiosa para el refactor — el clúster puede remodelarse detrás de este único método.

Dos salvedades en el mismo archivo:

* `+newDataTableWithDefinition:` llama a `NSAssert(NO, @"Not implemented.")` y devuelve `nil`
  cuando no hay id de objeto presente (`:44-46`). La intención de "predeterminar a virtual" en el comentario de
  `:31-32` es inalcanzable — `objectIdSet` condiciona la única ruta de retorno.
* `+newDataTableForIdentifier:` (`:79-92`) es el punto de entrada público *de facto*: la mayoría de los sitios de llamada
  (`MTTableController.m:90`, `MADQuerySampleDataTable.m:68`, `MADQuerySampleDataTableRange.m:69`)
  van directamente por `newDataTableWithDefinition:` en su lugar, y siempre fijan el tipo a Virtual.

### 1.4 El contrato de escritura

Cada controlador de base de datos puebla una tabla a través de la API de la **clase base**, nunca a través de una
específica de subclase. `MADDatabaseSqlite3.m:474-540` es el bucle canónico:

```objc
[dataTable removeAllObjects];
// first row only:
[dataTable addColumn:dataColumn];       // per column, discovered from sqlite metadata
[dataTable beginBulkInsert];
// per row:
[dataTable addRowWithDataForFieldKeys:resultsForRow];
[dataTable endBulkInsert];
```

`MADDatabaseSQLServer.m:500 / :1367 / :1472` usa la misma forma de cinco llamadas.
`MADMySQLFetch+DataTable.m:211 / :438 / :442` igualmente.

Este es un **puerto de escritura estrecho y bien definido**: cinco métodos. Es la frontera existente
más fuerte de la familia y debería preservarse textualmente en cualquier refactor.

Divergencia entre controladores:

| Controlador | Tabla que construye | Ruta de escritura |
|---|---|---|
| `MADDatabaseSqlite3` | cualquiera que se le entregue (típicamente `MADDataTableFast`) | `executeSQL:...intoResultTable:` |
| `MADDatabaseMySQL` | **construye** `MADDataTableVirtual` él mismo (`MADDatabaseMySQL.m:83, 110, 137, 175, 196, 376`) | `MADMySQLFetch+DataTable.m` |
| `MADDatabaseSQLServer` | **nunca construye una** — puramente de solo escritura en una tabla suministrada por el llamador | `MADDatabaseSQLServer.m` |

Así que MySQL no puede producir un `MADDataTableFast`, y SQL Server no puede producir ninguna tabla.
El almacenamiento "físico" (respaldado por sqlite) existe solo para la caché local, no para resultados remotos.

### 1.5 El contrato de lectura

Hay tres estilos de lectura distintos en uso en producción:

1. **Acceso aleatorio** — `-objectAtRow:` / `-objectAtRow:column:`.
   `MADMySQL` usa `objectAtRow:i column:0` dentro de bucles O(n)
   (`MADDatabaseMySQL.m:88-92, 118-122, 150-154, 187-189`) para leer resultados de `SHOW TABLES`.
   `MADQuerySampleDataTable.m:126` / `MADQuerySampleDataTableRange.m:131` llaman a `objectAtRow:0`
   una vez para leer una fila de ancho. `MTTableController.m:281, 284, 393` usa `objectAtRow:` para paginar.

2. **Enumeración** — `-enumeratorForKeyObjectsSorted`.
   `MADocument.m:865-867` devuelve esto como `enumeratorForReportData`, consumido por
   `MADReportFormatter.m:449-502`.

3. **Recuentos** — `-rowCounter` / `-count` / `-numberOfRows`.
   `MADocument.m:197` (`numberOfResults`), `MTTableController.m:249` (tamaño de tabla) y
   `:377, :399, :449, :455` (aritmética de cursor de página).

`MADReportFormatter` es el consumidor más tolerante y el que menos constriñe el
refactor. Nótese `MADReportFormatter.m:463-472`:

```objc
if (!calculatedRowId) {
    if ([resultRow isKindOfClass:[NSDictionary class]]) { rowIdOnly = NO; }
    calculatedRowId = YES;
}
self.machineState.detailRowId = rowIdOnly
    ? ((NSNumber *)resultRow).unsignedIntegerValue
    : ((NSNumber *)resultRow[MADIdentifierROWID]).unsignedIntegerValue;
```

El formateador **ya tolera un enumerador que produce `NSNumber`s de solo id de fila** así como
diccionarios de fila completos. `enumeratorForAllObjectsSortedRowIdOnly` existe precisamente para ese caso.
Esta es una costura lista para usar: un cursor que solo transmite ids de fila ya es una entrada aceptada.

---

## 2. Modelo de memoria, ciclo de vida y estado

### 2.1 ARC y el único ivar crudo

Todos los archivos son ARC (guardas `#if !__has_feature(objc_arc) #warning ...`). El estado vive en extensiones de clase.
`MADDataTableFast` tiene exactamente un ivar no objeto:

```objc
@implementation MADDataTableFast {
	sqlite3_stmt *_statementInsert;   // MADDataTableFast.m:103
}
```

Se finaliza en `-dealloc` (`:163-165`) y en `-endBulkInsert` (`:1334-1339`). El patrón
es correcto pero *era* frágil: `-endBulkInsert` solía anular la sentencia **antes** de tomar
la barrera, así que el desmontaje quedaba fuera de la única ventana en la que no hay inserción en vuelo.

**Arreglado (Revisión 4).** El desmontaje ahora se ejecuta dentro de la barrera, en `:1337-1338`.

### 2.2 Dos conexiones sqlite sobre un archivo

`-reopenDbConnection` (`:385-401`) construye **dos** instancias independientes de `MADDatabaseSqlite3`
apuntando al mismo archivo `.maddb`:

```objc
// write handle
MADDatabaseConnection *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
database.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
database.databaseConnection = connection;
[(MADDatabaseSqlite3 *)database openDatabaseWithFlags:
     SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX];
self.databaseForInserts = database;

// read handle — same URL, separate connection, default flags
MADDatabaseConnection *connectionSelect = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *databaseSelect = [[MADDatabaseSqlite3 alloc] init];
[databaseSelect setDatabaseConnection:connectionSelect];
[databaseSelect openDatabase];
databaseSelect.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
self.databaseForSelects = databaseSelect;
```

El handle de lectura se abre con **`-openDatabase` (banderas predeterminadas)** y el de escritura con
`SQLITE_OPEN_FULLMUTEX`. `SQLITE_OPEN_FULLMUTEX` es un modo de serialización **por conexión**;
no arbitra entre dos conexiones sobre el mismo archivo. Combinado con §2.4, esta es la
mayor suposición de corrección única de la familia.

### 2.3 La ubicación del almacenamiento se resuelve desde el estado global ambiente

`-urlFastCache` era una propiedad *calculada* (`:299-311` antes de esta revisión), no almacenada:

```objc
- (NSURL *)urlFastCache {
	NSString *filename = [[self filenameCacheMadDB] copy];
	NSURL *cacheDirectory;
	if (self.cacheDelegate == nil) {
		id <UIApplicationDelegate, MADApplicationProtocol> appDelegate = [MADApplication AppDelegate];
		id groupIdentifier = [appDelegate groupIdentifier].copy;
		cacheDirectory = [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
	} else {
		cacheDirectory = [self.cacheDelegate cachedFilesDirectory].copy;
	}
	return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}
```

Consecuencias:

* Una tabla sin `cacheDelegate` **depende en silencio del delegado de aplicación global** para su
  identidad en disco. Es por eso que `MADDataTableFast` no podía instanciarse en una prueba lógica sin host
  sin un delegado — la suite de regresión lo sortea con un stub que cumple
  `MADCacheProtocol` + `MADDatabaseResultsProtocol`.
* `-setCacheDelegate:` (`:377-383`) llama a `-reopenDbConnection`. Cambiar un
  delegado **reapunta la tabla a un archivo diferente** mientras mantiene `tag`/`rowCounter`/
  `columnKeys` en memoria. Nada detecta la discrepancia.
* `-copyPlist` asevera `urlFastCache != nil` (`:243`) — así que la URL persistida de una tabla archivada
  depende del estado ambiente en el momento del archivo.

**Arreglado (Revisión 4).** `-urlFastCache` ahora se resuelve una vez y mantiene la respuesta
(`_urlFastCache`, en `:347-355`, escrita por el getter y por `-setCacheDelegate:` en `:377-383`,
que la descarta antes de reabrir). `-newUrlFastCache` (`:357-373`) mantiene la resolución misma,
con una nueva primera opción: un directorio de caché suministrado en el init. `MADDataTableFast` ganó
`-initWithId:cacheDirectory:` (`:173-181`),
`+[MADDataTable newDataTableOfType:withObjectID:cacheDirectory:]` lo pasa (`nil` mantiene
el comportamiento antiguo), y abre la conexión inmediatamente para que la tabla sea utilizable sin
delegado y sin aplicación. El reenvío del cambio de delegado de arriba sigue ocurriendo — esa es la lectura prevista
de "la URL se deriva del delegado" — pero ya no depende de *cuándo* se leyó
la propiedad por primera vez.

`tag` (establecido desde `initWithId:fromCache:`, `:190`) es la única identidad estable; produce tanto
el nombre de la tabla (`t<tag>`, `:403-409`) como el nombre de archivo (`<tag>.maddb`, `:340-343`).

### 2.4 Seguridad de hilos: sin bloqueos, una cola

Busqué en toda la familia `dispatch_sync`, `dispatch_async`, `@synchronized`, `NSLock`,
`os_unfair_lock` y `pthread_mutex`. La **única** primitiva de concurrencia presente es
`queueBulkAdd`:

* Creada tres veces por separado — `initWithId:fromCache:` (`:186`), `initWithCoder:` (`:202`),
  y `beginBulkInsert` (`:1322`) — cada una `dispatch_queue_create(..., SERIAL)`.
* Usada en exactamente **dos** lugares: `-endBulkInsert` (`:1334`) envuelve la llamada al delegado en
  `dispatch_barrier_sync`, y (desde la Revisión 4) `-addRow:error:` entra en ella con
  `dispatch_sync`.
* Antes de la Revisión 4 **nunca** se usó para serializar `-addRow:error:`.

Así que `-addRow:` — el punto de entrada de mutación — *estaba* completamente desprotegido por la cola. Bajo
`_bulkInsertLoop`, `-addRow:` reutiliza un único `_statementInsert` cacheado entre llamadas
(`:529-611`): `sqlite3_bind_*` → `sqlite3_step` → `sqlite3_clear_bindings` →
`sqlite3_reset`, sin exclusión mutua. Dos hilos que entran en `-addRow:` de forma concurrente compiten por
esa sentencia compartida independientemente de `SQLITE_OPEN_FULLMUTEX`, porque la carrera está en la
*secuencia* bind/step/clear/reset, no dentro de ninguna llamada sqlite individual.

La suite de regresión registra el comportamiento concurrente actual pero no puede hacerlo seguro — la
serialización tiene que añadirse.

**Arreglado (Revisión 4).** `-addRow:error:` (`:504-528`) ahora es un envoltorio fino que ejecuta el cuerpo de inserción
(`-insertRow:error:` en `:529`, el método antiguo renombrado) bajo `dispatch_sync(queueBulkAdd)`, recurriendo
a una llamada directa solo cuando la cola es nil — lo que ocurre solo en una tabla que nunca
terminó de inicializarse. El `sqlite3_finalize(_statementInsert)` de `-endBulkInsert` se movió *dentro* de
su `dispatch_barrier_sync`, así que la sentencia cacheada se desmonta solo cuando no hay una inserción
en vuelo. En una cola serial la barrera y el `dispatch_sync` son mutuamente exclusivos, que es
toda la exclusión mutua que necesita la secuencia bind/step/clear/reset. Dos pruebas lo fijan:
`testFastTableConcurrentWritersLoseNoRows` (nueva) impulsa cuatro escritores desde una cola *concurrente*;
`testFastTableSerializedConcurrentWritesLoseNoRows` mantiene el patrón de cola serial de la aplicación, y su
nota de contrato "la tabla no serializa internamente" se corrigió. El paso 13 (un par de conexiones
por archivo) no se toca.

### 2.5 `rowCounter` es un contador independiente, no un valor derivado

`-insertRow:error:` incrementa `rowCounter` (`:532`) y **nunca consulta sqlite**.
`-numberOfRows` / `-count` lo devuelven directamente (`:1222` / `:1216`), y `-removeAllObjects` lo pone a cero
(`:683`). Pero `-dropTable` (`:799`), `-dropTableName:` (`:804`), `-deleteAll` (`:818`) y
`-vacuumCacheDb` (`:789`) **no** lo tocaban hasta la Revisión 5.

Las dos fuentes de verdad pueden por lo tanto divergir:

* `rowCounter` dice N; el archivo `.maddb` contiene un número diferente de filas.
* En una ida y vuelta de `-loadFromCacheWithUrl:` el contador venía del plist
  (`MADDataTable.m:305-306`) mientras las filas vienen del archivo sqlite — se rehidratan por
  dos mecanismos no relacionados.

**Arreglado (Revisión 4) — la mitad de recarga.** `-loadWithPlist:` ahora termina con
`self.rowCounter = [self recountRows];` (`:313`), donde `-recountRows` (`:317-338`) pregunta
al archivo de caché por `SELECT COUNT(*)` y recurre al valor del plist solo cuando la tabla
no existe todavía. Un contador inflado por la ruta en memoria ya no puede sobrevivir a una recarga.
`testFastTableReloadRecountsRowsFromCacheFile` lo fija cargando un plist cuyo contador dice
99 sobre un archivo que contiene 3 filas.

**Arreglado (Revisión 5) — la mitad en memoria, que era el paso 10/11.** `-dropTable` (`:799`) y
`-dropTableName:` (`:804`) ahora ponen a cero el contador, `-deleteAll` (`:818`) lo pone a cero, y
`-vacuumCacheDb` (`:789`) deliberadamente no lo hace, porque VACUUM conserva cada fila — la
fuente lleva un comentario que lo dice, ya que "por qué este *no* lo reinicia" es exactamente la pregunta
que tendrá el siguiente lector. `-dropTableName:` toma un nombre arbitrario, así que pone a cero el contador
solo cuando la tabla que se fue es esta; eliminar una tabla ajena no debe tocar este
recuento. `-numberOfRows` (`:1222`) y `-count` (`:1216`) siguen devolviendo el ivar en lugar de
consultar el archivo, que es el punto — `-recountRows` es la comprobación de la ruta de recarga, no un
costo por lectura.

`-removeAllObjects` (`:674`) ocultaba todo el peligro, y lo sigue haciendo: es el único llamador de los
cuatro, y pone el contador a cero él mismo (`:683`). Eso es exactamente por qué valía la pena cerrar esto
en lugar de dejarlo — el peligro estaba a un llamador de estar vivo, `-count` es un cursor de página
para la aplicación (§4.3), y los cuatro métodos privados están a un `git log -S` de ser llamados desde
algún sitio nuevo. La nota de la Revisión 4 aquí llamaba a la deriva "real en el código, pero ningún llamador puede
alcanzarla hoy"; la auditoría de llamadores sigue vigente — `-deleteAll` **no tiene llamadores en ninguna parte del
repositorio**, y `-dropTable` solo se alcanza desde `-removeAllObjects` — pero el contador ahora está
correcto en cada ruta en lugar de solo porque su único llamador resulta ordenar después.
Cuatro pruebas en `MADDataTableRegressionTests.m` impulsan cada uno de los cuatro directamente.

`MADDataTableVirtual` tiene la misma forma (`:179`, `:193`, `:225`) pero su contador y su
`sortIndex` se mutan juntos, así que es consistente por construcción.

Este es el estado más en riesgo bajo un refactor de clúster de clases: `MTTableController.m` lee
`datatable.count` en `:377` y `:399`, y deriva `hasMore = (count == limit)` de él en
`:455`, así que un contador que diverja de la realidad corrompería la paginación. La Revisión 5 hace esa
derivación total también — una página vacía ya no envuelve `offset + count - 1` a `NSUIntegerMax`
(`:380`, `:402`), y la ruta de fallo devuelve `completion(NO)` (`:449`) en lugar de leer un
recuento que todavía describe la página *anterior*.

Escribir esas pruebas destapó un defecto en `-deleteAll` que no tenía nada que ver con el contador:
pasaba un `NSString` a `-[MADQueryCacheDeleteAllFromTable initWithObject:]`, que usa su argumento
como subíndice del diccionario de parámetros, así que lanzaba `unrecognized selector` en la primera
fila. `-initWithTableName:` es el inicializador que toma un nombre y es el que
`MADDatabaseSqlite3 -beginBulkInsert` ya usaba. Ningún llamador lo alcanzó nunca, porque no hay
llamador.

### 2.6 Dos mecanismos de persistencia no relacionados

| Mecanismo | Dónde | Almacena |
|---|---|---|
| Plist, `NSPropertyListBinaryFormat_v1_0` | `MADDataTable.m:193-220`, `:135-191` | `name`, `columnKeys`, `columns` (metadatos), `rowCounter`. **Ninguna fila.** |
| Archivo sqlite `.maddb` | `MADDataTableFast.m` | datos de fila reales, más claves específicas de `MADDataTableFast` (`urlFastCache`, `tag`, `bulkInsertLoop`, `sortDescriptorsSet`, `groupKeyIndexes`) |

`-cacheWithUrl:error:` en la clase base está documentado como caché genérica pero solo
serializa *forma*, no *contenido*. `MADocument.m:413-414` deriva `urlDataTableCache` de
`[self.dataTable newFilenameMDCache]` (`<tag>.mdcache`) mientras `MADDataTableFast` lee y
escribe `<tag>.maddb` (`:340-343`). Dos extensiones de archivo, dos formatos, dos propietarios, una tabla
lógica.

**Evaluado (Revisión 5) — paso 15, que pedía una reconciliación. El planteamiento es incorrecto, y
ese es el hallazgo.** "El plist base es solo metadatos" es cierto de la clase base y falso de
la familia: cada subclase extiende `-copyPlist` / `-loadWithPlist:` con exactamente una clave extra,
y esa clave *es* su almacenamiento.

| Clase | Almacenamiento | Clave del plist que lo lleva |
|---|---|---|
| `MADDataTable` | ninguno (abstracta) | `name`, `columnKeys`, `columns`, `rowCounter` |
| `MADDataTableVirtual` | `sortIndex`, un arreglo de diccionarios de fila (`MADDataTableVirtual.m:106-109`, `:89-104`) | `keySortIndex` — las filas mismas |
| `MADDataTableFast` | el archivo `.maddb` | `keyUrlFastCache`, `keyTag`, … — un *localizador* de las filas |

Así que las filas ya hacen ida y vuelta a través del plist donde el plist es el almacenamiento, y no pueden donde
el almacenamiento es un archivo sqlite. Ni el renombrado ("llámalo metadatos") ni la alternativa ("pon las filas
dentro") es correcto para la familia en su conjunto; la clase base son los metadatos que *ambas* subclases
comparten, y el mecanismo es por subclase por diseño. Las dos extensiones tampoco son un conflicto:
`MADocument` escribe `<tag>.mdcache` (el plist) junto a `<tag>.maddb` (las filas), y
`-loadFromCacheWithUrl:` lee el primero para encontrar el segundo — siempre que la etiqueta coincida, lo cual
hace, porque `-filename` (`MADocument.m:1397-1399`) es `fileURL.lastPathComponent`
`stringByDeletingPathExtension`, la misma cadena que hashea el init para la etiqueta.

Lo que vale la pena hacer, y no se hace aquí, es documentación en lugar de reestructuración: nombrar los
dos archivos en el directorio de caché de `MADocument` por lo que son, y decir en `MADDataTable.h` que
`-copyPlist` devuelve los metadatos compartidos y que una subclase con su propio almacenamiento debe extenderlo.
Ese es un cambio de comentario sin comportamiento que preservar, así que pertenece a una pasada de documentación, no
aquí.

### 2.7 Ciclo de vida del enumerador

`MADDataTableObjectEnumerator` mantiene su propio `MADDatabaseSqlite3` + conexión + sentencia
preparada, todo construido en `-initWith...` (`:60-72`) y liberado en `-dealloc` (`:45-49`).
Por lo tanto:

* Un enumerador mantiene vivo un handle de base de datos y un descriptor de archivo mientras se retenga
  — y `MADReportFormatter.m:449-502` mantiene uno durante toda la duración del renderizado de un informe.
* Cualquier mutación de tabla que elimine o reconstruya la tabla (`-removeAllObjects`, `-dropTable`)
  invalida la sentencia viva en un enumerador pendiente. Nada protege esto.
* Cada llamada `-objectEnumerator` / `-enumeratorFor...` asigna una **conexión nueva** al
  mismo archivo (`:1139`, `:1158`, `:1186`, `:1202`). Enumerar dos veces abre sqlite dos veces.

**Evaluado (Revisión 5) — paso 13, que pedía un par de conexiones compartido por archivo. No
hecho, y la razón está en el ciclo de vida, no en el recuento.** La conexión de inserción no puede compartirse
en absoluto: `MADDatabaseSqlite3 -endBulkInsert` termina cerrándola y anulando `_database`
(`:794-795`), que es por lo que `MADDataTableFast -removeAllObjects` reabre antes de eliminar nada
y por lo que las cuatro mutaciones privadas aseveran cuando se impulsan directamente (es incorrecto impulsarlas
directamente — véanse las pruebas de la Revisión 5, que reabren primero exactamente por esta razón). Un
"par" compartido tendría que ser por lo tanto una conexión de *lectura* compartida más una conexión de escritura por ciclo,
lo que ahorra un handle, no dos.

Y el ahorro es menor de lo que parece: cada conexión aquí abre
`SQLITE_OPEN_SHAREDCACHE` (`MADDatabaseSqlite3.m:220`), así que los enumeradores ya comparten una
caché de páginas y un conjunto de bloqueos en todo el archivo. Lo que cada enumeración cuesta realmente es un
`sqlite3*` y un descriptor de archivo — real, pero no el costo de caché duplicada que implica el paso.

Frente a eso, compartir la conexión de lectura *perdería* algo. Los enumeradores se mantienen durante
toda la duración de un renderizado de informe (`MADReportFormatter.m:449-502`), y `-removeAllObjects` elimina y
reconstruye la tabla debajo de ellos; hoy un enumerador pendiente posee su sentencia y su
handle, así que los dos interfieren solo a través del archivo. Darles un handle compartido pondría
esa interacción dentro de una sola conexión, en una clase cuyas lecturas no llevan bloqueo propio.
El escenario para el que diseñar es el que §2.7 ya señala — un enumerador vivo a través de una reconstrucción
de tabla — y compartir conexiones lo empeora, no lo mejora. Se deja como está deliberadamente.

---

## 3. API pública vs. abstracciones con fugas

### 3.1 Superficie declarada vs. implementación real

`MADDataTable.h` declara 30 métodos (más las propiedades `name` / `columnKeys` / `sortDescriptors` /
`columns` / `rowCounter` / `tag`, dos de las cuales el protocolo de escritura vuelve a declarar —
véase §4.2). La clase base implementa 18 de ellos y stub 12:

| Declarado en `MADDataTable.h` | Impl. base (`MADDataTable.m`) | Virtual | Fast |
|---|---|---|---|
| `-addColumn:` | **assert** `:365` | override `:112` | override `:431` |
| `-addRow:error:` | **assert** `:369` | override `:179` | override `:504` |
| `-addRowWithDataForFieldKeys:` | **assert** `:374` | override `:197` | override `:614` |
| `-sortUsingDescriptors:` | **assert** `:378` | override `:208` | override `:634` |
| `-removeAllObjects` | **assert** `:382` | override `:225` | override `:674` |
| `-objectAtRow:column:` | **assert** `:386` | override `:159` | override `:834` |
| `-objectAtRow:` | **assert** `:391` | override `:151` | override `:848` |
| `-columnsEnumerator` | **assert** `:396` | override `:149` | override `:1123` |
| `-objectEnumerator` | **assert** `:401` | override `:148` | override `:1127` |
| `-beginBulkInsert` / `-endBulkInsert` | no-op `:408-409` | no-op `:236-238` | override `:1311`/`:1330` |
| `-allObjects` | `return @[]` `:414-417` | override `:118` | override `:1209` |
| `-objectAtRow:limit:` | `return @[]` `:419` | override `:220` | override `:1086` |
| `-count` / `-numberOfColumns` / `-numberOfRows` | `0` `:420-422` | override `:122`, `:214`, `:216` | override `:1216`, `:1220`, `:1222` |
| `-countByEnumeratingWithState:...` | `0` `:423-427` | override `:140` | hereda (0) |
| `-enumeratorForAllObjectsSorted*`, `-objectsForGroupKeys:`, `-dataForRow:error:`, `-enumeratorForKeyObjectsSorted` | `NSAssert(NO, @"Not implemented")` `:327-350` | **también** `NSAssert(NO)` `:31-54` | implementado `:1034`, `:1148`, `:1172`, `:1193`; `-dataForRow:error:` `:941` |

### 3.2 Fuga 1 — la clase base no puede expresar "abstracta"

Objective-C no tiene `abstract`. Así que la base solía devolver **`YES` desde `-addRow:error:`** y
**`nil` desde cada lector**. Una subclase parcialmente implementada, o una instancia directa de `MADDataTable`,
aceptaría escrituras en silencio e informaría éxito, luego no leería nada.

**Arreglado (Fase 0).** Las nueve operaciones de escritura/lectura que una subclase de almacenamiento debe sobrescribir ahora
abren con `NSAssert(NO, @"%s must be overridden", __PRETTY_FUNCTION__)` (`MADDataTable.m:365`,
`:369`, `:374`, `:378`, `:382`, `:386`, `:391`, `:396`, `:401`), coincidiendo con el grupo `:327-350`.
`-addRow:error:` devuelve `false` en Release en lugar de `true`, así que incluso con las aserciones compiladas
fuera ya no afirma que se almacenó una fila.

Dos grupos se **dejaron** deliberadamente como valores predeterminados silenciosos, porque para ellos el silencio es correcto:

* `-beginBulkInsert` / `-endBulkInsert` (`:408-409`) — ganchos opcionales. Una subclase que no
  necesita el modo masivo puede heredar legítimamente el no-op.
* `-allObjects` (`:414-417`), `-objectAtRow:limit:` (`:419`), `-count` / `-numberOfColumns` /
  `-numberOfRows` (`:420-422`) y `-countByEnumeratingWithState:...` (`:423-427`) — estos
  devuelven `@[]` / `0`, que es la respuesta *veraz* para una tabla sin filas, y coincide con lo que
  devuelve `MADDataTableVirtual`. Aseverar en `-count` convertiría una respuesta correcta en un fallo.

La mitad restante de esta fuga — expresar la división en el sistema de tipos en lugar de por
aserción — es la Fase 1 (§4.2).

### 3.3 Fuga 2 — un contrato de nulabilidad que ya está roto

`MADDataTable.h:65` declara (dentro de `@protocol MADDataTableCursoring`):

```objc
- (nonnull NSArray *)allObjects;
```

`MADDataTableFast.m` solía responderlo así (`:1093-1096` antes de esta revisión):

```objc
- (NSArray *)allObjects {
	// FIXME: Implement this.
	return nil;
}
```

Un método declarado `nonnull` que devuelve `nil` en una subclase y `@[]` / `[self.sortIndex copy]`
en las otras. Cualquier llamador que confiara en la anotación fallaría — era el único `FIXME` de
la familia que contradecía un contrato de encabezado.

**Corregido:** no hay llamador de producción. Los únicos envíos a `-allObjects` sobre una tabla de datos
están en esta suite de regresión, y `MADDataTableRegressionTests.m` fijaba deliberadamente el
`nil` en `testFastTableBulkInsertAllObjectsIsUnimplemented`. Así que la anotación era una trampa
puesta para un futuro llamador, no un fallo activo.

**Arreglado:** `MADDataTableFast -allObjects` (`:1209-1214`) ahora devuelve cada fila mediante
`-objectAtRow:0 limit:numberOfRows`, y `@[]` para una tabla que no tiene columnas, coincidiendo con la
declaración `nonnull` y el comportamiento existente de `MADDataTableVirtual` (`:118-120`). La prueba
que fijaba el `nil` se reemplazó por dos que afirman el contrato real.

### 3.4 Fuga 3 — `-objectAtRow:column:` significa cosas distintas por subclase

Las dos implementaciones discrepan tanto en el significado de `row` como en el almacenamiento consultado:

```objc
// MADDataTableVirtual.m:159-163 — reads the per-column store, applies the sort index
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSString *fieldKey = self.columnKeys[column];
	MADDataColumn *dataInColumn = self.columns[fieldKey];
	return [dataInColumn objectAtIndex:[self sortedIndexForIndex:row]];   // LOGICAL row
}
```

```objc
// MADDataTableFast.m:834-846 — reads the row dictionary, physical order
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSDictionary *objForRow = [self objectAtRow:row];
	if (objForRow == nil || column >= self.columnKeys.count) return nil;
	NSString *key = self.columnKeys[column];
	MADDataColumn *columnMetaData = self.columns[key];
	if (columnMetaData == nil) return nil;
	return objForRow[columnMetaData.identifier];      // PHYSICAL (sqlite) order
}
```

Nótese también que la disciplina de límites difiere: Virtual **no** hace comprobación de límites en `column`
(`self.columnKeys[column]` lanzará `NSRangeException` fuera de límites, atrapado solo por el
`@try` en `-objectAtRow:`, no aquí) ni comprobación de nil en `dataInColumn`; Fast hace ambas.

Mismo selector, dos conjuntos de semántica. `MADMySQL` llama a esto en un bucle apretado
(`MADDatabaseMySQL.m:88-92` y tres sitios más), así que un refactor que unifique la semántica se
sentirá primero en MySQL.

### 3.5 Fuga 4 — `-dataForRow:error:` está implementado en una subclase y falta en la otra

**Esta sección estaba equivocada en la primera revisión de este informe.** Afirmaba que
`MADDataTableFast` no implementa `-dataForRow:error:` y que la ruta de código de barras/impresión
por lo tanto alcanzaba el `NSAssert(NO)` de la clase base. Eso es falso, y envió a un lector por un
camino falso. El análisis corregido sigue.

`MADDataTable.h:67` declara
`- (nullable NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)rowID error:(NSError **)error;`
y la base lo implementa como `NSAssert(NO, @"Not implemented: %s")` + `return nil`
(`MADDataTable.m:342-345`).

* **`MADDataTableFast` sí lo implementa**, en `MADDataTableFast.m:941-1015`:

  ```objc
  - (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)cacheId
                                                   error:(NSError * __autoreleasing *)outError {
  ```

  Es una firma de dos líneas, que es lo que la revisión anterior malinterpretó: el selector se envuelve
  en una segunda línea, y la segunda línea se tomó por una sobrecarga separada `-dataForRow:column:`.
  (El verdadero `-dataForRow:column:error:` es un método diferente en `:866-932`.) La
  implementación es real, y la suite de regresión ya la cubre --
  `MADDataTableRegressionTests.m` `testFastTableDataForRowReturnsValues` y
  `testFastTableDataForRowCachesLastRow` ambos envían el selector de dos argumentos a un `MADDataTableFast`
  vivo y pasan.

* **`MADDataTableVirtual` no implementa ninguna forma.** Tiene un stub `-dataForRow:` en
  `:41-44`, pero ese stub es `NSAssert(NO, @"Not implemented: %s")` + `return nil` — no es
  una sobrecarga funcional, y no está declarado en `MADDataTableVirtual.h`. La
  forma de dos argumentos recae en la base que asevera. Así que la subclase en memoria no tiene
  acceso a fila por id en absoluto.

Los sitios de llamada por lo tanto no están en riesgo: `MADocument.m:875/880/919` despachan a
`MADocument.dataTable`, que es tanto estática como realmente un `MADDataTableFast`
(`MADocument.m:159`, asignado en `:230` y `:288`). Las rutas `MADPrintPageElement.m:80` y
`MADPrintPageElementBarcode.m:30` alcanzan el mismo objeto. Nada en una ruta viva asevera.

El defecto real es más estrecho y ahora está arreglado: porque `MADDataTableVirtual` nunca
implementó el selector, cualquier futuro llamador que tuviera un `MADDataTable *` que resulta ser
una tabla Virtual habría aseverado en Debug y recibido `nil` en silencio en Release.
`MADDataTableVirtual` ahora implementa `-dataForRow:error:` delegando en `-objectAtRow:`
e informando el caso fuera de rango a través del puntero de error.

La implementación de `MADDataTableFast` también tenía un defecto genuino, ahora arreglado: su
`if (sqlite3_prepare == SQLITE_OK)` **no tenía `else`**, así que un fallo de preparación devolvía `nil`
sin establecer `*outError`, y el error de `-getSql:` se descartaba. Su hermano
`-dataForRow:column:error:` (`:905-932`) maneja ambos correctamente. El SQL también se pasaba a
`sqlite3_mprintf` como la cadena de *formato* (`sqlite3_mprintf((char *) sql.UTF8String)`), que
destroza o falla con SQL que contiene `%`; ahora es `sqlite3_mprintf("%s", ...)`, coincidiendo
con el hermano en `:901`. Ocho sitios más en `MADSqlite3` tenían el mismo defecto; todos están ahora
arreglados — véase §4.5.

### 3.6 Fuga 5 — `MADDataTableFast` alcanza el ivar privado de otra clase

`MADDataTableFast.m` accede directamente al ivar privado `_database` de `MADDatabaseSqlite3` en
quince sitios — `:488`, `:538`, `:784`, `:793`, `:810`, `:829` (a través de `_databaseForInserts`)
y `:905`, `:976`, `:1065`, `:1078`, `:1106`, `:1108`, `:1248`, `:1251`, `:1261` (a través de
`databaseForSelects`):

```objc
sqlite3 *sqlite_database = _databaseForInserts->_database;                       // :451
NSAssert(prepareResult == SQLITE_OK, @"%s", sqlite3_errmsg(databaseForSelects->_database)); // :1008
```

Esto evita por completo la API de `MADDatabaseSqlite3` y es la razón por la que `MADDataTableFast` necesita un
archivo sqlite real para hacer algo en absoluto. También es por lo que el objetivo de pruebas necesitó el
trabajo de importación del módulo `MADDataTable+Constructor`: la familia de clases solo es utilizable desde código que
enlaza ambos frameworks juntos.

### 3.7 Fuga 6 — API pública muerta — **eliminada (Revisión 5)**

`MADDataTableLocation` (`MAD/Source/MADDataTableLocation.{h,m}`, 67 líneas) era un
objeto de valor `(row, column)` con `NSCoding` y una fábrica `+newDataTableLocationForRow:inColumn:`. Busqué
en todo el código base excluyendo su propia implementación: **sus únicas referencias
estaban en el archivo de prueba de regresión.** Estaba muerta en producción. Además adoptaba `NSCoding` pero no
`NSSecureCoding`, que la suite de regresión registraba como contrato.

El paso 14 de la fase 5 ofrecía una elección — conectarlo a una función o eliminarlo. Se elimina, porque
no había ninguna función que estuviera esperando: un commit en toda su historia (`e702bb062`, la
reorganización del framework `MAD`), ningún llamador, y nada más que sus propias tres pruebas describiendo para qué
servía. Una clase que solo se mantiene viva por sus pruebas es una clase por la que las pruebas están pagando dos veces.
Los archivos, sus dos entradas de compilación `.pbxproj` y las tres pruebas se van con él; §3.7 se queda
como Fuga 6 en lugar de renumerarse, para que la numeración que cita el resto del informe se mantenga.

### 3.8 Fuga 7 — la tabla alcanza *hacia atrás* la consulta de escritura

`MADDataTableFast` cumple de forma privada cuatro protocolos
(`:71`):

```objc
@interface MADDataTableFast () <MADQueryParametersStandardProtocol,
                                MADQueryParametersColumnKeysProtocol,
                                MADQueryParametersColumnMetaProtocol,
                                MADQueryParametersColumnDataProtocol>
```

e implementa `-queryTableName` / `-queryColumnKeys` / `-queryColumns` / `-queryRowData`
(`:419-430`) puramente para que `MADQueryCacheAddRow` pueda sacar estado de la tabla en la que está escribiendo.
La ruta de inserción es por lo tanto un ciclo: tabla → objeto de consulta → de vuelta a la tabla. Nótese el
riesgo de colisión de nombres — `-queryRowData` (`:428`) y la propiedad privada `_rowDataLastInserted`
no tienen relación con la familia pública `-dataForRow:`.

### 3.9 Qué *no* tiene fugas (preserva esto)

* Toda la selección de subclase está en `MADDataTable+Constructor.m:51-69`.
* El puerto de escritura son cinco métodos de la clase base (§1.4).
* Las clases enumeradoras son privadas de `MADSqlite3` y solo afloran como `NSEnumerator *`.
* `MADReportFormatter.m:463-472` ya tolera la enumeración de solo id de fila.
* `MADArrayCaching` (`MADSqlite3`) es precedente en este código base de una abstracción de caché con
  una superficie más estrecha y con forma de protocolo.
* Ningún sondeo de clase en tiempo de ejecución sobre tablas en ningún lado.

---

## 4. Estrategia de desacoplamiento y refactorización

El objetivo es hacer de `MADDataTable` una *interfaz estable* sobre estrategias intercambiables de almacenamiento y acceso,
sin cambiar el comportamiento del que ya dependen los cinco controladores y los cuatro consumidores.

### 4.1 Forma objetivo

Mantén los nombres de clase (están incrustados en archivos `NSCoding` y Core Data) pero mueve la
variación detrás de dos protocolos que devuelven los constructores:

```
                    ┌─────────────────────────────────────┐
                    │  MADDataTable        (concrete base) │
                    │  metadata, plist persistence,        │
                    │  NSCoding, — no-op defaults removed   │
                    └──────────────┬──────────────────────┘
                                   │
        ┌──────────────────────────┴───────────────────────────┐
        │                                                       │
  MADDataTableVirtual                                   MADDataTableFast
  (unchanged semantics)                          (sqlite; owns a connection pair)

  Both conform to:
     <MADDataTableWriting>   removeAllObjects / addColumn: /
                             begin|endBulkInsert /
                             addRowWithDataForFieldKeys:
     <MADDataTableReading>   objectAtRow: / objectAtRow:column: /
                             count / numberOfRows
     <MADDataTableCursoring> enumeratorForKeyObjectsSorted /
                             enumeratorForAllObjectsSorted /
                             enumeratorForAllObjectsSortedRowIdOnly
```

`MADDatabaseSqlite3.m:474-540` y `MADDatabaseSQLServer.m:500-1472` deberían tomar
`id <MADDataTableWriting>` en lugar de `MADDataTable *`. Eso solo elimina el peligro de "la clase base
devuelve YES de una escritura que descarté" de cada controlador.

### 4.2 Plan secuenciado

**Fase 0 — hacer ruidosos los modos de fallo (sin cambio de comportamiento).**
1. **Hecho**, con un alcance más estrecho que el propuesto inicialmente. Las nueve operaciones que una subclase de almacenamiento
   debe sobrescribir ahora aseveran (`MADDataTable.m:365-403`); las respuestas honestas de tabla vacía
   y los ganchos masivos opcionales se dejaron como valores predeterminados, porque para ellos el valor
   silencioso es el *correcto*. Véase §3.2 para la división y el razonamiento, y
   `MADDataTableRegressionTests.m` `testBaseTableAbstractOperationsAssert` para el contrato.
2. **No necesario — véase §3.5.** El texto original aquí decía implementar
   `MADDataTableFast -dataForRow:error:` porque "actualmente asevera". No lo hace; el
   método está implementado en `:941-1015`, y la lectura anterior confundió una firma de dos líneas
   con una sobrecarga `column:`. La subclase que realmente le faltaba el selector es
   `MADDataTableVirtual`, y ahora lo implementa delegando en `-objectAtRow:`.
3. **Hecho.** `-allObjects` (§3.3) era un método `nonnull` que devolvía `nil` en
   `MADDataTableFast`; ahora devuelve las filas. En la misma pasada
   `MADDataTableFast -dataForRow:error:` ganó el `else` faltante en su comprobación de preparación, y
   ya no descarta el error de `-getSql:` ni pasa SQL a `sqlite3_mprintf` como cadena de formato.
4. Re-verificar contra la suite de regresión existente (`MADDataTableRegressionTests.m`) — ya
   fija la instanciación, la enumeración y la concurrencia, así que detectará un error aquí.
   (También fijaba el contrato de `MADDataTableLocation` hasta que la Revisión 5 eliminó la clase.)

**Fase 1 — declarar los protocolos.**

5. **Hecho — el bloque stub se mantuvo deliberadamente.** Los tres protocolos están declarados en
   `MADFoundation/Source/MADDataTable.h` sobre el `@interface`, que ahora dice
   `MADDataTable : NSObject <NSCoding, NSFastEnumeration, MADDataTableWriting,
   MADDataTableReading, MADDataTableCursoring>`, y las treinta declaraciones planas de método que
   solían estar en el cuerpo del `@interface` se han ido de él. La división es por eje: **Writing**
   es la superficie mutable (`removeAllObjects`, `addColumn:`, `addRow:error:`,
   `addRowWithDataForFieldKeys:`, `sortUsingDescriptors:`, más `beginBulkInsert`/`endBulkInsert`
   `@optional`); **Reading** es acceso aleatorio y los recuentos;
   **Cursoring** es enumeración, con los tres enumeradores ordenados y
   `objectsForGroupKeys:` `@optional` porque `MADDataTableVirtual` genuinamente no puede servirlos.

   El "eliminar el bloque stub ahora redundante" del plan **no** se llevó a cabo, porque ambos
   bloques stub son contratos fijados, no redundancia:
   `testBaseTableAbstractOperationsAssert` requiere que los nueve stubs que aseveran de la clase base
   existan y lancen, y `testVirtualTableDoesNotImplementSortedEnumerators` afirma que
   `-respondsToSelector:` es **YES** para los cuatro selectores solo de sqlite en
   `MADDataTableVirtual`. Eliminar cualquiera de los dos habría convertido un defecto detectado en un
   fallo de selector no reconocido y roto una prueba que existe específicamente para evitarlo.
   `MADDataTable` satisface los miembros `@required` de los protocolos aseverando, que es lo que
   la Fase 0 puso allí.

6. **Hecho (Revisión 4) — los tres controladores y el protocolo.** El bloque de abajo es el relato de la Revisión 3
   de por qué esto estaba bloqueado; se conserva para el registro. El desbloqueo que identificó se
   tomó: los metadatos de columna que `MADMySQLFetch+DataTable.m` necesita (`columns`, `columnKeys`) ahora están
   declarados por `<MADDataTableWriting>` mismo, así que el puerto de escritura es suficiente también para MySQL.
   Los dos métodos `fetchWithCommand:dataTable:...` de `MADMySQLFetch` y su
   `-fetchResultsFromConnection:intoDataTable:...` privado toman `id <MADDataTableWriting>` por valor y
   devuelven la misma tabla (`(MADDataTable *)dataTable`); los 11 sitios de llamada en
   `MADDatabaseMySQL.m` y los 7 en `MADMySQLLiveTests.m` eliminaron su `&`. Los metadatos se
   pusieron en el protocolo de escritura en lugar de un cuarto porque MySQL los lee *mientras escribe* —
   corrige el tipo de una columna en la primera fila — y porque cada conformador los obtiene gratis de
   la clase base. El `// FIXME: This is a hack.` de §2.5 no se toca.

   *Texto de la Revisión 3, para el registro:* **hecho en parte — dos controladores de tres, y la declaración
   del protocolo deliberadamente no estrechada.** `MADDatabaseSqlite3`
   (`executeSQL:...intoResultTable:`,
   `executeQuery:withDataTable:andError:`, `executeQuery:withError:`) y
   `MADDatabaseSQLServer` (los mismos dos, más el privado `-runQuery:onProcess:withDataTable:`
   y `-runSQL:onDataTable:fieldKeys:process:`) ahora toman `id <MADDataTableWriting>`. Ambos son
   genuinamente de solo escritura: `grep` por lo que envían a la tabla devuelve exactamente el puerto de cinco llamadas
   y nada más.

   **`MADDatabaseMySQL` no puede estrecharse todavía**, y tampoco
   `MADAPI/Source/MADDatabaseProtocol.h:28-31`. El obstáculo no está en el controlador — está en
   `MADMySQLFetch+DataTable.m`, que lee `(*dataTable).columns` y `.columnKeys` *mientras*
   llena la tabla, para corregir el tipo de una columna una vez que ve la primera fila
   (`:301` y `:321`, bajo el `// FIXME: This is a hack.` existente en `:297`). Un puerto de escritura que
   no expone los metadatos de columna por lo tanto no es suficiente para esa ruta. Dado que
   `MADDatabaseMySQL` cumple `MADDatabaseDataSource` y debe seguir haciéndolo, estrechar
   el protocolo le habría hecho prometer algo que su propia implementación no puede cumplir —
   un fallo remoto para el siguiente llamador, no un error de compilación. Ambas declaraciones llevan un comentario
   que apunta aquí.

   **El desbloqueo concreto, encontrado al comprobar esto:** `MADMySQLFetch+DataTable.m` nunca
   asigna a través de sus parámetros de salida `MADDataTable * __autoreleasing *` —
   `grep -n '\*dataTable *=' MADMySQL/Source/MADMySQLFetch+DataTable.m` no devuelve nada. El
   puntero es un parámetro de entrada que los llamadores nunca supieron. Hacerlo por valor
   (`dataTable:(id <MADDataTableWriting>)dataTable`) elimina el problema del tipo de puntero
   de raíz y deja que los 11 sitios de llamada en `MADDatabaseMySQL.m` eliminen su `&`. Eso, más
   añadir los accesores de metadatos de columna a `<MADDataTableWriting>` o a un cuarto protocolo,
   es todo lo que queda para MySQL. Se difiere en lugar de agruparse porque §4.3 ya clasifica a MySQL como el consumidor
   de mayor riesgo, y el cambio es lo bastante mecánico como para revisarse por separado.

7. **Ahora posible para sqlite, no probado para MySQL.** El bucle de filas de `MADDatabaseSqlite3` puede
   ser impulsado por cualquier objeto que cumpla `<MADDataTableWriting>` sin archivo `.maddb` y sin
   delegado de aplicación, ya que el parámetro ya no implica la clase `MADDataTable` — y,
   a través de ella, la dependencia de `-urlFastCache` en `[MADApplication AppDelegate]` descrita en
   §2.3. Aún no se ha escrito tal prueba mock; es el siguiente paso natural y lo primero
   que el directorio de caché inyectado de la fase 2 hace más barato.
   **Revisión 4:** la mitad sin host está probada — `testFastTableInitWithCacheDirectoryNeedsNoDelegate`
   construye una tabla física funcional con un directorio y sin delegado.
   **Revisión 5: hecho, ambas mitades.** `testDriverFillsAWritePortWithNoDataTableBehindIt`
   (`MADSqlite3Tests/MADDatabaseSqlite3DatabaseTests.m`) entrega al bucle de filas un
   `MADWritePortRecorder` — un `NSObject` que cumple `<MADDataTableWriting>` y nada más,
   así que sin `MADDataTable`, sin `MADDataTableFast`, sin delegado de caché, sin `.maddb` — y afirma que
   las cinco llamadas llegan en el orden prometido con ambas filas intactas, fallando si aparece cualquier archivo `.maddb`.
   El mock solo es expresable porque el parámetro es el protocolo.

**Fase 2 — eliminar la ambigüedad de ubicación del almacenamiento. HECHO (Revisión 4).**
8. ✅ Hacer `urlFastCache` almacenada, no calculada (§2.3). Resuelta una vez en `_urlFastCache`; un
   cambio de delegado la descarta en `-setCacheDelegate:` antes de reabrir, así que la resolución siempre es
   contra el delegado actual.
9. ✅ Inyectar el directorio de caché en lugar de buscar `[MADApplication AppDelegate]` dentro
   de la propiedad. `-initWithId:cacheDirectory:` y
   `+newDataTableOfType:withObjectID:cacheDirectory:` lo llevan; `nil` mantiene la cadena antigua.
   `testFastTableInitWithCacheDirectoryNeedsNoDelegate` construye, llena y lee una tabla física
   sin ningún delegado.

**Fase 3 — hacer que `rowCounter` se derive.**
10. ✅ Añadir un `-recountRows` privado respaldado por `SELECT COUNT(*)`, y hacer que `-numberOfRows`/`-count`
    lo usen (o invaliden contra él) en `MADDataTableFast`. Mantener la propiedad `rowCounter` por
    compatibilidad de archivo, pero dejar de tratarla como la fuente de verdad (§2.5).
    **Revisión 4:** `-recountRows` existe y se ejecuta al final de `-loadWithPlist:`, así que una tabla recargada
    ya no puede llevar un contador que no coincida con su archivo.
    **Revisión 5:** la mitad en memoria está cerrada — las cuatro mutaciones que nunca tocaban el
    contador ahora lo dejan describiendo el archivo (§2.5). `-numberOfRows`/`-count` siguen devolviendo el
    ivar por diseño; ese es ahora el único lector, y `-recountRows` protege la recarga.
    Cuatro pruebas cubren los cuatro métodos.
11. ✅ Auditar `MTTableController.m` (antes `:375/395/440/445`) — la paginación no debe leer un contador que
    pueda divergir del archivo. **Hecho (Revisión 5)**, y no puede, una vez que el contador es honesto:
    cada obtención comienza en `-removeAllObjects`, que vacía la tabla y pone el contador a cero, así que
    el recuento al completarse mide la página recién escrita y nada más. Dos defectos en esas
    líneas exactas se encontraron y arreglaron de todos modos. `offset + count - 1` se envolvía a `NSUIntegerMax` en una
    página vacía en `:380`/`:402`; y la ruta de fallo en `:449` leía el recuento de una tabla que el
    controlador *no* había vaciado (solo vacía al tener éxito), así que medía la página anterior, y una
    obtención fallida informaba `hasMore = YES` y se reemitía. Una página fallida ahora informa que no hay más.

**Fase 4 — corregir la concurrencia.**
12. ✅ Serializar `-addRow:error:` en `queueBulkAdd` (§2.4). La cola ya existe y ya se
    usa para `-endBulkInsert`; extenderla a la ruta de mutación es un cambio pequeño y contenido.
    Mover el `sqlite3_finalize(_statementInsert)` de `-endBulkInsert` *dentro* de la
    barrera para que la sentencia cacheada solo se desmonte cuando no hay un `-addRow:` en vuelo.
    **Hecho (Revisión 4)** — el desmontaje es ahora lo primero dentro del
    `dispatch_barrier_sync` en `:1334`.
13. **Evaluado y rechazado (Revisión 5)** — un par de conexiones compartido por archivo en lugar de por
    instancia de tabla, ya que `-objectEnumerator` actualmente abre una conexión nueva en cada llamada
    (§2.7). Compartir no está disponible para la mitad de escritura (`-endBulkInsert` cierra ese handle) y
    apenas compra nada para la mitad de lectura (`SQLITE_OPEN_SHAREDCACHE` ya comparte la caché),
    mientras empeora el caso de enumerador vivo a través de una reconstrucción en lugar de mejorarlo. §2.7 tiene el
    argumento completo.

**Fase 5 — retirar la superficie muerta.**
14. ✅ Eliminar `MADDataTableLocation` (§3.7) y sus tres pruebas, o conectarlo a una función real.
    Actualmente es API pública sin llamador de producción. **Eliminada en la Revisión 5** — eliminada
    en lugar de conectada, porque tiene un commit en su historia y nada más que sus propias pruebas
    describiéndola. Las fases Headers y Sources del objetivo MAD eliminan los dos archivos con ella.
15. **Evaluado (Revisión 5)** — reconciliar los dos mecanismos de persistencia (§2.6). La premisa
    no se sostiene para la familia: las filas *sí* hacen ida y vuelta a través del plist donde el plist es
    el almacenamiento (`keySortIndex` de `MADDataTableVirtual`), y no pueden donde es un archivo sqlite
    (`keyUrlFastCache` de `MADDataTableFast`), así que ni el renombrado ni la alternativa son correctos.
    §2.6 registra la tabla por subclase y el cambio de documentación que queda por hacer.

### 4.3 Clasificación de roturas para los consumidores actuales

| Consumidor | Sitio | Riesgo bajo refactor |
|---|---|---|
| `MTTableController` | `:249, :281, :284, :377, :393, :399, :449, :455` | **Alto** — trata `count` como cursor de página; cualquier cambio en la semántica de `rowCounter` rompe la paginación. La Revisión 5 hizo total la derivación — una página vacía ya no subdesborda y una obtención fallida ya no lee el recuento de la página anterior (§2.5) — pero el acoplamiento no cambia |
| `MADDatabaseMySQL` | `:88-92, :118-122, :150-154, :187-189` | **Alto** — `objectAtRow:i column:0` en O(n); la semántica de `row` por subclase debe unificarse primero |
| `MADocument` | `:197` (`rowCounter`), `:865-867` (enumerador), `:874-919` (`dataForRow:error:`), `:1053-1072` | **Alto** — pero solo para el enumerador y `rowCounter`. Sus envíos de `-dataForRow:error:` se resuelven en `MADDataTableFast`, que implementa el selector, así que la ruta de impresión/código de barras es sólida (véase §3.5) |
| `MADMySQLFetch+DataTable` | `:301, :321` | **Medio** — muta `column.type` a mitad de la obtención detrás de `// FIXME: This is a hack.` (`:297`); el diccionario de columna debe seguir siendo públicamente mutable |
| `MADQuerySampleDataTable(Range)` | `:118, :126` / `:123, :131` | **Bajo** — sonda de ancho de un único `objectAtRow:0` |
| `MADReportFormatter` | `:449-502` | **Bajo** — tolerante tanto con la enumeración de id de fila como de diccionario |
| `MADDatabaseSQLServer` | `:500, :1367, :1472` | **Bajo** — de solo escritura a través del puerto de cinco métodos |

### 4.4 Restricciones a respetar

* **No cambies los valores crudos de `MADDataTableType`.** `MADDataTableParametersType` se codifica
  en diccionarios de definición (`MTTableController.m:91`, `MTTableViewControllerBarcodeExtraMaxicode.m:104`)
  y el enum se serializa mediante `initWithShort:`.
* **No renombres las clases.** Los archivos de `MADDataTableFast` llevan
  claves estilo `[MADDataTableFast keyTag]` (`:114-119`) y `MADDataTableVirtual` lleva
  `keySortIndex` (`:202`) en archivos `.mdcache`/`.maddb` existentes.
* **Mantén el puerto de escritura de cinco métodos.** Los tres controladores dependen de la secuencia exacta
  `removeAllObjects → addColumn: → beginBulkInsert → addRowWithDataForFieldKeys: → endBulkInsert`.
* **No se introdujo ningún sondeo de nombre de clase.** Presérvalo: cualquier rama nueva debe ser sobre
  un protocolo o un enum, nunca sobre una clase.

### 4.5 SQL pasado a `sqlite3_mprintf` como cadena de formato

Encontrado al arreglar §3.5. Otros ocho sitios de llamada entregaban una variable a `sqlite3_mprintf` como la
cadena de *formato* en lugar de como argumento. Cualquier `%` en el SQL se leería entonces como una
conversión, así que una consulta que contenga uno se destroza — o lee más allá de la lista de argumentos y falla.

**Arreglado.** Los ocho ahora pasan un `"%s"` literal y el SQL como argumento, coincidiendo con los sitios
que ya eran correctos:

| Archivo | Sitios |
|---|---|
| `MADSqlite3/Source/MADDataTableFast.m` | `:1062`, `:1102`, `:1245` |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | `:301`, `:397`, `:875` |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | `:69` |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | `:64` |

Los sitios de referencia ya correctos eran `MADDataTableFast.m:548`, `:901` y `:973`, y
`MADDatabaseSqlite3.m:459`. Cada llamada `sqlite3_mprintf` en `MADSqlite3` ahora usa
un `"%s"` literal o una cadena de formato literal que no contiene conversiones — `grep -n
sqlite3_mprintf MADSqlite3/Source/*.m` devuelve catorce llamadas y ninguna cadena de formato variable.

La alcanzabilidad era baja: el SQL viene de los constructores de consulta generados, y una búsqueda en todo el repositorio
no encontró ningún patrón `LIKE` que introdujera un `%`. Los identificadores, sin embargo, vienen del
esquema de la base de datos conectada, así que un `%` en un nombre de columna o tabla habría alcanzado esto. Era un
error de corrección latente en lugar de activo — arreglado porque el cambio es mecánico y la
consecuencia de estar equivocado es corrupción silenciosa.

---

## Apéndice — Archivos examinados

| Archivo | Líneas |
|---|---|
| `MADFoundation/Source/MADDataTable.h` / `.m` | 123 / 435 |
| `MADFoundation/Source/MADDataTableVirtual.h` / `.m` | 21 / 240 |
| `MADFoundation/Source/MADDataTableType.h` | 17 |
| `MADFoundation/Source/MADDataColumn.h`, `MADDataProtocol.h`, `MADCacheProtocol.h` | — |
| `MADSqlite3/Source/MADDataTableFast.h` / `.m` | 47 / 1355 |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | 173 |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | 149 |
| `MADSqlite3/Source/MADQueryCacheAddRow.m` | 152 |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | 1346 |
| `MAD/Source/MADDataTable+Constructor.h` / `.m` | 30 / 94 |
| `MAD/Source/MADocument.m`, `MADReportFormatter.m` | — |
| `MADMySQL/Source/MADDatabaseMySQL.m`, `MADMySQLFetch+DataTable.{h,m}` | — |
| `MADTdsClient/Source/MADDatabaseSQLServer.m` | — |
| `MADAPI/Source/MADDatabaseProtocol.h`, `MADQuery.h`, `MADDatabaseResultsProtocol.h` | — |
| `MADDesigner/Source/MTTableController.m` | — |
| `MAD/MADTests/MADDataTableRegressionTests.m` | 69 pruebas |
