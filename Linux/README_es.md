[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md) | [Deutsch](README_de.md) | **Español**

# Linux: la compilación del motor sin interfaz gráfica

`docs/project/MAD_LINUX.md` §9: la Fase B demostró la cadena de herramientas (un Dockerfile que
compila desde fuentes clang + libobjc2 + GNUstep Base y compiló un subconjunto de
MADFoundation); la Fase C es la lista de shims de la §4, y este directorio es donde aterriza.
La compilación ahora compila **los once frameworks sin interfaz gráfica**: todos los de la tabla de
la §3 de docs/project/MAD_LINUX.md más `MADPostgres`, excepto los que son solo de interfaz (`MADExplorer`, `MADBarcodes`,
`MADFeedback`, `Scrimpter`, la aplicación), y ejecuta sus suites dentro del
contenedor: 126 ejecutables de prueba, 1 303 pruebas, 7 necesidades registradas. La cobertura de pruebas que
master integró el 2026-10-10 (~100 archivos de prueba de Xcode) está portada en
su totalidad, suite por suite. Nada de esto se distribuye en la aplicación; la CLI —el punto de control de la Fase D—
también se compila y ejecuta aquí (véase «La CLI se ejecuta aquí» más abajo), y la
imagen de ejecución de la Fase F la ejecuta como entregable («La imagen de ejecución», más abajo).

## Ejecutarla

	./Linux/build.sh              build the image, run the tests, exit with the result
	./Linux/build.sh --test       run the tests in the existing image
	./Linux/build.sh --runtime    build the runtime image (mad-cli:latest)
	./Linux/build.sh --verify     build the runtime image, then verify the CLI in it
	./Linux/build.sh --probe      run only the toolchain probe, with its report
	./Linux/build.sh --info       print clang and gnustep-config from the image
	./Linux/build.sh --shell      interactive shell in the build image
	./Linux/build.sh --toolchain  build only the toolchain image (the cache base)
	./Linux/build.sh --rebuild    rebuild without cache
	./Linux/build.sh --clean      remove both images

La CLI de Docker Desktop no está en `PATH` de forma predeterminada; `build.sh` la encuentra en
`/Applications/Docker.app/Contents/Resources/bin` y la pone (junto con el
asistente de credenciales que la acompaña) en `PATH` durante la ejecución. La primera compilación tarda
15–25 minutos (la etapa de la cadena de herramientas) y produce una imagen de ~2.5 GB; las ejecuciones posteriores
se almacenan en caché: solo se recompila la capa de fuentes. La comprobación cruzada con `--platform linux/amd64`
se ejecutó por última vez de extremo a extremo después de que llegara la cobertura integrada
(2026-10-11, antes de la Fase D): la imagen entera se compila bajo emulación (la etapa de la cadena de herramientas
amd64 y las bibliotecas vinieron de la caché anterior; el subconjunto,
incluidas las 55 suites nuevas, se recompiló), y la ejecución coincidió exactamente con arm64 nativo:
114 ejecutables, 1098 pruebas, 6 necesidades, 10 elementos de informe, los recuentos
de ese día. Se conserva como registro de esa ejecución manual; está superada por
la compilación de CI, que compila la imagen de forma nativa en amd64
(ubuntu-latest) y ejecuta `--verify` allí en cada push a master: el
flujo de publicación publica la etapa de ejecución de esa misma plataforma. Ejecútela con su
propia etiqueta (`MAD_LINUX_IMAGE=mad-linux:phase-b-amd64 ./Linux/build.sh
--platform linux/amd64`) para no reemplazar la imagen nativa.

## Versiones fijadas

`toolchain.conf` es el único lugar donde se escriben la versión, la fuente
y el hash de un componente de la cadena de herramientas, con la misma forma que `Compressor/matrix.conf`; las fuentes de git fijan la etiqueta de versión *y* el commit que se toma, y los
tarballs de GNUstep llevan valores sha256 calculados desde `ftp.gnustep.org`.

	libobjc2      2.3      v2.3                 (github.com/gnustep/libobjc2)
	libdispatch   6.1.3    swift-6.1.3-RELEASE  (github.com/apple/swift-corelibs-libdispatch)
	gnustep-make  2.9.3    ftp.gnustep.org tarball
	gnustep-base  1.31.1   ftp.gnustep.org tarball

La combinación de bibliotecas es `ng-gnu-gnu` con ABI de ejecución `gnustep-2.2`, de modo que todo
se compila con `-fobjc-runtime=gnustep-2.2` y ARC.

## La capa de bibliotecas

`libraries.conf` + `lib/libraries.sh` compilan las bibliotecas C que enlazan los frameworks,
de forma nativa, en `/usr/local` (docs/project/MAD_LINUX.md §7). La misma forma e intención que
la matriz de Compressor de al lado; nada de esto se distribuye.

	sqlite3      3.53.3   the released amalgamation; the option list still comes
	                      from Compressor/sqlite3.xcconfig, the one place it lives
	openssl      3.5.9    static, before freetds
	freetds      1.4.27   --enable-msdblib, apps/server/pool/odbc off, and the
	                      recipe's sybdb.h BOOL edit (spelled for GNU sed)
	zlib         1.3.2
	bzip2        1.0.8    CC=clang: its Makefile hardcodes gcc
	libarchive   3.8.9    the .mad container's tar/bzip2 path
	mariadb      3.4.11   the mariadbclient static target, openssl + external
	                       zlib, auth plugins static, others off (mirrors
	                       Compressor/lib/recipes/mariadb.sh)
	postgres     17.11    the libpq static client library + libpgcommon/libpgport,
	                       with openssl, without readline/icu/gssapi/ldap/pam/xml/
	                       xslt/lz4/zstd/zlib (mirrors Compressor/lib/recipes/postgres.sh)

