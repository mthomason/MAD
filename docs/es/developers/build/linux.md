---
layout: default
title: "Compilar el motor en Linux"
description: "La compilación con Docker, los doce frameworks headless y sus suites."
lang: es-419
---

# Compilar el motor de MAD en Linux — una evaluación técnica

Esta página registra la compilación de Linux: la imagen de Docker, el toolchain fijado, los doce frameworks headless y las suites que ejecutan. `Linux/README.md` tiene los comandos del día a día.

*Escrito en la fecha original; los hechos del estado actual se conciliaron el 2026-11-22.*

Escrito el 2026-10-04 contra `master` en `c807eeb4d`. La auditoría de dependencias (§4) y la
investigación del ecosistema (§5-6) en las que se basa este documento se produjeron el mismo día:
la auditoría buscando en el directorio de fuentes de cada framework, la investigación en fuentes primarias
(notas de versión, repositorios de paquetes, listas de correo del proyecto). Donde la evidencia
era escasa, se dice. Este documento es el compañero técnico de `MAD_FUTURE.md`
§5.1, que esbozaba la matriz de plataformas; esta es la inmersión.

---

## 1. La pregunta, respondida

¿Se puede compilar en Linux? **Sí, condicionalmente — en ambos sentidos.**

- El código que debe compilar — el motor headless — está, por medición, ya
  casi libre de dependencias de Apple. Las dos que quedan (Core Data y
  UIKit/CoreGraphics) o están en plena migración o están enumeradas archivo por archivo, y
  ninguna se sienta en la ruta de actualización.
- El ecosistema que debe hospedarlo — Objective-C con Foundation en Linux — existe,
  está empaquetado en cada distribución importante, y ejecuta un servidor de groupware de producción
  hoy (SOGo, empaquetado en Debian contra GNUstep Base 1.31.1). Es de nicho, su
  cobertura de API moderna no está verificada en los márgenes, y su historia de UIKit no
  existe — pero este código base no necesita UIKit en Linux. Necesita el motor.

Los dos asteriscos: **la Foundation de GNUstep está presente pero no verificada** para las API exactas
en las que más se apoya este código (`NSPredicate`/`NSExpression`, archivado con claves,
`NSURLSession`), y **no hay un UIKit realista en Linux** — lo cual está bien,
porque la auditoría muestra que el código ya confina UIKit a archivos nombrados, y el
plan de renderizado se mueve fuera de UIKit de todos modos.

---

## 2. La pregunta de los dos productos: reescribir o compilar y llamar

La elección que planteó el usuario: reescribir todo en Python y mantener dos productos,
o compilar una vez y hacer que Python llame al motor. La auditoría lo resuelve.

**El motor es grande.** El conjunto de frameworks headless — `MADFoundation` (65 archivos h+m),
`MADCocoaExtensions` (44), `MADDataStructures` (36), `MADFileManager` (30), `MADAPI`
(33), `MAD` (403), `MADSqlite3` (64), `MADMySQL` (41), `MADTds` (3), `MADTdsClient`
(8) — es aproximadamente 727 archivos. Una reescritura en Python duplica no solo el volumen sino
*comportamiento que está fijado por pruebas y ganado con esfuerzo*: el generador de SQL, la
ruta de ingesta `MADDataTableFast` (200,000 filas en 1.16 s, medida), los mapeos de tipos de los
controladores (el manejo moderno de fecha/hora de SQL Server existe solo porque las pruebas en vivo
lo detectaron dos veces), la familia de centinelas nulos, el lector del almacén. Dos implementaciones de
eso divergen; la suite fija solo una. Eso no son "dos productos", es un producto
y un pasivo.

**La superficie de integración ya existe.** La CLI *es* el contrato: `mad inspect` → metadatos, `mad query` → SQL, `mad refresh` → filas, `mad export` → formatos, con
códigos de salida que distinguen documento malo (2) de servidor inalcanzable (3) de consulta fallida
(4). Un servicio Python la llama como subproceso con `--format json` y obtiene
el informe. La sobrecarga del subproceso es irrelevante en las escalas de tiempo de actualización (las muestras
se actualizan en 0.02-1.2 s; el lanzamiento de un proceso es ~10 ms). Si alguna vez se
mide que la incrustación en proceso importa, las mismas fuentes pueden compilar una pequeña biblioteca de ABI C para
ctypes/CFFI — pero eso es opcional, no un requisito previo.

**Sobre la razón declarada para preferir Python — la conexión de controladores.** Es cierto que el
ecosistema de conectores de Python es amplio, y un `pip install` llega a bases de datos para las que este proyecto
no tiene controlador. Pero para los orígenes que existen hoy la conexión ya es
neutral respecto al lenguaje: los controladores de MAD se asientan sobre freetds y MariaDB Connector/C — las mismas bibliotecas C
que enlazaría un programa Python o C — y ambas compilan de forma nativa en Linux (§7).
Compilar el motor mueve esa conexión a Linux sin cambios. Donde Python genuinamente
tiene ventaja es en *nuevos* tipos de origen (Postgres, BigQuery, REST), y allí la respuesta correcta
es la costura de extensibilidad que el proyecto ya promete: una subclase de `MADDatabase`
que devuelve un esquema y filas. Un controlador que habla HTTP se comporta
igual en Objective-C y Python; Python compra más conectores preescritos, no
un núcleo más fácil.

**El compromiso honesto, dicho claramente:** esta es una elección entre mantener *dos
implementaciones* (Python + Objective-C) con riesgo de deriva permanente, y mantener
*una implementación en un toolchain de nicho* (clang + libobjc2 + GNUstep) con
riesgo de ecosistema. Este documento recomienda lo segundo, con un disparador medible para
revisarlo: §9 nombra el punto de control. Lo único que hace vinculante la recomendación
es la **forma de la exportación JSON** — el contrato de Python es tan bueno como su
esquema, y definirlo es la decisión 1 en §10.

Y si alguna vez ocurre una reescritura, el lenguaje correcto es Swift en Linux — no Python
— porque el almacén SQLite portable (el trabajo de la Fase C) ya es un contrato
neutral respecto al lenguaje: cualquiera de los dos lados escribe el almacén, el otro lo lee.

---

## 3. Qué debe compilar y qué no

| Framework | Necesario headless | Por qué / por qué no |
|---|---|---|
| `MADFoundation` | sí | la base: operaciones, fábrica de URL, llavero (excluible), registro |
| `MADCocoaExtensions` | sí | ayudantes usados en todas partes (11 archivos UIKit, pero excluibles) |
| `MADDataStructures` | sí | 0 importaciones de Apple; 3 archivos C++ (necesita libc++) |
| `MADFileManager` | sí | 0 importaciones de Apple; coordinador de nube excluido (iCloud se elimina en la Fase D de todos modos) |
| `MADAPI` | sí | capa de conexión; 3 archivos UIKit son controladores de vista, no headless |
| `MAD` | sí | el difícil: 29 de UIKit, 34 de CoreData, 15 de CoreGraphics de 403 |
| `MADSqlite3` | sí | 0 importaciones de Apple; `MADArrayCaching` (el almacén `.madac`) está 100% limpio |
| `MADMySQL` | sí | 0 importaciones de Apple |
| `MADTds` / `MADTdsClient` | sí | 0 importaciones de Apple |
| `MADExplorer` | no | interfaz del explorador de archivos (19 de 32 archivos importan UIKit) |
| `MADBarcodes` | sí | el núcleo de codificación + PNG es portable (zint + libpng); solo `MADBarcodeView` y `MADBarcodeCache` se quedan del lado Apple |
| `MADFeedback` | no | sin usar y sin mantenimiento |
| `Scrimpter` | no | 0 importaciones de Apple, pero sin usar |
| `MADDesigner` (aplicación) | no | 302 archivos UIKit; la interfaz se queda en las plataformas Apple |

