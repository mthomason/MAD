---
layout: default
title: "Pegar SQL en el diseñador de consultas"
description: "El subconjunto de SQL admitido, el analizador y la ruta de aplicación."
lang: es-419
---

# MAD SQL Entry — pegar una consulta SQL en el diseñador de consultas

Esta página registra la función de entrada de SQL: el subconjunto de `SELECT` admitido, el analizador y el resolutor, y la ruta de aplicación que convierte una sentencia de vuelta en el grafo de consulta portable. Las fases A-D están implementadas; la fase E está diferida.

**Alcance:** un nuevo analizador/resolutor/compilador en `MAD/Source/sql/`, una ruta de aplicación en `MADocument`,
el popover de SQL en `MADDesigner`, el texto fuente persistido (§8, que añade el primer paso de versionado del almacén),
y las pruebas que fijan todo ello.
**Fecha:** 2026-10-22, leído en `cf0fe3acd`; revisado el 2026-10-22 con la decisión de persistencia (§8).
**Estado:** implementado — las fases A–D aterrizaron el 2026-10-22 y se fusionaron en master como `c48a39fb7`
(la cola de tareas interna §16). La fase E (§9) sigue diferida; §8.1–§8.2 llevan las enmiendas tal como se construyó.

---

## 1. El objetivo

Hoy la única forma de construir una consulta es el diseñador visual: elegir tablas, enlazarlas campo por
campo, añadir filtros, añadir agrupaciones — todo a través de la interfaz con pestañas. El usuario quiere una segunda forma de entrada:

> "…a user could hit a button and it flips around and shows a multiline text view where they
> can paste the SQL… when that SQL is saved, it manually creates the query in the backend of
> the report… it does everything it already would do with the user selecting all the details…
> the software still recognizes what fields are used what joins are used what tables are used,
> and it completely setups the document in the proper way, and then allows the user to even
> use the query designer with the fields entered by the standard query (if they wish to)."

Así que: el SQL pegado se **compila en el modelo de consulta del documento** (el grafo de objetos `Rptq`),
a través de exactamente las mismas fábricas que llama el diseñador visual. Después de aplicar, el diseñador visual de consultas,
el lienzo de visualización y el diseñador de informes ven la consulta como si se hubiera
construido a mano — y el usuario puede seguir editándola allí. Debe haber una fase de validación.

## 2. Qué existe hoy (leído de primera mano)

### 2.1 El modelo de consulta canónico — el grafo `Rptq`

La consulta del documento vive en el almacén portable como objetos `Rptq*` simples
(`MAD/Source/rptq/`); la capa `MADModel*` es una vista de solo lectura sobre ellos
(`MADModel_Layer.md`). El importador escribe filas `Rptq` y nada más.

* `RptqQuery` (`MAD/Source/rptq/autogen/RptqQuery.h:30-34`): `hasQueryTables`,
  `hasQueryLinks`, `hasQueryPredicate` (nota el nombre en singular), `hasQueryGroups`.
* `RptqQueryTable` — una referencia a tabla de esquema más un alias; el alias es *calculado*:
  el nombre de la tabla de esquema para la primera copia, nombre + índice de drop después
  (`Customer`, `Customer0`, … — `MADModelQueryTable.m:119-129`).
* `RptqQueryField` — dos ids: `inQueryTable` + `databaseSchemaField`. Cada campo de cada
  tabla de consulta recibe una fila (el flujo de añadir tabla crea una por campo de esquema,
  `MADQueryViewController.m:762-770`).
* `RptqQueryLinks` — una unión: `hasLeftField`/`hasRightField` (un `RptqQueryField` cada uno),
  `type` (`MADLinkType`, `MADQueryLinkType.h`: inner / equi / natural / cross / left / right
  / full outer). Exactamente un par de campos por vínculo; el generador siempre emite `ON l = r`
  (`MADQueryFull.m:366-380`).
* `RptqQueryPredicate` — `comparson` (`MADPredicateOperator`: `=`, `<>`, `>`, `>=`, `<`,
  `<=` — `MADPredicateOperator.h`, `RptqQueryPredicate+Extras.m:245-265`), más un
  lado izquierdo/derecho que es un `RptqQueryField` o una cadena de valor con tipo
  (`leftFieldID`/`rigthFieldID`). Todos los predicados se combinan con AND, cada uno escrito `(left op right)`
  (`MADQueryPredicate.m:43-93`). Sin OR, sin LIKE, sin IN, sin funciones.
* `RptqQueryGroup` — `hasField`, `sort` (`MADSortOrder`), `weight` y `hasSection`: las
  secciones de encabezado/pie de grupo del informe (`RptqQueryGroup.h:24-29`).

Lo que el modelo **no** contiene — los límites que el importador debe respetar:

* **Ninguna lista SELECT.** El SELECT se deriva en el momento de construir el SQL a partir de qué campos de consulta
  son referenciados por los elementos del diseñador (etiquetas de datos, agregados, códigos de barras), uniones y grupos
  (`MADQueryActiveQueryFields.m:37-97`, `MADQuerySelectExpressionActiveFields.m`).
* **Ningún ORDER BY libre.** El orden de clasificación existe solo por grupo (`RptqQueryGroup.sort`).
* **Ningún OR / IN / LIKE / funciones / subconsultas / UNION** — ninguno es representable.
* **Ningún texto SQL almacenado**, y ningún versionado del almacén para añadir una columna (abajo, §8).

### 2.2 Generación de SQL — el contrato de ida y vuelta

`MADQueryFull` construye el SQL ejecutado a partir del modelo
(`SQLOnlyActiveFields:managedObjectContext:error:`, `MADQueryFull.m:143-273`):

* Parte `SELECT` del controlador, luego los campos activos, ordenados por alias de columna, escritos
  **sin `AS`**: `"Table0"."Field"` (`MADQuerySelectExpressionActiveFields.m:32-38, 46-53`).
* `FROM` — un DFS sobre el grafo de uniones: `tableName <connector> queryAlias`, luego
  `LEFT OUTER JOIN tableName <connector> queryAlias ON l.field = r.field` por vínculo
  (`MADQueryFull.m:275-426`, texto de unión de `RptqQueryLinks SqlForLinkType:`,
  `RptqQueryLinks+Extras.m:76-86`).
* `WHERE` — las tripletas de predicado combinadas con AND (`MADQueryPredicate.m`).
* Ningún `GROUP BY`/`ORDER BY` en el SQL — la agrupación y la ordenación se aplican sobre la
  caché `.maddb` (`MADParameters+QueryCacheAggregate`, `MADQueryCacheSelectGroupKeys`).
* Una cláusula `LIMIT` suministrada por el controlador.

El contrato del importador es, por lo tanto: **una sentencia pegada es aceptable exactamente cuando
podría ser la salida de `MADQueryFull` para algún modelo.** Eso es lo que hace honesta la ida y vuelta
— el lado View del popover de SQL muestra el SQL regenerado a partir del modelo importado,
y se lee como lo que el usuario pegó.

### 2.3 La tubería de actualización — el patrón que reutiliza la validación

`MADOperationRefresh.m:60-172`: conectar con credenciales suministradas por las dependencias de la operación,
construir el SQL **en la cola principal** (el contexto del almacén es propiedad de la cola principal — BUGS.md), luego
`[database executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`
(`MADDatabaseProtocol.h:33`) y `dataTableMakeCache`. Una sonda de validación es la misma
forma de operación menos la construcción de la caché.

### 2.4 El backend que la interfaz ya llama — la costura que reutiliza el compilador

Escribir filas `Rptq` y guardar es suficiente; la capa `MADModel*` refleja el cambio en la
interfaz mediante notificaciones del almacén (`MADModel_Layer.md` §3.3). Las fábricas a llamar, textualmente del
código de interfaz actual:

* **Añadir tabla** — `[RptqQueryTable newQueryTableForSchemaTable:database:forManagedObjectContext:]`
  luego un `[RptqQueryField newQueryField:context]` por campo de esquema, conectado a la tabla,
  tabla añadida a `query.hasQueryTables`, guardar (`MADQueryViewController.m:744-799`).
* **Añadir vínculo** — `[RptqQueryLinks newQueryLinksWithLeftField:rightField:joinType:managedObjectContext:]`
  luego `[document.activeDocumentModel addQueryLink:link]`, guardar
  (`MADQueryLinkBuilderController.m:112-122`).
* **Añadir predicado** — `[RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:…]` /
  variantes `…WithLeftValue:…` (`MADQueryAddPredicateController.m:142-162`,
  `RptqQueryPredicate+Extras.h:20-39`).
* **Añadir grupo** — `[document addQueryGroupWithQueryField:andSortOrder:]`
  (`MADocument.m:728-792`). Esta única llamada crea la fila de grupo *y* las secciones de encabezado/pie de grupo
  del informe *y* sus gestores de diseño de sección — "configura completamente el
  documento" para un `GROUP BY`, gratis.
* **Eliminación, para la ruta de reemplazo** — `removeGroupWitObjectID:fromManagedObjectContext:`
  (`MADocument.m:1130`), `deleteDatafieldsRelatedToTable:inContent:` y
  `deleteAggregateFieldRelatedToTable:inContent:` (`MADocument.h:91-95`), y las rutas de eliminación
  de vínculos/predicados existentes en la interfaz de consulta. La fase B los inventaría; cualquier ayudante simétrico
  faltante para vínculos/predicados se añade allí.

### 2.5 La costura de la interfaz

