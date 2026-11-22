---
layout: default
title: "Compilar el motor en Windows"
description: "El toolchain fijado de Clang y GNUstep y la compilación nativa del motor para Windows."
lang: es-419
---

# Compilar el motor de MAD en Windows — arquitectura y registro de decisiones

Esta página registra la compilación del motor para Windows: el toolchain fijado, el port de frameworks y sus shims, y el punto de entrada `Windows/Engine/build.ps1`. La guía de la aplicación está en `/windows.html`.

*Escrito en la fecha original; los hechos del estado actual se conciliaron el 2026-11-22.*

Escrito el 2026-11-18 contra `master` para la rama `windows-engine` (Fase 2
del PoC de Windows). La compilación de Windows es la hermana
de `Linux/`: los frameworks Objective-C del motor headless compilados de forma nativa en
Windows con Clang contra GNUstep Base, para que el mismo motor que ejecuta la aplicación
macOS y la CLI de Linux pueda ejecutarse en Windows. Este documento es el compañero técnico
de `Linux/README.md` / `docs/project/MAD_LINUX.md`; registra la
receta del toolchain, por qué se fija cada pieza, y las decisiones que tomó este incremento.

---

## 1. Qué es esto y qué no es

El objetivo es un MAD Designer nativo de Windows (WPF sobre .NET 10 LTS) que reutiliza el
motor Objective-C headless existente compilado de forma nativa para Windows. La compilación del motor
aterriza bajo `Windows/`, un hermano de `Mac/` y `Linux/`; la aplicación WPF
siguió en las fases 5–6f (`Windows/App`; §6e–§6i).

El incremento de la Fase 2b probó el toolchain y el port de frameworks. La fase 2 (el
primer incremento) compiló **MADDataStructures** y **MADFoundation** y ejecutó una
prueba de humo. La Fase 2b añadió **MADAPI** (la dependencia transitiva que atrae MADSqlite3)
y **MADSqlite3**, compiló la fusión SQLite fijada en una
biblioteca estática, y portó las suites de prueba de Linux para MADDataStructures,
MADFoundation y MADSqlite3 (`Testing.h` de GNUstep + `MADTestSupport.h`). Todavía no
compilaba los frameworks headless restantes, la CLI ni la aplicación.

---

## 2. La receta del toolchain, y por qué se fija cada pieza

El resumen (esta sección se sostiene sola):

### 2.1 Compilador: Clang 20.1.8

El fallo de arranque de la Fase 1 (`0xC0000005` en cada binario de Foundation) era una
regresión de runtime en los componentes flotantes de master de GNUstep — las siete fijaciones
de §2.3 lo corrigen — no un error de codegen de Clang 23. Clang 20.1.8 es el compilador
probado en CI y parte de la receta probada; Clang 22/23 con las fijaciones no se
probaron. Esto es una fijación, no una preferencia; no actualices LLVM sin una nueva
prueba de viabilidad.

### 2.2 La anulación de la puerta STL

Esta máquina envía Visual Studio 2026 (18.12.0), cuyo STL de MSVC exige duramente
"Clang 22 o posterior" (`_MSVC_STL_UPDATE 202609L`, `yvals_core.h:923`):

```c
#elif defined(__clang__)
#if __clang_major__ < 22
_EMIT_STL_ERROR(STL1000, "Unexpected compiler version, expected Clang 22 or newer.");
```

La anulación `-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH` es la propia
salida de emergencia del STL. Se ha probado benigna: un programa C++ que usa `<map>` compila y
se ejecuta con Clang 20.1.8 + la anulación, y también el toolchain completo y los
archivos `.mm` de MAD (que incluyen `<map>`/`<vector>`). Se aplica a la compilación del toolchain
(`Engine/toolchain/stl-gate-override.patch`) y a cada unidad de traducción Objective-C++ de
la compilación de frameworks.

### 2.3 Las siete revisiones fijadas de GNUstep (la regresión de master flotante)

`gnustep/tools-windows-msvc` clona el último master de cada componente
(`TAG=` está vacío en sus scripts de fase). Su CI (`.github/workflows/ci.yml`)
compila y empaqueta el toolchain pero **nunca ejecuta un binario**, así que una regresión
de runtime pasó desapercibida. Las pruebas A/B lo aislaron:

| Componente | 11-14 (funciona) | 11-17/18 master (falla) |
|---|---|---|
| libobjc2 | `a21ae931` | `762f9d7` |
| gnustep-base | `24654296` | `ff647838` |
| libdispatch | `22798930` | `20b4c8b2` |
| gnustep-make | `e7c0730d` | `8fa108c7` |
| libffi | v3.8.0 | v3.8.1 |
| libiconv | v1.19 (`a536e24a`) | v1.19.1 |

La corrección es fijar las siete revisiones buenas conocidas de 11-14
(`Engine/toolchain/revision-pins.patch`). El controlador mismo también está fijado al
commit `54d08e57` (su master flota y no debe rastrearse). Ambos hechos están
registrados en `Windows/Engine/toolchain.conf`.

### 2.4 Los tres requisitos no obvios del contenedor de compilación

El `build.bat` del toolchain debe ejecutarse desde el entorno de desarrollador `vcvars64`,
con `BASH` establecido al shell de MSYS2, y por ruta **absoluta** de `build.bat`, sin
editar `PATH` (el `PATH` de vcvars64 tiene ~2500 caracteres y rompe la resolución de nombres simples de cmd).
Desde Git Bash, invoca `cmd` con `cmd //c` (no `cmd /c`); desde
PowerShell, `cmd /c` es correcto. `Engine/toolchain/bootstrap.ps1` encapsula
los tres.

---

## 3. El punto de entrada de la compilación

`Windows/Engine/build.ps1` reproduce la receta desde el repositorio:

1. **Comprobación de requisitos previos** — Clang 20.1.8, lld, CMake, Ninja, MSYS2, git, curl,
   tar, `llvm-lib`, VS 2026, el SDK de Windows, NASM.
2. **Bootstrap idempotente del toolchain** — `Engine/toolchain/bootstrap.ps1`
   clona el controlador fijado, aplica los dos archivos de parches, y compila GNUstep
   desde fuentes en `C:\GNUstep` (configurable; ~20–30 min en la primera ejecución).
3. **Compilación de la biblioteca SQLite** — descarga la fusión 3.53.3 de
   `Engine/libraries.conf`, verifica su sha256, extrae, compila `sqlite3.c`
   con la lista de opciones de `Compressor/sqlite3.xcconfig`, y la archiva en un
   `sqlite3.lib` COFF con `llvm-lib`.
4. **Compilación de frameworks** — compila MADDataStructures, MADFoundation, MADAPI y
   MADSqlite3 (más los shims de `Engine/Compat`).
5. **Compilación de pruebas** — compila y enlaza un ejecutable por archivo de prueba portado (más
   la prueba de humo).
6. **Ejecución de pruebas** — ejecuta la prueba de humo y cada suite; sale con código distinto de cero en cualquier
   fallo.

Las opciones de compilación de frameworks coinciden con el perfil Debug de la compilación de Linux: el
`gnustep-config --objc-flags` de GNUstep bajo `--enable-debug-by-default` (que usa el toolchain de Linux)
lleva `-DDEBUG`, así que `build.ps1` pasa `-DDEBUG=1` a cada
unidad de traducción — biblioteca y prueba por igual — y **no** define
`NS_BLOCK_ASSERTIONS`, manteniendo `NSAssert` activo exactamente como en Linux.

**Decisión — `build.ps1` impulsa Clang directamente, no a través de CMake.** El soporte del lenguaje
Objective-C de CMake en Windows está roto para la combinación que requiere esta
receta (el `clang` de controlador GNU apuntando a `x86_64-pc-windows-msvc`):
su sonda de enlace Objective-C pasa opciones de GNU-ld (`--out-implib`, `-nostdlib`,
`-nostartfiles`) a `lld-link` y añade `.lib` a nombres de biblioteca ya
prefijados con `-l`, así que el enlace falla (`undefined symbol: $_OBJC_CLASS_NSObject`,
y errores de GC de secciones para metadatos ObjC). La receta probada son invocaciones directas de
`clang` — el `compile-mad.sh` / `link-and-run.sh` de la fase de viabilidad — y
`build.ps1` es esa receta limpiada y hecha idempotente. Las listas de fuentes por framework
siguen viviendo en `Engine/cmake/<Name>Sources.cmake` (el inventario canónico,
listo para CMake con razones de exclusión), y `build.ps1` las lee
para que los dos no puedan divergir; una compilación CMake real puede consumirlas sin cambios una vez que
aterrice el soporte de Objective-C para Windows de CMake.

---

## 4. Qué compila, y los shims de Windows