Quedan dos dependencias de compilación externas de la retirada compilación de mysqlclient
(`libncurses-dev` y `libtirpc-dev`, que necesitaba el cmake de mysql); la compilación de
mariadb no las usa, pero siguen en la imagen.

## Qué compila y qué no

| Framework | Compilación de Linux | Excluido, y por qué |
|---|---|---|
| MADFoundation | 26 de 27 | `MADKeyChain` (Security.framework; §4: la ruta de actualización nunca lee el llavero). El paraguas se va con él |
| MADDataStructures | los 17 | (los archivos del objetivo de Xcode; `madmap.cpp` tampoco está en él) |
| MADFileManager | 10 de 11 | `MADCloudFileCoordinator` (NSMetadataQuery; §4: iCloud muere en la Fase D) |
| MADCocoaExtensions | 7 de 17 | los diez dibujantes/presentadores de UIKit (colores, etiquetas, campos de texto, alertas, ayudas de vistas, el presentador de errores, MessageUI) |
| MADAPI | 8 de 11 | los tres controladores de vista de conexión (§3: no son sin interfaz gráfica) |
| MADSqlite3 | los 26 | (cinco archivos `.m` huérfanos tampoco están en el objetivo de Xcode) |
| MADTds | el 1 | |
| MADTdsClient | 4 de 5 | su controlador de vista de conexión |
| MADMySQL | 18 de 19 | su controlador de vista de conexión |
| MADPostgres | 5 de 6 | su controlador de vista de conexión |
| MAD | 150 de 181 | la cola de interfaz (§5.2), `MADocument` + las operaciones que construyen/cierran uno (las de la Fase D), las operaciones de llavero, los archivos de elementos respaldados por MADBarcodes. Cada uno se nombra en `cmake/MADSources.cmake` |

La lista de fuentes de cada framework es un `cmake/<Name>Sources.cmake` junto a la
compilación, con las exclusiones nombradas y sus motivos: la misma forma que
`MADFoundationSources.cmake`. `MADExplorer`, `MADBarcodes`, `MADFeedback` y
`Scrimpter` no están en la compilación de Linux en absoluto (docs/project/MAD_LINUX.md §3).

La compilación de Linux suple lo que le falta a GNUstep sin tocar las fuentes de los frameworks:

* un shim de inclusión por framework para que las autoimportaciones `<Framework/…>` se resuelvan
  (el de MAD es un directorio de enlaces simbólicos, porque el objetivo de Xcode aplana sus
  cabeceras como `<MAD/Foo.h>`), más cuatro shims de cabeceras de bibliotecas
  (`<MADSqlite3/sqlite3.h>`, `<MADTds/sybdb.h>`, el paraguas de MADTdsClient,
  `<MADPostgres/libpq-fe.h>`);
* una cabecera de preludio (`Compat/MADCompat.h`) que lleva las carencias de plataforma que son
  macros o typedefs (véase la lista de abajo);
* enlace con whole-archive, el `-ObjC` de Apple, sin el cual las categorías de los frameworks
  se descartan silenciosamente de los archivos estáticos;
* una categoría compilada en `libmad.a` (`target_sources` en
  `Linux/CMakeLists.txt`): los `-whereClauseWithRowIds:` /
  `-whereClauseWithParameters:` de MADQuery+Sqlite3 se alcanzan por envío de mensaje, así que el enlazador
  descarta el miembro del archivo, y aplicar whole-archive a `libmadsqlite3.a` duplicaría
  los objetos de compatibilidad que cada archivo de framework ya incluye;
* `-lgnustep-base` antes de `-lobjc` en la línea de enlace: libobjc2 exporta un
  `objc_enumerationMutation()` débil que aborta, y GNUstep Base exporta el real
  que lanza una excepción, y gana la primera biblioteca de la línea.

Los frameworks en sí ganaron pequeñas salvaguardas de plataforma, todas `#if __APPLE__`
para que las rutas de Apple queden textualmente sin cambios. Las suites de macOS son la prueba
de que no alteran el comportamiento: MADFoundation, MADDataStructures, MADFileManager,
MADCocoaExtensions, MADAPI, MADSqlite3, MADMySQL, MADTdsClient, MADPostgres
y MAD están todas en verde en el simulador, y el espacio de trabajo `MAD Designer` compila.

## Los drivers se registran, no se importan

El constructor solía importar los drivers, que es el ciclo `MAD` ↔ drivers
(`docs/project/ROADMAP.md` §5.1). `MADDatabaseDriverRegistry` (`MADAPI`) es ahora la costura: la clase de conexión de cada
driver implementa `MADDatabaseDriver` y se registra en
`+load`, y `MADDatabase+Constructor` / `MADDatabaseConnection+Constructor` buscan un
driver por `MADDatabaseType` en lugar de nombrar uno. Por lo tanto, qué drivers tiene un proceso
depende de lo que *enlaza*.

En Apple, el anfitrión enlaza los frameworks de drivers: la aplicación y la CLI nombran MADMySQL,
MADTdsClient y MADPostgres, y `MAD.framework` ya no lo hace, así que su bundle de pruebas también los nombra.
En Linux, los archivos de los drivers se enlazan **con whole-archive** desde el objetivo `mad`
(`$<LINK_LIBRARY:WHOLE_ARCHIVE,…>`, que se propaga a todos los consumidores): un archivo
estático se busca, no se carga, así que un miembro al que nada hace referencia —el
`+load` de un driver, o una categoría— se descarta de otro modo. No es un detalle menor: es lo que
hizo que `mad refresh` sobre MySQL abortara antes de corregirse (§ la categoría de abajo).
`MADDatabaseDriverDispatchTests` fija el registro, y
`Linux/Tests/MADHeadlessDocumentTests.m` impulsa toda la cadena.

Añadir un driver significa una entrada de enlace en `Linux/CMakeLists.txt` y nada en `MAD`.

