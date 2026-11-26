---
layout: default
title: "Informes multi-origen"
description: "Informes como tablas, y controladores para cualquier cosa que devuelva una tabla."
lang: es-419
---

# Informes multi-origen — informes como tablas, y controladores para cualquier cosa

Esta página describe los informes componibles: el resultado de un informe se convierte en una tabla que otro informe puede consultar, y un controlador puede poner al frente cualquier cosa que devuelva filas. Es un registro de diseño; §8 nombra las fases, y no todas están construidas.

**Alcance:** la arquitectura que el usuario describió el 2026-11-22: un usuario diseña un informe
contra un origen de datos (MySQL, SQL Server, PostgreSQL, SQLite, o una API web como la
Seller API de eBay); el resultado de ese informe es una tabla SQLite materializada; y otro informe puede
diseñar una consulta contra ese informe — uniendo la salida de un informe a la salida de otro
informe, y a orígenes base, en un solo grafo de consulta. Al actualizar, el motor recorre el grafo
de abajo arriba, ejecuta cada hoja contra su propio origen, materializa cada resultado, y finalmente
ejecuta la consulta compuesta sobre las materializaciones. La costura del controlador no-SQL forma parte de
esto: un controlador que pone al frente una API recibe una consulta estructurada, no texto SQL, y devuelve
filas en forma de tabla.
**Fecha:** 2026-11-22, leído en `eba4225a1`; decisiones incorporadas el 2026-11-22 (§9.2).
**Estado:** informe de diseño. Enuncia la idea y el diseño; no implementa
nada y no añade trabajo a `TASKS.md`. La auditoría del código que fundamenta la
mitad de objeto de datos es [`MAD_DATA_OBJECT.md`](data-object.md); la dirección es
[`docs/vision.md`](../vision.md). Este documento añade el modelo de composición multi-origen
(primero subinformes dentro del mismo documento), la API de controladores que hace de primera clase a los orígenes no-SQL,
y un orden de fases combinado.

---

> **Modelo normativo:** el contrato de ejecución que motiva esta página se expresa ahora de
> forma normativa y en un solo lugar en
> [`MAD_COMPOSITION_SPEC.md`](../../project/design/MAD_COMPOSITION_SPEC.html). Donde esta página
> (o `data-object.md`) difiera de él, prevalece la especificación. La §0 de la especificación es
> **definitiva**: cada nodo de una composición es un informe completo con su propio diseño y
> datos, y la raíz es el informe predeterminado del documento, no el único visible. La frase de
> §3.2 paso 5 que solo menciona la raíz queda sustituida.

## 1. La idea, en una página

Un informe es una función de orígenes de datos a una tabla. La distinción cuenta-vs-pedido que
importa para este diseño ya está en el código:

- La **definición** es el grafo de consulta — tablas, campos, vínculos, predicados, agrupaciones —
  más el diseño por bandas. Vive en el archivo `.mad`.
- El **resultado** es un esquema (`MADDataColumn`s) y filas. Vive junto al documento en una
  caché SQLite complementaria (`.maddb` + `.mdcache`), fuera del archivo, porque es
  derivado y regenerable.

La extensión consiste en hacer que el resultado sea **direccionable como una tabla**. La salida de un informe entonces
se convierte en un origen para otro informe, exactamente como hoy una tabla de esquema es un origen. Un informe
construido sobre informes es un DAG de tablas derivadas: una capa semántica portable donde diseñar un
informe es también diseñar un origen de datos reutilizable.

La misma extensión hace naturales los informes multi-origen. Cada objeto de origen se ejecuta contra
su propia base de datos o API, con su propio controlador y credenciales, y se materializa en su propia
tabla SQLite. El objeto compuesto se ejecuta contra la **caché local**, no contra un servidor
remoto, uniendo las materializaciones. No se añade ningún motor de federación; las instantáneas son la
federación.

El ejemplo del usuario: una empresa quiere un informe de sus anuncios de eBay. Un objeto de informe
consulta la Seller API de eBay y materializa los anuncios; otro consulta la base de datos
MySQL de la empresa para las ventas; un informe compuesto une las dos salidas por SKU. Cada controlador solo
conoce su propio origen. La unión ocurre en SQLite, localmente.

El controlador no-SQL es lo que hace posible el primer objeto. Su contrato es el mismo
contrato de "esquema más filas" que satisfacen los controladores SQL — pero su entrada debería ser el grafo de consulta,
no una cadena SQL que tenga que analizar.

## 2. Qué ya es cierto en el código

Las partes caras existen. `MAD_DATA_OBJECT.md` §3 es la auditoría detallada; los hechos
fundamentales para este informe son:

1. **La definición es un grafo, y el almacén permite muchos.** `RptqQuery` posee tablas,
   campos, vínculos, predicados y grupos. `MADModelDocument` construye un `MADModelDatabase`
   por `RptqQuery`, con la propia nota del código de que las versiones actuales usan uno. La cardinalidad
   es una convención de los flujos de la aplicación, no del almacén (`MAD_DATA_OBJECT.md` §3.1).
2. **El compilador existe y es determinista.** `MADQueryFull -copySQLWithManagedObjectContext:error:`
   (`MAD/Source/MADQueryFull.m:133-273`) construye la lista SELECT, el árbol FROM/JOIN a partir de un
   grafo ordenado topológicamente, la cláusula WHERE y el límite, a través de los ganchos de dialecto
   del controlador.
3. **La costura de ejecución ya tiene forma de tabla.** El punto abstracto de `MADDatabase` es
   `executeSQL:fieldKeys:onConnection:intoResultTable:withError:`
   (`MADAPI/Source/MADDatabaseProtocol.h:33-34`), y el destino es cualquier
   `id <MADDataTableWriting>`, no una clase de tabla concreta. Los cuatro controladores lo llenan de la misma
   forma: eliminar todos los objetos, añadir columnas, inserción masiva, añadir filas.