| Framework | Compilación en Windows | Excluido, y por qué |
|---|---|---|
| MADFoundation | 26 de 27 (+ `madlib.c`) | `MADKeyChain` (Security.framework; ya excluido en Linux) y `BDHost` (DNS inverso con sockets POSIX — `sys/socket.h`/`netpacket/packet.h`/`ifaddrs.h`/`arpa/inet.h`; necesita un port a Winsock2). El paraguas va con `MADKeyChain`. |
| MADDataStructures | los 17 | (`madmap.cpp` tampoco está en el objetivo de Xcode) |
| MADAPI | 8 de 11 | los tres controladores de vista de conexión (`MADConnectionViewController`, `MADConnectionSQLGenericViewController`) — UIKit, no headless. No es un entregable propio de la Fase 2b; es la dependencia transitiva de MADSqlite3. |
| MADSqlite3 | los 26 | cinco archivos `.m` huérfanos que tampoco están en el objetivo de Xcode (nombrados en `Engine/cmake/MADSqlite3Sources.cmake`) |

`Windows/Engine/Compat/` es una copia de `Linux/Compat`, adaptada para Windows:

* **`syslog.h`** — `syslog()` no-op y las constantes `LOG_*`, para la rama fuera de Apple de
  `madlog` (`madlog.h` incluye `<syslog.h>` cuando `__APPLE__` no está
  definido).
* **`pthread.h`** — `pthread_mutex_t` (recursivo) sobre un
  `CRITICAL_SECTION` de Windows, para el bloqueo de estado de `MADOperation.m`.
* **`NSData+ReadingOptions` eliminado** — el master fijado de GNUstep ya
  lleva `NSDataReadingOptions` y `-options:error:`; el shim de Linux
  (que los vuelve a declarar, para gnustep-base 1.31.1) sería una interfaz duplicada
  en Windows.
* **`NSPropertyListSerialization+Stream.m`** gana un
  `#import <Foundation/NSData.h>` explícito — una divergencia del orden de inclusión de encabezados
  de Windows (los encabezados de Linux llegan a NSData primero por casualidad; los de Windows no).
* **`MADCompat.h`** (el preludio incluido a la fuerza) elimina el bloque `<endian.h>` +
  `htonll`/`ntohll` — ni MADFoundation ni MADDataStructures lo usan
  (verificado con grep), y `<endian.h>` no existe en Windows. La capa de controladores
  (`MAD`) necesitará un shim de orden de bytes de Windows cuando se porte.
* **`MADCompat.h`** también gana un `static inline strlcat` — el UCRT de Windows no tiene
  `strlcat`/`strlcpy` (grafías de BSD/Apple; glibc 2.38+ las proporciona, que
  es por lo que Linux no necesita shim), y `MADQueryCacheAddRow.m` lo usa.
* **`NSURL+FileSystem.m`** responde `-fileSystemRepresentation` con
  `self.path.UTF8String` en lugar de la grafía `GSNativeChar*` de GNUstep (UTF-16
  en Windows), que rompía la ruta de `sqlite3_open_v2` al enmascararse como
  `const char *`.

Los otros shims de Linux se mantienen sin cambios, ya que el GNUstep-base de Windows y Linux
es la misma línea 1.31.x.

---

## 5. Los cambios inevitables en fuentes compartidas

Se requirieron dos cambios en fuentes compartidas, ambos mínimos y portables (la CI de Linux
y las suites de Apple son las compuertas):

### 5.1 El renombrado `itoa`/`ltoa`/`ultoa` de `madlib.c`

`MADFoundation/Source/madlib.c` define `itoa`/`ltoa`/`ultoa`, que colisionan
con los nombres no estándar de tres argumentos del UCRT de Windows con la misma grafía.
Se renombran a `mad_itoa`/`mad_ltoa`/`mad_ultoa`, y se actualiza cada llamador:

* `MADFoundation/Source/madlib.{c,h}` — las definiciones y declaraciones;
  también elimina `#import <strings.h>` (sin usar, y ausente en Windows).
* `MADFoundation/MADFoundationTests/madlibTests.m` y `Linux/Tests/madlibTests.m`
  — las pruebas.
* `MAD/Source/model/MADModelQueryTable.m`, `MAD/Source/rptq/RptqQueryTable+Extras.m`
  (`ltoa`) y `MADSqlite3/Source/MADDataTableFast.m`,
  `MADSqlite3/Source/MADQueryCacheAddRow.m` (`ultoa`).

Este es un renombrado puramente mecánico, neutral en comportamiento en Apple y Linux.
`uitoa`, `reverse`, `count_digits` y `count_digits_ul` no se tocan (no
colisionan con el UCRT). La referencia a `itoa` en `MADExplorer` está dentro
de un bloque comentado y no es un llamador.

### 5.2 El puntero de cursor de enumeración rápida

`MTStack.m`, `MTQueue.m` y `MTLinkedList.m` guardan el puntero de nodo de cursor de
`countByEnumerating…
` en `NSFastEnumerationState.extra[0]`, convertido mediante
`unsigned long`. Eso es 32 bits en Windows (LLP64) pero 64 en Linux/Apple
(LP64), así que el puntero se truncaba y la enumeración de múltiples lotes (cualquier
colección de más de un búfer de pila de elementos) fallaba o producía basura.
Los tres archivos ahora copian el puntero en `extra` con `memcpy` (correcto en
LP64 y LLP64) y lo mantienen en una variable local `__unsafe_unretained` — la
colección posee la cadena de nodos, que sobrevive a la llamada, así que el puntero prestado
es el modelo de propiedad honesto en cada plataforma. El cambio es
neutral en comportamiento en Apple/Linux (los mismos bytes de puntero se mueven).

---

## 6. Brechas conocidas y siguientes incrementos

> Esta sección registra las brechas de las fases 1/2 tal como estaban entonces. Las fases 3a–6e
> cerraron todas excepto las aceptadas; véanse §6b–§6h y
> `Windows/README.md` para el estado actual.

* **`BDHost`** (DNS inverso) y **`MADKeyChain`** (Security.framework) están
  excluidos; `BDHost` necesita un port a Winsock2, `MADKeyChain` no tiene equivalente de llavero de
  Windows todavía. `BDHostTests` no se registra en Windows por la
  misma razón (no puede enlazar sin `BDHost.m`) — registrado, no omitido.
* **Los frameworks headless restantes** (`MAD`, los controladores, `MADFileManager`,
  `MADCocoaExtensions`, …) y **la CLI** son los siguientes incrementos.
* **La aplicación WPF** es una fase posterior.

## 6b. Fase 3a — los frameworks, la pila de archivo y la CLI

La Fase 3a compila los frameworks headless restantes, las bibliotecas C del contenedor
`.mad`, y `mad.exe`:

* **Frameworks.** `MADCocoaExtensions` (7 archivos), `MADFileManager` (10) y `MAD`
  (168) se unen al conjunto de las fases 2/2b, desde las mismas listas de fuentes de Linux y con las
  mismas razones de exclusión (la cola de interfaz, `MADocument`, las operaciones de llavero,
  `MADCloud`). `MADDirectoryMonitor` compila contra un shim inerte de `sys/inotify.h`
  — la CLI es de un solo disparo y no necesita eventos de cambio.
* **Bibliotecas C.** `zlib` 1.3.2, `bzip2` 1.0.8 y `libarchive` 3.8.9 (las fijaciones
  de Linux) se compilan en `build.ps1`: zlib y bzip2 por clang directo + `llvm-lib`,
  libarchive mediante CMake + clang-cl (zlib/bzip2 dentro; xml2/lzma/zstd/lz4/openssl
  y las herramientas fuera), coincidiendo con `Linux/lib/libraries.sh` / Compressor. La pila de
  códigos de barras — `libpng` 1.6.59 y `zint` 2.16.0 — se compila de la misma
  manera (ambos mediante CMake + clang-cl), así que `MADBarcodes` también compila y renderiza aquí.
* **CLI.** `CLI/Source` → `mad.exe`, enlazado con archivo completo. `inspect`, `schema`, `query`
  y `refresh` (76 filas) se ejecutan sobre `London.portable.mad`; los seis digests de exportación
  coinciden con las fijaciones de Mac/Linux byte a byte, y `write --reproducible` escribe el
  mismo documento de 16261 bytes (`09815b24…`) que escriben Mac y Linux.

### 6b.1 Las dos correcciones de runtime solo de Windows (final de la Fase 3a)