## Los shims de compatibilidad son un archivo propio, y por qué

Cada archivo de framework solía incluir `Compat/*.m`. Eso hacía que aplicar whole-archive a dos
de ellos produjera un error de símbolo duplicado, y por eso exactamente una categoría
(`MADQuery+Sqlite3`) se había compilado a mano en `libmad.a`. La CLI descubrió el
coste de esa disposición: `mad refresh` contra MySQL en vivo **abortaba** (SIGABRT,
sin diagnóstico) porque `MADMySQLFetch (DataTable)` —el método que ejecuta la
sentencia preparada— era una categoría alcanzada por envío de mensaje, así que el enlazador
nunca había incluido su archivo objeto. `nm` mostraba `.objc_category_MADMySQLFetchDataTable`
presente en el binario de pruebas de MySQL y ausente en el de la CLI.

`madcompat` es ahora su propia biblioteca estática, con whole-archive en cada ejecutable
(`mad_add_test`, `ToolchainProbe`, `mad-cli`), y los archivos de los frameworks son
puros, así que los archivos de los drivers se pueden tratar con whole-archive como cualquier otro código. El
truco por archivo de `target_sources` desapareció. La regla general que esto deja: **un archivo de
framework solo es seguro de enlazar si se trata con whole-archive**; cualquier cosa menos que eso
y sus categorías faltan silenciosamente en tiempo de ejecución.

## Divergencias de GNUstep que encontraron la sonda y las pruebas

* **NSOperationQueue y KVO: encontrado aquí, corregido en MADOperation.** El
  `NSOperationQueue` de GNUstep elimina su observación de `"isReady"` en cada notificación
  que recibe, y comprueba `isReady` una vez más después de registrar esa
  observación. MADOperation solía avanzar su máquina de estados desde dentro de
  `-isReady` (a través de las claves dependientes KVO de `state`), así que la primera
  comprobación de disponibilidad disparaba la notificación que la cola esperaba, y la
  segunda llamada eliminaba una observación que ya se había ido:
  `NSInvalidArgumentException`, y la operación nunca se ejecutaba. MADOperation ahora
  impulsa el avance de forma explícita (`-willEnqueue` inicia la evaluación de condiciones)
  y envía `will`/`didChangeValueForKey:` para `isReady`, `isExecuting` y
  `isFinished` solo cuando cada valor cambia realmente, así que la cola ve una
  notificación `isReady` por encolado, como la de Apple. Las pruebas de Linux
  lo comprueban claramente en ambas plataformas; nada está silenciado, y la ruta de actualización de la Fase D
  ya no queda bloqueada por ello.
* **La archivación con codificación segura no existe.** `archivedDataWithRootObject:
  requiringSecureCoding:YES` devuelve nil sin error, así que las rutas de código
  que deben funcionar fuera de Apple —la caché de renderizado `.madac` de MADArrayCaching,
  el conjunto de claves de grupo de MADDataTableFast, los archivos de MADFileUtilities— recurren a
  `requiringSecureCoding:NO` tras `#if __APPLE__`, que es el mismo codificador
  sin el endurecimiento. El lado de desarchivado no necesita alternativa:
  `unarchivedObjectOfClass:fromData:error:` y su forma plural sí funcionan en GNUstep
  (medido el 2026-10-06: el informe anterior de la sonda de que ni eso ni
  `+unarchiveTopLevelObjectWithData:error:` existen venía de una rama a la que el archivo
  estricto nil nunca llegó, así que solo lo segundo fue siempre cierto). Ese
  no existe y se suple en `Compat/` sobre `+unarchiveObjectWithData:`.
* **`-localizedCaseInsensitiveCompare:` distingue mayúsculas y minúsculas en GNUstep**: ya
  no es fundamental (corregido el 2026-10-25). La colación de SQLite que registra
  MADDatabaseSqlite3 (`compare_string_utf8_localized_asc_collation`),
  los selectores de ordenación en memoria y el comparador de cadenas del formateador de informes
  pasan todos por un orden definido propio (`NSString+Comparison.h`:
  plegado de mayúsculas y minúsculas, y después orden de puntos de código UTF-8), así que la divergencia que causaba
  la comparación localizada ha desaparecido, no se ha disimulado; las pruebas comprueban el orden definido
  de forma idéntica en ambas plataformas. Véase la sección `mad export` de `docs/project/MAD_CLI.md`.
* **La codificación en tiempo de ejecución de BOOL y la herencia de `class_getProperty`:
  encontradas por las suites rptq de MAD, corregidas en RptqObject.** El tiempo de ejecución compara la codificación de tipo
  de un accesor instalado con la del sitio de llamada compilado, y BOOL es
  `unsigned char` (`'C'`) en GNUstep donde Apple usa `signed char` (`'c'`),
  así que los accesores booleanos instalados dinámicamente de `RptqObject` ahora registran una
  codificación por plataforma (`MAD_RPTQ_BOOL_TYPE`). Y `class_getProperty()` de GNUstep
  mira solo a la propia clase, mientras que el de Apple recorre
  la cadena de superclases, así que una propiedad heredada (el `alignment` de una etiqueta) caía
  en la rama de objeto genérico; `RptqPropertyNamed` hace el recorrido en ambas
  plataformas. El modo de fallo era un valor silenciosamente incorrecto, no una caída, así que ambos
  quedan fijados por las suites portadas.
* **Las API de archivos de GNUstep rechazan URLs sin esquema: encontrado por las
  pruebas portadas de MADFileManager, corregido en MADURLFactory.** `-contentsOfDirectoryAtURL:` y
  `-writeToURL:` no hacen nada silenciosamente para una URL que no lleva el esquema `file://`
  (medido el 2026-10-11), y `+newURLForLocalDocumentsDirectory`
  construía su URL con `-initWithString:` a partir de una ruta, lo que Apple tolera.
  Ahora usa `+fileURLWithPath:`, la respuesta honesta en ambas plataformas; eso,
  más el shim de coordinación de abajo, convirtió cinco necesidades aparcadas en cinco
  pruebas que pasan (`MADLocalFileCoordinatorTests`, 12 pruebas, 0 necesidades).