Dirección de dependencias: todo se asienta sobre `MADFoundation`; los controladores heredan de
`MADDatabase` en `MAD`, mientras los archivos `Constructor` de `MAD` importan los controladores — el
ciclo conocido (`ROADMAP.md` §3.4). El registro de controladores (`ROADMAP.md` §5.1) importa a
Linux por partida doble: rompe ese ciclo y es lo que permite que una compilación de Linux enlace
controladores como plugins en lugar de como un montón importado directamente.

---

## 4. La auditoría medida

Archivos que importan cada framework de Apple, por directorio de fuentes de framework (un archivo
que importa varios encabezados de UIKit cuenta una vez):

| Framework | total | UIKit | CoreData | CoreGraphics | Security | os/log | CoreFoundation | dispatch |
|---|---|---|---|---|---|---|---|---|
| MADFoundation | 65 | 4 | 0 | 0 | 1 | 9 | 3 | 1 |
| MADCocoaExtensions | 44 | 11 | 0 | 3 | 0 | 1 | 0 | 0 |
| MADDataStructures | 36 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| MADFileManager | 30 | 0 | 0 | 0 | 0 | 2 | 0 | 5 |
| MADAPI | 33 | 3 | 0 | 0 | 0 | 4 | 0 | 2 |
| MAD | 403 | 29 | 34 | 15 | 1 | 15 | ~19 | 3 |
| MADSqlite3 | 64 | 0 | 0 | 0 | 0 | 4 | 3 | 5 |
| MADMySQL | 41 | 0 | 0 | 0 | 0 | 2 | 0 | 1 |
| MADTds | 3 | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| MADTdsClient | 8 | 0 | 0 | 0 | 0 | 0 | 0 | 3 |

La cola larga fuera de los pilares, cada una con una disposición:

| Elemento | Sitios | Disposición |
|---|---|---|
| `os_log` (todo se canaliza por `madlog.h`, dos copias) | 9+15+4+2+… archivos importan el shim | reescribir un encabezado de ~20 líneas contra syslog/printf; ningún otro sitio de llamada cambia |
| `asl.h` (Apple System Log obsoleto) | `MADocument.m:107`, `RptqDocumentElement+Extras.m:60` | cambiar al shim de madlog |
| `copyfile.h` | `MADArchiveManager.m:14`, `madtar.m:18` | rename/link POSIX |
| `mach/machine/vm_param.h` (tamaño de página) | `MADocument.m:108` | `getpagesize()` |
| DNS inverso `CFNetwork`/`CFHost` | `BDHost.m` (1 archivo) | `getaddrinfo` |
| Coordinador de nube `NSMetadataQuery` | `MADFileManager` (3 archivos) | excluir — iCloud se elimina en la Fase D |
| `Security.framework` / `SecItem` | `MADKeyChain.m`, `MADOperationKeyChainGet.m` + prueba | excluir — la ruta de actualización toma credenciales de una dependencia de operación, nunca del llavero; la CLI ya sustituye `--credentials` |
| Guarda de `AppKit` en `MADApplication.m` | 1 archivo | añadir una rama `TARGET_OS_LINUX` |
| Escala de `UIScreen` en `MADURLFactory.m:32` | 1 línea | devolver 2.0 |
| Tarea en segundo plano de `UIApplication` en `MADOperation.m:549-563` | 1 función protegida | `#if` fuera |
| CoreFoundation (`CFNumber`/`CFData`/`CFString`, puenteo toll-free) | ~25 sitios en MAD, MADFoundation, MADSqlite3 | equivalentes de GNUstep / reescritura mecánica; CoreBase (el clon de CF de GNUstep) es inmaduro, no confíes en él |
| Transformadores de valores de UIKit (`MADColorTransformer`, `MADLocaleTransformer`, `MADPngImageTransformer`) | 3 archivos, actualmente arrastrados a través de la frontera de objetivos de la CLI | **mueren con la Fase D** — la migración del almacén convierte los transformables a escalares portables |

SystemConfiguration: cero ocurrencias. CommonCrypto: cero en frameworks (solo en la aplicación,
validación de recibos). `@import`: cero — todo es `#import`, que es lo que
quiere GNUstep.

---

## 5. Los tres pilares

### 5.1 Core Data — la migración en curso es la palanca

34 archivos de MAD importan Core Data; `MADocument` es un `UIManagedDocument`; el almacén es un
`MAD.momd` compilado; `MADAtomicStore` se asienta debajo. Nada de eso existe en Linux,
y nada de eso necesita existir — porque el proyecto ya lo está reemplazando: `MAD_STORE_MIGRATION.md`
Fase C aterrizó el 2026-10-03, y `RptqStoreContext.h` declara "Nothing here imports
Core Data." La Fase D elimina `UIManagedDocument`, los transformadores de valores, el
`.xcdatamodel` y la maquinaria de iCloud — lo que simultáneamente mata varios elementos de §4
(los transformadores de valores, el coordinador de nube, el `MAD.momd` que la CLI
actualmente copia del paquete de la aplicación).

**Terminar las fases C y D es el paso de mayor palanca hacia Linux**, y es
trabajo que el proyecto ya posee por portabilidad, no esfuerzo específico de Linux. Una nota del plan de migración: los documentos antiguos de la
era de iCloud se recuperan por el usuario a través de la app Archivos de iOS y se convierten al abrir
(`MADStoreConverter`) — la maquinaria de iCloud no es necesaria para recuperarlos, así que la
eliminación de la Fase D no deja nada varado.

### 5.2 UIKit / CoreGraphics — 29 archivos, la mayoría triviales

Los 29 archivos UIKit de MAD se desglosan así:

| Tipo | Recuento | Disposición |
|---|---|---|
| Estructuras `CGGeometry` (`CGRect`/`CGSize`/`CGPoint`) | 15 archivos | estructuras simples — replicar las definiciones; cero dibujo |
| `UIEdgeInsets` en el formateador | ~3 archivos | reemplazar con la aritmética de estructuras |
| `UIFont`/`UIColor`/`UIImage` en código de modelo/diseño | varios | equivalentes ligeros para métricas y estilos almacenados |
| `UIActivityItemProvider` / hoja de compartir | 2 archivos | no headless — excluir |
| `UIScreen`/`UIApplication` | 2 archivos | de una línea, §4 |
| `MADPrintPageRenderer` + contextos PDF de `UIGraphics` | la costura de exportación | **el trabajo real** — véase abajo |
| La base `UIManagedDocument` de `MADocument` | la clase de documento | muere con la Fase D |

