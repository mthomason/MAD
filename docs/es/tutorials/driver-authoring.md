---
layout: default
lang: es-419
---

# Escribir un driver de MAD en una tarde

Todas las referencias de archivo:línea a continuación están vigentes a fecha de 2026-10-25.

## Qué es un driver

Un driver son dos clases pequeñas y una llamada de registro:

1. una subclase de `MADDatabase` (`MADAPI/Source/MADDatabase.h` — la cabecera
   lo dice claramente: «This class is built for subclassing») que sabe cómo
   explorar el esquema de una fuente y ejecutar una consulta contra ella;
2. una clase de conexión: una subclase de `MADDatabaseConnection` que implementa
   el protocolo `MADDatabaseDriver`
   (`MADAPI/Source/MADDatabaseDriverRegistry.h`) y se registra en
   `+load`.

Todo lo demás —el grafo del diseñador de consultas, la generación de SQL, la caché de
filas, la canalización de renderizado, los siete formatos de exportación, la CLI y la imagen de
Docker— es maquinaria compartida a la que el driver se conecta. El contrato que cumple un driver es
*«devolver un esquema y filas en forma de tabla»*
(`docs/project/MAD_STRATEGY.md` §3.7), y por eso un driver puede estar frente a
cualquier cosa que se pueda hacer parecer una tabla: una base de datos SQL, un servicio
web, un archivo.

Los tres ejemplos de servidor de los que tomar ejemplo son `MADPostgres` (6 archivos,
`MADPostgres/Source/`, subclase `MADDatabasePostgres` sobre `libpq`),
`MADMySQL` (18 archivos, `MADMySQL/Source/`, subclase `MADDatabaseMySQL`) y
`MADTdsClient` (SQL Server sobre FreeTDS). Sqlite3 es el cuarto driver distribuido
(`MADSqlite3`), y el caso respaldado por archivo
(`+newDatabaseConnectionWithURL:`) se muestra en su clase de conexión.

## Paso 1: la constante de tipo

Elija el siguiente valor libre de `MADDatabaseType` (`MADAPI/Source/MADDatabaseType.h`;
los tipos distribuidos son 1–12) o amplíe la enumeración. Es lo que el documento
almacena, así que es una constante de formato: una vez que existen documentos con su tipo,
el número es permanente.

## Paso 2: crear la subclase de `MADDatabase`

Las costuras abstractas viven en `MADAPI/Source/MADDatabaseProtocol.h`
(`MADDatabaseDataSource`). La superficie obligatoria:

```objc
- (void)getTables:(void (^)(BOOL success, NSError *error,
                            NSArray <MADDatabaseTable *> *tables))completion;

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn
                                                    error:(NSError **)error;
- (NSArray <MADDatabaseField *> *)fieldsForTable:(NSString *)tableName
                                     connection:(id)dbconn
                                          error:(NSError **)error;

- (id)connectWithConnection:(MADDatabaseConnection *)connection
                 credentals:(MADCredential *)credentals
            connectionError:(NSError **)error;

// The execution seam: the driver fills the table it is handed.  The
// destination is any <MADDataTableWriting>, which is what keeps the
// promise to "anything that returns a table" (MADDataTable.h).
- (BOOL)executeSQL:(NSString *)sql
         fieldKeys:(NSArray *)fieldKeys
      onConnection:(id)dbconn
  intoResultTable:(id <MADDataTableWriting>)dataTable
         withError:(NSError **)error;

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError **)error;
- (BOOL)executeQuery:(MADQuery *)query
       withDataTable:(id <MADDataTableWriting>)dataTable
            andError:(NSError **)error;

// Optional: only file-backed drivers have nothing to dial.
- (void)closeConnection:(id)process;
```

La exploración del esquema (`getTables…`, `fieldsForTable:…`) es lo que llama el flujo de
creación de documentos de la aplicación cuando importa el esquema de una base de datos a un nuevo
`.mad`; la costura de ejecución es lo que llaman `mad refresh` y el visor.
`MADOperationRefresh.m:134` muestra la llamada exacta que hace la cadena de actualización.

## Paso 3: la clase de conexión y el registro

```objc
@interface MyDriverConnection : MADDatabaseConnection <MADDatabaseDriver>
@end

@implementation MyDriverConnection
+ (void)load {
	[MADDatabaseDriverRegistry registerDriverClass: self];
}
+ (MADDatabaseType)databaseType { return MADDatabaseTypeMyDriver; }
+ (NSString *)Identifier { return @"MyDriver"; } // stored in documents
+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentials { … }
+ (Class)databaseClass { return [MyDatabase class]; }
+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host
										 database:(NSString *)database
											 port:(NSInteger)port { … }
@end
```

`+Identifier` es lo que contiene `RptqDatabaseCredentals.driverID`, así que es una
constante del formato del documento: elija una grafía estable («MySQL», «TDS»,
«PostgreSQL», «Sqlite 3» son las distribuidas). Una segunda clase que reclame un tipo ya tomado es un error de
programación; el registro lo comprueba con una aserción.

## Paso 4: enlazarlo para que se ejecute el registro

El registro es por proceso y **por enlace**: un proceso que no enlaza
su driver no puede construir sus bases de datos (el constructor falla con una
aserción y un mensaje claro en lugar de fallar más tarde con nil).

* **Apple:** enlace su framework en el anfitrión (la CLI nombra sus drivers
  en la lista `FRAMEWORKS` de `CLI/build.sh`), o use `-ObjC` al enlazar un
  archivo estático; de lo contrario, las categorías y los métodos `+load` se descartan
  silenciosamente.