* **los objetos dispatch son punteros C simples** (`os/object.h` rechaza el soporte ObjC fuera de Darwin, y
  rechaza `OS_OBJECT_USE_OBJC=1` de plano: los comentarios de la compilación de
  libdispatch lo dicen), así que ARC no puede poseer uno: cada
  propiedad dispatch `strong`/`copy` es `assign` fuera de Apple, comentada en
  el lugar. Las colas se crean una vez y viven durante todo el proceso; nada las libera.
* **Carencias más pequeñas, suplidas o protegidas:** `NSOperation.name`,
  `NSOperation.cancelled` y `NSOperation.asynchronous` (GNUstep conserva solo
  la antigua grafía `-isConcurrent`, como un stub que siempre responde NO: su
  propio control interno la consulta, y sin la categoría Compat respondiendo
  `[self isAsynchronous]` una operación asíncrona que terminaba lanzaba una excepción desde
  `-dealloc`), los métodos de ubicuidad de NSFileManager (sin iCloud fuera de
  Apple; todas las respuestas son la vacía), `-initWithFilePresenter:` en
  NSFileCoordinator, `-coordinateAccessWithIntents:queue:byAccessor:`
  (la implementación de GNUstep falla cuando ejecuta el accesor: SIGSEGV,
  medido; la categoría Compat llama al accesor en la cola dada, no
  habiendo nada con lo que coordinar fuera de Apple), el acceso con ámbito de seguridad de NSURL y
  `-fileSystemRepresentation`, los lectores `-options:error:` de NSData y sus
  constantes, `-decodeTopLevelObjectOfClasses:forKey:error:` en NSCoder,
  `-registerUndoWithTarget:handler:` en NSUndoManager,
  `+propertyListWithStream:options:format:error:` (un stub que devuelve nil, con el
  flujo nunca leído: la categoría Compat lee el flujo y delega en
  `+propertyListWithData:`; con ella, `-loadFromCacheWithUrl:` de MADDataTable
  se ejecuta en Linux y se comprueba en ambas plataformas), las grafías `CG*Value` de NSValue,
  las macros `CF_ENUM`/`CFAvailability`, las llamadas de extracción de CFNumber
  (un `CoreFoundation/CFNumber.h` de compatibilidad), `copyfile(3)` en POSIX,
  `htonll`, los escalares de MacTypes (`Float64`, `SInt32`…`UInt64`, `Boolean`),
  `NS_RETURNS_INNER_POINTER`, la grafía `__nullable`,
  `NSOperation.qualityOfService`, `NSDataWritingFileProtection*`,
  `containerURLForSecurityApplicationGroupIdentifier:` (ausente: la razón por la que
  la ruta de grupo de MADURLFactory recurre a los directorios por usuario),
  `QOS_CLASS_DEFAULT` de `<sys/qos.h>` (ausente).
* **Verificado correcto:** ARC y puesta a cero de referencias débiles, bloques, excepciones,
  `@synchronized`, KVO (manual y claves dependientes), la KVO de la máquina de estados de `NSOperation`,
  `NSPredicate predicateWithFormat:@"error != nil"` (el predicado exacto de MAD),
  dispatch (once/colas/grupos/semáforos), el drenaje de la cola principal
  bajo un ejecutable simple, JSON, UUID, fechas, plists, descriptores de ordenación, flujos,
  NSDecimalNumber, NSCalendar y archivación con claves en la ruta permisiva. El informe
  completo es lo que imprime `--probe`; sus 19 comprobaciones principales rigen
  el código de salida, sus 12 elementos de informe no (la ejecución de la CLI añadió
  `directory-enumeration` y `directory-enumeration-url-form`).

**Formato de moneda (encontrado el 2026-10-16, corregido el 2026-10-17).** Dos comportamientos de GNUstep
hacían que el dinero renderizado difiriera del de Apple: `NSNumberFormatterCurrencyStyle` renderiza
sin dígitos fraccionarios para cualquier configuración regional (`en_US` daba `$1`, Apple `$0.99`), y la configuración regional
actual de la imagen es `en_US_POSIX`, cuya moneda tiene un espacio después del símbolo y ninguna
agrupación. Ambos se resuelven sin reemplazar el formateador: el informe toma su
configuración regional y sus dígitos fraccionarios del formato numérico del documento (la alternativa es
`en_US`, no la configuración regional de la máquina), y el símbolo de moneda se escribe explícitamente con
el signo del yen normalizado (GNUstep lo escribe U+FFE5 de ancho completo). Una comparación de 60 casos,
seis configuraciones regionales por diez valores, incluidos negativos y 1e12, es ahora idéntica byte a byte
entre las dos plataformas; la única diferencia que encontró fue ese punto de código del yen.
`docs/project/BUGS.md` tiene la entrada (archivada: está corregida), y las exportaciones del lado del renderizado de abajo están
fijadas a los bytes del Mac.

## El recuento de necesidades, y por qué son 6

La imagen de la Fase B informaba de 3 necesidades; la imagen terminada de la Fase C informa de 6, y
las tres nuevas vienen de que las suites de MAD aterrizan en maquinaria exclusiva de Apple.
Son necesidades, no omisiones, deliberadamente: la comprobación no puede ejecutarse
sin un recurso que Linux no tiene, y la necesidad lo dice en voz alta donde una
omisión lo ocultaría.