Buena noticia notable: el uso de UIKit en `MADReportFormatter.m` es efectivamente vestigial
(un `UIEdgeInsetsMake`, una importación sin usar de `UIPrintInteractionController`), y
`MADArrayCaching` — el almacén de páginas renderizadas `.madac` — está 100% libre de UIKit/CoreData
ya. Compila en cualquier Foundation ObjC hoy.

**La decisión del renderizador.** Los contextos PDF de CoreGraphics no tienen equivalente en Linux. La
puesta en escena que menos cuesta: primero los verbos de la ruta de datos en verde; `export --format json` /
`--format csv` después (Foundation puro — y estos son los formatos que un llamador Python
quiere de todos modos); páginas HTML/SVG después (sin dependencias nativas); PDF al final, colocando un
escritor cairo o libharu detrás del mismo bucle de dibujo de `MADPrintPageRenderer`, o manteniendo el renderizado PDF en workers de macOS
mientras Linux sirve datos y páginas. La opción `--deterministic` que la CLI ya parchea por bytes en los PDF
es la semilla de una prueba de renderizador multiplataforma.

### 5.3 Foundation en GNUstep — existe, verificada en parte, riesgosa en los márgenes

Lo que la investigación verificó, de fuentes primarias:

- **GNUstep Base 1.31.1** (2025-02-28) es actual; master está activo (trabajo notable
  de NSURLSession fusionado 2026-08). La cadencia de versiones es lenta — aproximadamente anual.
- Presentes y funcionales: `NSJSONSerialization`, `NSUUID`, `NSRegularExpression`
  (ICU), `NSISO8601DateFormatter`, `NSDateFormatter` (respaldado por ICU — `libicu-dev` es una
  dependencia de compilación requerida), `NSOperationQueue`, listas de propiedades, `NSXML*`
  (libxml2), archivado con claves con el objetivo de compatibilidad con XML de Apple.
- **`NSURLSession` es el punto débil**: se envió en 1.31.0 como "nueva implementación
  experimental", explícitamente no una clase soportada; el trabajo de desbloqueo de 2026
  (compilar sin blocks) está fusionado pero la estabilización está inacabada. No construyas
  el producto de Linux sobre ella — prefiere conexiones directas del controlador (que es lo que
  hace la actualización de todos modos) o libcurl.
- **`libdispatch` es opcional por la propia política de GNUstep** — el mantenedor de la base la llama
  "no en un estado en el que sea lo bastante portable/fiable" para depender de ella. Este
  código base usa dispatch ampliamente (`dispatch_once`, `dispatch_sync`, semáforos).
  swift-corelibs-libdispatch es C y se puede llamar desde ObjC (con
  `OS_OBJECT_HAVE_OBJC_SUPPORT=1`), y el *núcleo* usado aquí es la parte estable —
  pero trata dispatch como una capa adaptable con shim, no como algo dado.
- **CoreBase** (el clon de CoreFoundation de GNUstep) es inmaduro — la guía de compilación dice
  que no se confíe en él. Los ~25 sitios CF obtienen equivalentes de GNUstep.
- **No verificados en los márgenes, y fundamentales aquí:** `NSPredicate`/`NSExpression`
  (13+ sitios de importación en MAD), `unarchivedObjectOfClass:` (API de iOS 11+ — la cobertura de GNUstep
  varía), el comportamiento de `NSOperation`+KVO. La presencia está probada; la paridad
  de comportamiento no. Este es el riesgo honesto, y es exactamente lo que los fixtures de §8
  existen para probar.

**La prueba de existencia:** SOGo, un servidor de groupware Objective-C, se envía en Debian
sid con una dependencia dura de `gnustep-base-runtime (>= 1.31.1)` — GNUstep Foundation
ejecutándose como daemon de producción a escala. Darling impulsa libobjc2. Las herramientas ObjC
sin interfaz gráfica en Linux son normales, no exóticas.

---

## 6. Toolchain y ecosistema

- **Tiempo de ejecución: libobjc2 2.3** (2025-09-16) — la única forma de obtener Objective-C moderno
  en Linux. ARC, blocks, referencias débiles, `@synchronized`, ivars no frágiles, la
  ABI gnustep-2.0. **ARC requiere clang + libobjc2**, y los paquetes de las distribuciones
  principales compilan GNUstep contra el runtime de GCC sin ARC — así que el entorno de compilación
  se ensambla desde fuentes (o desde el empaquetado de libobjc2 de Fedora), no desde
  los valores predeterminados de Debian. Este es un compromiso operativo real.
- **Blocks**: libobjc2 2.3 puede consumir el BlocksRuntime de swift-corelibs-libdispatch;
  `libblocksruntime-dev` también está empaquetado. Los blocks del código son estándar.
- **Excepciones**: clang + libobjc2 da excepciones nativas basadas en unwinder; los
  dos mecanismos de excepción de GNUstep no deben mezclarse en un ejecutable — compila todo
  con la ruta nativa.
- **Sin módulos de clang / soporte de `@import`** — y el código base ya usa `#import`
  en todas partes, así que esto no cuesta nada.
- **UIKit en Linux: confirmado ausente.** El recuerdo del usuario de Microsoft es WinObjC —
  el Windows Bridge for iOS, un subconjunto de UIKit deliberadamente parcial en Windows, impulsado por última vez
  en 2022, archivado el 2025-05-28. Chameleon (UIKit en macOS) murió en 2015.
  `gnustep/libs-uikit` (junio de 2026) es un experimento de 26 commits con una estrella. La
  lección que sacar incluso de que Microsoft abandonara la idea: **no portes UIKit.**
  La auditoría muestra por qué este proyecto no tiene que hacerlo — UIKit ya está confinado a
  archivos nombrados, y todo lo headless renderiza a través de datos, no de vistas.
- **Pruebas: no hay XCTest para ObjC en Linux** (swift-corelibs-xctest es solo para Swift).
  El propio `gnustep-tests` + `Testing.h` de GNUstep es el corredor de pruebas unitarias de cero dependencias;
  UnitKit está archivado. La verdadera capa de aceptación son los fixtures de §8, no las pruebas unitarias.
- **Cripto y secretos**: sin port de CommonCrypto (el propio consejo del proyecto GNUstep es
  `#ifdef` a OpenSSL o GnuTLS); sin llavero (el análogo funcional es
  libsecret/Secret Service, o keyutils para secretos de sesión) — y según §4 el
  motor headless no necesita ninguno de los dos.

---

## 7. Las bibliotecas C — la parte fácil, con un bloqueador de licencia

Cada biblioteca vendida es C portable con una compilación upstream de autoconf/cmake:

| Biblioteca | Versión | Licencia | Compilación en Linux |
|---|---|---|---|
| sqlite3 | 3.53.3 | dominio público | nativa; las opciones que fijan el formato ya viven en `Compressor/sqlite3.xcconfig` |
| zlib | 1.3.2 | Zlib | nativa |
| openssl | 3.5.9 | Apache-2.0 | nativa |
| bzip2 | 1.0.8 | tipo BSD | nativa |
| libpng | 1.6.59 | PNG Reference v2 | nativa |
| libarchive | 3.8.9 | BSD-2 | nativa |
| freetds | 1.4.27 | LGPL-2.0+ | nativa (la receta tiene un `sed -i ''` de BSD que corregir) |
| mysqlclient | 8.4.10 | **GPL-2.0 + excepción FOSS** | nativa — **pero GPL es un bloqueador de envío para un binario propietario**; MariaDB Connector/C (LGPL-2.1) es el reemplazo ya nombrado en `LICENSE_COMPLIANCE_PLAN.md` |
| zint | 2.16.0 | BSD-3 | nativa; el backend de códigos de barras que enlaza el núcleo PNG de MADBarcodes (con libpng arriba) |

Más el C en el árbol (`miniz`, `madmath`, `madpng`, `madtar`, `madlib` — todos portables,
todos con licencias permisivas). Solo la capa de *empaquetado* de Compressor es específica de Apple
(`xcrun`, `-isysroot`, `lipo`, `xcodebuild -create-xcframework`); un controlador de Linux
descarta todo eso, ejecuta las mismas compilaciones upstream de forma nativa, y termina con un simple
`ar` + instalación de inclusión. La complejidad específica de iOS (la compilación de herramientas de host de dos etapas de mysqlclient, el encabezado generado por plataforma de freetds) *desaparece* en las compilaciones
nativas. Una bandera de la auditoría: el conector MySQL de Karl Kraft no tiene licencia —
reemplázalo con el cambio a MariaDB, no lo envíes.

---

## 8. El plan de compilación y pruebas

- **Sistema de compilación**: CMake para los doce frameworks headless más la CLI — un conjunto de opciones
  (`clang`, `-fobjc-arc`, `-fblocks`, `gnustep-config --objc-flags` de GNUstep).
  La danza de copiar `.momd` en `CLI/build.sh` desaparece con la Fase D, y
  el alcance de `REFRESH_SOURCES` a través de la frontera de objetivos desaparece con el
  movimiento de `MADOperationRefresh` (`ROADMAP.md` §3.4).
- **Capa de aceptación**: los fixtures de ida y vuelta en `MAD_CLI.md` §6, ejecutados en Linux
  y comparados byte a byte contra la ejecución de macOS/simulador — fidelidad del contenedor, legibilidad v0,
  ida y vuelta sin caché, códigos de salida. La caché de filas y la salida JSON/CSV
  son comparables byte a byte; PDF es comparable estructuralmente solo hasta que exista un
  renderizador. Estos fixtures son también la *prueba de cobertura de GNUstep Foundation*: ejecútalos
  pronto, clasifica cada fallo, y las incógnitas de §5.3 se resuelven
  empíricamente en lugar de leyendo índices de API.
- **CI**: un trabajo de Linux en la matriz de pruebas ejecutando los fixtures; la suite sigue siendo la
  suite del simulador que es hoy.

### 8.1 La ruta de despliegue: contenedores, no compilación cruzada

¿Cómo se compila y se envía realmente esto?

- **No compiles de forma cruzada desde macOS.** Un runtime Objective-C más GNUstep Base está
  acoplado al host — compilarlo de forma cruzada contra un sysroot de Linux desde un Mac es un proyecto de investigación,
  no un paso de compilación. La aplicación iOS sigue compilándose con Xcode en el Mac; el motor de Linux
  se *compila en Linux*.
- **Docker es el entorno de compilación.** Un Dockerfile, dos etapas: una etapa de toolchain
  que compila desde fuentes clang + libobjc2 2.3 + GNUstep Base (requerido para ARC — §6), y
  una etapa de compilación que ejecuta el controlador Linux de Compressor para las bibliotecas C (§7), luego
  CMake para los doce frameworks y la CLI. La misma imagen sirve como entorno de CI
  y como artefacto de despliegue.
- **Qué Linux admitir: una línea base, en un contenedor.** Elige una única línea base —
  Debian estable o un Ubuntu LTS — y compila allí, porque la verdadera restricción de compatibilidad
  es glibc: todo lo enlazado se compila desde fuentes excepto la libc, así que
  "Linux admitido" significa "la glibc de la imagen que enviamos". Compilar sobre la glibc más antigua
  que aceptes es la regla. Enviar un contenedor significa que cualquier host con Docker
  ejecuta el producto sin una matriz de distribuciones.
- **El flujo de trabajo es el script-y-compila al que ya estás acostumbrado, automatizado.**
  `git clone` en el compilador de Linux → las recetas de Compressor compilan sqlite, zlib, openssl,
  bzip2, libpng, libarchive, freetds y MariaDB desde fuentes → CMake compila los
  frameworks con un conjunto de opciones → enlaza `mad` → ejecuta los fixtures de ida y vuelta (arriba) →
  etiqueta la imagen. Un runner ubuntu de GitHub Actions es el lugar estándar para que esto
  ocurra en cada commit.
- **El papel de macOS.** El Mac sigue siendo el host de desarrollo de la aplicación, la CLI del simulador,
  y las salidas de fixture de referencia. Las dos plataformas se unen por git y por
  la comparación de bytes de los fixtures — la compilación de Linux se *comprueba contra* las salidas
  del Mac, que es la garantía de portabilidad hecha ejecutable.

---

## 9. Esfuerzo y fases

Cubos, en el orden en que deberían abordarse:

| Fase | Trabajo | Carácter |
|---|---|---|
| A | Terminar las fases C + D de la migración del almacén | trabajo de portabilidad ya propiedad del proyecto; elimina Core Data, iCloud, transformadores de valores, `.momd` — la mayor palanca única para Linux |
| B | Spike de toolchain: un Dockerfile que compila desde fuentes clang + libobjc2 + GNUstep Base; compilar un subconjunto de MADFoundation | prueba el entorno y se convierte en la imagen de compilación/CI; días |
| C | La lista de shims de §4 | acotada y enumerada — madlog, asl, copyfile, vm_param, CFHost, MADApplication, UIScreen, tarea en segundo plano, ~25 sitios CF, exclusiones |
| D | **El punto de control**: verbos de la ruta de datos en verde en Linux — `inspect`, `schema`, `query`, `refresh` contra ambas muestras, fixtures comparados byte a byte | si esto no está en verde después de C, la cola de GNUstep Foundation es más grande de lo estimado, y *ese* es el momento de revisar la pregunta de la reescritura — no antes |
| E | Exportación: JSON/CSV (el contrato de Python), luego páginas HTML/SVG, luego la decisión de PDF (cairo/libharu vs renderizado del lado de macOS) | Foundation puro primero; renderizador al final |
| F | Controlador Linux de Compressor (compilaciones nativas, columna de matriz, cambio a MariaDB, corrección de sed de freetds) + pulido de CMake + fila de CI + la imagen desplegable | mecánico, condicionado por licencias |

Razón del orden: A es trabajo propio, B es barato y desriesga todo, C es
enumerable, y D es el honesto sí/no. Nada en E o F es necesario para *responder*
la pregunta; solo son necesarios para *enviar*.