* **`write --reproducible` (la lectura de almacén de 116 bytes).** El `open`/`read` del escritor de archivo
  pasaba por `Windows/Engine/Compat/unistd.h`, cuyo `open` se asignaba
  al `_open` del UCRT — que usa el modo *texto* por defecto.  Un almacén SQLite
  contiene un byte `0x1A` (Ctrl-Z) en el desplazamiento 116; el `_read` en modo texto se detiene allí
  como EOF, así que el escritor vio 116 de 663552 bytes y emitió un archivo de 518 bytes.
  El shim ahora hace OR de `_O_BINARY` en las banderas, así que `open`/`read` tienen el
  comportamiento POSIX byte a byte.  Protegido al shim de Windows; los bytes de Apple/Linux
  no cambian.  Fijado por `MADArchiveManagerTests` (5 pruebas, 0 necesidades).
* **`export` repetido en un usuario (el renombrado de `.mdcache`).** El `.mdcache` de la caché de filas
  es un plist que se lee a través de `NSInputStream` y luego se reescribe de forma atómica.
  `Compat/NSPropertyListSerialization+Stream.m` abría el flujo ya abierto
  una segunda vez; el `GSFileInputStream -open` de win32 de GNUstep llama a `CreateFileW`
  (`FILE_SHARE_READ`) cada vez y sobrescribe `_loopID`, filtrando el primer
  handle. Ese handle bloqueaba el `MoveFileEx` posterior sobre el `.mdcache`
  (`"being used by another process"`), así que la segunda exportación fallaba.  El shim
  ahora lee el flujo abierto sin reabrirlo (el contrato de Apple), y dos
  exportaciones en un usuario tienen éxito.

### 6b.2 El inventario de pruebas

Las suites copiadas de MAD/MADFileManager/MADCocoaExtensions/MADAPI se cablean en
`build.ps1` (rutas de fixture adaptadas para `Windows/Engine/Tests`): **107 suites
portadas + la prueba de humo, 966 pruebas, 6 necesidades, 5 omisiones, 0 fallos**. Las seis
necesidades coinciden con las brechas de plataforma de la imagen de Linux: `MADDirectoryMonitorTests` (3 — el
monitor de Windows es inerte), `MADStoreTests` (1 — Core Data + `MAD.momd`) y
`RptqStoreContextTests` (2 — la ruta de convertidor/documento). Cuatro suites de MAD que
necesitan los controladores de la Fase 3b están diferidas y registradas en `build.ps1`:
`MADDatabaseDriverDispatchTests`, `MADQueryFullTests`, `MADSQLParserTests` y
`MADQueryMaxFieldLengthTests`. Las cinco omisiones son el benchmark de SQLite en su
escala predeterminada.

Los shims adicionales de `Compat` de Windows son `unistd.h`, `dirent.h`, `libgen.h`,
`sys/{unistd,fcntl,inotify}.h`, más `MADCompat.h` ganando `strlcpy`, las
macros de modo `S_IS*`/`S_IR*`, `ssize_t`/`mode_t`, `M_PI`, `arc4random` y
`gmtime_r`. Los cambios mínimos adicionales en fuentes compartidas (todos seguros con `#if __APPLE__`
o neutrales en bytes en Linux; la CI de Linux y las suites de Apple son las compuertas):

* `MADReportSectionRepresentation.m` elimina un `@finally` vacío (el codegen GNUstep-2.2 + ARC de clang 20.1.8
  fallaba con él).
* `madtar.m` gana una rama `_WIN32` de mtime (el `struct stat` del UCRT tiene `st_mtime`,
  no `st_mtim`).
* `MADArchiveManager.m`, `MADStore.m` y `MADCLIInspect.m` usan
  `NSString -UTF8String` donde tomaban `-fileSystemRepresentation` (la grafía
  NSString de GNUstep devuelve UTF-16 en Windows).
* El `+Identifier:` de `MADDatabaseConnection+Constructor.m` devuelve las cuatro
  constantes del formato de documento directamente, para que un proceso que solo enlaza Sqlite3 todavía pueda
  asignar un `driverID` almacenado a un tipo. (La Fase 3b eliminó esta guarda — véase §6c.)

## 6c. Fase 3b — los controladores, BDHost y los fixtures en vivo

La Fase 3b añade los cuatro controladores de base de datos y las bibliotecas C que enlazan:

* **Bibliotecas C** (`Windows/Engine/libraries.conf`, `build.ps1` §3c): OpenSSL
  3.5.9 (Strawberry Perl + `VC-WIN64A` + `nmake`, estático), FreeTDS 1.4.27 (CMake
  `db-lib`, `ENABLE_MSDBLIB`, edición BOOL de `sybdb.h`), MariaDB Connector/C 3.4.11
  (CMake `mariadbclient`, plugins de autenticación estáticos), libpq 17.11 (**Meson + MSVC
  `cl.exe`**, `libpq_st` + `libpgcommon_shlib` + `libpgport_shlib` fusionados en un
  `libpq.lib` COFF). PostgreSQL 17 eliminó la compilación MSVC, así que Meson es su ruta
  en Windows; se usa `cl.exe` (no `clang-cl`) porque los chequeos Meson de PostgreSQL
  `cc.get_id() == 'msvc'` y `clang-cl` informa `clang-cl`, descartando silenciosamente
  `win32gettimeofday.c`/`dirent.c` y el directorio de inclusión `win32_msvc`. Meson y
  Strawberry Perl están documentados como requisitos previos.
* **BDHost** — `MADFoundation/Source/BDHost.m` gana una rama
  `#elif defined(_WIN32)` sobre `winsock2.h`/`ws2tcpip.h` (`WSAStartup` una vez,
  `getaddrinfo`/`getnameinfo`, solo IPv4); `+ipAddresses`/`+ethernetAddresses` se
  compilan fuera en Windows. `BDHostTests` pasa 3/3.
* **Controladores** — cuatro listas `cmake/*Sources.cmake` (18/1/3/4 archivos) y shims de
  encabezados para `<MADTds/sybdb.h>`, `<MADTdsClient/MADTdsClient.h>` y
  `<MADPostgres/libpq-fe.h>` etc. `MADTdsDb.m` se enlaza normalmente (su
  `err_handler` global colisiona con el de `MADDatabaseSQLServer.m`). La guarda
  `+Identifier:` de la Fase 3a se elimina — la búsqueda en el registro funciona con los cuatro controladores
  enlazados, fijada por `MADDatabaseDriverDispatchTests` (9/9).
* **Inventario de pruebas** — **129 suites + la prueba de humo, 1308 pruebas, 6 necesidades, 5 omisiones
  (48 cuando los contenedores en vivo no están en ejecución), 0 fallos** (el incremento de códigos de barras
  añadió `MADBarcodesTests` y `MADBarcodeExportTests`; el cierre de imágenes añadió
  `MADImageElementTests` y `MADImageExportTests`). Suites en vivo contra los contenedores
  locales `127.0.0.1`: `MADMySQLLiveTests` 44/44, `MADTdsClientLiveTests` 29/29, `MADPostgresLiveTests`
  14/14. La `mad refresh` de la CLI devuelve 50 filas de MySQL / 20 de TDS / 25 de PostgreSQL.

## 6d. Fase 4 — el contrato de proceso JSON sobre stdio

La Fase 4 añade `mad serve`, la frontera de proceso de larga vida que usará el shell WPF. Lee
JSON delimitado por saltos de línea en la entrada estándar y escribe una respuesta JSON delimitada por saltos de línea
por petición en la salida estándar; el diagnóstico se queda en la salida de error, así que los
dos nunca se mezclan. La forma del cable reutiliza el contrato JSON existente del proyecto en lugar de
inventar uno paralelo.

**Petición / respuesta** — un valor JSON por línea, UTF-8, terminado en `\n`:

```text
request:   { "id": <int|string>, "method": "<name>", "params": { … } }
ok:        { "id": <id>, "ok": true,  "result": { … } }
error:     { "id": <id|null>, "ok": false, "error": { "code": <int>, "message": "…" } }
```

`id` lo elige el cliente y se devuelve para correlación; una petición malformada responde con
`"id": null`. `error.code` es el código de salida de la CLI (MADCLI.h): 1 uso/protocolo, 2 documento
malo, 3 base de datos inalcanzable, 4 consulta fallida, 5 exportación fallida. Una línea malformada, un
método desconocido, un parámetro faltante y una excepción inesperada del motor responden todos
`ok: false` con un mensaje — nunca un traceback — y la sesión sigue funcionando.

**Métodos:**