* **Las tres que ya estaban.** La comprobación de archivación estricta de la sonda de la cadena de herramientas
  (`requiringSecureCoding:YES` devuelve nil; arriba) y su comprobación de grupo de aplicaciones
  (`containerURLForSecurityApplicationGroupIdentifier:` está ausente), más
  la condicional de MADCredentialTests sobre la misma carencia de archivación estricta.
* **MADStoreTests**: la comprobación de fidelidad del modelo necesita Core Data y el
  `MAD.momd` compilado, ambos exclusivos de Apple.
* **RptqStoreContextTests, dos veces**: la fixture de muestra convertida necesita
  `MADStoreConverter`, Core Data y `London.mad`, y la ruta del documento necesita
  `MADocument` y `MADStoreConverter` (pendientes de resolver en la Fase D).

Las suites de bases de datos en vivo se omiten (nunca fallan) cuando no hay ningún servidor disponible: el
mismo contrato que tienen los schemes de Xcode. Y los benchmarks de SQLite se omiten en su
escala predeterminada; las omisiones se cuentan por separado y no son necesidades.

## Las suites de bases de datos en vivo se ejecutan aquí

`MADMySQLLiveTests`, `MADTdsClientLiveTests` y `MADPostgresLiveTests` se comunican con
servidores reales y se omiten (nunca fallan) cuando no hay ninguno disponible: el mismo contrato que
tienen los schemes de Xcode. Los servidores son los tres contenedores que
`docs/project/DEVELOPER.md` documenta; inícielos primero:

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on :13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on :1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on :5432

	docker run --rm \
		-e MAD_MYSQL_TEST_HOST=host.docker.internal \
		-e MAD_MYSQL_TEST_PORT=13306 \
		-e MAD_TDS_TEST_HOST=host.docker.internal \
		-e MAD_PG_TEST_HOST=host.docker.internal \
		--entrypoint bash mad-linux:phase-b -c \
		'/src/Linux/build/MADMySQLLiveTests && /src/Linux/build/MADTdsClientLiveTests && /src/Linux/build/MADPostgresLiveTests'

Medido el 2026-10-17 con esa configuración limpia: MySQL 44/44, 311 comprobaciones (sentencias
preparadas, las conversiones de tipos, descubrimiento de esquema), y SQL Server 29/29, 169
comprobaciones (la ruta de transporte de freetds, el descifrado de fecha/hora, decimal/blob/nvarchar,
descubrimiento de esquema); PostgreSQL 14/14, 132 comprobaciones (medido el 2026-10-27: obtención con libpq,
conversiones de tipos OID, descubrimiento de esquema en esquemas públicos y no públicos), así que los tres drivers funcionan en Linux, no solo compilan.
Las dos pruebas de fallo de conexión de `MADTdsClientTests` se ejecutan sin servidor.

## Licencias

Todo lo de la imagen es herramienta de compilación; nada se enlaza en la aplicación.
libobjc2 es MIT; libdispatch es Apache-2.0 con la excepción del tiempo de ejecución de Swift;
GNUstep Base es LGPL-2.1-or-later; gnustep-make es GPL-3.0-or-later, y su
`Testing.h` (GPL-3.0-or-later) se compila en los binarios de prueba de Linux: esos
existen solo dentro de esta imagen de compilación. Las bibliotecas C llevan sus propias licencias
(docs/project/THIRD_PARTY_LICENSES.md); el problema GPL de mysqlclient está resuelto: la D1 fue
a MariaDB Connector/C (LGPL-2.0-or-later, elegida LGPL-3.0) y esta imagen
lo compila (`docs/project/TASKS.md` §10). La imagen de ejecución se publica como
`ghcr.io/mthomason/mad`, así que los componentes LGPL que distribuye necesitan ofertas de
revinculación: la oferta escrita en `ThirdParty/Licenses/README.md` ahora nombra la
imagen, y la entrada del registro es `THIRD_PARTY_LICENSES.md` §9. gnustep-make
es herramienta de compilación y no está en la imagen de ejecución.

## La CLI se ejecuta aquí: Fase D

`mad` lo compila este CMakeLists desde `CLI/Source` (las mismas fuentes que
`CLI/build.sh` compila para el Simulador de iOS), enlaza los once frameworks
con whole-archive y se ejecuta en la imagen:

	/build/mad inspect <document.mad>
	/build/mad schema  <document.mad>
	/build/mad query   <document.mad>
	/build/mad refresh --credentials user:pass <document.mad>

`export` es el único verbo que no está aquí: el PDF es un contexto de Core Graphics dibujado por
un `UIPrintPageRenderer`, así que se queda en Apple y lo dice (`docs/project/MAD_LINUX.md` §5.2;
la decisión del renderizador es de la Fase E).

**`export` hizo crecer aquí sus formatos de Foundation (Fase E, 2026-10-16).** La costura de exportación
(`MADReportExporting` + `MADReportExporterRegistry`, `docs/project/MAD_CLI.md` §5.3) está en `mad`, así que
`text`, `csv` y `json` se ejecutan en la imagen y escriben los mismos bytes que la herramienta del Mac
(los formatos del lado del renderizado —`html`, `html-flow`, `json-report`— también se ejecutan aquí; véase la
sección de abajo, y `pdf` explica por qué no puede).
La comparación, ejecutada para el registro sobre la fixture London (`CLI/Fixtures/London.portable.mad`,
actualizada primero, `sha256sum` en cada lado):

| formato | bytes | sha256 (idéntico en ambas plataformas) |
|---|---|---|
| `json` | 64595 | `569c6ee25223c51ecffd15923dd897e75c8362d72f4ece72f8dbeee3e9c8cdbc` |
| `csv` | 12538 | `773f6215a5447f72d499282d337a5916b11f0f3b06cb4c5aec134db6f493cb21` |
| `text` | 40441 | `7dcee96c45951fac0e0057094a6a142c90a88d6d88a1c03278b273f5140c6e49` |