4. **La materialización es una tabla SQLite real.** `MADDataTableFast` escribe
   `<tag>.maddb` y la tabla `t<tag>` (`MADSqlite3/Source/MADDataTableFast.m:403-406`,
   `:463-467`, `:503-511`). El plist de esquema es `.mdcache`; filas y esquema son separables
   (`docs/05-companion-files.md` §5). SQLite ya es un controlador
   (`MADSqlite3/Source/MADDatabaseSqlite3.m`), así que una consulta cuya "base de datos" es la caché es
   código de hoy, no código nuevo.
5. **La caché es desechable y por dispositivo.** No está en el documento ni en iCloud
   (`docs/05-companion-files.md` §5.2). Eso es correcto para un artefacto derivado, pero es una
   restricción para cualquier diseño que trate la caché de otro informe como origen: la caché puede
   no estar allí.

La misma sección nombra los tres puntos de cableado fijo de consulta única, y siguen siendo ciertos
hoy:

- `MADQueryFull` vuelve a leer la primera base de datos y la primera consulta del documento en lugar de usar
  la consulta con la que se inicializó (`MAD/Source/MADQueryFull.m:147-149`).
- `MADocument -dataTableForQuery:` es un switch de una sola ranura: devuelve la única tabla del documento
  para `MADQueryFull` y nil para todo lo demás (`MAD/Source/MADocument.m:873-880`).
- `MADQueryActiveQueryFields` escanea cada elemento, vínculo y grupo del almacén sin
  alcance de consulta (`MAD/Source/MADQueryActiveQueryFields.m:27-100`). Los campos de una segunda consulta
  se filtrarían en la lista SELECT de la primera consulta.

Dos hechos más importan para el diseño de composición:

- **La dirección es el hash del nombre de archivo.** El documento crea su tabla con
  `initWithId: self.fileURL.lastPathComponent.hash` (`MAD/Source/MADocument.m:273-275`), y
  el directorio de caché se nombra con ese hash. Nada puede apuntar a la tabla por una identidad
  estable.
- **Un `MADDataTableFast` es un archivo.** `filenameCacheMadDB` es `<tag>.maddb`
  (`MADSqlite3/Source/MADDataTableFast.m:403-406`), y cada instancia abre sus propias conexiones de inserción
  y selección (`:482-501`). No hay modo de "varias tablas en un `.maddb`" hoy.
  `MAD_DATA_OBJECT.md` §5.1 describe ese modo como una variante de diseño; la clase actual
  no lo implementa.
- **No hay soporte de `ATTACH`.** Una búsqueda en `MADSqlite3`, `MAD` y `CLI` no encuentra ningún
  uso de `ATTACH DATABASE`. La composición entre archivos necesita que se añada, o un paso de copia dentro.

## 3. El modelo de composición

### 3.1 Nodos y aristas

- Un **objeto de origen** posee un `RptqDatabase` (controlador + conexión + credenciales) y una
  definición de consulta. Se ejecuta contra su origen.
- Un **objeto compuesto** posee una consulta cuyas tablas son otros objetos de datos (de origen o
  compuestos). Se ejecuta contra la caché local. Un objeto compuesto no posee un
  origen remoto en este diseño: una tabla remota que necesita es un **objeto de origen** cuya salida
  referencia. Eso mantiene la taxonomía de nodos en dos tipos — hojas remotas y compositores locales —
  y mantiene honesta la caminata de actualización.
- Una **arista** es una referencia de tabla en una consulta compuesta a la salida de otro objeto.
- El grafo debe ser acíclico. Un ciclo es un error de diseño, informado en la referencia
  infractora, no un desbordamiento de pila al actualizar.

### 3.2 La actualización es topológica

1. Recorre el DAG de abajo arriba. El compilador existente ya ordena topológicamente el grafo de uniones
   (`MAD/Source/MADQueryFull.m:170-204`); el grafo de objetos necesita la misma disciplina a
   nivel de objeto.
2. Ejecuta cada hoja contra su propio origen, a través de su propio controlador, en su propia
   materialización.
3. Adjunta o abre las materializaciones que necesita el objeto compuesto.
4. Ejecuta la consulta compuesta contra la base de datos SQLite local y materializa su resultado.
5. Repite hacia arriba en el grafo. La raíz es un informe ordinario; su caché es lo que lee el visor.

La paginación no cambia. El motor sigue extrayendo el resultado completo en la caché local; la interfaz
pagina sobre la caché. Para un controlador de API, la "paginación" es un **bucle interno** sobre las
páginas de la API para llenar su materialización; no es un contrato de streaming o paginación con el
motor. El `limit`/`offset` del plan existen para vistas previas en modo diseñador y para un controlador que
quiera limitar su extracción, no para la paginación del visor.

La agrupación, la ordenación y los agregados no cambian: se calculan sobre la caché local
(`MAD_DATA_OBJECT.md` §3.5). El controlador devuelve filas de detalle; no necesita implementar
`GROUP BY` ni la agrupación del informe. Una sugerencia de orden en el plan permite que un controlador empuje una
petición top-N cuando hay un límite presente; el motor sigue reordenando.

### 3.3 Dos diseños de materialización

El instinto del usuario fue `ATTACH`, y el código actual lo convierte en la ruta más corta.

**Diseño A — un `.maddb` por objeto de origen, `ATTACH` para unir.**
- El `MADDataTableFast` de cada objeto conserva su propio `<tag>.maddb` y `t<tag>`.
- La consulta compuesta abre una conexión a la caché local (o a una base de datos en memoria) y
  ejecuta `ATTACH DATABASE '<path>' AS <alias>` por cada objeto de origen que necesita.
- La generación de SQL califica la tabla como `<alias>.t<tag>`.
- Trabajo nuevo: soporte de `ATTACH` en `MADDatabaseSqlite3`, gestión de alias y entrecomillado de rutas.
  La clase ya es un envoltorio SQLite completo, así que es una adición pequeña.
- Límites: el `SQLITE_MAX_ATTACHED` de SQLite es 10 por defecto, y ninguna receta de compilación del
  repositorio lo aumenta (`Compressor/sqlite3.xcconfig`, `Linux/`, `Windows/Engine/`). Aumentarlo
  es un cambio de compilación en tres plataformas. v1 trata más de diez orígenes directos como un
  error de diseño.
- El objeto compuesto mismo se materializa en su propio `.maddb`, como cualquier otro resultado.

