---
layout: default
title: "La compilación de bibliotecas estáticas de Compressor"
description: "Las bibliotecas C de terceros, cómo se compilan y cómo llega Xcode a ellas."
lang: es-419
---

# Bibliotecas estáticas: el sistema de compilación Compressor

Esta página describe las bibliotecas C de terceros que enlaza la aplicación y el sistema de compilación `Compressor` que las produce.

*Escrito en la fecha original; los hechos del estado actual se conciliaron el 2026-11-22.*

Este documento describe las bibliotecas estáticas de terceros que enlaza la aplicación, y
el sistema de compilación que las produce — tal como se construyó, no como se planeó. El estado
anterior a la reforma (dos generaciones de scripts superpuestas, binarios versionados, directorios
por plataforma) se condensa en el apéndice del final.

**Restricción permanente:** nada en `Compressor/library` que sea anterior a esta reforma
se elimina hasta que el nuevo sistema haya compilado cada combinación y la aplicación compile y
sus pruebas pasen contra los nuevos artefactos. La poda ocurre al final, un commit por
elemento.

---

## 1. Qué es el sistema

Una matriz declarativa, un controlador, una receta por biblioteca, un manifiesto por compilación.

```
Compressor/
  matrix.conf                  # the single place version/source/platforms/deps live
  build.sh                     # the driver: ensure (default) / --all / --rebuild /
                               #   --verify / --platforms ios,simulator,macosx
  sqlite3.xcconfig             # the single place SQLite compile options live
  lib/common.sh                # download cache, per-arch compile helpers, lipo,
                               #   xcframework creation, manifest writer, lock
  lib/recipes/<lib>.sh         # one recipe per library (configure/cmake + install)
  lib/verify/<lib>.sh          # optional per-library artifact checks
  patches/                     # local modifications to upstream sources, captured
                               #   as diffs (none current; zint's 2.4.2 patch retired)
  media/<sha256>-<archive>     # content-addressed download cache (gitignored)
  src/  build/                 # extracted sources and build trees (gitignored)
  library/
    <lib>.xcframework/         # the single artifact Xcode links (gitignored)
    <lib>/include/             # the canonical header dir consumers name (gitignored)
    manifests/<lib>.json       # version, source hash, flags, slice SHAs (gitignored)
```

### La matriz (`matrix.conf`)

Orientada a líneas y analizable por bash:

```
lib        version  sha256  url   ios-archs  sim-archs  mac-archs  min-ios  min-mac  deps
```

`sha256` es el hash del archivo descargado — fijado para cada biblioteca. `deps`
nombra otras filas de la matriz que el controlador compila primero. Nada sobre la compilación de una biblioteca
vive en ningún otro lado: las opciones por biblioteca viven en la receta y se copian al
manifiesto, así que "¿qué opciones construyeron esto?" se responde solo desde el manifiesto.

### El controlador (`build.sh`)

* `build.sh <lib>…` — asegurar cada biblioteca (dependencias primero); una operación nula rápida cuando
  el manifiesto coincide con la fila de la matriz y cada slice existe.
* `--all` — cada biblioteca de la matriz.
* `--rebuild` — forzar las bibliotecas **nombradas**; sus dependencias mantienen la comprobación
  fresca normal, así que iterar sobre una receta no reconstruye su cadena.
* `--verify` — comprobar los artefactos contra la matriz + manifiestos: versión y hash de origen,
  arquitecturas de slice, presencia de encabezados, la cadena de versión incrustada de cada biblioteca,
  más las comprobaciones por biblioteca en `lib/verify/`.
* `--platforms ios,simulator,macosx` — limitar qué plataformas se compilan (predeterminado:
  las tres).

Las compilaciones se serializan con un bloqueo en `build/.ensure.lock.d` (un bloqueo `mkdir` con
recuperación de propietario obsoleto — `flock` no está en macOS), porque varios objetivos de Xcode pueden
ejecutar fases de aseguramiento en paralelo durante una compilación de espacio de trabajo.

Las descargas aterrizan en la caché `media/` direccionada por contenido, así que una fuente fijada se
descarga una vez y se verifica por hash en cada uso. Una primera compilación necesita acceso a la red; el
mensaje de fallo lo dice y nombra el tarball.

### Recetas

Cada receta extrae la fuente fijada en `build/<lib>/source`, compila por arquitectura,
lipos por plataforma, y llama a `finish_library`, que crea el xcframework,
instala el directorio de inclusión canónico y escribe el manifiesto. Una biblioteca por
identificador de slice de xcframework es una restricción dura de `-create-xcframework`, así que
las bibliotecas multicomponente se fusionan: openssl fusiona crypto+ssl en `libopenssl.a`,
freetds fusiona ct+sybdb+tds en `libfreetds.a`, y mariadb es un único
`libmariadbclient.a` (el objetivo `libmariadb` de Connector/C está codificado como compartido en
UNIX, así que la receta compila el objetivo estático `mariadbclient`). Los slices se infieren de los comandos
de carga Mach-O de las bibliotecas (las opciones `-m*-version-min` por plataforma), que es por lo que no se necesitan
pistas de `-platform`.

