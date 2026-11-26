---
layout: default
title: "El objeto de datos"
description: "La definición, el esquema y el conjunto de resultados de un informe como un solo contrato."
lang: es-419
---

# El objeto de datos — la definición de un informe, su esquema y su conjunto de resultados

Esta página define el objeto de datos: la definición de un informe, su esquema y su conjunto de resultados como un solo contrato. Es el diseño sobre el que se construye el trabajo multi-origen; la especificación del formato describe el documento tal como se envía hoy.

**Alcance:** el concepto planteado el 2026-10-16 — qué es un objeto de datos, cómo se representa en
este código base, y qué se necesita para formalizarlo. El montaje multi-origen / subinforme descrito
en la misma conversación se escribe aquí como consecuencia del contrato, deliberadamente
no construido.
**Fecha:** 2026-10-16, leído en `445794e11`.
**Estado:** documento de diseño. Propone; no implementa nada, y nada aquí está
programado. [la visión del proyecto](../vision.html) §1 — "un informe es una función de orígenes de datos a una tabla" — es
la visión que este archivo hace concreta y para la que nombra el código.

---

> **Decisión final sobre la composición (2026-11-26):** el esbozo de composición de §5
> (incluida su recomendación de Diseño B, §5.1/§9.2) queda sustituido por el documento
> normativo [`MAD_COMPOSITION_SPEC.md`](../../project/design/MAD_COMPOSITION_SPEC.html), que
> adopta el Diseño A (`ATTACH`, un `.maddb` por nodo). La §0 de la especificación es
> **definitiva**: cada nodo de una composición es un informe completo con su propio diseño y
> datos; la raíz es el informe predeterminado del documento, no el único. Combinar informes
> conserva el diseño y el resultado de cada hijo.

## 1. La idea, y lo que no es

Hoy el usuario diseña una consulta ad hoc contra una base de datos (MySQL, SQL Server o Sqlite3),
esta devuelve una tabla de datos, y el informe se construye sobre esos datos con las herramientas de diseño. El
informe es consulta más diseño. La generalización consiste en tomar la mitad de consulta y convertirla en el
objeto:

> Un objeto de datos es una definición con nombre que produce un **esquema** y un **conjunto de resultados** — la
> consulta de un informe, separada de su diseño y dotada de una identidad, para que su salida pueda
> actualizarse, direccionarse y usarse como origen por otro objeto de datos. Un informe es un objeto de datos
> más una presentación enlazada a las columnas del objeto.

Palabras del propio usuario (2026-10-16): *"something that returns a schema of sorts and a result
set, whereas the report is ad hoc query, reporting, and design."*

Tres consecuencias, cada una desarrollada abajo:

1. **La consulta se convierte en la frontera del producto.** El mismo objeto sirve al diseñador (lo que edita la
   pestaña MAD Query), al visor (lo que ejecuta la actualización), a la CLI (lo que ejecuta `mad refresh`),
   a un futuro servidor web (lo que ejecuta un endpoint), y a una IA (lo que redacta y el
   motor valida). Una definición, muchos consumidores — lo cual solo es cierto una vez que el objeto tiene
   un nombre y un esquema propios.
2. **Los objetos se componen.** *"The idea would be to link multiple ones together. In the reporting
   world, this would be subreports"* (usuario). En términos de datos es un DAG de tablas derivadas:
   la salida de un objeto es una tabla para otro, exactamente como hoy lo es una tabla de esquema.
3. **Los orígenes se multiplican como consecuencia, no como función.** Un objeto por base de datos de origen —
   cada uno ya lleva su propio controlador y conexión — materializado, y luego unido por sus
   salidas. El esbozo del usuario: *"you would query MySQL in a subreport, and you would query
   SQL Server in a subreport… and then you could link those reports together as tables in the
   query designer by their output."* [la visión del proyecto](../vision.html) §1 dice lo mismo: no se necesita un motor
   de federación; las instantáneas *son* la federación.

Lo que explícitamente **no** es:

- No es un motor de federación. Nada nuevo habla con MySQL y SQL Server en una sola sentencia; cada
  objeto se ejecuta contra su propio origen, y la unión ocurre sobre los resultados ya locales.
- No es una segunda implementación de consultas. El generador de SQL, los controladores, la tabla de resultados y
  el motor de unión de SQLite ya existen; §5 es un montaje sobre ellos.