**Estado de la Fase A (2026-10-06).** Core Data está fuera del framework MAD: `MADocument` es un
`UIDocument`, el convertidor heredado y el modelo compilado viven en el objetivo de la aplicación
detrás de `MADLegacyStoreConversion`, un documento convertido poda sus archivos Core Data, y el
barrido de framework/MADDesigner eliminó las importaciones, tipos y código muerto restantes. Los transformadores
de valores, el panel de nube del explorador y los derechos de iCloud se conservan por decisión
del usuario — están del lado de la aplicación, así que no bloquean la compilación headless; el código
de nube del gestor de archivos se queda donde está, sin usar (según el usuario: no necesario para el modo headless). Lo que
queda antes de B son las exclusiones a nivel de archivo de §4 que el spike de toolchain demuestre necesarias.

**Estado de la Fase B (2026-10-06).** El spike de toolchain está en verde en la
rama `linux-port`, fusionada en `master` el 2026-10-16 (`524e0d86e`):
`Linux/` compila una imagen de Docker — Ubuntu 24.04 con el clang 18 de la distribución
(el requisito "desde fuentes" de §6 se refiere a que GNUstep se compila contra
libobjc2, no a LLVM), más libobjc2 2.3, libdispatch 6.1.3,
gnustep-make 2.9.3 y gnustep-base 1.31.1 compilados desde fuentes, fijados en `Linux/toolchain.conf` —
compila 23 de los 27 archivos de implementación de MADFoundation y `madlib.c` contra
GNUstep, y ejecuta 15 ejecutables de prueba (14 suites portadas y una sonda de toolchain)
dentro de ella: todas pasan, con 5 necesidades registradas y 10 elementos de informe de sonda.
`./Linux/build.sh` es el punto de entrada; la suite de iOS siguió en verde (118 pruebas) como
prueba de que las seis pequeñas guardas de plataforma que el trabajo requirió son neutrales en comportamiento
en Apple.

La sonda retira la mayor parte de la lista de riesgos de §5.3 para la Foundation que el motor realmente
usa: ARC y puesta a cero de débiles, blocks, excepciones, `@synchronized`, KVO (manual y
claves dependientes), KVO de la máquina de estados de `NSOperation`, `NSPredicate
predicateWithFormat:@"error != nil"` (el predicado exacto de MAD), dispatch incluida
la cola principal drenando bajo un ejecutable simple, JSON, fechas, plists, descriptores de ordenación,
streams y archivado con claves en la ruta permisiva, todos pasan. Dos brechas
se registran, no se ocultan: el archivador de GNUstep no tiene soporte de codificación segura
(`requiringSecureCoding:YES` devuelve nil; la ruta permisiva hace ida y vuelta), y
el `NSOperationQueue` de GNUstep elimina su observación de `isReady` en cada
notificación mientras la máquina de estados de MADOperation solía notificar `isReady` más
de una vez por encolado — la segunda eliminación lanzaba una excepción, así que un MADOperation no podía
encolarse en Linux. Eso está resuelto (2026-10-06, `linux-port`, ahora en `master`):
MADOperation impulsa el avance de estado explícitamente desde `-willEnqueue` y envía
KVO para `isReady`/`isExecuting`/`isFinished` solo en cambios reales de valor, así que la
cola ve una notificación, como en Apple; las pruebas de Linux lo afirman claramente en
ambas plataformas y las necesidades bajaron a 3. El mecanismo está escrito en
`Linux/README.md` junto a los archivos excluidos y los shims más pequeños
(`NSOperation.name`, `qualityOfService`, `NSDataWritingFileProtection*`,
`QOS_CLASS_DEFAULT`, contenedores de grupo de aplicaciones). Las exclusiones a nivel de archivo que la Fase A anticipó resultaron ser exactamente
los cuatro archivos de §4 (`BDHost`, `MADApplication`, `MADKeyChain`, `MADURLFactory`); la
limpieza de encabezados autocontenidos que el preludio solía tapar está hecha (2026-10-06):
cada encabezado y fuente de la compilación de Linux importa lo que usa, y
`Linux/Compat/MADCompat.h` se reduce a la única brecha real de plataforma, la propiedad
`name` de `NSOperation`.

**Estado de la Fase C (2026-10-06).** La lista de shims de §4 está despejada y la compilación ya no
es un spike: los doce frameworks headless de la tabla de §3 compilan y enlazan
dentro de la imagen — MADFoundation 26 de 27 archivos, MADDataStructures 17,
MADFileManager 10 de 11, MADCocoaExtensions 7 de 17, MADAPI 8 de 11,
MADSqlite3 26, MADTds 1, MADTdsClient 4 de 5, MADMySQL 18 de 19, MAD 150 de
181 — y sus suites se ejecutan bajo ctest: 114 ejecutables (1098 pruebas), todas
en verde, con 6 necesidades registradas, cada una maquinaria solo de Apple (Core Data, el
modelo compilado, `MADocument`, el convertidor) nombrada en `Linux/README.md`. La
cobertura de master fusionada el 2026-10-10 (~100 archivos de prueba de Xcode) está portada en
su totalidad — 55 ejecutables nuevos, suite por suite — y la fusión encontró dos defectos
del lado de Apple, ambos corregidos y en `BUGS.md`: los objetivos de framework habían eliminado
`$(inherited)` de sus defines de preprocesador (DEBUG estaba muerto en cada
compilación Debug de framework), y los fixtures de documento de MAD compartían un almacén entre
ejecuciones. Una capa de bibliotecas
(`Linux/libraries.conf`, `Linux/lib/libraries.sh`) compila sqlite3,
openssl, freetds, zlib, bzip2, libarchive, libpng, zint y mysqlclient de forma nativa
en la imagen (las bibliotecas C de §7; nada se envía). Los elementos de cola larga fueron como §4
predijo — las importaciones de `asl.h`/`vm_param.h` eran vestigiales, `copyfile(3)`
se convirtió en POSIX, `CFHost` se convirtió en `getaddrinfo`, los sitios CF se convirtieron en un
shim de `CFNumberGetValue` — y la cola de UIKit/CoreGraphics se excluye
archivo por archivo con razones, no se porta (la disposición de §5.2; `MADocument`, un
UIDocument, y `MADReportFormatter` esperan a la Fase D, que es el problema de la CLI tanto
como el de la plataforma). Las suites de MAD encontraron tres divergencias más,
todas corregidas o con shim y anotadas en `Linux/README.md`: la codificación BOOL del runtime
(`'C'` fuera de Apple), el recorrido faltante de superclase de `class_getProperty()`
(ambos corregidos en `RptqObject`), y un stub `+propertyListWithStream:`
(con shim). El port de cobertura de pruebas añadió tres más, igualmente corregidos o con shim:
`NSOperation.asynchronous`/`-isConcurrent` (una categoría Compat — sin ella una
operación asíncrona que terminaba lanzaba una excepción desde `-dealloc`), `-coordinateAccessWithIntents:`
(su implementación de GNUstep falla; la categoría Compat llama al accesor en
la cola), y URL sin esquema de `MADURLFactory` (ahora
`+fileURLWithPath:`, que desaparcó cinco pruebas de coordinador). La única divergencia
que se mantuvo fijada por más tiempo — el `-localizedCaseInsensitiveCompare:` de GNUstep distingue
mayúsculas, así que la colación registrada de MADSqlite3 ordenaba el texto de forma diferente
que en Apple — está corregida ahora (2026-10-25): la colación, los selectores de ordenación
en memoria y el comparador del formateador se enrutan todos por un orden definido propio
(`NSString+Comparison.h`), y la fijación se convirtió en pruebas de orden definido
que se mantienen idénticamente en ambas plataformas. La suite en vivo
`MADTdsClientLiveTests` se ejecuta en verde desde dentro
de la imagen contra el contenedor de SQL Server (29/29), así que la ruta del controlador se
ejercita en Linux, no solo se compila. La Fase D — la CLI y los verbos de la ruta
de datos — es el siguiente paso y el sí/no.