| método | parámetros | resultado |
|---|---|---|
| `open` | `path`, `host`/`port`/`database` opcionales | `handle`, `filename`, `driver` |
| `create` | `path`, `driver` + campos de conexión, `credentials` opcionales | `handle`, `filename`, `driver` (el documento creado) |
| `test-connection` | `driver` + campos de conexión, `credentials` opcionales | `tableCount` |
| `describe` | `handle` | `driver`, `columns` (clave/nombre/tabla/tipo), `tables` (nombre + campos) |
| `connection` | `handle` | `driver` + `file`/`host`/`port`/`database`/`server` |
| `apply-connection` | `handle`, `driver` + campos de conexión, `credentials` opcionales | `{}` |
| `query` | `handle` | `sql` |
| `query-model` | `handle` | token `driver`, `sql`, `sqlSourceText`, `tables`/`links`/`predicates`/`groups` (con identificadores de almacén) |
| `add-table` | `handle`, `table` (nombre de esquema) | el `query-model` completo |
| `remove-table` | `handle`, `table` (id de tabla de consulta) | el `query-model` completo |
| `add-link` | `handle`, `leftField`, `rightField` (ids de campo) | el `query-model` completo (Left Outer Join por defecto) |
| `set-link-type` | `handle`, `link`, `type` | el `query-model` completo |
| `swap-link` | `handle`, `link` | el `query-model` completo |
| `delete-link` | `handle`, `link` | el `query-model` completo |
| `add-predicate` | `handle`, `leftField`, `operator`, `value` | el `query-model` completo |
| `remove-predicate` | `handle`, `predicate` | el `query-model` completo |
| `add-group` | `handle`, `field`, `sort` | el `query-model` completo |
| `remove-group` | `handle`, `group` | el `query-model` completo |
| `validate-sql` | `handle`, `sql` | `tables`, `links`, `predicates`, `groups` (los recuentos del plan) |
| `apply-sql` | `handle`, `sql` | `tables`, `links`, `predicates`, `groups` |
| `refresh` | `handle`, `rows`/`credentials` opcionales | `rowCount`, `elapsed` |
| `export` | `handle`, `format`, `path`/`deterministic` opcionales | `format` + `data` (los bytes del exportador) o `path` + `bytes` |
| `write` | `handle`, `out`, `reproducible` opcional | `path`, `bytes` — serializa el documento en vivo |
| `shutdown` | — | `{}`, luego el proceso sale con 0 |

Los métodos de conexión (`create`, `test-connection`, `connection`, `apply-connection`)
toman un token `driver` — `sqlite3` | `mysql` | `sqlserver` | `postgres` — y
campos específicos del controlador: SQLite toma `file`; los controladores de servidor toman
`host`/`port`/`database` (SQL Server también toma una instancia `server` opcional), más la
cadena `credentials` (`user:password`) existente. Reutilizan el
`createDocumentAtURL:`, `MADDatabase` (connect/getTables/close) y
`applyDatabaseConnection:` del motor — las mismas llamadas que hace la ventana de conexión del Mac.

`export` es la costura de exportación (`MADReportExporting` / `MADReportExporterRegistry`), no un
esquema nuevo: `format: "json"` devuelve los bytes exactos de `mad.report/1` que escribe `mad export
--format json` (`MADReportExporterJSON` — `columns` y `rows`), y `format:
"csv"` los bytes RFC 4180. Un formato que esta compilación no puede producir (por ejemplo `pdf` fuera de
Apple) responde `error.code` 5 con la razón del exportador. Las `columns` de `describe` son
esas mismas columnas `mad.report/1` (`MADReportExportSource`), y sus `tables` son el
esquema de base de datos almacenado que imprime `mad schema`. `open` aplica `host`/`port`/`database` como
hacen los verbos de un solo disparo, así que un documento versionado puede ejecutarse contra un servidor diferente
para la sesión. `write` ahora serializa el documento de la sesión en vivo en lugar de reabrir
`sourceURL`, así que una conexión aplicada en la sesión se persiste. El fin de archivo en la entrada
estándar es un cierre limpio, igual que `shutdown`.

Los métodos `query-model`/`add-table`/…/`apply-sql` son la extensión del espacio de trabajo Query de la Fase 6b.
El contrato original de `serve` exponía la consulta solo como su `sql` generado,
que el Mac deriva mutando los objetos `RptqQuery` en proceso; la aplicación WPF no tiene
tal handle en proceso, así que estos métodos cierran esa brecha. `query-model` lee el modelo de consulta completo
— tablas/campos/vínculos/predicados/grupos con sus identificadores de almacén, el
`sqlSourceText` introducido, y el token del controlador — y cada método de mutación responde esa
misma forma, para que el cliente reemplace su instantánea de forma atómica. Las mutaciones llaman a las mismas
fábricas y ayudantes de `MADSQLQueryDocument` que usa el `MADMacQueryViewController` del Mac
(`newQueryTableForSchemaTable:`, `newQueryLinksWithLeftField:`, `addQueryGroupWithQueryField:`,
`removeGroupWitObjectID:`, …), y `validate-sql`/`apply-sql` ejecutan la ruta existente
`MADSQLParser` → `MADSQLStatementResolver` → `MADSQLQueryCompiler` sin cambios.
`query` ahora devuelve primero el SQL de todos los campos y recurre al select de campos activos,
coincidiendo con el `generatedSQLString:` del Mac — así que un documento nuevo sin elementos de informe
todavía produce SQL.

**Cliente y pruebas.** `Windows/Client/` contiene el cliente de aceptación de consola de .NET 10
(`Mad.Client`) y la suite xunit (`Mad.Client.Tests`), ambos fijados por
`Windows/global.json`. El cliente lanza `mad serve` y cubre los siete métodos; las
pruebas ejercitan la ruta de éxito sobre `CLI/Fixtures/London.portable.mad` (abrir → describir
→ consultar → actualizar 76 filas → exportar json/csv → apagar, salida 0, sin proceso huérfano),
peticiones malformadas, un método desconocido, un documento malo, un formato no disponible, y
el apagado del proceso.

## 6e. Fase 5 — la prueba del shell WPF

La Fase 5 añade la primera aplicación WPF sobre la frontera de proceso de la Fase 4: un
shell `net10.0-windows` bajo `Windows/App/` que prueba que el motor se ejecuta desde una interfaz real.
Reutiliza `Mad.Client` sin cambios y añade un `EngineService` asíncrono (un `SemaphoreSlim`
serializa el protocolo de líneas de un solo hilo; cada llamada bloqueante se ejecuta en el grupo de
hilos), una capa MVVM hecha a mano (`ObservableObject`, `RelayCommand`, `AsyncRelayCommand`),
y un `DocumentViewModel` que refleja el `MADMacDocument` del Mac para el primer fragmento:
abrir → describir → consultar → actualizar → exportar.

El shell tiene el marco de tres espacios de trabajo (MAD Query / Designer / Viewer). Query muestra el
esquema almacenado y el SQL generado; Viewer muestra las filas actualizadas en un `DataGrid` (alimentado por
el análisis de `mad.report/1` en un `DataTable`) y exporta CSV/JSON; Designer es un marcador de posición
de la Fase 6. Al iniciar abre automáticamente `CLI/Fixtures/London.portable.mad` (anulable con
`MAD_DOCUMENT`), así que se demuestra sin clics. La ventana About (Overview / License &
Notice / Acknowledgements) renderiza el registro de dependencias de Windows desde
`ThirdParty/Licenses/Windows/` y la oferta de relink — el conjunto de componentes de Windows, nunca el
de Apple.

La aceptación se verifica de forma headless por `Windows/App/Mad.Designer.Windows.Tests` (xunit):
abrir London → describir (21 columnas / 11 tablas / controlador "Sqlite 3") → actualizar 76 filas →
exportar json (76 filas) / csv (78 líneas) → apagado limpio sin huérfanos, más el
analizador de `mad.report/1` y las comprobaciones del registro de licencias. La aplicación y las pruebas compilan y se ejecutan en
`net10.0-windows` (fijado por `Windows/global.json`); la CI de Linux no se ve afectada (nunca
compila .NET).

## 6f. Fase 6c — el modelo de diseño de informe (Designer)

La Fase 6c extiende `serve` con el modelo de diseño de informe que edita el espacio de trabajo Designer, usando el
mismo patrón granular que los métodos de query-model de la 6b. `layout-model` lee la instantánea completa;
cada método de mutación muta los objetos `RptqDocumentSection`/`RptqDocumentElement` existentes
y responde esa misma instantánea, para que el cliente reemplace su estado de forma atómica. El código de barras forma parte
del modelo (el incremento de cierre de códigos de barras añadió el tipo de elemento, sus ediciones de contenido, el
catálogo de simbologías, una vista previa renderizada por el motor y el compositor WPF — §6j; el cierre de imágenes
siguió con contenido PNG y el selector de archivos WPF — §6k). Los colores están diferidos (sin
tipo de color portable en el modelo headless). Deshacer/rehacer es del lado del cliente.