- No es un cambio al paradigma de caché de dos pasadas que lo extrae todo. La caché es fundamental y
  deliberadamente grande (`MAD_FORMAT.md` §5.1); un objeto de datos produce exactamente lo que la caché
  ya contiene hoy.

## 2. Vocabulario, porque "esquema" son cuatro cosas distintas en este código base

| Término | Qué es | Clases actuales |
|---|---|---|
| **Esquema de origen** | Las tablas y campos de una base de datos que el usuario puede consultar | Navegación en vivo: `MADDatabaseTable` / `MADDatabaseField` (`MADAPI`). Instantánea: `RptqDatabaseSchemaTable` / `RptqDatabaseSchemaField`, importada una vez al crear el documento |
| **Definición** | El grafo de consulta: qué tablas, qué campos, las uniones, filtros, agrupaciones, orden | `RptqQuery` + `RptqQueryTable` / `RptqQueryField` / `RptqQueryLinks` / `RptqQueryPredicate` / `RptqQueryGroup` |
| **Esquema de resultado** | Las columnas de la salida: nombre, tipo, tipo nativo, longitud/precisión, clave primaria, no nulo | `MADDataColumn` (una por columna), transportada en la tabla |
| **Conjunto de resultados** | Las filas | Clúster de clases `MADDataTable`; materializado como `MADDataTableFast` |
| **Materialización** | El conjunto de resultados en disco: la tabla SQLite y su esquema serializado | `<tag>.maddb` (SQLite) + `<tag>.mdcache` (plist, `MADDataTable -copyPlist`) en el directorio de caché del documento |
| **Instantánea** | La palabra de `MAD_FUTURE.md`: una materialización hecha con nombre, versionada y direccionable | No existe; §4.3 es cómo empieza |
| **Esquema de almacén** | Sin relación con todo lo anterior: el propio formato de almacenamiento del documento | `MADStoreSchema` (`MAD/Source/rptq/store/`) |

El documento hoy contiene definiciones y diseños; las materializaciones viven junto a él, con clave por
el documento (no por la definición). Esa separación es la correcta — `MAD_FORMAT.md` §5 — y
este diseño la mantiene.

## 3. Cómo se representa la idea hoy

Cada pieza de un objeto de datos ya existe, en una capa diferente, construida para un propósito
diferente. Lo que sigue es el estado exacto de cada una, con la costura que la formalización
apretaría.

### 3.1 La definición existe — `RptqQuery` y su grafo

El grafo de consulta está lo bastante completo para compilar: tablas (`RptqQueryTable`, con `alias` y un
`dropIndex` para que una tabla de esquema pueda incluirse varias veces), proyecciones
(`RptqQueryField` — ids de tabla de esquema + campo de esquema), uniones (`RptqQueryLinks`, con un tipo de
unión), filtros (`RptqQueryPredicate`), agrupaciones (`RptqQueryGroup`, que impulsa descriptores de orden
mediante `RptqQuery -sortDescriptorsForDatabase:`), y una fila de orden vestigial (`RptqQuerySort`,
leída solo por descripciones de depuración). El diseñador la edita a través del modelo de lectura `MADModel*`
("escribe a través de `Rptq`; lee y observa a través de `MADModel`" — `MADModel_Layer.md`).

Una agrupación es una definición a nivel de consulta, no una sección del informe. `RptqQueryGroup.hasField`
nombra el campo por el que agrupa la consulta y `sort` su dirección. Para que la consulta se ejecute, cada
campo de grupo debe pertenecer a una tabla de consulta que el documento selecciona
(`hasField.inQueryTable`): la agrupación se materializa como una clave ordenada sobre las filas
de resultado (`-sortDescriptorsForDatabase:`), y el formateador compara esa clave para encontrar los límites
de grupo. Una sección de encabezado/pie de grupo del informe es solo la presentación de ese grupo —
puede no contener ningún elemento que muestre el campo de agrupación, y la agrupación sigue ocurriendo.
Ningún diseño puede suplir un campo de agrupación faltante, así que un grupo con un campo nil, o un campo no
respaldado por una tabla de consulta seleccionada, es un documento inválido. El diseñador aún construye y
etiqueta tal sección para que el grupo roto pueda verse; la ejecución de la consulta y el renderizado lo rechazan
con `NSInvalidArgumentException` y registran el grupo.

Dos hechos sobre su identidad:

- Un `RptqQuery` cuelga de una fila `RptqDatabase`, y llega al documento a través de
  "el primero de cada uno": `RptqDatabase -defaultQuery` es `hasQueries.anyObject`
  (`RptqDatabase+Extras.m:88`), `RptqDocument -mainQuery` igualmente (`RptqDocument+Extras.m:184`).
- El almacén ya permite muchos: `MADModelDocument` construye **un `MADModelDatabase` por
  fila `RptqQuery`** (`MADModelDocument.m:210-240`), con el propio comentario del código de que "current
  versions of the software only use one database and query." La cardinalidad es una convención
  de los flujos de la aplicación, no del almacén.

### 3.2 El compilador existe — `MADQueryFull`

`MADQueryFull -copySQLWithManagedObjectContext:error:` (`MADQueryFull.m:133`) construye el SQL:
las columnas proyectadas vienen de `MADQuerySelectExpressionActiveFields`, que pide
`MADQueryActiveQueryFields` por cada campo que referencian los *elementos*, uniones y grupos
del informe; FROM/JOIN se compila a partir de un `MTGraph` de tablas y uniones, ordenado topológicamente
(`:170-204`); los predicados y el entrecomillado de literales pasan por `MADDatabase`
(`newSafeIdentifier:`, `newSafeLiteral:`); `LIMIT` mediante `sqlLimitClause:`.

Esta es la generación de SQL determinista y propia que `MAD_FUTURE.md` §3 cuenta como diferenciador
— existe, y es headless (en la compilación de Linux, `MADSources.cmake:93`).

**Pero está soldada al documento.** `MADQueryFull` guarda la consulta con la que se inicializó
en `queryObject` (`:79`) y **nunca la usa**: la ruta de SQL vuelve a leer la primera base de datos
y la primera consulta del documento (`:147-149`). Y no implementa `-getSql:error:` (la base
devuelve `@""`, `MADQuery.m:48`), así que la ruta genérica `MADDatabase -executeQuery:withError:`
no puede ejecutar la consulta principal del documento en absoluto. El objeto de consulta que le entregas no determina
lo que se ejecuta.

### 3.3 La costura de ejecución existe — `MADDatabase`

El punto abstracto es
`-[MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`
(`MADAPI/Source/MADDatabase.m:147`, sobrescrito por los tres controladores). Su destino está
tipado como `id <MADDataTableWriting>` — *cualquier* tabla escribible, no una clase de tabla. El contrato de llenado
es uniforme entre los controladores: `removeAllObjects` → `addColumn:` → `beginBulkInsert` →
`addRowWithDataForFieldKeys:` → `endBulkInsert` (controladores de `MAD_DATA_OBJECT`: MySQL
`MADMySQLFetch+DataTable.m:148-235`, SQL Server `MADDatabaseSQLServer.m:485-571`, Sqlite3
`MADDatabaseSqlite3.m:474-540`).

Los controladores además ya prefieren la tabla de destino propia de una consulta sobre la del documento, cuando la
consulta cumple `MADQueryDataTableProtocol` (`MADQuery.h:28-50`; el `-executeQuery:`
de cada controlador lo comprueba — p. ej., `MADDatabaseMySQL.m:331-339`). Múltiples tablas de resultados por
proceso son un punto de extensión previsto, ejercitado solo por la familia de consultas de datos de ejemplo.

El cosido a nivel de documento es `MADOperationRefresh` (`MADDesigner/Source/MADOperationRefresh.m`,
131 líneas, cero UIKit): entran credenciales, `document.mainQuery` → SQL, `document.database`
se conecta, ejecuta hacia `document.dataTable`, `dataTableMakeCache` escribe el `.mdcache`,
`document.refreshed = YES`. También es el verbo de actualización de la CLI, compilado a través de la frontera de objetivos
por `REFRESH_SOURCES` de `CLI/build.sh` (`ROADMAP.md` §3.4). Es *actualizar +
persistir + publicar*, no *ejecutar*: está cableado al estado compartido del documento, descubre
credenciales inspeccionando `self.dependencies`, y muta el documento.

### 3.4 El valor de retorno existe — `MADDataTable` y `MADDataColumn`

`MADDataTable` (`MADFoundation/Source/MADDataTable.h`) es el clúster de clases cuyo trabajo entero
es "esquema más filas": metadatos más persistencia en la base, almacenamiento por subclase
(`MADDataTableVirtual` en memoria, `MADDataTableFast` sobre SQLite). El objeto de esquema es
`MADDataColumn` — `identifier`, `fieldName`, `caption`, `type` (`MADDataType`), `nativeType`,
`dataLength`, `dataPercision`, `isPrimaryKey`, `isNotNull`, `isAutoIncrement`, `defaultValue`
— una descripción de columna de primera clase y serializable.

