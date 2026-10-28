# Static Libraries: the Compressor Build System

This document describes the third-party static libraries the application links, and
the build system that produces them — as built, not as planned. The pre-rework
state (two overlapping script generations, committed binaries, per-platform
directories) is condensed in the appendix at the end.

**Standing constraint:** nothing in `Compressor/library` that predates this rework
is deleted until the new system has built every combination and the app builds and
its tests pass against the new artifacts. Pruning happens last, one commit per
item.

---

## 1. What the system is

One declarative matrix, one driver, one recipe per library, one manifest per build.

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

### The matrix (`matrix.conf`)

Line-oriented and bash-parseable:

```
lib        version  sha256  url   ios-archs  sim-archs  mac-archs  min-ios  min-mac  deps
```

`sha256` is the hash of the downloaded archive — pinned for every library. `deps`
names other matrix rows the driver builds first. Nothing about a library's build
lives anywhere else: per-library flags live in the recipe and are echoed into the
manifest, so "which flags built this?" is answerable from the manifest alone.

### The driver (`build.sh`)

* `build.sh <lib>…` — ensure each library (dependencies first); a fast no-op when
  the manifest matches the matrix row and every slice exists.
* `--all` — every library in the matrix.
* `--rebuild` — force the **named** libraries; their dependencies keep the normal
  fresh check, so iterating on one recipe does not rebuild its chain.
* `--verify` — check artifacts against the matrix + manifests: version and source
  hash, slice architectures, header presence, every library's embedded version
  string, plus the per-library checks in `lib/verify/`.
* `--platforms ios,simulator,macosx` — limit which platforms are built (default:
  all three).

Builds are serialized by a lock on `build/.ensure.lock.d` (a `mkdir` lock with
stale-owner recovery — `flock` is not on macOS), because several Xcode targets can
run ensure phases in parallel during a workspace build.

Downloads land in the content-addressed `media/` cache, so a pinned source is
downloaded once and verified by hash on every use. A first build needs network
access; the failure message says so and names the tarball.

### Recipes

Each recipe extracts the pinned source into `build/<lib>/source`, builds per arch,
lipos per platform, and calls `finish_library`, which creates the xcframework,
installs the canonical include dir and writes the manifest. One library per
xcframework slice identifier is a hard constraint of `-create-xcframework`, so
multi-component libraries merge: openssl merges crypto+ssl into `libopenssl.a`,
freetds merges ct+sybdb+tds into `libfreetds.a`, and mariadb is a single
`libmariadbclient.a` (Connector/C's `libmariadb` target is hardcoded shared on
UNIX, so the recipe builds the `mariadbclient` static target). Slices are inferred from the libraries'
Mach-O load commands (the per-platform `-m*-version-min` flags), which is why no
`-platform` hints are needed.

Notes worth knowing when touching a recipe:

* **sqlite3** generates the amalgamation on the host, then compiles it per slice
  with the option list parsed from `sqlite3.xcconfig` — the recipe is the *only*
  consumer of that list (the MADSqlite3 target used to be the second, which is
  hazard H7 in `BUGS.md`). The options pin the `.maddb` cache format (page size
  8192, `DQS=0`, FTS5, STAT4, …); treat changes as format decisions.
* **mariadb** builds the `mariadbclient` static target per slice with
  `WITH_SSL=OPENSSL` against the per-platform openssl install and
  `WITH_EXTERNAL_ZLIB=ON` against the zlib install, the `caching_sha2_password`
  and `sha256_password` auth plugins compiled in statically and every other
  plugin disabled (no plugin `.so` ships). The DEFAULT install layout nests
  headers under `include/mariadb`; the recipe flattens them so `mysql.h`
  resolves from the canonical include root, and its cross preset answers the
  one run-based cmake probe (the LibreSSL check) with the OpenSSL outcome.
