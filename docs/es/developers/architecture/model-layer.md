---
layout: default
title: "La capa MADModel"
description: "El modelo de lectura del documento sobre las entidades Rptq, y cómo se mantiene actualizado."
lang: es-419
---

# MADModel — la capa de modelo de lectura del documento

Esta página describe `MADModel`, el modelo de lectura sobre las entidades `Rptq`: qué es cada clase, cómo se llena y se mantiene actualizada, y quién la lee.

*Escrito en la fecha original; los hechos del estado actual se conciliaron el 2026-11-22.*

**Alcance:** `MAD/Source/model/MADModel*.{h,m}`, `MAD/Source/model/MADTableFieldIdentifier.{h,m}`, y cada
consumidor de la capa en `MAD` y `MAD Designer`.
**Fecha:** 2026-10-16, leído en `d7faff320`.
**Estado:** referencia. Todo aquí se leyó de primera mano en ese commit; los candidatos de refactorización de §7 son propuestas y no están aplicados.

---

## 1. Qué es la capa

`MADModel*` es una **vista de solo lectura, con alcance de documento, de la definición del documento** — la
conexión, el esquema (tablas y campos) y el grafo de consulta (qué tablas usa la consulta,
qué campos, y las uniones entre ellos). Es a lo que se enlaza la interfaz de consulta del diseñador.

*No* es el modelo canónico. El modelo canónico es el grafo de objetos `Rptq*` en el
almacén portable: es lo que la aplicación edita, guarda, convierte y renderiza. Un objeto `MADModel*` es
poco más que **un identificador de fila del almacén (`int64_t`) más un puntero débil al
`RptqStoreContext` más algunos valores de presentación copiados**, resueltos de forma perezosa obteniendo filas con
`objectsForEntity:identifier:`.

La regla empírica que sigue el código:

> **Escribe a través de `Rptq`; lee y observa a través de `MADModel`.**

Las dos capas comparten un espacio de identificadores: el `identifier` de un objeto de modelo *es* el
`identifier` de la fila del almacén. Ese es todo el pegamento — véase §3.

```
MADModelDocument                       one per open .mad — MADocument.documentModel
 └ databases: [MADModelDatabase]       (today: exactly one)
    ├ driverID / driverType / schemaName   ← RptqDatabase + RptqDatabaseCredentals
    ├ tables / tableDictionary : {id → MADModelTable}      ← RptqDatabaseSchemaTable
    │   └ MADModelTable  (name, queryable)
    │      └ fields / fieldIDs : {id → MADModelField}      ← RptqDatabaseSchemaField
    │         └ MADModelField (name, dataType, decimals, width, primaryKey)
    └ queries: [MADModelQuery]         (today: exactly one; `firstQuery` everywhere)
       └ MADModelQuery
          ├ queryTableIDs / tables : {id → MADModelQueryTable}   ← RptqQueryTable
          │   └ MADModelQueryTable  (schemaTable id, dropIndex, alias)
          │      └ queryFields : {id → MADModelQueryField}       ← RptqQueryField
          │         └ MADModelQueryField (schemaTable + schemaField ids)
          └ queryLinkIDs / links : {id → MADModelQueryLink}      ← RptqQueryLinks
              └ MADModelQueryLink   (left/right table+field ids — one join)
```

## 2. Las clases

### 2.1 `MADModel` — identidad (`MADModel.h`, `MADModel.m`)

La clase base es solo identidad: `_uid` (`MADModel.m:32-64`), con `hash`, `isEqual:` (misma
clase y mismo `_uid`) y `-objectID` devolviendo el id encajado en un `NSNumber`.
`+[MADModel newModelDocument:]` (`MADModel.m:35`) es la fábrica nominal — nadie la llama;
`MADocument` asigna `MADModelDocument` directamente. `MADModelType.h` define
`MADModelTypeUnknown/Document/Database/Queries`; nada en el árbol usa el enum.

El nombre `objectID` y un `debugDescription` comentado que formatea
`_objectID.URIRepresentation` son la señal de la edad de la capa: los objetos solían envolver
`NSManagedObjectID`s (véase §5).

### 2.2 `MADModelDocument` — la raíz (`MADModelDocument.h`, `.m`)

- Creado una vez por documento abierto por `-MADocument.documentModel`
  (`MADocument.m:389-395`), de forma perezosa, sobre `self.storeContext`. Nada más en producción
  construye uno; el delegado de la aplicación no participa en ello.