`Linux/Tests/MADReportExporterTests.m` es la misma comprobación como prueba: actualiza la
fixture y comprueba el checksum FNV-1a de cada exportación contra los bytes del Mac (más la
forma y algunos valores), así que una grafía que se desvíe entre GNUstep y Apple falla
aquí; y los mismos checksums FNV-1a están fijados ahora en el lado del Mac
(`MAD/MADTests/MADReportExporterTests.m`), así que la desviación no puede pasar inadvertida en ninguna de las
plataformas. `json-report` es el mismo esquema con el informe renderizado como miembro adicional;
necesita la mitad del renderizado (`MADReportFormatter` y el renderizador de páginas), que
compila aquí desde la Fase E: la sección de abajo lleva su resumen, y solo `pdf`
se registra y explica por qué no puede ejecutarse (`docs/project/MAD_CLI.md` §3); `Linux/Tests/MADReportExporterTests.m`
comprueba que falla
en lugar de escribir silenciosamente la mitad de los datos.

**Cómo se resolvió la clase de documento.** `MADocument` es un `UIDocument`, así que no
puede venir, y `MADCLIDocument` solía construirse sobre él. La mitad de datos de
un documento es ahora un protocolo —`MADDocumentDataProtocol`— que `MADocument`
implementa (comportamiento sin cambios; cada miembro era ya uno de sus accesores)
y `MADHeadlessDocument` implementa: abre el contenedor y el almacén portátil
con `MADDocumentStore` (la disposición del almacén que MADocument también usa, así que los dos
no pueden discrepar sobre ella), compila la consulta, construye la base de datos respaldada por el driver
a través del registro y mantiene la tabla de filas. La cadena de actualización toma el
protocolo, así que Apple y Linux ejecutan el *mismo* `MADOperationRefresh`: solo una de sus ramas del
lado del renderizado (el formateador de informes y los gestores de diseño de secciones) está
`#if __APPLE__`. El usuario eligió esta forma el 2026-10-16 en lugar de un shim de `UIDocument`
en Compat y de dividir `MADocument` mismo.

**El punto de control, desde dentro de la imagen** (Docker Desktop; los documentos están en
`CLI/Fixtures/`, y su nombre de host `mac` se resuelve aquí al Mac):

| Ejecución | Resultado |
|---|---|
| `mad inspect` sobre `London.mad` (la muestra heredada) | v0, 6 miembros, almacén + WAL + SHM informados |
| `mad inspect` sobre `London.portable.mad` | v1, 4 miembros, `StoreContent/store.sqlite (portable)`, 41 secciones / 25 elementos |
| `mad schema` sobre las dos fixtures portátiles | idéntico a la salida del Mac, byte a byte |
| `mad query` sobre las mismas | el mismo conjunto de campos que el Mac; el *orden* difiere (abajo) |
| `mad refresh` sobre `London.portable.mad` | 76 filas, y la caché de filas es idéntica a la del Mac (21 columnas por nombre, 76 filas, todos los valores iguales) |
| `mad refresh --rows 50 --credentials root:root` sobre `MySQL.employees.mad` | 50 filas de MySQL 8.4 en vivo (obtención con sentencia preparada, base de datos `employees`) |
| `mad refresh --rows 20 --credentials sa:Root1@Root2` sobre `TDS.AdventureWorksLT2022.mad` | 20 filas de SQL Server 2022 en vivo (freetds, `AdventureWorksLT2022`) |
| `mad refresh --rows 25 --credentials mad:mad_test_pw` sobre `Postgres.chinook.mad` | 25 filas de PostgreSQL 17 en vivo (libpq, `chinook`) |

Las suites en vivo están de acuerdo: `MADMySQLLiveTests` 44/44, `MADTdsClientLiveTests` 29/29
y `MADPostgresLiveTests` 14/14 desde la misma imagen. `Linux/Tests/MADHeadlessDocumentTests.m` es el mismo
punto de control como prueba: abrir, esquema, consulta, resolución del driver, actualización, 76 filas,
así que falla en CI en lugar de en una ejecución manual.

**Dos diferencias que conviene conocer, ambas encontradas aquí.** El orden de las columnas de la lista SELECT
era el orden de *conjunto* (`MADQueryActiveQueryFields` acumula en un `NSSet`), así que el
mismo documento producía un orden distinto en Apple y en GNUstep: los mismos campos,
distinto orden; los *datos* de la caché son idénticos una vez comparados por nombre de campo, y
los nombres de columna `c<hash>` de la caché derivan de hashes, así que también diferían por plataforma.
**Resuelto el 2026-10-16 (la decisión de la forma de la exportación JSON, `docs/project/MAD_LINUX.md` §10.1):** el
orden ahora se define como el alias de columna, ordenado con `-compare:`, en ambos constructores de SQL,
así que el SQL generado, la caché de filas y cada exportación coinciden en ambas
plataformas (docs/project/BUGS.md, la entrada de la lista SELECT; las pruebas de orden en
`Linux/Tests/MADQuerySelectExpressionTests.m`). Una caché actualizada antes del cambio
ordena sus columnas de forma distinta a una actualizada después: los mismos datos, un nuevo
orden, así que actualice una vez antes de comparar cachés a través de esa fecha.

## El escritor se ejecuta aquí, y las dos plataformas coinciden

La otra mitad de la Fase E (`docs/project/MAD_LINUX.md` §9; el requisito del usuario, 2026-10-16): el escritor
`.mad` funciona en Linux y produce los **mismos bytes** que el del Mac para el mismo
documento. `mad write <doc.mad> --out <copy.mad> [--reproducible]` es la superficie, y
el documento se abre sin interfaz gráfica en ambas plataformas, así que ambos lados ejecutan el mismo escritor.