Notas que vale la pena conocer al tocar una receta:

* **sqlite3** genera la fusión en el host, luego la compila por slice
  con la lista de opciones analizada desde `sqlite3.xcconfig` — la receta es el *único*
  consumidor de esa lista (el objetivo MADSqlite3 solía ser el segundo, que es el
  peligro H7 en `BUGS.md`). Las opciones fijan el formato de caché `.maddb` (tamaño de página
  8192, `DQS=0`, FTS5, STAT4, …); trata los cambios como decisiones de formato.
* **mariadb** compila el objetivo estático `mariadbclient` por slice con
  `WITH_SSL=OPENSSL` contra la instalación de openssl por plataforma y
  `WITH_EXTERNAL_ZLIB=ON` contra la instalación de zlib, los plugins de autenticación `caching_sha2_password`
  y `sha256_password` compilados estáticamente y cada otro
  plugin deshabilitado (no se envía ningún `.so` de plugin). El diseño de instalación DEFAULT anida
  los encabezados bajo `include/mariadb`; la receta los aplana para que `mysql.h`
  se resuelva desde la raíz de inclusión canónica, y su preset cruzado responde la
  única sonda de cmake basada en ejecución (la comprobación de LibreSSL) con el resultado de OpenSSL.
* **zint** es la versión 2.16.0 estándar compilada por `lib/recipes/zint.sh` con cmake
  (`ZINT_SHARED=OFF`, `ZINT_STATIC=ON`, `ZINT_FRONTEND=OFF`, `ZINT_USE_PNG=ON`,
  enlazada contra el libpng y zlib de la receta) en
  `library/zint.xcframework`.  La compilación directa de la era 2.4.2 y su parche local
  (`patches/zint-2.4.2-mad.patch`) están retirados: `ZBarcode_Encode_and_Buffer`,
  que el parche retroportaba, es API upstream en 2.16, y los nombres `BARCODE_*` del
  contenedor sobreviven como alias.
* **freetds** parchea los encabezados *instalados*, no las fuentes: `typedef int BOOL;`
  se comenta en `sybdb.h` después de cada instalación, porque Objective-C ya
  define `BOOL` con typedef — pero la biblioteca misma debe conservar el typedef, ya que las fuentes C
  de dblib lo usan.
* **postgres** compila solo las interfaces de cliente (`src/common`, `src/port`,
  `src/interfaces/libpq`, `src/bin/pg_config` y `src/include`) contra la
  instalación de `openssl` por plataforma (`--with-ssl=openssl` y las opciones de módulo
  explícitas desactivadas), luego fusiona `libpq.a`, `libpgcommon.a` y `libpgport.a` en un
  único `libpostgres.a` para `postgres.xcframework`.

### El manifiesto (`library/manifests/<lib>.json`)

```json
{
  "library": "openssl", "version": "3.5.0",
  "source": { "url": "…", "sha256": "…" },
  "toolchain": { "xcode": "…", "clang": "…" },
  "headers": "ios",
  "flags": "configure: no-shared no-asm no-async; opt: -O3",
  "built": "…",
  "slices": { "ios": { "archs": "…", "sha256": "…" }, … }
}
```

`headers` registra de qué plataforma tomó el directorio de inclusión canónico los encabezados generados
(freetds genera `tds_sysdep_public.h` por plataforma; la copia de ios es la
canónica, como eligió el diseño heredado).

---

## 2. Cómo consume Xcode las bibliotecas

Cada objetivo consumidor enlaza uno o más xcframeworks por referencia de archivo, nombra el
`Compressor/library/<lib>/include` canónico en sus rutas de búsqueda de encabezados, y ejecuta
una fase de shell **Ensure Libraries** primero en sus fases de compilación:

```sh
set -euo pipefail
"${SRCROOT}/../Compressor/build.sh" --platforms ios,simulator <lib>
```

La fase es nula en milisegundos cuando el manifiesto está fresco y compila solo lo que
falta en caso contrario; `ENABLE_USER_SCRIPT_SANDBOXING = NO` está fijado en cada
objetivo que tiene una. Las plataformas están fijadas a `ios,simulator` porque ningún
objetivo compila para macOS todavía — los slices de macOS de la matriz están listos para cuando aterrice
el desacoplamiento de UIKit (véase `ROADMAP.md`, Pista 2).

| Objetivo | Enlaza | Fase Ensure |
|---|---|---|
| MADSqlite3 | `sqlite3.xcframework` | `sqlite3` |
| MAD | `libarchive.xcframework`, `bzip2.xcframework`, `zlib.xcframework` | `libarchive` |
| MADMySQL | `mariadb.xcframework`, `openssl.xcframework`, `zlib.xcframework` | `mariadb` |
| MADPostgres | `postgres.xcframework`, `openssl.xcframework` | `postgres` |
| MADTds | `freetds.xcframework`, `openssl.xcframework` | `freetds` |
| MADTdsClient | nada de Compressor (los símbolos tds llegan vía MADTds) | — |
| MADBarcodes | `libpng.xcframework`, `zlib.xcframework`, `zint.xcframework` | `zint` |
| Aplicación MAD Designer | `openssl.xcframework` | `openssl` |