**Estado de la Fase D (2026-10-16).** El punto de control se cumple: `mad` compila dentro de la
imagen desde `CLI/Source` (las mismas fuentes con las que se compila la herramienta del simulador de iOS),
enlaza los doce frameworks, y ejecuta la ruta de datos allí. `inspect` informa tanto una
muestra v0 heredada como un fixture v1 portable; `schema` y `query` producen las mismas
respuestas que la herramienta del Mac (idénticas byte a byte para `schema`); `refresh` llena la caché de filas
en la muestra Sqlite3 y es idéntica byte a byte a la caché del Mac cuando se compara
por nombre de campo (76 filas, 21 columnas); y contra servidores en vivo desde dentro de la
imagen, `mad refresh` extrajo 50 filas de MySQL 8.4 (`employees`, una obtención con sentencia
preparada) y 20 de SQL Server 2022 (`AdventureWorksLT2022`, sobre
freetds). Las suites en vivo están de acuerdo — `MADMySQLLiveTests` 44/44 y
`MADTdsClientLiveTests` 29/29 en la misma imagen — y la ejecución de ctest es 117
ejecutables, 1153 pruebas, 6 necesidades, todo en verde.

Hubo que resolver dos cosas para llegar allí, ambas registradas en `Linux/README.md`:

1. **La cuestión del documento (§5.1, §9 Fase D).** `MADocument` es un `UIDocument`,
   así que no puede venir. La elección del usuario (2026-10-16) fue una ruta de documento
   headless, no un shim de `UIDocument` en `Compat` ni una división de `MADocument`: la
   mitad de datos de un documento es ahora un protocolo, `MADDocumentDataProtocol`, que
   `MADocument` cumple (cada miembro ya era uno de sus accesores) y
   `MADHeadlessDocument` implementa sobre el mismo `MADDocumentStore` que usa el documento de la aplicación.
   La cadena de actualización — movida a `MAD` con el registro de controladores
   (`ROADMAP.md` §3.4, §5.1) — toma el protocolo, así que ambas plataformas ejecutan el mismo
   `MADOperationRefresh`; su única rama del lado del renderizado es `#if __APPLE__`, y
   `mad export` (PDF, Core Graphics) se queda en Apple, que es la puesta en escena de §5.2.
2. **El registro de controladores (§3, §5.1).** El constructor ya no importa MySQL
   y TDS: cada controlador se registra a sí mismo en `+load` y el constructor lo busca
   por tipo. En Linux los archivos de controlador se enlazan con archivo completo, porque el trabajo de un controlador
   se alcanza a través de *categorías* y una categoría es un envío de mensaje que el
   enlazador no puede ver — la CLI abortaba en MySQL hasta que eso se corrigió (§ la
   nota de archivo completo de compat en `Linux/README.md`).

Las divergencias de GNUstep que añadió la CLI: el enumerador de directorio
(`-enumeratorAtURL:…` produce URL con el directorio contenedor eliminado —
medido, y la lista de miembros de la CLI usa `-subpathsAtPath:` en su lugar), y el
orden de columnas de la lista SELECT, que era orden de conjunto y por lo tanto difería del de Apple
(mismos campos, mismas filas; anotado en `Linux/README.md`). **Resuelto el 2026-10-16**, con
la decisión de la forma de exportación JSON (§10.1 abajo): el orden se define como el alias de columna
en ambos constructores de SQL, así que el SQL generado, la caché de filas y cada exportación
concuerdan en ambas plataformas (docs/project/registers/BUGS.md, la entrada de la lista SELECT; las pruebas de orden en
`Linux/Tests/MADQuerySelectExpressionTests.m`).

**Estado de la Fase E (2026-10-16, primera mitad).** La costura de exportación es real y los
formatos de Foundation se ejecutan aquí. `MADReportExporting` + `MADReportExporterRegistry` tienen
la forma del registro de controladores (un protocolo de implementación, registro en `+load`, una
búsqueda por nombre), y `mad export` elige un formato a través de ellos, así que un formato nuevo es una
clase nueva (`MAD_CLI.md` §5.3, ROADMAP.md §5.2). `text`, `csv` y `json` son Foundation puro
y producen **salida idéntica byte a byte en Linux y en Apple** para el fixture London
— medido con `sha256sum` en la herramienta del Mac y la de la imagen (§ la sección CLI
de `Linux/README.md`; `Linux/Tests/MADReportExporterTests.m` fija los mismos
bytes con una suma de comprobación FNV-1a). La forma JSON está decidida (§10.1): `json` es el contrato
de datos — las columnas de la consulta en orden de alias, las filas, el SQL, el controlador — y
`json-report` es el mismo documento con las secciones del informe renderizado como miembro
extra, la elección del usuario el 2026-10-16: páginas, secciones en orden de dibujo, y el tipo,
marco y texto resuelto de cada línea, construido a partir del propio recorrido de páginas del renderizador con
nada dibujado — así que no puede desviarse de lo que muestra un PDF. Necesita la mitad de renderizado,
así que se registra en todas partes e informa por qué no puede ejecutarse aquí. Ese recorrido es
`MADPrintPageRenderer -buildPageAtIndex:context:inPageRect:`, que toma un contexto
anulable: la ruta PDF pasa el suyo y dibuja como antes, y json-report pasa NULL;
el primer protocolo de la mitad de renderizado, `MADDocumentRenderProtocol`, es lo que el formato pide
al documento. La mitad restante de la Fase E — el miembro de informe en Linux y
HTML/SVG — es el movimiento de la mitad de renderizado a Linux, que la decisión del renderizador del usuario
(HTML/SVG después, PDF al final, §10.2) pone en el paso de HTML. `pdf` sigue siendo el brazo
propio de la CLI; se convierte en un exportador con ese mismo paso.

---