**Diseño B — varias tablas en un `.maddb`.**
- Un archivo de caché por documento, varias tablas `t<tag>`, sin `ATTACH`.
- Esto requiere cambiar `MADDataTableFast` de "una instancia posee un archivo" a un modelo de archivo/conexión
  compartido, o añadir un registro de tablas por encima. Es un cambio más grande que
  `ATTACH`, y va en contra del diseño actual de un archivo por tabla de la clase.
- Su ventaja es un solo archivo y ningún límite de adjuntos.

**Recomendación:** el diseño A para la primera implementación de composición, porque sigue
el límite actual de la clase y coincide con el modelo del usuario. El diseño B sigue siendo la historia de archivos
más limpia a largo plazo si alguna vez se revisa el modelo de archivo por tabla.

### 3.4 Qué significa una referencia

La referencia de tabla de una consulta compuesta necesita un segundo tipo junto a `databaseSchemaTable`
(el actual `RptqQueryTable.databaseSchemaTable`, `MAD/Source/rptq/autogen/RptqQueryTable.h:27`).
La decisión del usuario (2026-11-22) es que la composición es **primero dentro del documento**: un `.mad`
contiene varias definiciones de informe/consulta — **subinformes** — y el informe compuesto
referencia uno por su identidad. Se preserva la propiedad de un solo archivo portable, y
el problema de reautorización entre archivos de iOS no surge para v1. Una referencia a un **informe en
otro archivo `.mad`** (una identidad de documento más una ruta) es una preocupación posterior y separada,
diferida detrás de la composición dentro del mismo documento.

La caché es por dispositivo y desechable, así que la referencia registra *qué ejecutar*, no *dónde
están los datos*:

- **Referencia viva (predeterminada).** El padre almacena la referencia de definición del hijo y, al
  actualizar, ejecuta el hijo y materializa su resultado.
- **Instantánea fijada.** El padre conserva la materialización del hijo en la caché complementaria
  (`.maddb`/`.mdcache`) y la reutiliza en lugar de volver a ejecutar el hijo. Fijar es un artefacto de caché
  conservado, **nunca datos incrustados en el `.mad`** — el archivo sigue siendo solo de definición
  (§6). Tanto lo vivo como lo fijado leen del directorio de caché; "fijar" significa "conservar y reutilizar
  esta materialización", no "copiar los datos al documento".

La nomenclatura de materialización pasa del hash del nombre de archivo a una identidad de objeto estable para que los archivos
no puedan chocar y un padre pueda direccionar a un hijo específico (§3.6, §6).

### 3.4.1 Cómo nombra el padre las columnas de un hijo

`RptqQueryField` tiene exactamente una referencia de campo, `databaseSchemaField`
(`MAD/Source/rptq/autogen/RptqQueryField.h:27`), y el constructor de select, el constructor de uniones,
los predicados y la interfaz de uniones leen todos `queryField.databaseSchemaField.name`. Las columnas de salida de un hijo
son `MADDataColumn`s, no campos de esquema. La recomendación es **sintetizar una
tabla de esquema de resultado y un conjunto de campos por objeto** a partir de los `MADDataColumn`s del hijo: los
campos de consulta del padre entonces apuntan a filas de campo de esquema ordinarias, y cada constructor
y interfaz existentes funcionan sin cambios. Las filas sintéticas son una instantánea del esquema de resultado del hijo y
se actualizan cuando cambia el esquema del hijo. La alternativa — un segundo tipo de referencia de campo
en `RptqQueryField` — toca cada constructor y no se recomienda. **Decisión del constructor.**

### 3.5 Fallo, obsolescencia y coordinación

- Si un hijo falla, la actualización del padre falla con el error del hijo y el nombre del nodo. La
  caché anterior del padre no se reemplaza con un resultado a medio construir.
- Un archivo de hijo faltante, un archivo movido, un esquema cambiado o una credencial faltante es un
  error de actualización que la interfaz puede explicar, no un resultado vacío silencioso.
- Los ciclos, las autorreferencias y un hijo que también es un ancestro se rechazan antes de
  la ejecución.
- Las referencias entre documentos (diferidas más allá de v1) pasarán, cuando lleguen, por la coordinación
  de archivos y las URL con ámbito de seguridad en iOS; iCloud puede desalojar al hijo. La CLI y
  macOS toman rutas explícitas. El diseño necesita una política de resolución de rutas en las tres.
- El progreso de actualización debería ser por nodo. Una extracción larga de API en un hijo debería ser visible como el
  progreso de ese hijo, no como un bloqueo inexplicado.
- La cancelación debe llegar al controlador en ejecución. El método de ejecución actual es síncrono
  y no tiene token de cancelación; un objeto de opciones de ejecución del plan es el lugar natural para
  uno.

### 3.6 Qué almacena el padre

En tiempo de diseño el padre necesita el **esquema de resultado** del hijo — nombres de columna, tipos,
longitudes — para dibujar la interfaz de uniones y validar las referencias de campo. No debería necesitar las filas
del hijo, ni la conexión de origen del hijo. El esquema es la misma
descripción `MADDataColumn` que la caché ya serializa. Esta es la mitad "describir sin
ejecutar" del contrato de objeto de datos; es un requisito previo para la composición, no una
comodidad opcional.

La decisión del usuario (2026-11-22) es que **el esquema de resultado son los campos activos** — las
columnas que referencian los elementos, uniones y grupos del informe — exactamente la lista SELECT
que `MADQueryActiveQueryFields` ya calcula (`MAD/Source/MADQueryActiveQueryFields.m:27-100`).
Sin cambio de comportamiento: describe devuelve esa lista como `MADDataColumn`s sin ejecutar. La
forma de todas las columnas sigue siendo una preocupación de vista previa de tabla, no un esquema de objeto de datos. Los nombres públicos de columna
deberían ser legibles por humanos: `MADDataColumn.caption` ya existe para el nombre de presentación,
y el constructor de la lista SELECT debería establecerlo desde el nombre de presentación del campo de esquema cuando
existe, en lugar de exponer solo el alias interno `"Table0"."Field"`.