- Contiene `databases` (construido por `-updateDocumentDatabaseQuery`, `MADModelDocument.m:210-240`:
  un `MADModelDatabase` *por cada fila de `RptqQuery`* — "base de datos" aquí significa la conexión más su
  esquema más una consulta) con accesores de conveniencia `firstDatabase` / `firstQuery`. El código
  dice por qué el plural es teatro: *"current versions of the software only use one database and
  query"* (`MADModelDocument.m:207-208`).
- **Se registra para las notificaciones de cambio del almacén** (`RptqStoreContextObjectsDidChange`,
  `WillSave`, `DidSave`, `MADModelDocument.m:160-176`) en una `NSOperationQueue` privada
  (`MADModelDocument.m:83-87`, `_objectContextQueue`). Al insertar o eliminar una fila `RptqQueryTable`
  o `RptqQueryLinks`, refleja el cambio en `firstQuery` — véase §3.3.
- `-update` (`MADModelDocument.m:201-205`) vuelve a ejecutar el escaneo documento→base de datos→consulta y
  *reemplaza* `_databases` con objetos nuevos.

### 2.3 `MADModelDatabase` — conexión, esquema y consultas (`MADModelDatabase.h`, `.m`)

- Tiene como clave el identificador de la fila `RptqDatabase`.
- Los metadatos se resuelven *a través del almacén, propiedad por propiedad*: `driverType`
  (`MADModelDatabase.m:157-164`), `schemaName` (`:166-173`) y `driverID` (`:175-182`) cada uno
  obtiene perezosamente el `RptqDatabase` y lee a través hasta `RptqDatabaseCredentals`. `schemaName`
  y el `driverName` roto (§6) responden ambos con el `dbname` de las credenciales.
- `tables` / `tableDictionary` (`-updateTables`, `MADModelDatabase.m:221-247`) listan cada
  `RptqDatabaseSchemaTable` cuyo `inDatabase` coincide, **ordenados por nombre** — restaurando el
  orden que aplicaba una obtención anterior a la migración, con un comentario que apunta a BUGS.md.
- `queries` (`-updateQueries`, `:249-261`) hace lo mismo para las filas `RptqQuery`.

### 2.4 `MADModelTable` / `MADModelField` — el esquema (`MADModelTable.{h,m}`, `MADModelField.h`)

- `MADModelTable` cachea `name`, y construye perezosamente `fields` / `fieldIDs`
  (`MADModelTable.m:120-146`) a partir de las filas `RptqDatabaseSchemaField` cuyo `inTable` coincide,
  ordenadas por nombre. `MADModelField` es un valor simple: nombre, indicador de clave primaria, tipo de datos,
  tipo nativo, decimales, ancho — sin acceso al almacén.

### 2.5 `MADModelQuery` — una consulta (`MADModelQuery.h`, `.m`)

La clase más grande, y la que realmente se gana su lugar. Posee:

- `queryTableIDs` + `tables` (`MADModelQuery.m:213-283`): cada `RptqQueryField` cuyo
  `inQueryTable.inQuery` es esta consulta se proyecta a un diccionario
  (`MADStoreProjectionForQueryField`, `:59-68`) — la forma exacta que producían las proyecciones de
  obtención antiguas de Core Data — y se pasa a `-insertTablesFromFetchRequestResults:`.
- `queryLinkIDs` + `links` (`:302-344`): lo mismo para `RptqQueryLinks`
  (`MADStoreProjectionForQueryLink`, `:70-78`).
- Ayudantes de topología: `-tablesInLinks` (`:183`) y `-orphanedQueryTables` (`:196`, las tablas
  que ninguna unión toca, mediante una resta de conjuntos con `NSExpression`).
- **La superficie de mutación**: `-insertQueryTable:` / `-insertQueryLink:` /
  `-deleteQueryTableID:` / `-deleteQueryLinkID:` y las variantes basadas en id. Cada una aplica el
  cambio a las colecciones y luego vuelve a publicar `MADNotificationQueryTableInsert/Delete` o
  `MADNotificationQueryLinkInsert/Delete` (nombres en `MADModel.h:22-26`) **en la cola principal**
  mediante `[NSOperationQueue mainQueue] addOperationWithBlock:`, con el objeto de modelo afectado en
  el `userInfo`. Estas notificaciones son el flujo de eventos público de la capa; el diseñador
  se suscribe a ellas (§4).