Y el esquema ya es separable de las filas en disco: `-copyPlist`
(`MADDataTable.m:238-253`) serializa nombre + claves de columna + plists de columna + contador de filas y
**explícitamente ninguna fila** — eso es exactamente lo que es el archivo `.mdcache`, escrito y leído por
`MADDataTableFast` (`-copyPlist` / `-loadWithPlist:`; `MAD_FORMAT.md` §5.3).

Lo que falta en esta capa:

- **Ninguna API de solo esquema.** Nada devuelve el esquema de resultado de una consulta sin ejecutarla.
  Esquema y datos son un solo objeto, nunca dos — el esquema se descubre *a partir de* las filas.
- **Los resultados Sqlite3 de cero filas pierden su esquema por completo.** El controlador Sqlite3 descubre
  las columnas solo dentro de la primera iteración de `SQLITE_ROW` (`MADDatabaseSqlite3.m:496-535`), así que un
  resultado vacío produce una tabla sin columnas y sin DDL. MySQL y SQL Server añaden columnas
  desde los metadatos del resultado antes de que llegue cualquier fila, así que la brecha es específica de Sqlite3.
- Las `columnKeys` de `MADDataTableFast` son nombres generados `c<hash>`, no nombres de campo; la superficie
  de esquema utilizable es el diccionario `columns` de `MADDataColumn`. Y `for (x in fastTable)`
  produce silenciosamente nada — la base devuelve 0 elementos y Fast no sobrescribe
  `countByEnumeratingWithState:`; los llamadores deben usar `objectEnumerator`.

### 3.5 La materialización es una tabla SQLite hoy

`MADDataTableFast` no es una abstracción sobre una tabla; *es* la tabla. Cada instancia posee
una tabla SQLite física `t<tag>` en `<tag>.maddb` (`-tableName` `MADDataTableFast.m:498`,
`-filenameCacheMadDB` `:399`), con columnas `c<hash-of-fieldName>`. Una segunda conexión
(`databaseForSelects`) ejecuta el lado de selección. La agrupación son índices sobre esa única tabla
(`-sortUsingDescriptors:` `:737`, `-setupGroupKeyIndexes` `:545`, un índice por nivel de prefijo de grupo),
y los agregados son SQL sobre la caché (`MADQueryCacheAggregateFunction`, impulsado por
`MADocument -dataForRows:column:groups:function:groupBy:`). **Nunca se genera un `GROUP BY`
para la base de datos de origen** — verificado: la cadena no aparece en ningún archivo fuente. El
origen se consulta plano; todo lo agrupado o agregado se calcula localmente, sobre la
materialización, por Sqlite3.

Dos stubs reveladores muestran que la arquitectura tiene razones para querer *muchas* tablas: la fábrica de clases
`MADDataTable+Constructor` (`newDataTableOfType:withObjectID:cacheDirectory:` — lo físico se asigna
a `MADDataTableFast` con el id como etiqueta, `:56-78`) hace la segunda y tercera tablas baratas por
construcción; y `-cacheTableNameForGroupLevel:` (`MADDataTableFast.m:813`) nombraría una
tabla `s<level>` por nivel de grupo — **no tiene llamadores**; las tablas por agrupación que implica
nunca se materializan.

**La dirección es el nombre de archivo.** La tabla del documento se crea con
`initWithId: fileURL.lastPathComponent.hash` (`MADocument.m:269-283`); el directorio de caché se
nombra `dataTableIdHash` (`MADURLFactory newURLCacheFilesDirectoryForFilename:`). Una tabla de resultados
por documento; su nombre cambia cuando se renombra el documento; nada puede apuntar a ella.

### 3.6 Qué falta, en una tabla