Hechos de encabezados que vale la pena recordar: los xcframeworks de bibliotecas estáticas **no** exponen
de forma fiable sus encabezados, así que cada consumidor nombra el directorio de inclusión canónico
explícitamente (los encabezados también se empaquetan en el xcframework para completitud
de archivo). `zint.h`, `sqlite3.h` y `libpq-fe.h` (con sus encabezados complementarios)
son encabezados públicos de framework cuyas referencias de archivo apuntan a los directorios
de inclusión canónicos, porque los encabezados públicos de MAD importan `<MADBarcodes/zint.h>`,
`MADSqlite3` exporta `sqlite3.h`, y `MADPostgres` exporta `libpq-fe.h`.

La lista heredada de `LIBRARY_SEARCH_PATHS` del objetivo MAD Viewer y Scrimpter (fuera
del espacio de trabajo) se dejan deliberadamente intactos: el fallo de enlace del visor es una decisión
de producto (véase `BUGS.md`), no cableado de compilación.

---

## 3. Primera ejecución, día a día y actualizaciones de versión

**Primera ejecución en un checkout limpio** (o después de borrar `Compressor/library/`): compila
las bibliotecas una vez, antes o durante la primera compilación de Xcode:

```
Compressor/build.sh --all --platforms ios,simulator
```

Necesita acceso a la red para las descargas y 30–90 minutos en la primera compilación,
la mayor parte en los tarballs de fuentes más grandes.
Después de eso, las fases Ensure de Xcode son nulas y una compilación normal procede.

**Verificar los artefactos:**

```
Compressor/build.sh --verify --all --platforms ios,simulator
```

**Actualizar una biblioteca:** edita su fila de `matrix.conf` (versión, URL, sha256 del
nuevo archivo), luego `Compressor/build.sh --rebuild <lib>` y ejecuta la suite de pruebas del
framework consumidor más `--verify`. Una biblioteca por commit. Si la nueva
versión añade una sonda de ejecución de cmake, el preset de mariadb falla ruidosamente y la nombra
— respóndela explícitamente, nunca adivinando.

**Las recetas de zint/freetds/mariadb/postgres llevan conocimiento por versión** (parches,
ediciones de encabezados instalados, respuestas a sondas, nombres de tipos de plugin, diseño de instalación,
listas de subárboles solo de cliente). Cuando una versión sube, esos son los lugares que hay que reexaminar.

---

## 4. Comandos de verificación

```sh
# slice inventory
for f in Compressor/library/*.xcframework/*/lib*.a; do lipo -archs "$f"; done

# version strings (each library embeds its matrix version)
strings Compressor/library/openssl.xcframework/*/libopenssl.a | grep -m1 "OpenSSL 3.5.0"

# sqlite correctness, against the BUILT framework (the H7 gate)
nm MADSqlite3.framework/MADSqlite3 | grep -c sqlite3Fts5Init     # present
strings MADSqlite3.framework/MADSqlite3 | grep -x 'DEFAULT_PAGE_SIZE=8192\|DQS=0'

# wiring cleanliness -- expect "" bases plus the MAD Viewer legacy list only
grep -rn 'LIBRARY_SEARCH_PATHS' --include='*.pbxproj' .

# the fresh-clone simulation (proves portability + on-demand building)
git archive HEAD | tar -x -C /tmp/fresh
cd /tmp/fresh
Compressor/build.sh --all --platforms ios,simulator     # bootstrap path (a)
xcodebuild build -workspace Reports.xcworkspace -scheme "MAD Designer" -destination …
Compressor/build.sh --verify --all --platforms ios,simulator
# path (b): wipe library/ xcframeworks and build in Xcode only -- the ensure
# phases rebuild everything
```

---

## Apéndice: el estado anterior a la reforma (para referencia)

Antes del 2026-10-04 las bibliotecas se compilaban con dos generaciones superpuestas de
herramientas — scripts `Compressor/build_*.sh` por biblioteca y un controlador `compressor.sh`
de 1,293 líneas (no ejecutable: variables indefinidas causaban descargas 404
bajo `set -e`; sus versiones declaradas tenían años de antigüedad) — y los resultados estaban
**versionados**: 99 archivos `.a` (~350 MB), todos los encabezados, y la fusión `sqlite3.c`
de 9.2 MB bajo `Compressor/library/`, más 53 archivos fuente de Zint vendidos
dentro de MADBarcodes. Xcode los consumía puramente por referencia de archivo con
rutas de búsqueda condicionales por SDK, que es por lo que macOS nunca pudo cablearse
(`PBXFileReference.path` no es condicional por SDK — la entrada en `BUGS.md` se
cierra con el recableado de xcframework). Los scripts antiguos y los árboles versionados se
eliminan en la fase de poda, solo después de que el nuevo sistema compile cada combinación
y la aplicación compile y sus pruebas pasen contra los nuevos artefactos.

Las versiones de línea base con las que empezó la matriz, y sus actualizaciones objetivo, se
rastrean en `TASKS.md` §6.