### 2.6 `MADModelQueryTable` / `MADModelQueryField` — las tablas y campos de la consulta

- `MADModelQueryTable` (`MADModelQueryTable.m`) cachea `dropIndex` y el id de la tabla de **esquema**,
  y mantiene perezosamente `queryFields` / `queryFieldIDs` (construidos por `-addField:schemaField:`, `:92`).
  `-alias` (`:119-129`) es el nombre de cara al SQL: el nombre de la tabla de esquema para la primera copia y
  nombre + índice de drop después (`Customer`, `Customer0`, …).
- `MADModelQueryField` (`MADModelQueryField.m`) son dos ids: la tabla de esquema y el campo de esquema.
  `-schemaField` (`:52-57`) resuelve los metadatos reales recorriendo
  base de datos → `tableDictionary[schemaTable]` → `fields[schemaField]`. Esa cadena —
  unión → tabla de consulta → tabla de esquema → campo de consulta → campo de esquema — es el patrón
  definitorio de la capa; `MADQueryVisualizationViewController.m:1024-1048` lo realiza a mano para colocar un
  conector.

### 2.7 `MADModelQueryLink` / `MADTableFieldIdentifier`

- `MADTableFieldIdentifier` (`MADTableFieldIdentifier.{h,m}`) es un pequeño par de valores
  (id de tabla + id de campo) con accesores `NSNumber`.
- `MADModelQueryLink` (`MADModelQueryLink.m`) contiene un `MADTableFieldIdentifier` para cada extremo,
  construido ya sea desde ids crudos o desde una fila `RptqQueryLinks` (`-initWithRptqQueryLink:`,
  `:60-76`, que lee `hasLeftField.inQueryTable.identifier` / `hasLeftField.identifier`).
  `-isAdjacentToQueryTable:` (`:78`) y `-tables` (`:82`) responden las preguntas de grafo que hace la
  visualización.

### 2.8 Los protocolos y las piezas vestigiales

- `MADModelIDProtocol` — cuatro líneas: `identifier` (`MADModelIDProtocol.h`).
- `MADModelDataProtocol` (`MADModelDataProtocol.h`) — `managedObjectContext`,
  `-initWithIdentifier:managedObjectContext:` y `-update`. En la práctica `-update` es un
  gancho de actualización interno: solo se llama desde los propios getters perezosos de la capa
  (`MADModelDocument.m:188`, `MADModelTable.m:99` y `:115`). `MADModelDatabase -update`
  (`MADModelDatabase.m:148`) y `-MADModelQuery -update` (`MADModelQuery.m:354`, un método vacío)
  no tienen ningún llamador.

## 3. Ciclo de vida

### 3.1 Creación

`MADocument` construye un `MADModelDocument` de forma perezosa (`MADocument.m:389-395`) y lo conserva durante
toda la vida del documento. Contiene el `RptqStoreContext` **débilmente**
(`MADModelDocument.m:42`), como cada objeto de modelo que mantiene un contexto — el contexto del almacén es
propiedad del documento.

### 3.2 Población

Todo lo que está debajo del documento es **perezoso y cacheado**: la primera lectura de `databases`, `tables`,
`fields`, `queryTableIDs`, `queryFields` o `links` dispara una pasada de obtención y filtrado
(`objectsForEntity:` sobre la entidad Rptq relevante, filtrada por el identificador del padre, y luego
ordenada donde una obtención anterior a la migración ordenaba). Las cachés solo se invalidan llamando a
`-update` o por la ruta de notificación siguiente; nada expira por sí solo.

### 3.3 Cambios en vivo — el viaje de ida y vuelta

Añadir una tabla o una unión en el diseñador escribe **filas de Rptq** (por ejemplo, el flujo de añadir tabla en
`MADQueryViewController.m:745-790` crea filas `RptqQueryTable` + `RptqQueryField` y guarda
el contexto). El modelo luego se pone al día por sí solo:

```
user adds a table / link
  → RptqQueryTable / RptqQueryLinks rows written + saved
    → RptqStoreContextObjectsDidChangeNotification
      → MADModelDocument's observer (on its private queue)     MADModelDocument.m:91-158
        → [firstQuery insertQueryTable:/insertQueryLink:]       MADModelQuery.m:361-410
          → MADNotification…Insert/Delete reposted on main      MADModelQuery.m:361-514
            → MADQueryVisualizationViewController, MADQueryBuilderAddTableViewController
```