Falta otra pieza de identidad: la **raíz**. `RptqDocument -mainQuery` y
`RptqDatabase -defaultQuery` son ambos `hasQueries.anyObject`
(`MAD/Source/rptq/RptqDocument+Extras.m:184-186`,
`MAD/Source/rptq/RptqDatabase+Extras.m:88`), y `MADocument -database` toma
`hasDatabaseSchemas.anyObject` (`MAD/Source/MADocument.m:1248-1258`). Con varios objetos de datos
en un documento, la consulta que renderizan el visor y el diseñador es no determinista. Añade
una referencia raíz explícita (o una bandera) al documento, migrando la consulta única actual a
ella. **Decisión del constructor.**

## 4. La costura de controladores para orígenes no-SQL

### 4.1 Por qué el texto SQL es la frontera equivocada

Hoy la actualización del informe compila el grafo a SQL y llama
`executeSQL:fieldKeys:onConnection:intoResultTable:withError:`
(`MAD/Source/MADOperationRefresh.m:134`). Eso es correcto para un dialecto SQL. Para una API REST
fuerza al controlador a analizar SQL de vuelta a un grafo, y el subconjunto del analizador no coincide con
el SQL generado al menos en dos lugares: el generador añade una cláusula `LIMIT`
(`MADQueryFull.m:164`) que `MADSQLParser` rechaza (`MAD/Source/sql/MADSQLParser.m:151-154`),
y el diseñador puede generar uniones `NATURAL`/`CROSS`
(`RptqQueryLinks+Extras.m:76-86`, `MADQueryLinkType.h:15-16`) que el analizador también rechaza
(`MADSQLParser.m:330-338`). Reutilizar el analizador también invertiría el estratificado: vive en
`MAD`, por encima de los controladores, y en Linux `mad` enlaza los controladores con archivo completo
(`Linux/CMakeLists.txt:469-474`).

Pasar `MADQuery`/`MADQueryFull` directamente tampoco es la respuesta: `MADQueryFull` está
atado al almacén, en `MAD`, y calcula la lista de campos activos solo mientras construye SQL. Un
controlador compilaría contra el almacén del documento.

### 4.2 El plan

Añade un objeto de valor neutral respecto al controlador en `MADAPI`:

```objc
@interface MADQueryPlanTable : NSObject
@property (copy) NSString *name;                        // schema table or object name
@property (copy) NSString *alias;                       // query alias
@property (copy, nullable) NSString *sourceIdentifier;  // nil = schema table
@end

@interface MADQueryPlanField : NSObject
@property (strong) MADQueryPlanTable *table;
@property (copy) NSString *field;
@property (copy) NSString *outputKey; // exactly what the driver names the column
@end

@interface MADQueryPlanLink : NSObject
@property (assign) MADLinkType type;              // moved down to MADAPI
@property (strong) MADQueryPlanTable *leftTable, *rightTable;
@property (copy) NSString *leftField, *rightField;
@end

@interface MADQueryPlanPredicate : NSObject
@property (assign) MADPredicateOperator op;        // moved down to MADAPI
@property (strong) MADQueryPlanOperand *left, *right; // field reference or literal
@end

@interface MADQueryPlan : NSObject
@property (copy) NSArray<MADQueryPlanTable *> *tables;
@property (copy) NSArray<MADQueryPlanField *> *fields;   // the active SELECT list
@property (copy) NSArray<MADQueryPlanLink *> *links;
@property (copy) NSArray<MADQueryPlanPredicate *> *predicates;
@property (copy) NSArray<MADQueryPlanSort *> *sort;      // pushdown hint
@property (assign) NSUInteger limit;
@property (assign) NSUInteger offset;
@end
```

`MADLinkType`, `MADPredicateOperator` y `MADSortOrder` están actualmente en `MAD`
(`MAD/Source/MADQueryLinkType.h`, `MADPredicateOperator.h`, `MADSortOrder.h`). Un plan en
`MADAPI` no puede referenciarlos hasta que se muevan abajo (o el plan define sus propios enums,
lo que duplica el modelo). Mover los tres enums puros es la corrección correcta.

La ejecución se convierte en un método opcional en el protocolo existente:

```objc
@protocol MADDatabaseDataSource <NSObject>
// existing required methods stay ...
@optional
- (BOOL)executeQueryPlan:(MADQueryPlan *)plan
                 options:(MADDatabaseExecutionOptions *)options
          intoResultTable:(id <MADDataTableWriting>)table
                withError:(NSError **)error;
@end

@interface MADDatabaseExecutionOptions : NSObject
@property (copy) BOOL (^isCancelled)(void);
@property (copy) void (^progress)(double fraction, NSString *node);
@property (strong) id credentials;                  // driver-specific, or a resolver
@property (copy) NSArray<MADMaterializationReference *> *attachments; // SQLite composer
@end
```

El plan sigue siendo **lógico**; las opciones llevan el contexto de ejecución. Un controlador SQLite compuesto
resuelve el `sourceIdentifier` de cada tabla a un adjunto (ruta, tabla, alias)
suministrado en `options`. Eso mantiene las rutas de archivo fuera de la superficie de controladores de terceros y da
un hogar a la cancelación y al progreso por nodo. **Decisión del constructor.**

`MADOperationRefresh` lo prefiere cuando el controlador lo implementa, y recurre a la
ruta SQL existente en caso contrario. Los cuatro controladores enviados no necesitan cambios el primer día. Una
implementación de referencia puede compilar el plan a SQL internamente y afirmar que coincide con la
salida del compilador actual, lo que fija el plan contra la suite existente.

### 4.3 Capacidades

El motor y la interfaz deberían preguntar a un controlador qué puede hacer en lugar de codificar los ID de controlador:

```objc
@interface MADDatabaseCapabilities : NSObject
@property (assign) MADLinkTypeMask supportedLinkTypes;
@property (assign) MADPredicateOperatorMask supportedOperators;
@property (assign) BOOL supportsLimitOffset;
@property (assign) BOOL supportsServerSideSort;
@property (assign) BOOL supportsNativeStatementText; // SQL editor
@property (assign) BOOL isReadOnly;
@property (assign) NSUInteger maximumPageSize;
@end
```