| Capa | Existe | Falta para un objeto de datos |
|---|---|---|
| Definición | Grafo de consulta completo; modelo de lectura; el almacén permite muchas consultas | Un nombre y una identidad propios; una referencia de origen que pueda ser otro objeto de datos |
| Compilador | SQL determinista a partir del grafo | Libertad de "la primera consulta del documento"; una ruta de solo esquema |
| Ejecución | Cualquier destino `MADDataTableWriting`; tres controladores; tablas de destino por consulta | Una ejecución que no sea actualización — sin mutación del documento, credenciales pasadas y no descubiertas |
| Valor de resultado | `MADDataTable` + `MADDataColumn`; persistencia de solo esquema (`-copyPlist`) | Una API de esquema sin ejecución; la pérdida de esquema con cero filas |
| Materialización | Tablas SQLite reales `t<tag>`; agrupación y agregados locales | Etiqueta = hash del nombre de archivo; una tabla por documento por convención |
| Enlace | Diseño → `referencesQueryField` → resuelto al renderizar por `MADDocumentObjectDataReference*` | Enlace a *un* objeto de datos en lugar de a la única consulta *del* documento |
| Dirección | — | Todo |

Tres puntos de cableado fijo son los bloqueadores concretos, y los tres son visibles en el código:

1. `MADQueryFull` ignora su propio objeto de consulta (`MADQueryFull.m:147-149`).
2. `MADDocument -dataTableForQuery:` devuelve `self.dataTable` para `MADQueryFull` y nil para
   todo lo demás (`MADocument.m:908`) — un switch de una sola ranura.
3. `MADQueryActiveQueryFields` escanea **todos** los elementos, uniones y grupos del almacén sin
   alcance de consulta (`MADQueryActiveQueryFields.m:27-99`), bajo su propio FIXME de encabezado: *"Right
   now the software only handles one query object."* Los campos de una segunda consulta se filtrarían
   en la lista SELECT de la primera consulta.

## 4. El contrato

### 4.1 Forma en código (propuesta, ilustrativa)

Dos mitades, deliberadamente separadas:

```objc
@protocol MADDataObjectSchema <NSObject>            // describe: no database needed
- (NSArray<MADDataColumn *> *)resultSchema;          // columns, types, from graph + snapshot
@end

@protocol MADDataObjectExecuting <NSObject>          // execute: yields the materialization
- (nullable MADDataTable *)executeIntoDataTable:(nullable MADDataTable *)target
                                      credentials:(MADCredentials *)credentials
                                            error:(NSError **)error;
@end
```

Los nombres son ilustrativos; la división es el punto. **Describe** debe funcionar sin
conexión, sin credenciales y sin filas — a partir del grafo más la instantánea del esquema almacenada —
porque eso es lo que dibuja el diseñador, contra lo que valida la IA, lo que lista un servidor web,
y lo que un documento renombrado no puede corromper. **Execute** debe tomar una tabla de destino y
credenciales como argumentos y devolver la tabla — sin mutación del documento, así que `MADOperationRefresh`
se reduce a "llama a execute, luego persiste, luego publica", y la CLI, un servidor y una prueba
llaman lo mismo.

### 4.2 Esquema sin ejecutar

Esta es la primera prueba honesta de que el contrato es real, porque es *derivable* y nada
lo deriva hoy: el esquema de resultado es exactamente la lista SELECT que `MADQueryFull` ya
calcula — los campos de consulta activos, con alias `Table.Field`, más lo que proyectan los agregados y
las agrupaciones. Los tipos y anchos vienen de la instantánea del esquema
(`RptqDatabaseSchemaField`); las columnas de agregado de `MADAggregateFunctionType`. El trabajo es
separar la construcción de la lista SELECT de la ejecución y devolverla como `MADDataColumn`s. También
corrige la brecha de Sqlite3 con cero filas gratis, en el momento en que las columnas existen antes que las filas: los controladores
ya hacen `addColumn:` antes de `addRow:`, y el DDL de la tabla se crea en la primera columna
(`MADDataTableFast.m:526-543`).

### 4.3 Identidad y dirección

Un objeto de datos necesita un nombre que sobreviva a los renombrados y una dirección que sobreviva a la regeneración:

- **Identidad:** el `identifier` de una fila del almacén, como toda otra entidad `Rptq`, más un
  nombre de cara al usuario. La etiqueta de materialización se convierte en el hash del identificador del objeto, no
  `fileURL.lastPathComponent.hash` — lo cual retira, para este propósito, el direccionamiento por
  nombre de archivo (peligro de `MAD_FORMAT.md` §5.3; la nota "content hash the key" de `MAD_FUTURE.md` §2.2
  es la misma corrección en la capa de renderizado).
- **Dirección:** el directorio de caché ya contiene un `.maddb` por documento; la formalización
  natural es una tabla `t<tag>` **por objeto de datos** en él (las etiquetas ya los hacen
  distintos), cada una con su propio plist de esquema estilo `.mdcache`. El archivo `.maddb` por objeto
  (el emparejamiento `t<tag>`/`<tag>.maddb` tomado literalmente) es la alternativa; §5.1 dice cuándo
  importa.