* **zint** is stock 2.16.0 built by `lib/recipes/zint.sh` with cmake
  (`ZINT_SHARED=OFF`, `ZINT_STATIC=ON`, `ZINT_FRONTEND=OFF`, `ZINT_USE_PNG=ON`,
  linked against the recipe's libpng and zlib) into
  `library/zint.xcframework`.  The 2.4.2-era direct compile and its local
  patch (`patches/zint-2.4.2-mad.patch`) are retired: `ZBarcode_Encode_and_Buffer`,
  which the patch backported, is upstream API in 2.16, and the wrapper's
  `BARCODE_*` names survive as aliases.
* **freetds** patches the *installed* headers, not the sources: `typedef int BOOL;`
  is commented out of `sybdb.h` after each install, because Objective-C already
  typedefs `BOOL` — but the library itself must keep the typedef, since dblib's C
  sources use it.
* **postgres** builds only the client interfaces (`src/common`, `src/port`,
  `src/interfaces/libpq`, `src/bin/pg_config`, and `src/include`) against the
  per-platform `openssl` install (`--with-ssl=openssl` and the explicit module
   flags off), then merges `libpq.a`, `libpgcommon.a`, and `libpgport.a` into a
  single `libpostgres.a` for `postgres.xcframework`.

### The manifest (`library/manifests/<lib>.json`)

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

`headers` records which platform's generated headers the canonical include dir
took (freetds generates `tds_sysdep_public.h` per platform; the ios copy is the
canonical one, as the legacy layout chose).

---

## 2. How Xcode consumes the libraries

Every consuming target links one or more xcframeworks by file reference, names the
canonical `Compressor/library/<lib>/include` in its header search paths, and runs
an **Ensure Libraries** shell phase first in its build phases:

```sh
set -euo pipefail
"${SRCROOT}/../Compressor/build.sh" --platforms ios,simulator <lib>
```

The phase no-ops in milliseconds when the manifest is fresh and builds only what
is missing otherwise; `ENABLE_USER_SCRIPT_SANDBOXING = NO` is pinned on every
target that has one. The platforms are pinned to `ios,simulator` because no
target builds for macOS yet — the matrix's macOS slices are ready for when the
UIKit decoupling lands (see `ROADMAP.md` Track 2).

| Target | Links | Ensure phase |
|---|---|---|
| MADSqlite3 | `sqlite3.xcframework` | `sqlite3` |
| MAD | `libarchive.xcframework`, `bzip2.xcframework`, `zlib.xcframework` | `libarchive` |
| MADMySQL | `mariadb.xcframework`, `openssl.xcframework`, `zlib.xcframework` | `mariadb` |
| MADPostgres | `postgres.xcframework`, `openssl.xcframework` | `postgres` |
| MADTds | `freetds.xcframework`, `openssl.xcframework` | `freetds` |
| MADTdsClient | nothing from Compressor (tds symbols come via MADTds) | — |
| MADBarcodes | `libpng.xcframework`, `zlib.xcframework`, `zint.xcframework` | `zint` |
| MAD Designer app | `openssl.xcframework` | `openssl` |

Header facts worth remembering: static-library xcframeworks do **not** reliably
expose their headers, so every consumer names the canonical include dir
explicitly (headers are also bundled into the xcframework for archival
completeness). `zint.h`, `sqlite3.h` and `libpq-fe.h` (with its companion headers)
are Public framework headers whose file references point into the canonical
include dirs, because public MAD headers import `<MADBarcodes/zint.h>`,
`MADSqlite3` exports `sqlite3.h`, and `MADPostgres` exports `libpq-fe.h`.

The MAD Viewer target's legacy `LIBRARY_SEARCH_PATHS` list and Scrimpter (outside
the workspace) are deliberately untouched: the viewer's link failure is a product
decision (see `BUGS.md`), not build wiring.

---

## 3. First run, day-to-day, and version bumps

**First run on a fresh checkout** (or after wiping `Compressor/library/`): build
the libraries once, before or during the first Xcode build:

```
Compressor/build.sh --all --platforms ios,simulator
```

Needs network access for the downloads and 30–90 minutes on first build,
most of it the larger source tarballs.
After that, Xcode's ensure phases are no-ops and a normal build proceeds.

**Verifying the artifacts:**

```
Compressor/build.sh --verify --all --platforms ios,simulator
```

**Bumping a library:** edit its `matrix.conf` row (version, URL, sha256 of the
new archive), then `Compressor/build.sh --rebuild <lib>` and run the consuming
framework's test suite plus `--verify`. One library per commit. If the new
version adds a cmake run-probe, the mariadb preset fails loudly and names it
— answer it explicitly, never by guessing.

**The zint/freetds/mariadb/postgres recipes carry per-version knowledge** (patches,
installed-header edits, probe answers, plugin type names, install layout,
client-only subtree lists). When a version bumps, those are the places to re-check.

---

## 4. Verification commands

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

## Appendix: the pre-rework state (for reference)

Before 2026-10-04 the libraries were built by two overlapping generations of
tooling — per-library `Compressor/build_*.sh` scripts and a 1,293-line
`compressor.sh` driver (non-runnable: undefined variables caused 404 downloads
under `set -e`; its declared versions were years stale) — and the results were
**committed**: 99 `.a` files (~350 MB), all headers, and the 9.2 MB `sqlite3.c`
amalgamation under `Compressor/library/`, plus 53 vendored Zint source files
inside MADBarcodes. Xcode consumed them purely by file reference with
SDK-conditional search paths, which is why macOS could never be wired
(`PBXFileReference.path` is not SDK-conditional — the entry in `BUGS.md` is
closed by the xcframework rewiring). The old scripts and the committed trees are
removed in the prune phase, only after the new system builds every combination
and the app builds and its tests pass against the new artifacts.

The baseline versions the matrix started from, and their target updates, are
tracked in `TASKS.md` §6.