Esto reemplaza las listas de controladores codificadas y las reglas de unión en
`MADDesigner/Source/MADDriverSelectorController.m:64-90,124-140`,
`MAD/Source/rptq/RptqDatabaseCredentals+MADDatabaseConnection.m:19-33`,
`Mac/Source/MADMacConnectionWindowController.m:198-204,359-375`,
`CLI/Source/MADCLIServe.m:277-291`, y
`MADDesigner/Source/MADQueryAddLinkJoinTypeController.m:46-95`. El registro ya
enumera los controladores (`registeredDriverClasses`); la interfaz puede usarlo más
`driverName`/`imageIconName` en lugar de un switch.

### 4.4 Qué conserva cada capa

- **La navegación de esquema** sigue siendo `getTables:` / `getTablesFromConnection:error:` y
  `fieldsForTable:connection:error:`. Un controlador no-SQL devuelve valores `MADDatabaseTable` y
  `MADDatabaseField`; el usuario de informes los ve en el diseñador de consultas exactamente como
  las tablas de esquema hoy.
- **El contrato de resultado** sigue siendo `id <MADDataTableWriting>`; el controlador añade
  `MADDataColumn`s y filas con clave por `fieldKeys`/`outputKey`.
- **Agrupación, ordenación, agregados** se quedan en el motor sobre la caché. El controlador devuelve
  filas de detalle.
- **Las uniones** son una capacidad: nativas, del lado del cliente, o no admitidas. La composición es el
  respaldo. Un controlador que no admite uniones puede seguir siendo un objeto de origen; el usuario
  divide los recursos en objetos separados y los une en el informe compuesto.
- **La entrada de texto SQL y la sonda de validación** están condicionadas por capacidad. Un controlador no-SQL no
  necesita aceptar un SELECT pegado.
- **El registro** puede quedarse en la clase de conexión (`MADDatabaseDriver`) por compatibilidad.
  El contrato más limpio a largo plazo pone el tipo, identificador, capacidades y construcción de conexión
  en la subclase `MADDatabase`; eso puede añadirse junto al protocolo actual
  sin romper los cuatro controladores.

## 5. El controlador de API genérico

El "un controlador para toda una clase de orígenes de datos" del usuario es un controlador cuyo esquema viene
de un **manifiesto de origen**, no del código. El motor ve un `MADDatabase` ordinario;
el manifiesto le dice al controlador qué tablas, campos, endpoints y reglas de paginación existen.

Forma mínima del manifiesto:

```json
{
  "name": "eBay Seller",
  "baseURL": "https://api.ebay.com",
  "resources": {
    "listings": {
      "path": "/sell/inventory/v1/inventory_item",
      "rowsPath": "inventoryItems",
      "primaryKey": "sku",
      "pagination": { "limitParam": "limit", "offsetParam": "offset", "max": 100 },
      "fields": {
        "sku": "string",
        "listingId": "string",
        "product.title": "string",
        "price.value": "number"
      },
      "filters": { "sku": { "eq": "sku" } }
    }
  }
}
```

El controlador asigna el plan a peticiones:

- `tables[0]` selecciona el recurso.
- `fields` se convierten en una lista de selección o se ignoran si la API devuelve objetos completos.
- `predicates` se convierten en parámetros de consulta cuando el manifiesto nombra una asignación; en caso contrario, el
  controlador filtra localmente.
- `limit`/`offset` impulsan el bucle de páginas. Sin límite, el controlador pagina hasta agotar.
- `links` son nativos si la API los admite, del lado del cliente si el controlador implementa una
  unión hash, o no admitidos (la capacidad deshabilita el vínculo en la interfaz).
- Los valores JSON se asignan a `MADDataType` a través de los tipos de campo del manifiesto.

En cuanto a la conexión, la fila de credenciales actual cubre los controladores SQL (`host`, `username`,
`password`, `database`). Para un controlador de API que necesita un secreto de cliente, un token de actualización, un
ID de marketplace o una bandera de sandbox, la decisión del usuario (2026-11-22) es un único **campo de opciones
extensible** en la credencial: una columna de texto que contiene JSON (o XML), versionada en el
formato del almacén, analizada por el controlador — en lugar de una nueva columna de almacén por controlador. Los campos
existentes asignan el caso común (`host` = URL base, `database` = nombre del manifiesto, `username` =
ID de cliente, `password` = token OAuth). Los valores sensibles (secreto de cliente, token de actualización) pertenecen
al Keychain, no al documento; el JSON contiene la forma no secreta más una referencia
de clave del Keychain. Esto no es un rodeo — es el punto de extensibilidad, para que un controlador no
cambie el formato del documento cada vez que añade un parámetro.

La autoría del manifiesto es **primero empaquetada/por el desarrollador** (decisión del usuario,
2026-11-22): el desarrollador del controlador escribe el manifiesto y lo envía con el controlador. Un
editor/importador de manifiestos para el usuario y su frontera de confianza se difieren detrás del sistema de
plugins (§5.1). El deseo a largo plazo — controladores que se enchufan y se añaden/quitan a través de la
interfaz — se registra aquí; es una preocupación primero de macOS/Linux/Windows y servidor, porque iOS
históricamente ha bloqueado la carga de código de terceros arbitrario, así que en iOS los controladores siguen
enlazados en tiempo de compilación.

El controlador genérico también lleva las obligaciones no-SQL que el plan no tiene: cliente HTTP y
TLS, actualización de autenticación, límites de tasa, reintentos, cancelación, límites de tamaño de respuesta y mapeo
de errores. Esas pertenecen al framework del controlador, no al motor.

Lo que el controlador genérico no puede hacer es tan importante como lo que puede: GraphQL arbitrario, un
origen cuyas filas no son tabulares, o uniones del lado del servidor que el manifiesto no puede expresar. El
objeto de capacidades es cómo lo dice, y el diseñador de consultas es donde el usuario se entera.

### 5.1 Controladores enchufables (futuro, no v1)