Medido sobre la fixture London (`CLI/Fixtures/London.portable.mad`):

	$ mad write London.portable.mad --out copy.mad --reproducible
	16261 bytes, sha256 09815b24e91e03b6e526008f7c2700074fed10679771b9e1ee4609e54a1192f5
	                                     (identical on the Mac and in this image)

La fixture es un almacén de versión 1, y la escritura abre el documento primero, así que la
copia abierta lleva la migración del almacén (Fase A de la entrada de SQL: la columna `sqlSourceText`
y `user_version` 2) en ambas plataformas; los bytes de arriba son los del documento migrado.

`--reproducible` fija uid/gid 0, la hora fija 2001-01-12T00:00:00Z y un recorrido de miembros
ordenado; una escritura ordinaria conserva los metadatos reales de los miembros, así que difiere entre ejecuciones
y plataformas por diseño.

Hubo que corregir dos cosas para que el escritor se ejecutara aquí, ambas registradas en `docs/project/BUGS.md`
(la entrada de identidad de bytes de `.mad`):

* `-write_archive:` recorría cada URL enumerada *hasta* el directorio archivado, y
  `-enumeratorAtURL:` de GNUstep elimina el directorio contenedor, así que el bucle nunca
  llegaba. Ahora los miembros se leen con `-subpathsAtPath:`, como ya lo estaba la lista de miembros
  de la CLI.
* `backup_file` entregaba su ruta a `dirname(3)`/`basename(3)`, que glibc tiene permitido
  modificar y de hecho modifica: la ruta del archivo del llamador volvía truncada en su última barra, así que
  el documento compuesto se escribía sobre su propio directorio (`Open (…) failed - Is a
  directory`). Las implementaciones de Apple dejan el búfer intacto, y por eso solo Linux
  lo veía.

`Linux/Tests/MADArchiveManagerTests.m` es la cobertura (5 pruebas, 0 necesidades): la ida y
vuelta (`docs/project/MAD_CLI.md` §6.1), la caracterización del modo ordinario, el modo reproducible,
incluido un checksum FNV-1a del documento completo contra los bytes del Mac, y la
ruta del documento, que escribe una copia y deja intacta la fuente.

## La mitad del renderizado y los formatos HTML se ejecutan aquí

La segunda decisión de la Fase E (del usuario, 2026-10-16) fue HTML primero y PDF último, y el
paso de HTML es donde la mitad del renderizado sale de Apple. Se movió como una conformidad:

* `MADReportFormatter` toma `id <MADDocumentRenderProtocol>`; `MADHeadlessDocument`
  lo implementa, y la rama de renderizado de `MADOperationRefreshInitialize` se basa en el protocolo.
* `MADReportPageBuilder` es el recorrido de páginas, extraído de `MADPrintPageRenderer` (que conserva
  `UIPrintPageRenderer` y el dibujo). Es dueño de la geometría del lado del renderizado (US
  Letter, el recorte de 1pt) y de la secuencia de preparación, así que el PDF, json-report y los
  formatos HTML no pueden discrepar sobre una página.
* `MADDocumentRenderDataSource` es la única implementación de las lecturas de la mitad del renderizado,
  compartida por `MADocument` y `MADHeadlessDocument`; la familia `MADPrintPageElement`
  compila aquí (sus inicializadores son Foundation; solo el dibujo es de Apple).

`mad export` ahora tiene `html`, `html-flow` y `json-report` aquí, y `pdf` se registra
y dice por qué no puede ejecutarse (su cuerpo es Core Graphics). Medido contra el Mac sobre
la fixture London:

| formato | bytes | sha256 (idéntico en ambas plataformas) |
|---|---|---|
| `json-report` | 118,109 | `9d01d0daabbb5e38921c0bfbed083b288031c9340e9a4af81679d03b691ce94c` |
| `html` | 62,007 | `285541ed59333e0e55b8c7fe5619e4b64dde7aaf8e93a24ba881b40111ab2327` |
| `html-flow` | 54,766 | `0565204a55d02f925602b5c0bf298bb0e41c9cbe56bea6df770e828a35782382` |
| `pdf` | — | no se produce aquí; `+isAvailable` NO con el motivo |

Los formatos del lado del renderizado son idénticos byte a byte entre las plataformas, como los de datos:
cada marco, fuente, tamaño de fuente, atributo, alineación, tramo de texto y caja de página, y el dinero
(el hallazgo que los hacía diferir, y su corrección, están arriba y en `docs/project/BUGS.md`).
`Linux/Tests/MADReportExporterTests.m` fija los tres checksums.

## La imagen de ejecución: el entregable de la CLI (Fase F)

El entregable de la Fase F es un contenedor que ejecuta la CLI, no un árbol de compilación del que un
desarrollador tenga que recordar la ruta. `./Linux/build.sh --runtime` lo compila
desde el mismo Dockerfile (la etapa `runtime`, aguas abajo de `build`), etiquetado
`mad-cli:latest`:

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad

La imagen se publica (2026-10-26) como `ghcr.io/mthomason/mad`, etiquetada
`latest` y con el SHA corto del commit. Las etiquetas publicadas las compila CI
(`.github/workflows/publish-image.yml`) en ubuntu-latest, así que son
**linux/amd64**: la compilación local `mad-cli:latest` del Mac es arm64. Descargar
en lugar de compilar es la ruta de diez segundos; en Apple Silicon añada
`--platform linux/amd64` (Docker Desktop ejecuta la etiqueta bajo emulación;
sin el indicador la descarga falla con `no matching manifest`):

	docker run --rm --platform linux/amd64 -v "$PWD/CLI/Fixtures":/docs:ro \
		ghcr.io/mthomason/mad mad inspect /docs/London.portable.mad