| método | parámetros | resultado |
|---|---|---|
| `layout-model` | `handle` | `paperSize`, `sections[]`, `elements[]`, `fields[]` |
| `add-element` | `handle`, `kind` (`label`\|`data-field`\|`aggregate`\|`image`\|`line`\|`barcode`), `section`, `x`, `y`; `data` para una imagen (PNG en base64) | la instantánea completa |
| `remove-elements` | `handle`, `elements: [id…]` | la instantánea completa |
| `duplicate-elements` | `handle`, `elements: [id…]` | la instantánea completa |
| `move-elements` | `handle`, `elements: [id…]`, `section` | la instantánea completa |
| `set-element-geometry` | `handle`, `elements: [{id,x,y,w,h}…]` | la instantánea completa |
| `set-element-content` | `handle`, `element`, `content{text,field,function,scope,group,barcodeType,humanReadable,borderStyle,data}` (`data` es el PNG en base64 de una imagen; vacío lo borra) | la instantánea completa |
| `set-element-typography` | `handle`, `elements: [id…]`, `style{fontname,fontsize,bold,italic,underline,strikethrough,hAlign,vAlign}` | la instantánea completa |
| `set-element-box-model` | `handle`, `elements: [id…]`, `box{borderTop,borderBottom,borderLeft,borderRight,padding,margin}` | la instantánea completa |
| `set-section` | `handle`, `section`, `{height,visible,pageBreak}` | la instantánea completa |
| `set-paper-size` | `handle`, `paperSize` (`MTPaperType` int16: Letter 2 / Legal 7 / A4 19) | la instantánea completa |

La instantánea lleva las secciones en el orden canónico del diseñador (Report Header, Page
Header, Group Headers, Detail, Group Footers, Page Footer, Report Footer), cada una con `id`,
`type` (`MADocumentSectionType`), `title`, `height` (la altura de interfaz `layoutHeight`),
`visible`, `pageBreak` y `groupField`. Cada elemento lleva `id`, `type`
(`MADPrintPageElementType`), `section`, `x/y/w/h`, `text`, `field` (id de campo de consulta vinculado),
`table`/`column`, `function`/`scope`/`group` (agregado), `fontname`/`fontsize`,
`bold`/`italic`/`underline`/`strikethrough`, `hAlign`/`vAlign`, `borderTop`/`borderBottom`/
`borderLeft`/`borderRight`, `padding` y `margin`. Un elemento de código de barras además lleva el
objeto anidado `barcode` (§6j); un elemento de imagen lleva `image{data}`, la imagen almacenada como
PNG en base64 (vacío cuando no tiene ninguna — §6k). `fields[]` lista los campos de consulta (con ids de almacén)
para el navegador de la barra lateral y el popup de vinculación.

## 6g. Fase 6d — el espacio de trabajo Viewer (renderizar, tamaño de página, exportar, imprimir)

La Fase 6d termina el MAD Viewer sobre el shell 6a–6c. El visor del Mac renderiza un
PDF paginado en `PDFView`; Windows no tiene PDFKit, así que la vista previa renderiza el facsímil
HTML del motor en su lugar, y el PDF mismo lo escribe el propio exportador del motor al
exportar (§6l):

* **Enfoque de renderizado — WebView2 sobre el exportador HTML del motor.** La vista previa muestra los
  bytes exactos de `export --format html` (una caja `<div class="page" data-index="N">` por
  página, el mismo formateador que usan el PDF y cada otro exportador), alojados en un WebView2.
  El recuento de páginas de la línea de estado es el número de esas cajas de página, así que el motor
  sigue siendo el único paginador y ningún exportador se reimplementa en C#. La vista previa añade
  solo cromo de presentación (escritorio gris, huecos de página y sombras) mediante un estilo inyectado;
  los bytes exportados no se tocan. El HTML se escribe en un archivo temporal y se navega
  por URL porque `NavigateToString` tiene un techo de 2 MB que alcanzaría un informe grande. El zoom es
  el `ZoomFactor` de WebView2; la navegación de páginas desplaza la caja de página solicitada a la vista.
  **Imprimir** usa `CoreWebView2.ShowPrintUI` — la ruta de impresión HTML provisional. El navegador se
  crea en `Loaded`, no en XAML, para que el espacio de trabajo se componga headless para sus pruebas.
* **`ViewerViewModel`** posee la selección de tamaño de página y su bloqueo renderizado (US Letter
  predeterminado, US Legal, A4), los pasos de zoom (0.25–4.0, 1.25×, restablecimiento a 100%), la navegación
  anterior/siguiente, el catálogo de formatos de exportación, y la línea de estado. La línea de estado es la
  del Mac: `Rendered N pages from M cached rows.` con su gramática singular/plural, verde en
  éxito y roja en fallo. Seleccionar un tamaño de papel no cambia el informe renderizado
  hasta la siguiente actualización (la división `selectedPaperType`/`renderedPaperType` del Mac); la
  selección sobrevive a la actualización, y la exportación usa el papel renderizado.
* **Exportar** ofrece los siete formatos que produce esta compilación, en el orden del visor del Mac —
  PDF Document, HTML Page, HTML Flow, CSV, JSON Data, JSON Full Report y Plain Text —
  cada uno con su propia extensión de archivo (`pdf`, `html`, `html`, `csv`, `json`, `json`, `txt`).
  La barra de herramientas lleva el selector de formato; Export abre el diálogo de guardado filtrado al
  formato elegido. PDF pasa por la forma de ruta de `serve` (`export` con un `path`), así que el
  motor escribe los bytes del exportador en el archivo elegido y la respuesta lleva solo el
  recuento de bytes; la lectura de vuelta `data` que usan los formatos de texto es UTF-8 y corrompería un
  PDF binario. Exportar antes de una actualización actualiza primero, como hace Export del Mac, y
  mientras una exportación se ejecuta la barra de estado muestra su barra de progreso indeterminada con una
  línea "Exporting…" (el comando está deshabilitado; `serve` no transmite progreso y la exportación
  es una única petición).
* **Integración con el documento.** `DocumentViewModel.RefreshAsync` ejecuta la consulta y luego llama a
  `Viewer.RenderAsync`, que aplica el papel seleccionado a través del documento (para que la instantánea del
  Designer siga) y carga la vista previa HTML. Los botones Refresh, Export
  y Print del Viewer pasan todos por esa misma ruta del documento.
* **Corrección del motor.** `set-paper-size` mutaba el `RptqDocument` almacenado pero no el
  documento de renderizado, cuyo `MTPaper` se cachea después del primer diseño, así que el segundo cambio de papel
  nunca llegaba a una exportación. Ahora también llama a `setPaperType:` en el documento de renderizado
  (la llamada que hace el visor del Mac antes de actualizar) y vuelve a formatear un informe que ya está
  diseñado, así que el nuevo tamaño llega a una exportación que sigue sin otra actualización.

El Viewer reemplaza la cuadrícula de filas de marcador de posición de la Fase 5: el informe renderizado es el espacio de trabajo,
como en el Mac, y las filas siguen disponibles mediante las exportaciones CSV/JSON.

**Pruebas.** `ViewerViewModelTests` (gramática de estado, catálogo de formatos, recuento de páginas, zoom,
navegación, petición de impresión), `ViewerSurfaceTests` (el espacio de trabajo materializado en un hilo
STA — la barra de herramientas, los siete formatos, el selector de tamaño de página, el color de estado y la
etiqueta de página), y `ViewerAcceptanceTests` contra el motor (London → 5 páginas / 76 filas
en caché, bloqueo de tamaño de página y persistencia a través de A4 con la caja de página exportada en 595 × 842,
cada formato de exportación con su extensión y el PDF comprobado por su firma `%PDF-`, una
exportación a una ruta con un espacio y un carácter no ASCII, el estado de exportación establecido mientras se
escribe el PDF y limpiado después, y el cambio de tamaño de papel A4 → Legal → Letter llegando a
cada exportación).

## 6h. Fase 6e — About, localización y la prueba de humo WPF

La Fase 6e cierra la compuerta de fusión sin cambiar el motor: termina el registro de dependencias de la ventana
About, localiza la aplicación WPF al conjunto de idiomas de la aplicación del Mac,
añade la contraparte WPF de `MADMacSmokeTest.m`, y pone al día este registro y
`Windows/README.md`. El `docs/windows.md` público y sus traducciones se
difieren por diseño.

**About y el aviso de WebView2.** La vista previa del Viewer se ejecuta en el
control **Microsoft Edge WebView2** (NuGet `Microsoft.Web.WebView2` 1.0.4314.35).
El SDK que se envía con la aplicación es BSD-3-Clause y lleva los avisos de terceros
de Microsoft; el Evergreen WebView2 Runtime es un redistribuible de Microsoft,
no software de código abierto. La ventana About por lo tanto lista
`Microsoft Edge WebView2` con ambos términos y la atribución del runtime, todo en
`ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`. El registro es
`docs/project/THIRD_PARTY_LICENSES.md` §10. El resto de la lista de componentes no
cambia (GNUstep Base, gnustep-corebase, libiconv, libobjc2,
libdispatch/BlocksRuntime, libffi y las bibliotecas C), y la oferta de relink LGPL
sigue nombrando el motor de Windows; la aplicación WPF nunca muestra el conjunto de Apple.