El controlador de vista dividida del constructor de consultas ya tiene un elemento de barra de herramientas `barButtonItemSQL` que
presenta un popover `MADViewControllerSQL` **de solo lectura** (`MADQueryBuilderSplitViewController.m:31,
106-111`; `MADQuery.storyboard`; `MADViewControllerSQL.m:27-56` muestra
`[doc.mainQuery SQLOnlyActiveFields:…]`). La función es un modo de esta misma pantalla, así que el
botón, el popover y la navegación ya existen.

## 3. La función, tal como la ve el usuario

1. En la pestaña de consulta, toca el botón SQL existente. El popover ahora tiene modos **View / Edit**.
2. **View** muestra ambas representaciones del SQL de la consulta, como un control segmentado:
   * **Generated** — el SQL que `MADQueryFull` construye a partir del modelo en este momento (el
     contenido actual del popover, mantenido como pestaña predeterminada).
   * **As entered** — la última sentencia aplicada por el usuario, textualmente
     (`RptqQuery.sqlSourceText`, §8); oculta o vacía cuando la consulta nunca se ha construido
     a partir de SQL pegado.
   Ambas pestañas son de solo lectura — la pantalla de "ve lo que pegaste, y ve en qué se convirtió".
3. **Edit** — una vista de texto multilínea monoespaciada, sembrada desde `sqlSourceText` cuando está presente
   (el usuario vuelve a editar *su* texto, con formato y comentarios intactos) y desde el SQL generado
   en caso contrario; un botón **Revert to generated** vuelve a sembrar desde la forma generada.
4. **Validate** — comprobación estructural más, cuando se puede alcanzar la base de datos del documento, una
   sonda de servidor con cero filas (§7). Los errores vuelven con línea y columna.
5. **Apply** — la sentencia se compila en el documento (atómica — §6.5) y el texto pegado exacto
   se persiste como `sqlSourceText` (§8). El popover se cierra; la lista de tablas de consulta,
   el lienzo de visualización y el diseñador de informes muestran todos la estructura importada.
   Los selectores de campos del diseñador funcionan como de costumbre.
6. Una aplicación fallida o en conflicto no persiste nada — ni el texto, ni ninguna fila. La consulta anterior
   y su texto introducido anterior permanecen exactamente como estaban.
7. El usuario puede volver en cualquier momento: el diseñador visual sigue trabajando sobre la consulta
   importada, View muestra ambas formas, y Edit reabre sus propias palabras.

## 4. Arquitectura

```
pasted SQL
  → MADSQLTokenizer        dialect-aware lexer; quotes per driver; tracks line:column
  → MADSQLParser           recursive descent; produces a MADSQLStatement parse tree
  → MADSQLStatementResolver  binds names to RptqDatabaseSchemaTable / RptqDatabaseSchemaField
  → [MADOperationValidateSQL]  server probe, when connected (§7); never writes
  → MADSQLQueryCompiler    the write plan: deletes + creates Rptq rows via the §2.4 factories
  → store save → model notifications → query UI / visualization / designer update
```

**Ubicación.** Todo excepto la operación de sonda y la interfaz del editor vive en el framework `MAD`,
Foundation puro, sin UIKit — así que se ejecuta en la suite de pruebas `MAD` y en la imagen de Linux.
Los archivos nuevos se añaden a `Linux/cmake/MADSources.cmake` y `./Linux/build.sh` sigue en verde.
La operación de sonda (necesita controladores, credenciales, alertas de UIKit) y la interfaz del popover viven en
`MADDesigner/Source`.

**Archivos nuevos.** `MAD/Source/sql/MADSQLTokenizer.{h,m}`, `MADSQLParser.{h,m}`,
`MADSQLStatement.{h,m}` (el árbol y sus tipos de valor: `MADSQLColumnReference`,
`MADSQLPredicateTerm`, …), `MADSQLStatementResolver.{h,m}`, `MADSQLQueryCompiler.{h,m}`,
`MADSQLCompileError.{h,m}`. Aplicación: `MADOperationValidateSQL.{h,m}` (que refleja
`MADOperationRefresh`), más los cambios del editor en `MADViewControllerSQL` o un controlador de editor hermano
en la misma costura del storyboard.

**Una pequeña adición a la API.** El lexer necesita el entrecomillado de identificadores de cada dialecto (acentos graves de MySQL,
corchetes de T-SQL, comillas dobles) antes de que exista una conexión. Añade
`+ (NSString *)identifierQuoteCharacters` a `MADDatabase` (predeterminado: comilla doble), con
sobrescrituras por controlador en `MADMySQL`/`MADTdsClient` (`MADPostgres` usa la comilla doble
predeterminada) — o, si se prefiere, un método de clase en el protocolo del controlador resuelto mediante
`MADDatabaseDriverRegistry`. De cualquier forma es una adición de tres métodos.