* **Linux:** añada su archivo **con whole-archive** al objetivo `mad` en
  `Linux/CMakeLists.txt`, tal como lo están `madsqlite3`, `madmysql`, `madtdsclient`
  y `madpostgres`:

  ```cmake
  target_link_libraries(mad PUBLIC
      "$<LINK_LIBRARY:WHOLE_ARCHIVE,my_driver>" …)
  ```

  No es un detalle menor: el trabajo de un driver se alcanza a través de categorías
  (envíos de mensajes, sin símbolos), y un enlace estático que no sea whole-archive los descarta: el
  fallo es una caída en el primer envío de mensaje, no una advertencia del enlazador
  (`Linux/README.md`, «The compat shims» / «The drivers are registered»).
  Una lista de fuentes por driver en `cmake/MyDriverSources.cmake` sigue la
  forma de `MADFoundationSources.cmake`, con cada archivo excluido nombrado y
  el motivo.

## Paso 5: las convenciones de prueba (este es el estilo de la casa; respételo)

Dos suites, en el objetivo de pruebas del framework:

1. **Pruebas sin conexión**: estructuras de esquema, metadatos de campos, entrecomillado de
   identificadores, ida y vuelta de propiedades de la conexión. Se ejecutan siempre.
2. **Pruebas en vivo**: se comunican con una fuente real y **se omiten, nunca fallan**, cuando
   una no está disponible. `MADMySQL/MADMySQLTests/MADMySQLLiveTests.m` es
   la plantilla: las credenciales toman como valor predeterminado un servidor local documentado y
   todas se pueden sobrescribir con una variable de entorno
   (`MAD_MYSQL_TEST_HOST`, `MAD_MYSQL_TEST_PORT`, `MAD_MYSQL_TEST_USER`,
   `MAD_MYSQL_TEST_PASSWORD`, `MAD_MYSQL_TEST_SCHEMA`), y cada prueba en vivo
   empieza con `XCTSkipIf(![self serverIsAvailable], …)`. Una máquina
   sin su fuente sigue obteniendo una suite verde. Observe el comentario del archivo MySQL: use
   `127.0.0.1`, no `localhost`, dentro del Simulador de iOS.
3. **Pruebas del registro**: `MADDatabaseDriverRegistryTests` muestra la forma:
   registre un driver de prueba, compruebe la búsqueda, compruebe el lanzamiento por tipo
   duplicado. Su driver obtiene una de estas gratis por construcción.
4. Porte las suites a `Linux/Tests/` si el driver pertenece a la
   compilación sin interfaz gráfica (consulte `cmake/` y «Adding the next
   framework» en `Linux/README.md`); si no, explique en la PR por qué es solo para Apple.

## Paso 6: la advertencia honesta: qué puede y qué no puede hacer hoy un driver que no sea SQL

Esta es la única parte del discurso que no está terminada, y está escrita
a propósito (`docs/project/MAD_STRATEGY.md` §4.7): la capa de **ejecución**
tiene forma de driver —`executeSQL:…intoResultTable:…` y el
destino `MADDataTableWriting` son honestos sobre «cualquier cosa que devuelva
una tabla»—, pero la capa de **compilación** es compartida: `MADQueryFull` compila
el grafo de consultas en un texto SQL por driver. Su driver recibe **texto
SQL**, no el grafo (tablas, campos, predicados, grupos).

Así que hoy un driver REST/servicio web:

* **puede** explorar su esquema (`getTables…`, `fieldsForTable:…`), tomar la
  forma de conexión que la aplicación ya tiene, recibir el SQL generado y
  traducirlo a llamadas de API, entregar filas a cualquier tabla escribible y
  recorrer toda la ruta de actualización/renderizado/exportación: un driver totalmente funcional;
* **no puede** recibir el grafo de consultas de forma nativa: para saber *qué* le está pidiendo el motor
  debe analizar el texto SQL de la cadena que se le
  entregó. La ruta práctica: el analizador de SQL del propio motor (construido para la
  función de entrada de SQL, `docs/project/MAD_SQL_ENTRY.md`) ya analiza el
  subconjunto admitido —el SQL generado es ese subconjunto por construcción—, así que
  un driver puede reutilizarlo para recuperar el grafo;
* la **solución correcta** es un hook de compilación por driver: la misma forma que el
  proyecto esbozó para Salesforce SFQL en 2012, de modo que «instalar un
  driver» signifique «instalar un driver para cualquier cosa», no «para los dialectos SQL que
  casualmente coincidan». Está secuenciada como trabajo del contrato del motor (Etapa 1) y
  es una primera PR genuinamente bienvenida si quiere un bocado más grande que un driver.

Una nota honesta más, para despliegues de servidor y no para drivers: un
driver instalado por el usuario es **código arbitrario dentro del proceso del servidor**. El
registro funciona hoy para drivers propios y de confianza; un mercado
de drivers necesita firma, aislamiento en sandbox o aislamiento de procesos de trabajo antes
de poder existir, y eso está diseñado en la API del servidor, no añadido a posteriori.

## Paso 7: llevarlo a tierra

Proponga el driver mediante la plantilla de issue de propuesta de driver, siga la
regla de las pruebas primero en [CONTRIBUTING.md](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING.md) (prueba que
falla, después código hacia el verde; fixtures de instantánea en lugar de generarlas
con el código nuevo), y si el driver enlaza una nueva biblioteca de terceros,
amplíe
[docs/project/THIRD_PARTY_LICENSES.md](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md)
y las obligaciones de licencia con ella: el repositorio se toma ese archivo en serio.