### 4.4 Dónde cambia el almacén — y qué ya permite

Forma mínima, recomendada:

- `RptqQuery` gana un nombre (ya es la definición; nada se mueve).
- La referencia de `RptqQueryTable` — hoy un id de tabla de esquema dentro de un `RptqDatabase` — gana un
  segundo tipo: **otro objeto de datos**. Este es el único cambio de esquema que la composición necesita,
  y es aditivo: una fila v1 con una referencia de tabla de esquema significa exactamente lo que significa hoy.
- Multi-origen no necesita ningún cambio de almacén: el almacén ya admite muchas filas `RptqDatabase`,
  cada una con su propia consulta (un `MADModelDatabase` por `RptqQuery`, §3.1). Lo que los documentos de hoy
  tienen es una de cada una porque el flujo de creación crea una; el esquema se
  preparó para el futuro en 2017 y todavía espera.

La alternativa más pesada — una nueva entidad `RptqDataObject` dueña de la definición, con
`RptqQuery` degradado — tiene mejor nomenclatura y una migración más grande. Registrada como decisión 9.1.

## 5. Composición — el montaje de subinformes, documentado, no construido

**Esta sección deliberadamente no está programada** (el usuario, 2026-10-16: *"I don't want to rig it
up… but I want to document this idea"*). Existe para que, cuando se quiera, sea un plan
en lugar de un descubrimiento.

### 5.1 El mecanismo, con precisión

1. Cada objeto de datos se ejecuta contra su propio origen — su propio `RptqDatabase`, controlador y
   credenciales — y se materializa en su propia tabla SQLite (una `t<tag>` en la caché del
   documento, según §4.3).
2. El grafo de consulta del objeto compuesto no cambia en su tipo: sus "tablas" incluyen objetos de datos;
   las uniones, filtros y alias se aplican todos, porque en ambos lados una tabla es un conjunto de columnas
   con nombre.
3. La ejecución es topológica sobre el DAG de objetos (el mismo algoritmo que `MADQueryFull` ya
   ejecuta sobre el grafo de uniones, `MADQueryFull.m:202`): primero los orígenes, al final el objeto compuesto, su
   resultado materializado como cualquier otro.
4. El objeto compuesto se ejecuta **contra la caché, no contra una base de datos remota** — es una consulta
   cuyo "base de datos" es el `.maddb`. `MADSqlite3` ya es un `MADDatabase` completo, así que el
   controlador para este paso se envía hoy. Un `.maddb` que contenga varias tablas `t<tag>` no necesita
   `ATTACH` en absoluto; `ATTACH DATABASE` es la variante para **archivos separados** — un `.maddb` por
   objeto, u objetos de *documentos diferentes*, que es el caso en el que la frontera de subinforme
   es una frontera de archivo y `ATTACH` (o una copia dentro) es la única ruta de unión.

La versión de una línea, que es toda la razón por la que esto es un montaje y no un proyecto: **el
resultado de toda consulta ya es una tabla SQLite, y SQLite ya es un controlador.** El
motor de federación está en la caja; actualmente se direcciona por un hash de nombre de archivo.

### 5.2 Qué se construiría, si se quisiera

1. El contrato de §4 (describe/execute, identidad, dirección) — un requisito previo, no una fase.
2. El tipo de origen: `RptqQueryTable` → objeto de datos; la generación de SQL lo resuelve a la
   tabla de materialización del objeto en lugar de `db.table`.
3. El orden de ejecución: recorrer el DAG; actualizar objetos obsoletos; luego la consulta compuesta.
4. El telescopaje del diseñador (palabra del usuario): en el panel Add Table, un segundo tipo de
   origen junto a las tablas de esquema — los otros objetos de datos del documento, o una caja de subinforme que
   lista los campos de salida del otro objeto. La interfaz de unión no cambia; ambos extremos son campos.
5. Soporte de `ATTACH` en `MADDatabaseSqlite3` si y cuando se quiera composición entre archivos.

### 5.3 Qué hace que no sea una sola línea

Registrado para que la estimación siga siendo honesta: los tres puntos de cableado fijo de §3.6
(la relectura de `MADQueryFull`, el `dataTableForQuery:` de una sola ranura, el
`MADQueryActiveQueryFields` sin alcance) tienen que caer antes de que una segunda consulta — y mucho menos una *anidada*
— pueda ejecutarse; `MADModelDocument` refleja solo `firstQuery` en la ruta de cambios
(`MADModel_Layer.md` §8); y `RptqQuery -sortDescriptorsForDatabase:` agrupa contra la
caché única del documento. Ninguno es difícil; todos son fundamentales para la aplicación actual de consulta única.

## 6. La CLI, el servidor web y el motor

La pregunta del usuario, 2026-10-16: *"the CLI is really for testing, understanding, and future
use… it's important, but the goal is to have something that can be called from the webserver,
and I don't know if the CLI is the best way to do that."*

La respuesta honesta, tal como están los artefactos:

- **La CLI es un cliente del motor, no el motor.** Sus seis verbos —
  `inspect`, `schema`, `query`, `refresh`, `export`, `write` — son sitios de llamada de ejemplo de la cadena de llamadas
  de §3: abrir el contenedor, leer el almacén, generar SQL, ejecutar hacia una tabla, renderizar. Lo que
  necesita un servidor web es la misma cadena detrás de un punto de entrada estable; un subproceso es una
  vinculación de esa cadena (la forma que esboza `MAD_LINUX.md` §2: `mad --format json` como
  subproceso), una biblioteca enlazada otra, una API en proceso de Objective-C/Swift una tercera.
- **El punto de entrada es la pieza faltante, y está nombrado.** No hay una clase de nivel superior
  libre de UIKit hoy que abra un `.mad`, ejecute la consulta y devuelva filas: en Apple,
  `MADocument` es un `UIDocument`; el `MADCLIDocument` de la CLI es headless en *comportamiento* pero
  espera en el run loop a ese UIDocument.  (La Fase D resolvió el lado headless:
  `MADHeadlessDocument` es el punto de entrada en Linux, y desde la Fase E también lleva la mitad de renderizado
  — `MADDocumentRenderProtocol`, `MADReportPageBuilder` — así que `mad export` se ejecuta
  allí.  `MAD_LINUX.md` §9.)  El contrato de §4 es lo que tal punto de entrada expondría:
  abrir → listar objetos de datos → describir → ejecutar → (esquema, filas).
- **El formato de intercambio es una decisión, no tres.** Esquema + filas como JSON es la misma forma que
  la exportación JSON (`MAD_CLI.md` §8.3, tabla de decisiones de `ROADMAP.md`) y la salida estructurada
  que valida una capa de IA (`MAD_FUTURE.md` §7). `MADDataColumn` ya es una descripción de columna
  convertible a plist; el plist `.mdcache` ya es un esquema de resultado serializado. Diseña la forma
  JSON una vez, abiertamente, y la exportación, la API y la IA la consumen toda.
- **De lo que la CLI sigue siendo responsable** es la disciplina que fijó la Pista 3 de `ROADMAP.md`: el
  documento visible con la aplicación fuera del camino, los códigos de salida (0–5) como el vocabulario de errores,
  los fixtures de ida y vuelta que fijan el formato. Esos no se mudan al servidor web; son
  cómo el motor del servidor web se mantiene honesto.

Los hechos medidos detrás de "esto es barato una vez que existe el contrato": la ruta de datos ya es
headless — la generación de SQL, el almacén, `MADDataTableFast` y los tres controladores compilan en
Linux hoy, con 124 ejecutables de prueba y 1,270 pruebas en verde (`Linux/README.md`), y desde
la Fase D la CLI compila y se ejecuta en esa imagen (`inspect`, `schema`, `query`, `refresh`,
`export`, `write`). Así que el orden que sigue es el contrato primero, el punto de entrada segundo,
las interfaces externas tercero — y hace que "¿CLI o servidor web?" sea una pregunta con una respuesta
de dos líneas en lugar de una bifurcación arquitectónica.

## 7. Qué se necesitaría — en fases, sobre las pistas existentes

Ordenado para que la aplicación siga enviándose y la suite siga en verde todo el tiempo; cada fase nombra el
cambio de §3 que retira.

| Fase | Trabajo | Retira |
|---|---|---|
| 1 | **El contrato.** Separa la construcción de la lista SELECT de `MADQueryFull` de la ejecución; devuélvela como `MADDataColumn`s. Añade los protocolos describe/execute; haz que `MADOperationRefresh` los llame. Sin cambio de comportamiento. | Ninguna API de solo esquema; pérdida de esquema de Sqlite3 con cero filas |
| 2 | **La consulta se posee a sí misma.** `MADQueryFull` toma la consulta que se le dio (sin relectura del documento); `-dataTableForQuery:` resuelve por consulta; `MADQueryActiveQueryFields` se limita a una consulta; `MADModelDocument` refleja cualquier consulta. Un documento, muchos objetos. | Los tres puntos de cableado fijo de §3.6 |
| 3 | **Identidad y dirección.** Nombra el objeto en el almacén; etiqueta las materializaciones por identificador de objeto, no por nombre de archivo; una tabla de resultados por objeto en la caché; plist de esquema por objeto. | Materialización con hash de nombre de archivo; una tabla por documento |
| 4 | **El enlace y las superficies.** El diseño se enlaza al esquema de un objeto de datos; la CLI gana `describe`; la forma JSON se fija una vez (exportación + API + IA). | Enlace a "la consulta del documento" |
| 5 | **Composición** (§5), solo cuando se pida. | — |

La fase 1 es la carga real del diseño y la más pequeña: no necesita cambio de almacén, ni cambio de interfaz,
ni formato nuevo — reordena código que ya existe, y es demostrable por las suites actuales más una
afirmación de esquema sobre una consulta de cero filas. Las fases 2–4 son la misma idea
aplicada a las capas que sostienen la suposición de consulta única. La fase 5 es el montaje, documentado,
sin programar.

## 8. Qué no hacer

- **No construyas el montaje multi-origen ahora.** Decisión del usuario, 2026-10-16; este documento es
  el registro, no un elemento de cola. (Se aplican las convenciones de `TASKS.md`/`BUGS.md`: nada aquí se
  inicia por iniciativa del agente.)
- **No comprimas ni rediseñes la caché.** Es fundamental, el diseño de dos pasadas la necesita,
  y `MAD_FORMAT.md` §5.1 es el análisis vigente.
- **No construyas un motor de federación.** Según §1 y §5, las materializaciones son la
  federación.
- **No implementes un segundo generador o ejecutor de SQL.** Todo excepto el direccionamiento y
  el orden ya existe.
- **No toques las cosas deliberadamente muertas** (`MADQueryDefinition*`, `RptqQuerySort`,
  `MADQueryFullTableEnumerator`, los campos de anulación de texto libre) como parte de esto — son
  decisiones de limpieza separadas.

## 9. Decisiones abiertas

1. **La forma del almacén.** ¿Nombrar el `RptqQuery` existente (mínimo, recomendado) o introducir
   `RptqDataObject` como su propia entidad (migración más limpia y más grande)?
2. **La unidad de materialización.** ¿Un `.maddb` por documento con una `t<tag>` por objeto
   (recomendado — sin `ATTACH`, sin archivos nuevos), o un archivo por objeto (`ATTACH` al
   componer)?
3. **Qué es la instantánea.** `MAD_FUTURE.md` §2.2 hace del par de materialización
   (`.maddb` + `.mdcache`) el artefacto compartible. Bajo este diseño, ¿la unidad de intercambio es
   el resultado del objeto de datos, o el documento?
4. **Qué expone hacia fuera el esquema de un objeto de datos.** `MADDataColumn` es rico;
   nombre/tipo/longitud es lo que necesitan un servidor web y una IA. La forma JSON (decisión única, §6) es
   donde esto se fija.
5. **Nomenclatura.** "Objeto de datos" es el término del usuario y de este documento; `MAD_FUTURE.md` llama
   al artefacto de la industria un *modelo*. Uno de los dos debería ganar antes de que se construya nada, porque
   aterriza en entidades del almacén, protocolos y los verbos de la CLI.

## 10. El hilo conductor

La pestaña de consulta ya construye la función; la cadena de actualización ya la compila y ejecuta;
la tabla de resultados ya *es* un esquema y un conjunto de resultados, en disco como SQLite; los controladores que
unirían dos de ellas ya existen y ya compilan en Linux. Lo que nada de eso tiene es un
nombre, una dirección y una mitad describe — las tres cosas que convierten "la consulta del informe" en un
objeto de datos, y un objeto de datos en una tabla que otro objeto de datos puede usar. El resto — subinformes,
múltiples orígenes, un servidor web de pie sobre el motor — es composición sobre eso, y se compone
precisamente porque nada nuevo tiene que inventarse: es la tubería existente, direccionada por
algo mejor que un hash de nombre de archivo.