**Localización.** Cada cadena de cara al usuario vive en un `ResourceDictionary` de WPF
bajo `Windows/App/Mad.Designer.Windows/Resources/`: `Strings-en.xaml` es la
fuente autoritativa y `Strings-de.xaml`, `Strings-es.xaml`,
`Strings-ja.xaml`, `Strings-pt-BR.xaml` y `Strings-zh-Hans.xaml` reflejan el
conjunto de idiomas de la aplicación del Mac (`MAD_APP_LOCALIZATION.md` D1/D9). Los diccionarios están
incrustados en el ensamblado principal (no elementos `Page` compilados ni ensamblados satélite
— el guion en `Strings-de.xaml` evita que MSBuild lea el
código de idioma como sufijo de cultura), y `Infrastructure/Localizer.cs` los carga
con `XamlReader` y sirve `Get`/`Format`. XAML los consume a través de la
extensión de marcado `{infra:Loc Key}`, que se resuelve en tiempo de carga; el código subyacente y
los modelos de vista llaman a `Localizer`. El idioma sigue la cultura de interfaz del sistema operativo al iniciar
(`de`, `es`, `ja`, `pt-BR`, `zh-Hans`; cualquier otro es inglés), y
`MAD_LANGUAGE` lo anula para inspección:

```powershell
$env:MAD_LANGUAGE = "de"
dotnet run --project .\Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj
```

Las traducciones reutilizan el `Localizable.xcstrings` del Mac donde la fuente inglesa
coincide, y luego siguen la política asistida por máquina (MAD_APP_LOCALIZATION.md D14):
el Overview de About termina con el aviso de que las traducciones son
asistidas por máquina y pueden contener errores, en cada idioma. El cromo de About,
el asistente de conexión, las barras de herramientas y líneas de estado de consulta/diseñador/visor, los diálogos,
y los nombres de banda están traducidos; los cuerpos de licencia, avisos de componentes, la oferta de
relink LGPL, el copyright y los nombres de marca se quedan en inglés textual (D6/§8), con una
frase localizada que dice que los textos de licencia se reproducen en su inglés original.
Las palabras clave SQL, los nombres de tipos de datos y los identificadores de campo/tabla no se
traducen, y el texto de error que el motor mismo devuelve (fallos de controlador, mensajes del analizador
SQL) se queda en inglés, como los mensajes de controlador del Mac.

**La prueba de humo.** `Windows/App/Mad.Designer.Windows.Tests/SmokeTests.cs` es
la contraparte a nivel de modelo de vista/servicio de `MADMacSmokeTest.m`, no una prueba
de píxeles:

1. **London.** Abre `CLI/Fixtures/London.portable.mad`, actualiza 76 filas (5
   páginas), luego exporta HTML Page, HTML Flow, CSV, JSON Data, JSON Full Report y
   Plain Text a través de la propia ruta del Viewer. El recuento de bytes y el SHA-256 de cada archivo
   se afirman contra las fijaciones de Mac/Linux en `Linux/README.md` (`html`
   `285541ed…`, `html-flow` `0565204a…`, `csv` `773f6215…`, `json` `569c6ee2…`,
   `json-report` `9d01d0da…`, `text` `7dcee96c…`).
2. **Un documento nuevo.** Crea un `.mad` a partir de `chinook.sqlite3`, aplica la sentencia SQL del Mac
   (`SELECT Customer.FirstName, Customer.LastName, Customer.City
   FROM Customer WHERE Customer.Country = 'United Kingdom';`), añade una etiqueta estática,
   un campo de datos vinculado a `LastName`, y un agregado COUNT de ámbito de informe,
   actualiza, luego exporta cada formato disponible y comprueba el recuento de filas JSON y
   el recuento de páginas HTML.

El Viewer exporta PDF en ambas pruebas a través de la exportación por ruta del motor; la
prueba de humo comprueba su firma `%PDF-` en lugar de leerlo como texto. La
suite se ejecuta headless con el resto de pruebas de la aplicación; véase `Windows/README.md`.

## 6i. Fase 6f — el tema, el shell y la pasada de usabilidad

La Fase 6f es solo de presentación: sin cambio de motor, protocolo, documento o flujo de trabajo.
Corrige los dos defectos funcionales que informó la revisión de diseño y aplica un
sistema de diseño y shell inspirados en Fluent en la arquitectura existente de tres espacios de trabajo.
(La pasada de tema no formaba parte de la compuerta de fusión; la sigue.)

**Defectos corregidos.** Help ▸ About terminaba el proceso: los `Overview`, `LicenseNotice` y
`SelectedAcknowledgement` de solo lectura de la ventana About estaban vinculados
a `TextBox.Text`, cuyo modo de vinculación predeterminado es TwoWay, y la vinculación lanzaba
`InvalidOperationException` durante el primer diseño de la ventana. Las vinculaciones son
ahora OneWay, y `AboutWindowTests` muestra la ventana para fijarlo. El defecto de arrastre del Designer
era el orden Z: el fondo opaco de cada banda se añadía con sus
elementos, así que un elemento arrastrado a una banda posterior se pintaba debajo de esa banda
y desaparecía hasta que el soltar reconstruía el lienzo; sus manijas de redimensionado también se quedaban
en la posición anterior. El elemento arrastrado ahora se pinta sobre cada banda, las
manijas se ocultan mientras se arrastra, el cromo de selección se actualiza en el lugar en lugar de
reconstruirse, el desplazamiento del ScrollViewer se preserva a través de una reconstrucción, y la matemática
del arrastre se fija en zoom 2 con la vista desplazada.

**El sistema de diseño.** `Themes/Theme.xaml` es el único conjunto de recursos:
tipografía (Segoe UI Variable Text/Display, tamaños Fluent), espaciado, radios de esquina,
superficies, estilos de comando y navegación, botones primarios/secundarios, alternadores
segmentados, estilos de formulario y tarjeta, y colores de estado semánticos. Los pinceles de cromo son
claves de recurso dinámico de Fluent, así que claro/oscuro, el acento del usuario y el alto contraste
siguen el sistema; `App.xaml` opta por el tema Fluent nativo con
`ThemeMode="System"` (se suprime el `WPF0001` de la API experimental). Los documentos de informe
conservan su propia paleta fija: `Infrastructure/DesignPalette.cs` es la
única fuente congelada para papel, tintes de elementos, el acento de selección, las uniones y
el minimapa. `MAD_THEME=Light|Dark` es una anulación de inspección como
`MAD_LANGUAGE`, y el escritorio WebView2 del Viewer la sigue (o la configuración AppsUseLightTheme de
Windows).

**El shell.** El icono de la aplicación se genera a partir del arte existente de MAD
(`Assets/AppIcon.png` y el `AppIcon.ico` multiescala) y es la identidad de la ventana,
la barra de tareas y About. Iniciar sin un informe muestra una pantalla Welcome/Home
(New report, Open report, informes recientes, una breve introducción) en lugar de un
Viewer vacío. Los tres espacios de trabajo son un raíl izquierdo estilo NavigationView con
icono + etiqueta, un estado seleccionado claro, y Ctrl+1/Ctrl+2/Ctrl+3; están deshabilitados
mientras se muestra Welcome. Un informe recién creado se abre en el Designer; un informe
existente se abre en el Viewer. No hay destino Home: los tres espacios de trabajo
siguen siendo el conjunto de pares de primera clase. El menú File mantiene New/Open/Save/Save As/Recent/
Connection/Exit; la barra de comandos mantiene New y Open (About se queda en Help).

**Organización de los espacios de trabajo.** El asistente de conexión es una ventana fija de 640 × 660
(redimensionable, con un cuerpo desplazable) cuyas tarjetas agrupadas mantienen el formulario
específico del controlador dentro del mismo marco; cambiar SQLite → MySQL/SQL Server/
PostgreSQL no la redimensiona. Query tiene un interruptor segmentado Designer/SQL, comandos agrupados,
un comando Add table de tamaño normal en el encabezado del panel de tablas, y una
barra de zoom inferior con acercar/alejar, porcentaje y Fit. El Designer agrupa los comandos de insertar y
editar, mueve el minimapa de la esquina superior izquierda a un Expander contraído
en la parte superior del inspector, y pone zoom/cuadrícula/ajuste/reglas en la
barra de vista inferior. El Viewer pone los comandos de documento/página/salida arriba y
zoom, navegación de páginas y la línea de estado/papel abajo, dando al informe
el área máxima.

**About.** La ventana ahora informa dos identidades distintas: el motor
(`v9.0 (r4433)`) y la aplicación de Windows (`v0.7`). La decisión asentada es
que la aplicación de Windows está por debajo de 1.0 mientras el motor es maduro.