Distribuir la imagen obliga a ofertas de revinculación de los componentes LGPL que contiene
(GNUstep Base, y mariadb y freetds estáticos dentro de `mad`); la oferta escrita
en `ThirdParty/Licenses/README.md` nombra la imagen (la sección §Licencias
de arriba).

La imagen contiene:

* `/usr/local/bin/mad`, la ruta estable de la regla de instalación de CMake (el binario ya
  no solo es alcanzable en `Linux/build/mad`);
* los objetos compartidos que enlaza el binario: GNUstep Base, libobjc2, libdispatch
  y libBlocksRuntime, más los directorios de ejecución y la configuración de GNUstep. Las
  demás bibliotecas C (sqlite3, freetds, openssl, zlib, bzip2, libarchive,
  mariadb, postgres) son estáticas y ya están dentro del binario;
* ninguno de los datos de `share` de mysqlclient: Connector/C incorpora sus mensajes
  de error de cliente y no instala archivos en `share/`;
* `chinook.sqlite3` en `/root/GNUstep/Library/ApplicationSupport/`, donde se resuelve el nombre
  de base de datos simple de un documento Sqlite3. Un documento almacena el nombre,
  no una ruta, así que este único archivo es lo que permite que las fixtures London y Music
  incluidas en el repositorio se actualicen sin configuración adicional.

Deja atrás el compilador, cmake, git, las fuentes, los 126 binarios de prueba,
y los archivos estáticos y las cabeceras: la etapa final es `ubuntu:24.04` más
las bibliotecas de ejecución de apt, no la imagen de la cadena de herramientas. Ocupa **283 MB en
disco (66.5 MB comprimida)**; la imagen de compilación ocupa 6.65 GB.

Cada verbo se ejecuta de la misma manera:

	docker run --rm -v "$PWD/docs":/docs mad-cli:latest mad schema /docs/x.mad
	docker run --rm -v "$PWD/docs":/docs -v "$PWD/out":/out mad-cli:latest \
		mad export /docs/x.mad --format html --out /out/x.html
	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad refresh /docs/MySQL.employees.mad --credentials root:root --rows 50

Las fixtures en vivo nombran el servidor `mac` (`CLI/Fixtures/README.md`); desde el
contenedor eso se resuelve al Mac a través de Docker Desktop. La caché de actualización
se escribe en `/root/GNUstep/Library/Caches` dentro del contenedor, así que
no sobrevive a `--rm`; `export` actualiza el documento en sí, así que eso no es
un problema. Añada un volumen si una caché debe persistir entre ejecuciones. La imagen
se ejecuta como root; una ejecución con `--user` necesita la base de datos de muestra (y cualquier documento) en
el directorio Application Support propio de ese usuario.

**`--verify` es la comprobación repetible.** Reconstruye la imagen de ejecución y ejecuta
`Linux/verify-cli.sh` en ella con el repositorio montado en solo lectura: los seis
verbos, cada formato de exportación contra su resumen fijado, la negativa de `pdf`, los
bytes del escritor `--reproducible`, los códigos de salida y la forma de la propia imagen (sin
clang, cmake, git ni árbol de compilación). 41 comprobaciones; termina con un código distinto de cero en cualquier fallo.

	./Linux/build.sh --verify
	...
	MADVERIFY 41 passed, 0 failed

`--live` añade las actualizaciones de MySQL, TDS y PostgreSQL (50, 20 y 25 filas); inicie
primero los tres contenedores de prueba (`docs/project/DEVELOPER.md` tiene sus scripts
y credenciales):

	MADMySQL/TestDatabase/mysql-test-db.sh up
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up
	MADPostgres/TestDatabase/postgres-test-db.sh up
	docker run --rm -v "$PWD":/repo:ro mad-cli:latest \
		bash /repo/Linux/verify-cli.sh --live

**Publicada, con CI (2026-10-26, revirtiendo la decisión del 2026-10-17).**
`.github/workflows/publish-image.yml` publica la etapa de ejecución en
`ghcr.io/mthomason/mad` como `latest` y `<short-sha>` en cada push a
master, además de a mano desde la pestaña Actions (`workflow_dispatch`); la
compilación local `./Linux/build.sh --runtime` no cambia. Las etiquetas publicadas son
amd64, compiladas por CI; la compilación local del Mac es arm64.

**Un riesgo del Dockerfile, escrito porque afectó a la primera compilación.** La
etapa de ejecución es la última del Dockerfile, así que `docker build` sin
`--target` ahora produce la imagen de ejecución. `build.sh` pasa `--target build`
para la imagen de compilación y `--target toolchain` para la caché de la cadena de herramientas; una
compilación manual debería hacer lo mismo.

## Lo que esto aún no hace

El escritor de PDF de Linux: **aplazado el 2026-10-17, bloqueado por la investigación del usuario; no lo
empiece sin su decisión.** `docs/project/MAD_PDF_LINUX.md` es el archivo de traspaso (lo que
existe, lo que falta, las pilas candidatas con licencias, las preguntas abiertas, la
prueba de aceptación); `docs/project/MAD_LINUX.md` §10.2 registra el razonamiento. Hasta que llegue, un PDF
en Linux es un navegador imprimiendo `--format html`.

Las demás partes de la Fase F, a fecha de 2026-10-17: la **imagen de ejecución** y su **verificación
repetible** están hechas (la sección de arriba), y la **fila de CI se descartó por
decisión del usuario**: no hay GitHub Actions, porque el port de Linux es una prueba de concepto
para pruebas, no una versión de producto. Eso cambió el 2026-10-26 con la publicación en GHCR:
la imagen se publica y `publish-image.yml` la compila y la publica
(la sección de arriba). El **driver de Linux de Compressor** no está hecho y
no se necesita para la CLI: la imagen ya compila las bibliotecas C de forma nativa
(`libraries.conf` + `lib/libraries.sh`). Pregunte antes de empezarlo.