Hay dos colas en juego: el modelo *muta* en `_objectContextQueue` (una `NSOperationQueue`
privada, `MADModelDocument.m:83-87`) y las notificaciones *llegan* en la cola principal.
Las colecciones mismas no están sincronizadas.

### 3.4 Obsolescencia

`-update` (documento o base de datos) reconstruye las colecciones con objetos de modelo **nuevos**; cualquier objeto de modelo
entregado antes sigue funcionando para lo que cacheó, pero ya no es el que está en
`firstQuery.tables`. Nada en el árbol llama a `-update` sobre un objeto de modelo hoy — la
ruta de notificación es la viva — pero el código que almacena objetos de modelo a través de un `-update`
estaría leyendo entradas obsoletas.

## 4. Consumidores

### 4.1 La pestaña Query (constructor de consultas ad hoc)

- `MADQueryViewDataSource.m:365` — la celda de encabezado del origen de datos: "You are connecting to
  *driverID* datasource named *schemaName*" desde `firstDatabase`.
- `MADQueryViewDataSource.m:533-546` — la lista de tablas de consulta toma `firstQuery` y usa
  `query.identifier` para filtrar filas `RptqQueryTable`. Nota el patrón: **el modelo suministra
  identidad y metadatos; las filas mismas son objetos Rptq.**
- `MADQueryTableViewController.m:163-174` — el título de la caja de una tabla de consulta viene de
  `firstQuery.tables[id].alias`; `:186-200` y `:239-266` renderizan la lista de campos de esquema desde
  `firstDatabase.tableDictionary[schemaTableID]` → `fieldIDs` / `fields`. Este es el modelo de contenido
  completo del navegador de esquema.
- `MADQueryBuilderAddTableViewController.m:29-33` — observa las notificaciones de inserción/eliminación del modelo
  para mantener su panel de tablas actualizado.

### 4.2 La pestaña Query Visualization (cajas y conectores)

- `MADQueryVisualizationModel` (`MADQueryVisualizationModel.m:40-77`) construye un `MTGraph` mediante
  `-[MTGraph initWtthQueryID:]` (`MTGraph+RptqQuery.m:39-67`), que está escrito **enteramente sobre
  el modelo**: `query.queryTableIDs` se convierten en vértices, `query.links` se convierten en aristas. Luego
  ordena topológicamente, calcula `startingPoints` (tablas a las que ninguna unión apunta *hacia dentro*) y almacena
  la bandera DAG. (La misma categoría también tiene inicializadores basados en el almacén, `:69-93`, anteriores a la
  ruta del modelo; la visualización usa la del modelo.)
- `MADQueryVisualizationViewController` (`MADQueryVisualizationViewController.m`) es el principal
  consumidor del flujo de notificaciones: se suscribe a las cuatro notificaciones del modelo
  (`:314-335`), añade y elimina cajas y conectores a medida que llegan, vuelve a marcar las tablas raíz después de
  eliminar una unión usando `-orphanedQueryTables` (`:936`), pide `-linksForQueryTable:` por tabla
  (`:644`), y dispone cada conector recorriendo la cadena de identificadores
  (`:1024-1048`, §2.6).
- `MADQueryVisualizationCacheManager` persiste el diseño del lienzo con clave por identificadores del modelo
  (`updateCacheWithQuery:…`, `MADQueryVisualizationCacheManager.h:20`).

### 4.3 El documento y las pruebas

`MADocument.documentModel` es el único punto de entrada de producción. Pruebas:
`MADDocumentTests.m:263-265` (`databases`/`queries` de un documento reabierto),
`MADDocumentTests.m:399-404` (el orden de tablas/campos de un `MADModelDatabase`), más las suites dedicadas
`MADModelQueryTableTests`, `MADModelQueryFieldTests` y la cobertura de `MADModelField` /
`MADModelQueryLink` en `MADModelValueTypesTests`.

### 4.4 Qué *no* la usa

- **Generación de SQL** — `MADQueryFull` y las clases `Rptq*+Extras` trabajan en la capa Rptq
  (p. ej., `RptqQueryField+Extras.m:137` construye nombres `table.field` desde `RptqQueryTable.alias`).
- **Diseño y renderizado** — `MADDesignerLayout` y la ruta del informe trabajan sobre
  `RptqDocumentElement`; `MADReportFormatter` no usa la capa en absoluto (sus tres
  importaciones `MADModel*` en `MADReportFormatter.m:18-20` están obsoletas).