**Accesibilidad y localización.** Las superficies de navegación y comandos tienen
tooltips, etiquetas de texto donde un icono es ambiguo, nombres de UI Automation (incluidos
los botones de zoom y página solo con icono), atajos de teclado, y estados de foco y
deshabilitado de Fluent. Cada cadena nueva o renombrada está en los seis diccionarios
(`LocalizerTests` comprueba completitud y marcadores de posición; el inglés sigue siendo la
fuente autoritativa); los cuerpos de licencia, avisos, copyright y nombres de marca se quedan
en inglés textual. La suite es de 110 pruebas, incluidas las pruebas de Welcome/navegación/
primer espacio de trabajo, la prueba de mostrar la ventana About, la prueba del diccionario de tema y
las pruebas de zoom/ajuste de consulta.

**Evaluación de la cinta.** No se introdujo ninguna cinta. La superficie de comandos del Designer
son dos grupos (paleta de inserción, edición) más una barra de vista; una cinta añadiría cromo
y quitaría espacio de lienzo sin ganancia de descubribilidad con este número de comandos. Una
cinta solo para Designer vale la pena revisarla solo si el conjunto de elementos/comandos crece
sustancialmente (por ejemplo, grupos completos de tipografía, alineación y diseño de tabla).
Los tres espacios de trabajo tienen comandos materialmente diferentes, así que una cinta de toda la aplicación
sería más compleja, no más simple.

**No hecho (registrado, no defectos).** Sin un cuarto destino Home; sin cierre en la aplicación
a Welcome. El color del escritorio WebView2 del Viewer se lee cuando se crea el navegador,
así que un cambio de tema a mitad de sesión necesita un relanzamiento. La aplicación WPF de referencia
nombrada en el encargo no estaba presente en la estación de trabajo; la dirección
sigue la guía de diseño de Windows 11 de Microsoft, el tema Fluent nativo y el
arte existente de MAD, con la paleta y el espaciado centralizados para un fácil
reajuste. El `docs/windows.md` público y sus traducciones siguen diferidos.

## 6j. El cierre de códigos de barras (2026-11-20)

El elemento de código de barras ya no es una brecha en ninguno de los dos lados de la frontera.

**Motor.** `MADBarcodes` compila aquí (cada subclase de simbología; `MADBarcodeView` y
`MADBarcodeCache` se quedan solo en Apple), enlazando libpng 1.6.59 y zint 2.16.0 de
`libraries.conf`. La pasada de codificación de `MADBarcode` es compartida, y `-renderedPNGData` escribe el
mapa de bits RGB de zint a través de libpng sin Core Graphics, así que el motor headless produce el mismo
símbolo. `MADPrintPageElementBarcode`, `RptqDocumentElementBarcode+Extras` y
`MADDocumentObjectDataReferenceBarcode` están en la compilación headless; el recorrido de páginas pone el PNG
en `MADReportLineRepresentation.imageData`, el facsímil HTML lo incrusta como data URI (la
entrada es el texto `alt`), y el informe JSON lo nombra con `"image": true`. Un código de barras con
`useStaticInput1`/`inputStatic1` renderiza esa cadena; uno vinculado lee su campo de consulta.

**serve.** `add-element` acepta `"kind": "barcode"` (Code 128, legible por humanos, `MAD-2026`
estático, 160×48, los valores predeterminados del Mac); `layout-model` lleva un objeto `"barcode"` anidado
(id y nombre de simbología, opciones, vinculación de entrada, y un `preview` PNG en base64 del mismo
núcleo de renderizado); `set-element-content` edita la simbología, la bandera legible por humanos, el estilo de borde y
la vinculación estática-o-campo; `duplicate-elements` copia las columnas del código de barras;
`barcode-types` devuelve la tabla de nombres de MADBarcode como `{id, name}` ordenada por nombre.

**WPF.** El botón Barcode de la paleta inserta uno; el lienzo dibuja la vista previa del motor
(recurso de texto cuando zint se niega); el inspector muestra el selector de simbología, Show text, el
selector de borde y el selector de entrada (estática, que edita el cuadro Text, o un campo de consulta).
`DesignerAcceptanceTests.Barcode_InsertEditBindAndUnbind` y la prueba de humo del documento creado lo
fijan (las exportaciones HTML/JSON llevan el símbolo y su texto), y las fijaciones de bytes de London no
cambian porque los bytes de un documento sin códigos de barras no se movieron.

**Licencia.** zint (BSD-3-Clause) y libpng (PNG Reference Library v2) están en §10, en la lista de componentes de la ventana
About y en `ThirdParty/Licenses/` (ambos textos ya existían).

## 6k. El cierre de imágenes (2026-11-20)

El elemento de imagen deja de ser un marcador de posición. No se añadió ninguna biblioteca: la columna de imagen del almacén
ya contiene bytes PNG.

**Motor.** Fuera de Apple `MADReferenceImage` y `MADElementImage` son `NSData` — el propio
formato de cable del almacén — así que el modelo está listo para headless y `RptqDocumentElementImage (Extras)`
ganó los portables `-pngData` / `-setPngData:`, que almacenan los bytes textualmente en todas partes
(los accesores `-image` de Apple siguen codificando/decodificando la imagen donde existen UIKit/AppKit).
`MADPrintPageElementImage -renderedImageData` responde el PNG almacenado, así que
`MADReportLineRepresentation.imageData` — la costura del cierre de códigos de barras — también lleva una imagen:
el facsímil HTML la incrusta como URI `data:image/png;base64,…` y el informe JSON la nombra
`"image": true` sin texto. En Apple la ruta PDF sigue dibujando el elemento y
`-renderedImageData` responde nil, que es el comportamiento de exportación del Mac preexistente.

**serve.** `add-element` acepta `"kind": "image"` con un `"data"` base64 opcional (decodificado
antes de insertar el elemento, así que una petición malformada no deja nada atrás); `layout-model`
lleva un objeto `"image"` anidado `{data}`; `set-element-content` acepta `"data"` (PNG en base64;
vacío lo borra); `duplicate-elements` copia la imagen.

**WPF.** El botón Image de la paleta inserta un elemento; el inspector muestra un botón localizado
"Choose Image…" para una imagen seleccionada (la fila del inspector del Mac). El selector decodifica cualquier
PNG/JPEG a través de WIC y lo recodifica como PNG (`ImageFileEncoder`) antes de enviarlo — la
columna es siempre PNG, así que el data URI HTML es honesto. El lienzo dibuja la imagen almacenada y
recurre al marcador de posición `[Image]` cuando el elemento no tiene ninguna. `ImageElementTests` fija
el protocolo, la recodificación del selector y el lienzo; la prueba de humo del documento creado añade uno
al documento exportado.

## 6l. El cierre de PDF (2026-11-20)

`mad export --format pdf` y el `export` de `mad serve` ahora escriben un PDF en Windows, y la
mitad de Windows es la tercera pila de bibliotecas headless que lleva la compilación.

**Bibliotecas.** `Windows/Engine/libraries.conf` fija exactamente las fijaciones de Linux: pixman
0.46.4 y cairo 1.18.6 (etiquetas git, commits fijados) y FreeType 2.15.0 (tarball), más
el tarball de fuentes Liberation 2.1.5. `build.ps1` compila FreeType con su propio CMake
(clang-cl, estático, solo núcleo), luego pixman y cairo con Meson bajo el entorno
MSVC (`cl`), de forma estática y solo con la superficie PDF. Las compilaciones Meson encuentran
sus dependencias locales a través de archivos `.pc` generados y el mismo shim de
pkg-config nativo de Windows que introdujo la compilación de libpq (`Ensure-PkgConfigShim`, ahora una función para que
ambas compilaciones lo compartan). Tres archivos se unen al enlace: `cairo.lib`, `freetype.lib`,
`pixman-1.lib`; `msimg32` se une a la lista del sistema para la superficie win32 de cairo.

**Fuentes.** Las caras Liberation se copian a `Engine/build/fonts`;
`MADReportExporterPDFCairo` busca `<exe>/fonts` primero (para que `mad.exe` encuentre
`build/fonts` y una prueba en `build/tests` encuentre `build/fonts` a través de `<exe>/../fonts`),
luego los diseños instalados y `MAD_FONTS_DIR`.

**Escritor.** `MADReportExporterPDFCairo` en `MAD/Source` es el cuerpo no-Apple de
`MADReportExporterPDF`; el cuerpo Apple no se toca y no enlaza Cairo. El objetivo
estructural, el mapeo de fuentes y el determinismo son los de
`docs/project/MAD_PDF_LINUX.md`. `MADPDFExportTests` es la prueba de aceptación en ambos
motores; lee el PDF de vuelta y compara el recuento de páginas, MediaBox, cada marco y el texto de cada
línea con el oráculo `json-report`, comprueba el código de barras y la imagen como XObjects de imagen,
y comprueba la igualdad determinista de bytes.

