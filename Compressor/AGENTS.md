# Compressor Agent Overview

## Project Description

The `Compressor` project builds the third-party static libraries the _MAD Designer_
application links (SQLite, zlib, OpenSSL, bzip2, libpng, libarchive, FreeTDS,
mysqlclient, zint). Nothing third-party is committed: sources are downloaded on
demand and built by recipes, and the artifacts are xcframeworks plus canonical
include dirs, all gitignored.

## Core Components

*   **`matrix.conf`** -- the single place a library's version, source URL, sha256,
    platforms, architectures, deployment targets and dependencies are written
    down. One row per library.
*   **`build.sh`** -- the driver. `build.sh <lib>…` ensures each library
    (dependencies first; a fast no-op when the manifest is fresh);
    `--all`; `--rebuild` forces only the named libraries; `--verify` checks
    artifacts against the matrix and manifests (version, source hash, slice
    architectures, embedded version strings, per-library checks in
    `lib/verify/`); `--platforms ios,simulator,macosx` limits the platforms.
*   **`lib/common.sh`** -- shared helpers: the content-addressed download cache,
    per-arch compile helpers, lipo, xcframework creation (preserving slices for
    platforms a run does not build), manifest writing, and the build lock.
*   **`lib/recipes/<lib>.sh`** -- one recipe per library. A recipe downloads the
    pinned source, builds per arch, lipos per platform, and calls
    `finish_library`, which creates `library/<lib>.xcframework`, installs
    `library/<lib>/include` and writes `library/manifests/<lib>.json`.
*   **`sqlite3.xcconfig`** -- the single place SQLite compile options live; the
    sqlite3 recipe is its only consumer. The options pin the `.maddb` cache
    format -- treat changes as format decisions.
*   **`lib/verify/<lib>.sh`** -- optional per-library artifact checks run by
    `--verify` (sqlite3's compile-option and FTS5 gate lives here; zint's
    `SKIP_VERSION_STRING` override).

## Usage Guidelines

First run on a fresh checkout (network required): `build.sh --all --platforms
ios,simulator`. Xcode builds then no-op through their "Ensure Libraries"
phases; see `LIBRARIES.md` and `DEVELOPER.md` for the day-to-day commands and
the version-bump procedure.

To add a new third-party library: add its row to `matrix.conf`, write
`lib/recipes/<lib>.sh` following the existing recipes (the sqlite3 recipe is
the simplest model), and add the xcframework + ensure phase to the consuming
Xcode target.

**Version bumps carry per-recipe knowledge.** The mysqlclient recipe (host
tools, cross preset answers), the freetds recipe (installed-header patch) and
the zint recipe (cmake flags) all encode assumptions about the pinned version
-- `LIBRARIES.md` section 1 lists them. When a version bumps, re-check those.

## Testing and Reports

*   **Note**: the project ships no test suite of its own. `build.sh --verify
    --all` is its verification, and the consuming frameworks' suites are the
    functional proof.
*   **Tracking**: [`BUGS.md`](../BUGS.md) -- the defect register;
    [`TASKS.md`](../TASKS.md) -- the engineering queue. Maintain them, but do
    not start work from them.
*   **Design document**: [`LIBRARIES.md`](../LIBRARIES.md).