- **Datos de fila** — nada de esto toca la caché `.maddb`; ese es territorio de `MADDataTableFast` /
  `MADReportFormatter`.

Así que el alcance real de la capa hoy es: **el lado de consulta del diseñador, y nada más.**

## 5. Por qué existe

La capa es de principios de 2017 (encabezados de archivo `1/22/17`–`6/3/17`) y se construyó en la era
de Core Data como un **modelo de vista hecho a mano para la interfaz de consulta**: objetos ligeros a los que las vistas de tabla
del diseñador y el lienzo de visualización podían enlazarse, en lugar de `NSManagedObject`s y
`NSFetchedResultsController`s. La evidencia está en los archivos: `-objectID`, el comentado
`debugDescription` de `NSManagedObjectID` en `MADModel.m:66-80`, y tres comentarios supervivientes que
dicen "was an `NSFetchedResultsController`" (`MADQueryChooseFieldController.m:149`,
`MTGroupByViewController.m:53`, `MADTableViewControllerCoreDataResults.h:14`).

La migración del almacén (Fase C/D de `MAD_STORE_MIGRATION.md`) recableó cada obtención de Core Data
a `RptqStoreContext` + `objectsForEntity:` **sin cambiar la superficie de esta capa** — que es
por lo que `MIGRATION_KICKOFF.md` §Findings la llama "[a] clean `MADModel*` domain layer [that]
already wraps the `Rptq` entities; it is the seam to keep."

Así que es MVC de un tipo, pero no "el modelo de la aplicación": es un **modelo de lectura por documento** (el
"modelo" de MVC tal como lo ve el controlador), y los objetos de dominio canónicos son el grafo Rptq. La
abstracción compra tres cosas y es delgada en todo lo demás: (1) el grafo de consulta en una forma
orientada a la presentación (alias, adyacencia, búsquedas de id a metadatos) sin recorrido
de relaciones; (2) un solo lugar que convierte las notificaciones de cambio del almacén en eventos del grafo de consulta;
(3) una interfaz que la interfaz de usuario podría mantener intacta mientras el almacén debajo cambiaba por completo —
que es exactamente lo que ocurrió.

## 6. Aristas ásperas conocidas

Leídas de primera mano; ninguna tiene un consumidor hoy, así que todas son latentes.

1. `MADModelField.inTable` (`MADModelField.h:20`) está declarado `weak MADModelField *` — el
   tipo es incorrecto (debería ser `MADModelTable *`) — y nada lo asigna nunca.
2. Los otros punteros inversos al padre están igual de sin usar: `MADModelTable.inDatabase`,
   `MADModelQueryTable.inQuery` y `MADModelQueryField.inQueryTable` nunca son asignados por
   ninguna ruta de código en el árbol. Solo `MADModelQuery.inDatabase` se establece alguna vez
   (`MADModelQuery.m:108-114`). (Que `-addField:schemaField:` no cablee el puntero inverso de su campo
   ya está registrado en BUGS.md.)
3. `MADModelDatabase -driverName` (`MADModelDatabase.m:184-215`) termina en `return @"";`, así que
   responde la cadena vacía incluso después de cachear el nombre real; `-schemaName` ya devuelve
   la misma cadena desde el mismo lugar. No existe ningún lector.
4. `MADModelDocument.m:228-234` decodifica un id de documento (`docID`) y nunca lo usa.
5. `MADModelQuery -update` (`MADModelQuery.m:354`) está vacío; `MADModelDatabase -update` no tiene
   llamadores; `+[MADModel newModelDocument:]` no tiene llamadores.
6. `MADModelType` no se usa.
7. No hay sincronización entre la cola privada que muta el modelo y los lectores
   del hilo principal; y `MADModelDocument` mantiene el contexto del almacén débilmente, así que un modelo que sobreviva a su
   documento no tiene contexto para resolver nada.
8. Nomenclatura: un `MADModelDocument` tiene `databases`, y un `MADModelDatabase` tiene `queries` — pero
   el documento construye una "base de datos" *por consulta* y hoy hay exactamente una de cada una. La
   estructura es preparación para el futuro de antes de la simplificación a una base de datos/una consulta.

## 7. Candidatos de refactorización (propuestas — ninguno aplicado)

Ordenados por valor sobre riesgo. A y B son pura limpieza; C cambia lo que promete un encabezado público;
D es una decisión.