**Licencias.** cairo (MPL-1.1), pixman (MIT), FreeType (FTL) y las fuentes Liberation
(SIL OFL 1.1) están registrados en `THIRD_PARTY_LICENSES.md` §3.5 y §10, sus textos están
en `ThirdParty/Licenses/`, y `WindowsLicenseRegistry` lista las cuatro para la ventana
About. Ninguna añade una obligación de relink.

**Viewer.** El selector de formatos del Viewer WPF lista PDF primero, como hace el del Mac, y
lo exporta a través de la forma de ruta de `serve` (`export` con un `path`), así que el motor escribe los
bytes del exportador y la respuesta lleva el recuento de bytes. Los formatos de texto mantienen la lectura de vuelta
`data`, cuya decodificación UTF-8 es sin pérdida para ellos. Una barra de progreso indeterminada y una
línea de estado "Exporting…" cubren la llamada; las cadenas `Format.Pdf` y `Viewer.Exporting`
se envían en los seis diccionarios.

## 7. Versiones de Windows admitidas

La matriz de sistemas operativos admitidos de .NET 10 (Windows 10 Enterprise 21H2/1809/1607, Windows
11) y la línea base de Windows 10 1903+ de GNUstep; probado en Windows 11 Enterprise
26H2 (build 26300). Windows 7/8 no son admitidos por .NET 10.

## 8. Licencias de terceros y la página About de Windows

El motor de Windows es una tercera superficie de distribución, registrada en
`docs/project/THIRD_PARTY_LICENSES.md` §10. Añade el runtime de GNUstep a la
superficie de cumplimiento:

* **GNUstep Base, gnustep-corebase y la biblioteca libiconv** son
  LGPL-2.1-or-later. La distribución de Windows debe llevar el texto LGPL-2.1, el
  aviso, y la oferta escrita de relink en `ThirdParty/Licenses/README.md`.
* **libobjc2 (incluido libBlocksRuntime) y libffi** son MIT; conserva los
  avisos.
* **libdispatch** es Apache-2.0 con la excepción del runtime de Swift; envía el texto
  completo.
* **FreeTDS y MariaDB Connector/C** se enlazan estáticamente bajo la elección LGPL-3.0
  existente; la edición de `sybdb.h` de FreeTDS está marcada, y la oferta de
  relink existente ahora nombra el motor de Windows.
* **Las bibliotecas C** (SQLite, zlib, bzip2, libarchive, libpng, zint, OpenSSL,
  libpq) usan las entradas y textos existentes en `ThirdParty/Licenses/`.
* **Microsoft Edge WebView2** (el control de vista previa del Viewer WPF, NuGet
  `Microsoft.Web.WebView2` 1.0.4314.35) es un producto de Microsoft, no software de
  código abierto: el Evergreen WebView2 Runtime se instala con Windows 11 y Edge
  y no es modificado ni redistribuido por este proyecto. Está registrado
  con la licencia BSD-3-Clause del SDK y los avisos de terceros de Microsoft, los
  Términos de licencia de software de Microsoft del runtime, y la atribución de este proyecto —
  todo en `ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`.
* **gnustep-make** son herramientas de compilación GPL-3.0-or-later y no se distribuye; su
  `Testing.h` se compila solo en binarios de prueba, que no se envían. Las herramientas
  `iconv` de libiconv y los programas de prueba de gnustep-corebase tampoco se
  distribuyen. Las herramientas de línea de comandos de GNUstep Base (`gdomap`, `gdnc`,
  `defaults`, `plutil`, `gspath`) son GPL-3.0-or-later y no forman parte de
  `mad.exe`; no las empaquetes sin el texto GPL y una oferta de código fuente
  correspondiente.

La división exacta DLL/estático se mide del `mad.exe` compilado con
`dumpbin /dependents` (o `llvm-objdump -p`) y se registra en el informe de la Fase 3b;
no se infiere del diseño del toolchain. La compilación y cualquier paquete
deben copiar `ThirdParty/Licenses/` y `NOTICE`.

La ventana **About** de WPF (prueba del shell de la Fase 5, completada en la Fase 6e; la
división de versión motor/aplicación llegó en la Fase 6f) refleja
las tres pestañas del Mac — Overview, License & Notice y Acknowledgements — y
lista cada componente anterior, incluido WebView2, con los textos de
`ThirdParty/Licenses/Windows/` y los textos raíz compartidos y la oferta escrita
LGPL. La lista de Acknowledgements es la lista de componentes de Windows, no la de la
aplicación de Apple; la pestaña License & Notice lleva el aviso de MIT/marca y la oferta de
relink de Windows; el Overview lleva el aviso de traducción asistida por máquina. Su
cromo está localizado, mientras cada cuerpo de licencia, aviso de componente, nombre de licencia
y línea de copyright se queda en inglés textual (D6/§8 de
`MAD_APP_LOCALIZATION.md`). Las pantallas About existentes de iOS y macOS se quedan
solo en Apple: listan las bibliotecas C que enlaza la aplicación de Apple y no deben afirmar que la
aplicación de Apple enlaza el runtime de GNUstep. El `docs/windows.md` público y la
entrada de Windows del `README.md` aterrizaron con la versión sin firmar 0.7 (2026-11-21);
la página está presente en los seis idiomas bajo el contrato de documentación
(`docs/project/LOCALIZATION.md`). El flujo de trabajo de verificación de Windows
(`.github/workflows/windows.yml`) prueba las suites .NET contra el
activo de motor `mad-windows-x64.zip` adjunto a `v0.7.0`;
`Windows/package.ps1` ensambla tanto ese activo como el zip de versión de la aplicación.

## Bases de datos de prueba

Las tres suites de controladores en vivo (Fase 3b) se ejercitan contra los mismos servidores de prueba
Docker fijados que usan las compilaciones de Apple/Linux, ejecutados como **contenedores locales de Windows
vinculados a `127.0.0.1`** (el Mac mantiene la publicación en todas las interfaces para que la
imagen de Linux y los fixtures de la CLI alcancen sus contenedores por nombre). Los puntos de entrada
multiplataforma son `TestDatabase/test-databases.sh` (Git Bash) y
`TestDatabase/test-databases.ps1` (PowerShell), que delegan en los tres
scripts por framework; `TestDatabase/README.md` es la referencia.

```powershell
.\TestDatabase\test-databases.ps1 -Action download   # fetch datasets, no Docker
.\TestDatabase\test-databases.ps1 -Action up         # create/start all three
.\TestDatabase\test-databases.ps1 -Action status     # -Service mysql|tds|postgres
.\TestDatabase\test-databases.ps1 -Action verify
.\TestDatabase\test-databases.ps1 -Action env        # print the env block
```

El bloque `env` es el contrato que leen las suites en vivo de la Fase 3b; aplícalo en la
misma sesión que `build.ps1`:

```powershell
$env:MAD_MYSQL_TEST_HOST = "127.0.0.1"; $env:MAD_MYSQL_TEST_PORT = "13306"
$env:MAD_MYSQL_TEST_USER = "root"; $env:MAD_MYSQL_TEST_PASSWORD = "root"
$env:MAD_MYSQL_TEST_SCHEMA = "employees"
$env:MAD_TDS_TEST_HOST = "127.0.0.1"; $env:MAD_TDS_TEST_USER = "sa"
$env:MAD_TDS_TEST_PASSWORD = "Root1@Root2"; $env:MAD_TDS_TEST_DATABASE = "AdventureWorksLT2022"
$env:MAD_PG_TEST_HOST = "127.0.0.1"; $env:MAD_PG_TEST_PORT = "5432"
$env:MAD_PG_TEST_USER = "mad"; $env:MAD_PG_TEST_PASSWORD = "mad_test_pw"
$env:MAD_PG_TEST_DATABASE = "chinook"
```

No hay `MAD_TDS_TEST_PORT` — la suite de TDS fija 1433. Los resultados de compilación de controladores
están documentados en el informe de la Fase 3b, no aquí.

## Documentos relacionados

* `docs/project/MAD_LINUX.md` y `Linux/README.md` — la compilación de Linux que
  esta compilación de Windows refleja.
* `docs/project/MAD_MACOS.md` y `Mac/README.md` — la aplicación nativa de macOS
  cuyo comportamiento reflejará la aplicación WPF.
* `docs/project/THIRD_PARTY_LICENSES.md` §10 — el registro de licencias del motor de
  Windows; `ThirdParty/Licenses/` y `ThirdParty/Licenses/Windows/` — los
  textos y la oferta escrita de relink.