El objetivo más amplio del usuario son controladores que se instalan, registran y desregistran como plugins, y
que pueden añadirse o quitarse a través de la interfaz en lugar de enlazarse en la aplicación. El registro
ya hace el registro por proceso mediante enlace (§1 del tutorial de controladores); un sistema de plugins real
es una cuestión de empaquetado y confianza sobre eso: carga dinámica, una ubicación
de descubrimiento, firma/sandbox y una interfaz. Esa es una función de macOS/Linux/Windows y servidor, no
de iOS, y está fuera del alcance de las fases de este diseño. Se anota aquí para que la
costura de controladores (fase 0) no se pinte a sí misma en un rincón: los tipos de plan, capacidad y
registro deberían seguir siendo cargables desde una imagen enlazada dinámicamente, lo que significa ningún
acoplamiento en tiempo de compilación a una lista fija de controladores.

## 6. Qué cambia en el almacén y el formato

Forma mínima, siguiendo `MAD_DATA_OBJECT.md` §4.4:

- `RptqQuery` gana un nombre. Ya es la definición.
- La referencia de `RptqQueryTable` gana un segundo tipo: **un objeto de datos (subinforme) en el mismo
  documento**, además de una tabla de esquema. Una fila v1 que nombra una tabla de esquema significa exactamente
  lo que significa hoy. Una referencia a un informe en *otro* archivo `.mad` se difiere más allá de
  v1; cuando llegue necesitará una identidad de documento y una ruta, más un marcador vivo/fijado.
- La credencial gana la columna de texto de **opciones** extensible (JSON/XML) para parámetros
  específicos del controlador (§5), versionada con el formato.
- La dirección de materialización pasa a ser el hash de identidad del objeto, no
  `fileURL.lastPathComponent.hash`. El nombre de la tabla sigue siendo `t<tag>`; la etiqueta se convierte en la
  identidad del objeto.
- Cada objeto obtiene su propio plist de esquema (`.mdcache`) y tabla. El diseño A mantiene un archivo por
  objeto; el diseño B cambiaría el modelo de archivos.
- El almacén necesita un paso de versión para la nueva referencia y los campos de opciones. El almacén existente
  ya tiene maquinaria de versionado para la columna de origen SQL (`MADStoreSchema.m:314`),
  así que este es un patrón conocido, no un mecanismo nuevo.

El documento `.mad` sigue siendo una definición y no contiene **ningún dato, ahora ni después** — esa es la
decisión explícita del usuario. Las instantáneas y materializaciones son archivos de caché complementarios en el
sistema del usuario, y son lo que `ATTACH` une. La auto-nomenclatura de esos archivos de caché
pasa del hash del nombre de archivo a una identidad de objeto estable para que los archivos no puedan chocar.

## 7. Interfaz, CLI y el motor headless

- El panel Add Table gana un segundo tipo de origen: los otros objetos de datos del documento
  (subinformes). La interfaz de uniones no cambia; ambos extremos son campos. Las referencias
  entre documentos `.mad` son una adición posterior.
- El diseñador debe poder mostrar el esquema de resultado de un hijo sin ejecutarlo, y
  marcar una referencia rota (esquema cambiado, credencial faltante) antes de actualizar.
- La actualización necesita progreso y errores por nodo. Un hijo que falla debe ser nombrado.
- Las credenciales son por nodo. Los subinformes del mismo documento mantienen sus credenciales en el único
  documento, así que la política es por objeto; la actualización entre documentos, cuando llegue, necesita una
  política para obtener las credenciales del hijo.
- La CLI y el motor headless recorren el mismo DAG. `MADOperationRefresh` es compartido por la
  aplicación, macOS y la CLI (`CLI/Source/MADCLIDocument.m:120-127`,
  `Mac/Source/MADMacDocument.m:337-360`), así que la caminata topológica pertenece allí o a un
  ayudante que llama, no a cada interfaz.
- El formulario de conexión de la aplicación de macOS y el mapa de tokens de controlador de la CLI necesitan el mismo
  tratamiento impulsado por el registro que el selector de iOS.

## 8. Fases

Ordenadas para que cada fase se envíe en verde y la aplicación de consulta única siga funcionando. La primera fase es
independiente de la composición y es la que desbloquea los orígenes no-SQL.

| Fase | Trabajo | Depende de |
|---|---|---|
| 0 | **La costura de controladores.** Añade `MADQueryPlan` + tipos de valor y mueve los tres enums a `MADAPI`; añade `executeQueryPlan:` opcional; añade capacidades; haz que la actualización prefiera el plan y recurra a SQL. Implementa el plan en un controlador existente como referencia y fija la equivalencia plan-a-SQL con pruebas. Sin cambio de comportamiento. | — |
| 1 | **El contrato de objeto de datos.** Separa la construcción de la lista SELECT de la ejecución; añade describe/execute; devuelve el esquema de resultado como `MADDataColumn`s; haz que la actualización llame al contrato. Esta es la fase 1 de `MAD_DATA_OBJECT.md`. | 0 (se solapa) |
| 2 | **La consulta se posee a sí misma.** `MADQueryFull` usa la consulta que se le dio; `dataTableForQuery:` resuelve por consulta; `MADQueryActiveQueryFields` se limita a una consulta; `MADModelDocument` refleja cualquier consulta. | 1 |
| 3 | **Composición dentro del mismo documento.** Una tabla de consulta puede referenciar otro objeto de datos (subinforme); actualización topológica; soporte de `ATTACH` en `MADDatabaseSqlite3`; la consulta compuesta se ejecuta contra la caché local. Este es el modelo de un solo archivo portable del usuario. | 1, 2 |
| 4 | **Composición entre documentos (diferida).** Una referencia a otro informe `.mad`; identidad de documento y resolución de rutas; vivo vs fijado; coordinación de archivos; política de credenciales; manejo de faltantes/renombrados. Menor prioridad: la composición dentro del mismo documento satisface el modelo del usuario. | 3 |
| 5 | **El controlador de API genérico.** Un controlador HTTP/JSON impulsado por manifiesto; esquema desde el manifiesto; asignación plan-a-petición; bucle de paginación; mapeo de tipos; el campo `options` de credencial extensible; eBay Seller como ejemplo desarrollado. | 0, 1 (y 3 para uniones) |
| 6 | **Superficies y documentación.** Listas de controladores y reglas de unión impulsadas por el registro; interfaz de actualización por nodo; verbos de CLI; el tutorial de autoría de controladores actualizado con la costura de plan/capacidades. | 0–5 |