**Estado de la Fase E (2026-10-16, segunda mitad: el escritor).** El escritor `.mad` se ejecuta en
Linux y ambas plataformas escriben los mismos bytes.  `MADArchiveManager.reproducible` es el
modo optativo que eligió el usuario (hora fija 2001-01-12T00:00:00Z, uid/gid 0, recorrido de miembros ordenado;
los guardados ordinarios conservan los metadatos del sistema de archivos), `MADHeadlessDocument` creció
`-writeToURL:reproducible:error:` (el guardado de la aplicación sin las partes de UIDocument), y
`mad write` es el verbo que llega a él en ambas plataformas.  Medido: el fixture London
escrito en el Mac y en la imagen es el mismo archivo de 16,261 bytes, sha256
`09815b24…` (la migración del almacén de la fase A de entrada de SQL cambió los bytes escritos; el
fixture mismo sigue siendo un almacén de versión 1); `Linux/Tests/MADArchiveManagerTests.m` fija
los bytes, la ida y vuelta y el modo.  Había dos defectos solo de Linux en el camino y están corregidos (`BUGS.md`, la
entrada de identidad de bytes): el recorrido que nunca terminaba, y `dirname(3)`/`basename(3)`
truncando la ruta de archivo del llamador en glibc.  Lo que cubre la comparación es el
contenedor: los miembros son los propios bytes del fixture.  Un escritor de Linux que *crea* un
almacén lo extiende a la capa del almacén.

**Estado de la Fase E (2026-10-16, tercera parte: la mitad de renderizado y HTML).** La mitad de renderizado
se movió a Linux, y se movió como una conformidad en lugar de un fork.  La respuesta del usuario
sobre la forma fue "un formateador, no dos rutas, y deberían renderizar
lo mismo", así que:

* `MADReportFormatter` toma `id <MADDocumentRenderProtocol>`; el protocolo creció los
  cuatro miembros que lee el formateador (`filename`, `storeContext` — antes pedía el
  `-managedObjectContext` de MADocument — `database`, `resetSectionLayoutManagers`)
  y hereda los protocolos de datos, caché y origen de datos de informe que el formateador asigna
  desde el documento.
* El recorrido de páginas se movió de `MADPrintPageRenderer` a `MADReportPageBuilder`, una
  clase Foundation simple: la misma transacción de lectura por página, las mismas referencias de
  elementos, la misma representación de una línea por elemento, con el dibujo ahora un
  block que pasa el llamador (el renderizador pasa uno que dibuja; los formatos no pasan ninguno).
  El constructor también posee la geometría del lado del renderizado (US Letter, el recorte de 1pt) y la
  secuencia de preparación (ordenar las filas, dimensionar el formateador, formatear), que se copiaban
  en el brazo PDF de la CLI y en json-report.
* `MADDocumentRenderDataSource` es la única implementación de las lecturas de la mitad de renderizado —
  `MADPrintPageRendererDataSourceProtocol` y `MADReportFormatterDataSource` sobre un
  documento — y tanto `MADocument` como `MADHeadlessDocument` responden preguntándole.  Los
  cuerpos son de MADocument, movidos; las páginas de la aplicación leen exactamente lo que leían antes.
* `MADHeadlessDocument` cumple `MADDocumentRenderProtocol`, así que un documento sin
  ventana ahora formatea y recorre.  La rama de renderizado de `MADOperationRefreshInitialize` se basa
  en el protocolo en lugar de en `[doc isKindOfClass: [MADocument class]]`.
* La familia de elementos compila headless: los inicializadores de `MADPrintPageElement` son
  Foundation (el texto se resuelve allí), y solo los cuerpos `-drawInRect:` son
  `#if __APPLE__`.  Fuera de Apple la imagen del elemento de imagen son los bytes PNG del almacén
  (`MADElementImage` es `NSData`), y `-renderedImageData` los entrega a la representación de línea
  que leen los exportadores.  `MADElementStylizedText` sigue siendo de Apple — es
  dibujo, no diseño.

**La paginación no necesita un motor de texto**, medido en lugar de asumido: la altura de presentación de una sección
viene de `MADSectionLayout` (rect almacenado + margen + relleno + borde), que
está en la compilación de Linux y lo ha estado desde la Fase C, así que los saltos de página son los mismos
en todas partes.  Las métricas de texto entran solo cuando un elemento se *dibuja*, y el renderizador
dibuja con `NSLineBreakByTruncatingTail` — una línea, recortada — que CSS deletrea
`white-space: pre; overflow: hidden; text-overflow: ellipsis`.  Nada se ajusta, así que no
hay modelo de ajuste que portar; no se añadió ningún motor de fuentes.

**`mad export --format json-report` se ejecuta aquí**, en el mismo recorrido, y los marcos que
informa son ahora coordenadas de *página* (el marco del elemento desplazado por su sección), que
es lo que necesita un renderizador o un navegador.

**Dos formatos nuevos, ambos en ambas plataformas** (el usuario eligió ambos): `html` es el
facsímil — una caja de página CSS por página recorrida, cada elemento posicionado de forma absoluta en
su marco con su texto resuelto y su fuente, tamaño, rasgos y alineación almacenados; un
navegador lo imprime en las mismas páginas que tiene el PDF.  `html-flow` es el mismo informe
refluible — `<section>`s, un `<table>` por sección, un `<td>` por elemento, el mobiliario de página
emitido una vez; una vista de lectura, mientras `--format json` sigue siendo el contrato de datos.
Ambos son un archivo UTF-8 con un `<style>` incrustado y sin script; el CSS del facsímil
son las 20 líneas anteriores más una regla de posicionamiento, y los estilos del archivo de flujo son una
tabla de clases generada (nueve clases para el fixture London).

**`pdf` está en la costura**: `MADReportExporterPDF` se registra en todas partes.  En Apple su
cuerpo es Core Graphics + `MADPrintPageRenderer`, sin cambios; fuera de Apple entrega las mismas
páginas recorridas a `MADReportExporterPDFCairo`, que las dibuja en una superficie PDF Cairo
con glifos FreeType de caras Liberation incluidas (docs/developers/build/pdf.md).  La
CLI no tiene brazos locales restantes.  El movimiento de Apple fue neutral en bytes: la exportación determinista
de la muestra London es el mismo PDF de 43,177 bytes y 5 páginas antes y después
(`sha256 3eb2f1c4…` en ambos), medido compilando la CLI del commit anterior y
comparando.  El escritor headless apunta a paridad estructural, no a paridad de bytes.

**Lo que dice la comparación multiplataforma.** El texto de cada línea, cada marco,
cada fuente, el recuento de páginas y la estructura de archivo son idénticos en Apple y Linux para
el fixture London, y también lo son los bytes: `html`, `html-flow` y `json-report` tienen el
mismo sha256 en ambas plataformas (`Linux/README.md` tiene los digests).  Llegar allí tomó
un hallazgo y su corrección: la moneda renderizada solía depender de la máquina.  El informe
ahora toma su configuración regional *y* su recuento de decimales del formato numérico del documento (el
almacén conserva ambos; un documento que no lo dice recurre a `en_US`, no a la
configuración regional de la máquina), la fábrica de elementos registra la configuración regional de diseño en los elementos nuevos, y
el símbolo de moneda se escribe explícitamente con el signo del yen normalizado (GNUstep lo deletrea
en ancho completo).  Una comparación de 60 casos en seis configuraciones regionales es idéntica byte a byte; la entrada completa
está en el archivo de `BUGS.md`.