## 5. El subconjunto admitido

El importador acepta **exactamente el lenguaje que el modelo puede contener** — un `SELECT`, sin
subconsultas en ningún lugar, y cada cláusula dentro de los límites de §2.1:

* **Lista SELECT** — solo referencias de columna: `col`, `tbl.col`, `schema.tbl.col`, `alias.col`,
  entrecomilladas o simples, más `alias.*` / `schema.tbl.*`. La lista se *valida y se usa para
  el descubrimiento de tablas/columnas*, no se almacena (el modelo no tiene lista SELECT — §2.1): cada columna
  debe resolverse, y una columna calificada nombra una tabla que debe aparecer en `FROM`. Las expresiones,
  agregados, alias (`AS x`) y `DISTINCT` se rechazan con un puntero a la fase E (§9),
  que es la fase que hace real la lista de columnas pegada sintetizando elementos del diseñador.
  El texto introducido mismo *sí* se almacena, textualmente, en `sqlSourceText` (§8) — la forma de validación
  y el texto de entrada son cosas separadas.
* **FROM** — una referencia de tabla `[schema.]name [AS alias]`, luego una cadena/árbol de
  `[INNER] JOIN`, `LEFT [OUTER] JOIN`, `RIGHT [OUTER] JOIN`, `FULL [OUTER] JOIN` cada uno con
  exactamente una condición de equi `l.col = r.col` (columnas simples, de dos partes o de tres partes `schema.tbl.col`;
  simple permitida cuando no es ambigua).
  * Los alias deben ser el nombre propio de la tabla de esquema (o su forma sin puntos), o la forma de índice de drop
    (`name0`, `name1`, `schema.name0`, o `schemaname0` sin puntos que coincida con
    `RptqQueryTable -queryAlias`) para una segunda copia de la misma tabla — el modelo calcula
    los alias él mismo y no puede contener renombrados (`Customer AS c` se rechaza: "el diseñador nombra
    las tablas él mismo").
  * Como máximo una unión entre un par de tablas dado (el generador emite un `JOIN` por
    par de tablas; dos vínculos entre el mismo par duplicarían el alias).
  * Sin uniones por comas, sin uniones `NATURAL`/`CROSS` (el modelo de vínculos contiene exactamente un par de campos
    y el generador siempre escribe `ON …`), sin subconsultas en `FROM`/`ON`.
* **WHERE** — una conjunción (AND) de comparaciones `left op right`, `op` ∈
  `{ =, <>, >, >=, <, <= }` (el conjunto `MADPredicateOperator`), cada lado una referencia de columna
  o un literal. Los paréntesis se aceptan solo donde no cambian la forma plana de AND.
  Todo lo demás — `OR`, `IN`, `BETWEEN`, `LIKE`, `NOT`, funciones, subconsultas — se
  rechaza: el modelo de predicados combina tripletas planas con AND y nada más.
* **GROUP BY** — referencias de columna, importadas en orden (peso), cada una convertida en un grupo mediante
  el ayudante de `MADocument`, que también crea las secciones de grupo del informe.
* **ORDER BY** — aceptado **solo cuando cada columna es una columna de GROUP BY**, y el
  asc/desc se corresponde con los órdenes de clasificación de los grupos. De lo contrario se rechaza (no hay orden libre en el modelo).
* **LIMIT** — rechazado: la aplicación aplica su propio límite de modo diseñador/informes
  (`MADDocument.limitResultsDesignMode`, `MADQueryFull.limitResults`).

Los literales se manejan por dialecto en el momento de la generación (`newSafeLiteral:`,
`MADDatabaseSQLProtocol.h`); el importador solo registra la cadena de valor y el tipo de datos del campo,
exactamente como hace la interfaz de predicados (`MADQueryPredicate.m:74-88`).

Los rechazos nunca son silenciosos: cada uno nombra la construcción, la cláusula, la razón (qué
límite del modelo alcanza) y la línea:columna.

## 6. Resolución y compilación

### 6.1 Resolutor

* Alias (o nombre de tabla simple) → `RptqDatabaseSchemaTable` por nombre, sin distinguir mayúsculas.
  Desconocido → error "tabla desconocida".
* Columna → `RptqDatabaseSchemaField`: la calificada debe existir en su tabla; la simple debe ser única
  en el conjunto `FROM`, si no "columna ambigua".

### 6.2 El plan de escritura

La salida del resolutor es un plan de objetos de valor: lista ordenada de tablas, lista de uniones (`MADLinkType` por
unión), lista de predicados (`MADPredicateOperator` + términos izquierdo/derecho), lista de grupos con órdenes
de clasificación. El plan se valida entero antes de escribir nada.

### 6.3 Comprobación de conflictos — la aplicación es atómica

Apply **reemplaza** la consulta (el SQL pegado *es* la consulta — esa es la función). Antes de
escribir, comprueba cada tabla que el nuevo plan **no** incluye por referencias desde elementos del diseñador
— las tres formas que conoce `MADQueryActiveQueryFields`
(`MADQueryActiveQueryFields.m:37-68`: referencias de etiqueta-datos, agregado, código de barras) más cualquier
sección de grupo que se eliminaría. Si se referencia un campo de una tabla descartada, aborta
con un error que nombra los elementos ("este campo lo usa … en el diseñador"); no se
elimina nada, no se escribe nada, y la consulta anterior sigue ejecutándose. Este es el único caso en el que la
importación no puede ser atómica y silenciosa, así que falla ruidosamente.

### 6.4 Escritura

En orden de dependencia inversa usando los ayudantes de §2.4: eliminar vínculos y predicados, eliminar
grupos (mediante la ruta de eliminación de grupos existente, que desvincula sus secciones y gestores de
diseño), eliminar tablas que no están en el plan (mediante la familia existente
`deleteDatafieldsRelatedToTable:`), luego crear tablas → vínculos → predicados → grupos
a través de las mismas fábricas que llama la interfaz. Un solo guardado; el llamador luego marca el documento como modificado
y autoguarda, como hace el flujo de añadir tabla (`MADQueryViewController.m:796-799`).

### 6.5 Después de la escritura

Sin tocar la interfaz: la ruta de notificaciones del almacén actualiza la capa de modelo y ambas pantallas de consulta
(`MADModel_Layer.md` §3.3). El compilador devuelve un resumen (recuentos de tablas / vínculos / predicados /
grupos) para el popover.

## 7. Validación — dos niveles

**Estructural (siempre, sin conexión).** Analizar + resolver, §5–§6. Los errores son
`NSError` del dominio `MADSQLCompileError` con un código, línea, columna y mensaje. Esta es la
función completa cuando la base de datos del documento es inalcanzable.

**Sonda de servidor (cuando se puede establecer una conexión).** Envuelve la sentencia:

```sql
SELECT * FROM (<user sql>) AS _mad_probe WHERE 1=0
```

El alias de tabla derivada es obligatorio en MySQL y válido en T-SQL; `WHERE 1=0` se pliega, así que la
sonda compila la consulta y devuelve metadatos de columna sin leer filas. Ejecútala a través de
la forma de `MADOperationRefresh` (`MADOperationRefresh.m:104-162`): conectar con credenciales
de las dependencias de la operación, lecturas del almacén marshalling a la cola principal, resultados mediante el
`executeSQL:…intoResultTable:…` del controlador para que `MADDataColumn` dé nombres y tipos. La sonda
luego detecta lo que el análisis estático no puede — resolución de nombres del lado del servidor (sensibilidad a mayúsculas,
vistas, palabras reservadas), diferencias de dialecto, y los errores de sintaxis del propio servidor, que se
exponen con el mensaje del servidor. Los nombres/tipos de columna se comparan con los campos de esquema
resueltos y las discrepancias se informan como advertencias, no como fallos.

Sin conexión, o cuando las credenciales no están disponibles, la sonda se omite y la interfaz dice
"validado solo por estructura".

## 8. El texto fuente persistido — `RptqQuery.sqlSourceText`

El modelo compilado sigue siendo la fuente de verdad para la ejecución, pero **el texto pegado por el usuario
forma parte del documento**: un nuevo atributo de texto anulable `sqlSourceText` en `RptqQuery`
contiene la última sentencia aplicada con éxito, textualmente. Eliminar las palabras del usuario nunca fue
una opción — el documento conserva tanto la entrada como su compilación. El usuario eligió una única
propiedad sobre un arreglo de historial (2026-10-22); se puede añadir un historial de revisiones más adelante como
una relación de uno a muchos ordenada y rellenarlo desde el texto actual sin pérdida de datos.

Reglas de persistencia:

* Escrito solo por un Apply exitoso, reemplazado en su totalidad; una aplicación fallida o en conflicto
  no toca ni las filas del almacén ni este texto (§3.6).
* La vista Edit se siembra desde él cuando está presente; la pestaña View lo muestra como **As entered** junto a
  **Generated** (§3.2-3.3).

### 8.1 El cambio del almacén

El atributo aterriza en ambos lados de la verificación cruzada del esquema: el modelo compilado y los
descriptores `MADStoreSchema` mantenidos a mano, más la propiedad autogen de `RptqQuery`
(`MAD/Source/rptq/autogen/`). `MAD_FORMAT.md` gana la columna en su lista de campos.

**Enmendado (fase A, 2026-10-22).** El cambio del modelo es una **nueva versión `MAD 4.xcdatamodel`**,
no una edición en el lugar de `MAD 3`: el hash de una versión de modelo ya enviada fija los metadatos del almacén de cada
documento en circulación, y editarla los deja huérfanos. `MAD 4` también elimina el
`elementID="type"` muerto de `RptqDocumentElementBarcode.barcodeBorderType` (ninguna versión anterior a `MAD 3`
tiene una entidad de código de barras; BUGS.md).

### 8.2 Versionado del almacén — nuevo, pequeño y ahora obligatorio

El almacén portable no tiene versionado hoy (`MADStore.m` no lleva ningún pragma `user_version`).
Esta fase añade el mecanismo, deliberadamente mínimo:

* `MADStoreSchema` gana una constante de versión y una lista ordenada de pasos de migración. Hoy
  esa lista tiene una entrada: versión 1 (el esquema en circulación — `user_version` ausente o 0)
  → versión 2 (`ALTER TABLE` que añade `sqlSourceText`).
* Al abrir, `MADStore` lee `PRAGMA user_version`, aplica los pasos faltantes en una
  transacción, y escribe la nueva versión. Los almacenes nuevos se crean en la versión actual
  (`createSchemaSQL` ya genera todo el esquema).
* `MADLegacyStoreConversion` no se ve afectado en su flujo — los documentos Core Data convertidos se
  crean en la versión actual a través de la misma ruta de apertura de `MADStore`.
* El motor headless de Linux compila el mismo código de `MADStore`, así que los documentos existentes se abren
  de forma idéntica en la imagen; las pruebas de migración también se ejecutan allí.

**Enmendado (fase A, 2026-10-22).** `MADStoreConverter` ahora abre cada almacén heredado con
la versión de momd que coincide con sus metadatos, nunca mediante migración automática: Core Data no puede
inferir una asignación para esta familia de modelos (el choque de `elementID` del código de barras, BUGS.md), y
el modelo actual de momd ya no es la versión contra la que se escribieron los almacenes en circulación.

### 8.3 Considerado y rechazado: el plist de metadatos guts

El plist de metadatos que viaja junto al almacén en el directorio guts podría contener el texto
sin ningún cambio de esquema. Rechazado: los datos de consulta pertenecen a la parte de consulta del almacén
(`MADStorePartQuery` — el contrato del almacén es "tres partes y nada más",
`MADStoreSchema.h:12-13`), y el motor headless lee el almacén, no el plist.

### 8.4 El futuro que esto desbloquea

El texto introducido almacenado es la superficie de entrada natural para el diseño de consultas dirigido por agentes en
el horizonte del producto (`MAD_FUTURE.md`): un agente — o una persona — escribe una sentencia, el
compilador de abajo la convierte en el documento, y `sqlSourceText` conserva el prompt de registro.
La arquitectura estricta de modelo compilado es lo que hace que eso sea paso a paso: nada del
compilador cambia cuando el escritor se convierte en un agente.

## 9. Fases

**Fase A — el texto fuente persistido: versionado del almacén (solo MAD; Linux en verde).**
1. `sqlSourceText` en `RptqQuery`: modelo compilado + descriptores `MADStoreSchema` + propiedad autogen,
   en un solo cambio (la prueba de verificación cruzada falla en caso contrario).
2. El mecanismo de versionado de §8.2 — constante de versión, lista de migración, lectura/aplicación/escritura de
   `user_version` al abrir, almacenes nuevos en la versión actual.
3. Pruebas: `MADStoreSchemaTests` sigue en verde en ambos lados; nuevas pruebas de migración (§10.2);
   `MAD_FORMAT.md` actualizado.

Aceptación: un documento creado antes de esta fase se abre limpiamente, gana la columna, conserva sus
datos, y hace ida y vuelta a través de Linux; un documento nuevo nace en la versión actual. Esta
fase es autocontenida — aterriza antes, e independientemente, del analizador.

**Fase B — pruebas golden, luego el analizador (solo MAD; Linux en verde).**
4. Pruebas golden de SQL que fijan la salida exacta de `MADQueryFull` por dialecto (§10.1) — escritas
   primero, para que el analizador se construya contra el generador real.
5. `MADSQLTokenizer`/`MADSQLParser`/`MADSQLStatement` + la API de entrecomillado de identificadores (§4).
6. `MADSQLParserTests` — la matriz de aceptación/rechazo de §5, códigos de error, línea:columna.

Aceptación: toda construcción admitida que `MADQueryFull` pueda emitir se analiza; toda construcción rechazada
falla con un error codificado y posicionado; suite MAD y `./Linux/build.sh` en verde.

**Fase C — resolutor + compilador (solo MAD; Linux en verde).**
7. `MADSQLStatementResolver`, `MADSQLQueryCompiler` con aplicación atómica (§6) y la
   escritura de `sqlSourceText` en caso de éxito (§8).
8. Inventario de ayudantes de eliminación; añadir los ayudantes de eliminación de vínculos/predicados faltantes.
9. `MADSQLQueryCompilerTests` + la prueba de ida y vuelta de punto fijo (§10.4).

Aceptación: aplicar una sentencia produce exactamente las filas Rptq que el diseñador visual
habría producido, y almacena el texto textualmente; aplicar sobre una consulta existente no deja huérfanos; el
caso de conflicto aborta con el almacén — y el texto anterior — intactos; la prueba de punto fijo
pasa.

**Fase D — la aplicación (MADDesigner).**
10. El popover View/Edit de §3, la sonda `MADOperationValidateSQL`, la vista de resumen.
11. Pruebas de interfaz (§10.6) usando un documento de ejemplo (controlador sqlite3 — sin servidor necesario).

Aceptación: pegar → validar → aplicar muestra las tablas/uniones/predicados en el diseñador de consultas
y la visualización, las secciones de grupo en el diseñador de informes, y la actualización ejecuta la consulta; View
muestra tanto el SQL generado como el texto introducido; cerrar y reabrir el documento conserva
el texto introducido.

**Fase E — diferida, con sus propias decisiones.**
* Materialización de la lista SELECT: sintetizar elementos del diseñador (etiquetas de datos, agregados) para que
  la actualización devuelva exactamente las columnas pegadas. Hasta entonces, una consulta importada se comporta como cualquier
  documento nuevo — el SELECT se deriva de elementos, uniones y grupos (§2.1).
* Un historial de sentencias aplicadas, si alguna vez se quiere: una relación de uno a muchos ordenada rellenada desde el
  `sqlSourceText` actual (§8) — el compañero natural del diseño de consultas dirigido por agentes de
  §8.4.

## 10. Pruebas

### 10.1 Fijar la funcionalidad existente (escritas primero)

* **Pruebas golden de SQL** en `MAD/MADTests` (extendiendo `MADQueryFullTests.m`, que hoy
  solo afirma fragmentos, `MADQueryFullTests.m:140-162`): fixtures de almacén fijos → cadenas de SQL
  esperadas exactas, por dialecto de controlador (configuraciones MySQL, TDS y PostgreSQL), cubriendo la nomenclatura de alias
  y la forma de índice de drop, cada tipo de unión, cada operador de predicado con entrecomillado de literales,
  y el orden de campos activos. Estas fijan el generador con el que el analizador debe hacer ida y vuelta, y
  también se ejecutan en la imagen de Linux.
* **El contrato de ida y vuelta** — véase la prueba de punto fijo abajo; fija generador ∪ importador
  como un solo sistema.

### 10.2 Pruebas de persistencia y migración del almacén

* `MADStoreSchemaTests` — la verificación cruzada existente ahora afirma que los descriptores y el
  modelo compilado coinciden en `sqlSourceText` (es la prueba que obliga a que los dos lados de
  §8.1 aterricen juntos).
* Nuevo `MADStoreMigrationTests` (MAD): construir un almacén en disco en la versión 1 (el esquema tal como
  está hoy, `user_version` ausente) con filas dentro → abrir con el nuevo `MADStore` → la
  columna existe, `user_version` lee la versión actual, y cada fila y relación preexistente
  sobrevive; un almacén nuevo se crea en la versión actual; abrir dos veces es
  idempotente. Estas también se ejecutan en la imagen de Linux, ya que el motor headless comparte el
  código de migración.
* Afirmaciones a nivel de compilador (en §10.4): una aplicación exitosa almacena el texto **textualmente** —
  comentarios, espacios en blanco, mayúsculas — y una aplicación en conflicto deja el texto anterior intacto.

### 10.3 Pruebas del analizador — `MADSQLParserTests` (MAD)

* Lexer: identificadores entrecomillados por dialecto, literales de cadena con comillas escapadas, comentarios
  (`--`, `/* */`), números, operadores, palabras clave sin distinguir mayúsculas; posiciones en los errores.
* Analizador: la matriz de aceptación completa de §5 (tabla única, cada tipo de unión, cadenas de uniones, alias
  incluido el índice de drop, columnas simples y calificadas, conjunciones WHERE, GROUP BY,
  ORDER BY ⊆ GROUP BY) y la tabla de rechazo (OR, IN, LIKE, subconsulta, UNION, DISTINCT,
  expresiones en SELECT, ON multicondición, renombrados de alias, uniones por comas, NATURAL/CROSS,
  LIMIT, tabla/columna desconocida, columna ambigua, ORDER BY fuera de GROUP BY) — cada una afirmando
  el **código** de error y la línea:columna, nunca solo el mensaje.

### 10.4 Pruebas del compilador — `MADSQLQueryCompilerTests` (MAD)

Almacén en memoria con un fixture de esquema (el patrón que usa `MADModelQueryTableTests`):

* Camino feliz: aplicar → afirmar las filas Rptq resultantes — tablas con referencias de esquema correctas y
  filas por campo, vínculos con `MADLinkType` correcto y campos izquierdo/derecho, predicados con
  `comparson` y cadenas de valor correctos, grupos con orden/peso **y** las secciones de encabezado/pie de grupo
  creadas y los gestores de diseño; guardado una vez; `sqlSourceText` es igual a la sentencia de entrada
  exactamente (comentarios y espacios en blanco incluidos).
* Ruta de reemplazo: aplicar sobre una consulta poblada → las tablas/vínculos/predicados/grupos antiguos desaparecen, sin
  filas huérfanas (contar por entidad), la nueva estructura presente, y `sqlSourceText` reemplazado.
* Ruta de conflicto: un elemento del diseñador que referencia el campo de una tabla descartada → error, y una
  instantánea antes/después muestra el almacén sin cambios — incluido el `sqlSourceText` anterior.
* **Ida y vuelta de punto fijo**: construir un modelo a través de las fábricas → generar SQL mediante
  `MADQueryFull` → analizar → compilar en un almacén nuevo → generar SQL de nuevo → las dos cadenas
  de SQL son iguales. Esta es la prueba que *define* "el software reconoce lo que se
  pegó."

### 10.5 Pruebas de validación

* Construcción del SQL de sonda por controlador (unitaria, en el objetivo de pruebas de la aplicación): el contenedor, el
  alias, el plegado `WHERE 1=0` — con una base de datos simulada, sin servidor.
* **Pruebas en vivo** al estilo de `MADMySQLLiveTests.m` (se omiten cuando no hay servidor): el SQL pegado válido
  sondea limpiamente con los nombres/tipos de columna esperados; una columna mala devuelve el error
  del servidor; se leen cero filas.

### 10.6 Pruebas de interfaz — `MADDesignerUITests`

Con un `.mad` de ejemplo (controlador sqlite3): abrir el popover SQL, cambiar a Edit, pegar una
unión de dos tablas con un filtro y un grupo, Apply, luego afirmar que la lista de tablas de consulta muestra
ambas tablas, el lienzo de visualización muestra dos cajas y un conector, el diseñador muestra
las secciones de grupo, y el modo View muestra el SQL regenerado. Luego cerrar y reabrir el
documento: la pestaña **As entered** sigue mostrando el texto pegado exacto, y la pestaña **Generated**
sigue mostrando el SQL de la consulta compilada — el documento conservó ambos.

### 10.7 Restricciones de diseño para pruebas (vinculantes para los implementadores)

* Analizador/resolutor/compilador: Foundation puro, sin UIKit, sin importaciones de la aplicación — las suites MAD y la
  imagen de Linux los compilan.
* Cada fallo público es un `NSError` codificado (`MADSQLCompileError`); las pruebas afirman códigos.
* La sonda va detrás de un pequeño protocolo para que las pruebas unitarias simulen la base de datos; la cobertura en vivo
  vive solo en las suites en vivo (el patrón existente).
* El compilador toma el documento/contexto, nunca un controlador de vista; la aplicación no pasa nada
  con forma de interfaz.
* Los archivos nuevos de MAD se añaden a `Linux/cmake/MADSources.cmake`; `./Linux/build.sh` sigue en verde.
* El mecanismo de migración vive en el código compartido de `MADStore` con una constante de versión a la que las pruebas pueden
  hacer referencia — nunca en rutas solo de Apple — para que las suites de Linux lo ejerciten.

## 11. Decisiones — resueltas con el usuario (2026-10-22)

1. **Subconjunto estricto.** Confirmado: cualquier cosa que el modelo no pueda contener se rechaza con una razón
   (§5). Sin respaldo de SQL opaco.
2. **Apply reemplaza la consulta** (atómica, §6.3). Confirmado.
3. **La importación de GROUP BY crea las secciones de grupo del informe** automáticamente — el ayudante
   existente de `MADocument` hace esto, y se queda exactamente como está. Confirmado.
4. **La lista SELECT se valida, no se almacena, hasta la fase E** — hasta que exista la síntesis de elementos,
   una consulta importada devuelve columnas de unión/grupo al actualizar hasta que el usuario añade
   elementos, exactamente como cualquier documento nuevo. Confirmado como por fases.
5. **El texto pegado se persiste.** Confirmado — `sqlSourceText` en `RptqQuery`, una única
   propiedad que contiene la última sentencia aplicada con éxito (§8), mostrada como **As entered**
   junto a **Generated**. La forma generada sigue siendo lo que ejecuta la actualización; nada de que
   se almacene el texto cambia la ejecución. Se consideró un arreglo de historial y se dejó de lado
   (§8, fase E).