No es una fase: la **carga de controladores enchufables** (§5.1) es una función de macOS/Linux/Windows y servidor
rastreada por separado de este diseño; nada en las fases 0–6 depende de ella, y la fase 0
debería simplemente evitar el acoplamiento a una lista fija de controladores para que la carga dinámica siga siendo posible.

La fase 0 es la parte "no muy lejana": son tipos de valor nuevos, un método opcional, una rama en
la actualización, y pruebas. No requiere que cambien el almacén, la interfaz ni el modelo de composición.
La fase 3 es donde aterriza el modelo `ATTACH` del usuario, y es más pequeña de lo que suena
porque SQLite ya es un controlador y el compilador ya ordena un grafo.

## 9. Decisiones

### 9.1 Decisiones del constructor registradas en este documento

Estas están resueltas por el código o por un compromiso de diseño; pueden revisarse, pero el
plan las asume.

1. **Diseño A, con `ATTACH`.** Un `.maddb` por objeto; la conexión compuesta los adjunta.
   Esto sigue el modelo de una tabla por archivo de `MADDataTableFast`. El diseño B (varias tablas
   en un archivo) es un refactor posterior, no v1. Esto sustituye la recomendación del diseño B de
   `MAD_DATA_OBJECT.md` §9.2 para este diseño.
2. **Los objetos compuestos son solo locales.** Las tablas de una consulta compuesta son objetos de datos; una
   tabla remota se envuelve en un objeto de origen. Sin ejecución mixta remota/local.
3. **Los campos hijo del padre son campos de esquema ordinarios.** Sintetiza un conjunto de
   tabla/campos de esquema de resultado por objeto a partir de los `MADDataColumn`s del hijo, y actualízalo cuando cambie
   el esquema del hijo. Sin segundo tipo de referencia de campo.
4. **La raíz es explícita.** Una referencia (o bandera) raíz a nivel de documento, migrada desde
   la consulta única actual. No `hasQueries.anyObject`.
5. **El plan es lógico; el contexto de ejecución es separado.** `MADDatabaseExecutionOptions`
   lleva cancelación, progreso, credenciales y el conjunto de adjuntos del compositor SQLite.
   `MADQueryPlanTable.sourceIdentifier` nombra el origen lógico; no es una ruta de archivo.
6. **Más de diez orígenes directos es un error de diseño en v1.** Aumentar
   `SQLITE_MAX_ATTACHED` es un cambio de compilación en tres plataformas, diferido.
7. **Construye el plan en paralelo con el compilador SQL, luego fija la equivalencia.** No
   refactorices el compilador SQL para renderizar desde el plan hasta que el plan esté probado por la suite
   actual.
8. **Nombra el `RptqQuery` existente; no introduzcas `RptqDataObject` todavía.**
   `MAD_DATA_OBJECT.md` §9.1 recomienda esto, y es la migración más pequeña.
9. **Mantén `MADDatabaseDriver` en la clase de conexión por compatibilidad.** Un contrato de
   registro de clase de base de datos puede añadirse junto a él más adelante.
10. **El primer controlador de API genérico declara las uniones no admitidas.** Se apoya en la composición
    para las uniones, y luego hace crecer una unión hash del lado del cliente detrás del objeto de capacidades. Esto mantiene
    el primer controlador como una extracción de un solo recurso.
11. **La composición dentro del mismo documento se envía antes que la entre documentos.** La fase 3 retira los
    puntos de cableado fijo sin la complejidad de rutas/coordinación/credenciales; la entre documentos es
    la fase 4.

### 9.2 Decisiones respondidas por el usuario (2026-11-22)

Siguen las palabras del propio usuario; las implicaciones son del autor.

1. **El esquema de salida son los campos activos — sin cambios.** La salida de un objeto de datos son las
   columnas que usa el informe: los campos de los elementos de diseño, los campos de unión y los campos
   de grupo, que es precisamente la lista SELECT que `MADQueryActiveQueryFields` ya calcula
   (`MADQueryActiveQueryFields.m:27-100`). El usuario: *"it would just be the fields that are
   used in that report."* La forma de todas las columnas es solo una preocupación de vista previa de tabla. Describe
   devuelve esa misma lista como `MADDataColumn`s sin ejecutar. Dos consecuencias se anotan
   como funciones futuras, no como parte de este trabajo: **nombres de columna legibles por humanos** (establecer
   `MADDataColumn.caption`, que ya existe, en lugar de exponer solo el alias
   `"Table0"."Field"`), y **paginación de vista previa** (la vista previa actualmente se limita a ~512 filas
   y debería paginar por el resultado completo — el usuario lo marcó para la lista de deseos, que
   es el `TODO.md` del usuario, no este documento). La regla de cero filas sigue aplicándose: un objeto de origen
   materializa su esquema completo incluso cuando devuelve cero filas.
2. **Se espera que los controladores se ejecuten en cada plataforma; el enchufado es el objetivo.** El usuario:
   *"That's really up to the person who writes the driver, but yes I'd expect so."* El
   motor headless y el mismo DAG se mantienen en Linux/Windows; si un *determinado* controlador se ejecuta
   headless es preocupación de su autor. El deseo más amplio — *"drivers could be plug-and-play…
   add and remove drivers through the UI"* — es §5.1, una función futura y una
   preocupación de macOS/Linux/Windows/servidor, porque iOS históricamente ha bloqueado la carga de código
   de terceros arbitrario.
3. **Las instantáneas viven en la caché complementaria, nunca en el `.mad`.** El usuario: *"The `.mad`
   file only describes the schema… that shouldn't change… It would be in whatever the cache
   file is right now… the cached files that are Sqlite3 data stores, and that is what would
   be `ATTACH`ed together."* Así que el archivo sigue siendo solo de definición; una instantánea fijada es una
   `.maddb`/`.mdcache` conservada, y la nomenclatura de materialización pasa a una identidad de objeto estable
   para evitar choques.