**Estado de la Fase F (2026-10-17, en parte).** La CLI es un entregable como imagen de runtime,
no un binario en un árbol de compilación. `Linux/Dockerfile` creció una etapa `runtime`
sobre `ubuntu:24.04` que lleva `/usr/local/bin/mad` (la regla de instalación de CMake), los
objetos compartidos que enlaza la CLI (GNUstep Base, libobjc2, libdispatch,
libBlocksRuntime, mysqlclient), los directorios de runtime de GNUstep, los archivos
de mensajes y juegos de caracteres de mysqlclient, y `chinook.sqlite3` en la ruta de soporte de la aplicación; deja
atrás el compilador, fuentes, pruebas, encabezados y archivos estáticos. Es
283 MB en disco (66.5 MB comprimidos) frente a la imagen de compilación de 6.65 GB.
`./Linux/build.sh --runtime` la compila, y `--verify` ejecuta
`Linux/verify-cli.sh` dentro de ella: 30 comprobaciones — los seis verbos, el digest fijado de cada formato
sin conexión, la negativa de `pdf`, los bytes del escritor reproducible, los
códigos de salida, y la propia forma de la imagen (sin clang, cmake, git ni árbol de compilación).
Verde el 2026-10-17; `--live` añade las actualizaciones de MySQL y TDS (32/32). La suite
también ganó un `RESOURCE_LOCK` entre los dos binarios de prueba que comparten el
fixture London y la base de datos de muestra — el paralelismo de ctest había hecho que ese par
fallara de forma intermitente (35 ejecuciones paralelas verdes consecutivas después del bloqueo).

Las decisiones del usuario el mismo día: **sin CI** (el port de Linux es una prueba de
concepto y una prueba repetible, no una versión; `./Linux/build.sh --verify` es
la comprobación) y **sin publicación** (nada se extrae de un registro, así que la
cuestión de GPL se queda donde la dejó §10.3). El controlador Linux de Compressor es la
única parte de la Fase F no hecha, y no es necesaria para la CLI: la imagen compila
las bibliotecas C de forma nativa.

## 10. Decisiones para el usuario

1. **La forma de la exportación JSON** (`MAD_CLI.md` §8.3, `MAD_FUTURE.md` §10.5) — este es
   el contrato de Python; decídelo primero, porque todo en §2 depende de él.
   **Decidido 2026-10-16: ambos, la mitad de informe como su propio formato.** `--format json`
   es el contrato de datos — un sobre (id de formato, documento/controlador, el SQL, el recuento
   de filas), `columns` (clave, nombre, tabla, tipo), y `rows` como un objeto por fila con
   valores con tipo JSON — y `--format json-report` es ese documento más un miembro `report`
   (las secciones renderizadas). Con él, el orden de la lista SELECT se define como el
   alias de columna, ordenado, para que el SQL generado, la caché de filas y cada exportación concuerden en
   ambas plataformas (docs/project/registers/BUGS.md, la entrada de la lista SELECT — antes, orden de conjunto). La mitad de datos
   está construida (`MADReportExporterJSON`, ambas plataformas); el miembro de informe espera
   a la mitad de renderizado.
2. **Puesta en escena del renderizador** — ¿HTML/SVG primero, PDF al final, o workers de PDF del lado de macOS?
   **Decidido 2026-10-16: HTML/SVG después, PDF al final.** Sin renderizador PDF en Linux y sin
   workers del lado de macOS: el paso de HTML es también donde la mitad de renderizado
   (`MADReportFormatter`) se mueve a Linux, que `json-report` y las pruebas también quieren.
   `pdf` sigue siendo el brazo del lado de Apple de la CLI hasta entonces.
   **Hecho 2026-10-16 (el paso de HTML).** La mitad de renderizado está en Linux y `mad export`
   no tiene brazos locales: `pdf` es un exportador registrado cuyo cuerpo es de Apple, y
   dice por qué fuera de Apple.  La decisión adicional del usuario el mismo día: el escritor PDF de Linux
   es el *siguiente* paso, no parte de este, porque las cajas de página del facsímil HTML son
   la geometría que un escritor de Linux tiene que reproducir y convertir en su prueba.  La forma del escritor
   se registra aquí para ese paso: **Cairo (dibujo, superficie PDF) + Pango (diseño,
   ajuste) + FreeType/HarfBuzz**, la pila que usan GTK/WebKit/Firefox y lo más cercano que Linux tiene a
   Core Graphics + Core Text — API C llamadas desde Objective-C como ya lo son
   freetds y sqlite3, así que no se necesita ningún contenedor Impl.  Licencias: Cairo
   LGPL-2.1/MPL-1.1 dual, Pango LGPL-2.1, HarfBuzz MIT, FreeType FTL/GPLv2-dual; el
   proyecto ya envía LGPL (FreeTDS, `LICENSE_COMPLIANCE_PLAN.md` §4) y la imagen de Linux
   es una compilación de servidor, así que es una clase conocida de obligación.  `libharu` es la
   alternativa permisiva pero no tiene motor de diseño; Skia es la más cercana en capacidad
   pero una compilación C++ pesada.  **No alcanzable: PDF idénticos byte a byte entre plataformas** —
   el escritor de Core Graphics no se puede reproducir — así que el objetivo son las mismas páginas, cajas,
   texto y fuentes, con sustitutas métricamente compatibles para las fuentes de Apple
   (la familia predeterminada de `MADFont` es Helvetica Neue, que Linux no tiene).
   **Hecho 2026-11-20 (el cierre de PDF).** La pila es Cairo (superficie PDF) +
   FreeType, sin Pango: el recorrido entrega a cada línea su marco, texto, fuente, tamaño,
   rasgos y alineación, así que no hay diseño que hacer -- solo avances de glifos y la
   tabla `kern` propia de la cara, que FreeType suministra.  Cairo 1.18.6 (MPL-1.1) y
   pixman 0.46.4 (MIT) se compilan estáticamente; las caras Liberation (SIL OFL 1.1) son
   las sustitutas de las fuentes de Apple.  `MAD_PDF_LINUX.md` registra lo que aterrizó, la
   política de mapeo de fuentes y el residual medido.  El objetivo sigue siendo estructural:
   los bytes de Core Graphics no son reproducibles.
3. **Momento de mysqlclient → MariaDB Connector/C** — el bloqueador de GPL condiciona cualquier binario
   enviado; el reemplazo ya está nombrado en `LICENSE_COMPLIANCE_PLAN.md`.
4. **Política de toolchain** — clang/libobjc2/GNUstep compilados desde fuentes (necesarios para ARC) es un
   compromiso de mantenimiento; acéptalo o quédate en hosts macOS.
5. **El disparador de la reescritura** — la fase D de §9 es el punto de control medible; hasta que
   falle, la recomendación se mantiene: un motor Objective-C, llamado desde Python
   a través de la frontera de la CLI.
6. **La línea base de compilación** — Docker sobre una base Debian estable o Ubuntu LTS, compilada en
   Linux en lugar de compilada de forma cruzada desde macOS (§8.1). La elección fija el piso de glibc
   admitido, así que hazla una vez y deliberadamente.