**A. Documentación, no consolidación.** La victoria de claridad más barata son los comentarios de encabezado por clase
(2–4 líneas: qué es la clase, por qué está keyada, quién la lee) más este documento. Fusionar
los *archivos* de las clases es la opción cara, no la barata: más de dieciséis archivos importan los
encabezados por clase (`#import <MAD/MADModelQueryField.h>` etc.), cada encabezado es un archivo separado
en los objetivos de Xcode, y el shim de inclusión de la compilación de Linux es un directorio de enlaces simbólicos por encabezado
(`Linux/README.md`, el shim de MAD). Consolidar tocaría el pbxproj, las listas de fuentes de Linux
y cada sitio de importación por una ganancia estética. Si alguna vez se quiere alguna fusión, la dirección segura es
la opuesta: mantener una clase por archivo y hacer obvio el **punto de entrada** (documento al inicio de
`MADModel.h`, "start at `MADModelDocument`").

**B. Eliminar o completar la superficie vestigial.** Cada uno de estos es seguro para el comportamiento (nada
los lee) pero toca encabezados, así que trátalo como una decisión de API:
- `MADModelField.inTable`: corrige el tipo y establécelo en `MADModelTable -update` (una línea,
  simétrica con los otros padres), o elimina la propiedad.
- `MADModelDatabase -driverName`: devuelve el valor cacheado como sus hermanos, o elimínalo.
- `MADModelType`: elimina el encabezado. (Requiere la eliminación del archivo de proyecto; hazlo en un solo commit.)
- `+[MADModel newModelDocument:]`: o haz que `MADocument -documentModel` lo use (restaurando
  el propósito de la fábrica) o elimínalo.
- La decodificación `docID` sin usar en `MADModelDocument.m:228-234`.

**C. Cablear los punteros inversos declarados.** `inDatabase`, `inQuery` e `inQueryTable` existen para que el
grafo pueda recorrerse hacia arriba; hoy solo funcionan las búsquedas hacia abajo. Asignarlos en la construcción
(`MADModelDatabase -updateTables` ya tiene `self`; `insertTableRptqQueryTable:` tiene la
consulta de modelo; `-addField:schemaField:` tiene la tabla) hace que el grafo de objetos coincida con sus encabezados
y es seguro precisamente porque nada los lee todavía. Semántica a tener en cuenta: se
declaran `weak`, que es correcto para padres de propiedad descendente.

**D. Identidad a través de las actualizaciones (una decisión, no un arreglo).** `-update` reemplaza objetos; si
alguna vez se quiere identidad estable a través de las actualizaciones, los métodos de actualización deben mutar en el lugar
(reutilizar el objeto para un identificador, añadir/eliminar la diferencia) en lugar de reconstruir. Eso
cambia la identidad observable de los objetos entregados, así que necesita una elección deliberada.

**E. Deduplicación mecánica.** `MADModelTable.fields` y `-fieldIDs` (`MADModelTable.m:88-118`)
contienen el mismo bloque de inicialización dos veces, y los tres getters de `MADModelQuery` repiten la
misma danza de "asegurar colecciones, luego actualizar" (`MADModelQuery.m:116-181`). Ambos pueden colapsar
en un solo ayudante privado cada uno sin cambio de comportamiento; vale la pena hacerlo solo cuando el archivo esté abierto
por otra cosa.

**F. NO recomendado: renombrar.** `MADModelDatabase` → algo como `MADModelConnection`
se leería mejor, pero los renombrados aquí son agitación a través de los archivos de proyecto de Xcode/Linux sin
beneficio funcional.

## 8. Si cambias esta capa

- Mantén el contrato de solo identificadores: un objeto de modelo debe seguir siendo construible solo desde ids
  (eso es de lo que dependen la ruta de notificación y las pruebas).
- Cualquier cosa que cree o elimine filas `RptqQueryTable` / `RptqQueryLinks` es recogida por
  el observador de `MADModelDocument` automáticamente — pero solo para las filas alcanzadas a través de
  `firstQuery`; una segunda consulta en un documento no se refleja.
- Los cuatro nombres `MADNotification…` son la API pública de la capa para la interfaz de usuario; obsérvalos
  contra el objeto `firstQuery`, como hace `MADQueryVisualizationViewController`.
- La suite de iOS (esquema `MAD`) y `./Linux/build.sh` compilan ambos estos archivos; véase
  `Linux/cmake/MADSources.cmake`.