4. **Los manifiestos son primero empaquetados/por el desarrollador.** El usuario: *"your answer is correct…
   the idea was always that new drivers could be added through some plugin system… I don't
   believe you can have plugins in iOS."* v1 envía un controlador impulsado por manifiesto con
   manifiestos escritos por el desarrollador; un editor/importador de manifiestos para el usuario y su frontera de confianza
   van detrás del sistema de plugins.
5. **La composición es primero dentro del documento — subinformes en un archivo portable.** El usuario:
   *"maybe you could add 'sub-reports' to the mad document… the idea would still be one
   portable file."* Un `.mad` contiene varias definiciones de informe/consulta; cada una se ejecuta en una
   tabla SQLite; el informe compuesto las `ATTACH`ea. Esto preserva la propiedad de un solo archivo
   y elimina el problema de reautorización entre archivos de iOS para v1. Las referencias entre
   *documentos* se difieren detrás de la composición dentro del mismo documento.
6. **Las credenciales ganan un campo de opciones extensible.** El usuario: *"we could design one and add
   it to the report format… perhaps all in one database field, that we parse out somehow
   (like JSON or XML) so it can be extensible."* Una columna de texto que contiene JSON, versionada en
   el almacén, analizada por el controlador. Los valores sensibles (secreto de cliente, token de actualización) van en
   el Keychain; el JSON contiene la forma no secreta más una referencia al Keychain.

### 9.3 Valores predeterminados que el autor asume (decisiones del constructor)

- **Lo vivo es lo predeterminado; fijar significa conservar la instantánea de caché.** Lo vivo ejecuta el hijo al
  actualizar; fijar reutiliza la materialización conservada. Ambos leen del directorio de caché.
- **Política de actualización.** Recalcular cada nodo al actualizar (la descripción de abajo arriba del usuario). Un
  control de frescura/reutilización de caché para hijos de API caros es una adición posterior detrás del
  objeto de capacidades.
- **Nomenclatura.** "Objeto de datos" es el término del almacén/protocolo; "subinforme" es el término de cara al usuario
  para un objeto referenciado en la interfaz de composición.

## 10. Riesgos, y qué hace que no sea una sola línea

- **Los tres puntos de cableado fijo** (la relectura de `MADQueryFull`, la tabla de datos de una sola ranura, los
  campos activos sin alcance) son fundamentales para la aplicación actual de consulta única. Deben caer
  antes de que una segunda consulta, y mucho menos una anidada, pueda ejecutarse.
- **La dirección de la caché es el hash del nombre de archivo** y la caché es por dispositivo. La direccionabilidad es
  un requisito previo, no un detalle.
- **Las referencias entre documentos** traen resolución de rutas, desalojo de iCloud, coordinación de archivos,
  hijos faltantes y credenciales para un origen que el padre no posee. Esta es la parte más
  cargada de producto.
- **`ATTACH` tiene un límite** (`SQLITE_MAX_ATTACHED`, 10 por defecto) y necesita gestión de alias/nombres
  y entrecomillado de rutas. No lo descubras en producción.
- **Costo de la actualización completa.** El diseño de caché es extraerlo todo por diseño; un DAG multiplica
  eso. Una política de caché/frescura es parte del diseño, no una optimización.
- **Límites de tasa de API y volumen de datos.** Un controlador que pagina una API en cada actualización necesita
  reintentos, límites, cancelación y una historia de progreso visible.
- **Deriva de esquema.** Las columnas de un hijo pueden cambiar; la consulta del padre entonces referencia campos
  que ya no existen. Se requieren validación en tiempo de diseño y errores en tiempo de actualización.
- **Estabilidad de la API de controladores.** Los controladores de terceros compilan contra `MADAPI`; los tipos de plan y
  capacidad se convierten en una superficie pública. Versiónalos deliberadamente.
- **Matriz de pruebas.** Cuatro plataformas (iOS, macOS, Linux, Windows), controladores SQL y no-SQL,
  composición dentro del mismo documento y entre documentos. El orden de las fases es la mitigación: un nuevo
  eje a la vez.

## 11. Qué no es esto

- **No es un motor de federación.** Nada nuevo habla con MySQL y una API en una sola sentencia. Cada
  objeto se ejecuta contra su propio origen; la unión es local.
- **No es una segunda implementación de consultas.** El grafo, el compilador, los controladores, la tabla
  de resultados y el motor de unión de SQLite ya existen.
- **No es un cambio a la caché que lo extrae todo.** La caché de dos pasadas es fundamental
  (`docs/05-companion-files.md` §5.1).
- **No está programado.** Este es el registro de diseño para trabajo futuro. `docs/project/registers/TODO.md` es
  la lista de deseos del propio usuario (el deseo de paginación de vista previa pertenece allí), `TASKS.md` es la
  cola de ingeniería, y `ROADMAP.md` dice qué se toma a continuación. Nada aquí se inicia por
  iniciativa de un agente.

Dos funciones futuras se nombran aquí pero pertenecen a los archivos de seguimiento del usuario, no a este diseño:
la corrección de **paginación de vista previa** (§9.2.1) y el **sistema de controladores enchufables** (§5.1). Este
documento es donde se registra su forma; no las programa.

## 12. El hilo conductor

La pestaña de consulta ya construye la función. La cadena de actualización ya la compila y ejecuta.
La tabla de resultados ya es un esquema y un conjunto de resultados, en disco como SQLite. SQLite ya
es un controlador. Los controladores ya devuelven tablas. Lo que falta es el nombre, la
dirección, la mitad describe y la consulta estructurada que un controlador no-SQL necesita en lugar del
texto SQL. Son aditivos: un objeto de valor de plan, un objeto de capacidades, un método de
ejecución opcional, una identidad de objeto estable, un segundo tipo de referencia de tabla, una caminata
topológica y `ATTACH`.

La composición es entonces la tubería existente direccionada por algo mejor que un hash de nombre de
archivo. El controlador no-SQL es la misma tubería con un cuerpo de ejecución diferente. Ninguno es un
motor nuevo; ambos son lo que las abstracciones se construyeron para permitir.
