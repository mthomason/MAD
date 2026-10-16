# Linux Agent Overview

## What this is

The headless engine's Linux build (see [`../MAD_LINUX.md`](../MAD_LINUX.md) §9 and
this directory's [`README.md`](README.md)). One Docker image builds libobjc2,
libdispatch, GNUstep and the C libraries the frameworks link from pinned
sources on Ubuntu 24.04, compiles all ten headless frameworks against them,
and runs their suites. Nothing here ships in the app, the CLI is Phase D's
checkpoint, and no CI consumes it yet (Phase F does that).

## Layout

*   **`Dockerfile`** -- three stages: `toolchain-base` (Ubuntu + apt + compiler
    environment), `toolchain` (the four source builds from `toolchain.conf`,
    then the C libraries from `libraries.conf`), `build` (the repo compiled by
    `CMakeLists.txt`; `docker run` runs ctest).
*   **`toolchain.conf`** -- the toolchain pins, Compressor-`matrix.conf` style.
    The single place a component's version, source and hash lives.
*   **`libraries.conf`** + **`lib/libraries.sh`** -- the same for the C
    libraries the frameworks link (sqlite3, openssl, freetds, zlib, bzip2,
    libarchive, mysqlclient), built natively into `/usr/local`.
*   **`build.sh`** -- the entry point. Host modes, plus the internal
    `--in-image configure|build|test|probe` steps the Dockerfile and CMD call.
*   **`lib/common.sh`**, **`lib/toolchain.sh`** -- fetch/build helpers and the
    per-component build knowledge, again mirroring Compressor.
*   **`CMakeLists.txt`** + **`cmake/MADLinuxFramework.cmake`** -- the build:
    the toolchain flags, the include shims, the prelude, and the one recipe
    (`mad_make_include_shim`, `mad_add_framework`, `mad_add_test`) every
    framework is added through. The per-framework source list lives beside it
    (`cmake/MADFoundationSources.cmake`, with per-file exclusion reasons).
*   **`Compat/`** -- the Linux-only shims. `MADCompat.h` is the force-included
    prelude (the compat categories and the macro/typedef gaps); `Compat/`
    also holds `CoreGraphics/` (the CG geometry functions), `CoreFoundation/`
    (`CFNumber.h`, `CFAvailability.h`), `objc/NSObject.h` and
    `UIKit/UIGeometry.h` -- directory shims so the frameworks' Apple imports
    resolve unchanged. The shims compile into **`madcompat`**, one static
    library of their own, whole-archived by every executable; they used to be
    copied into each framework archive, which made whole-archiving two archives
    a duplicate-symbol error and cost the CLI a missing category (README.md).
*   **`Tests/`** -- the ported suites, one stand-alone executable per Xcode
    test file, plus `ToolchainProbe.m` (the environment probe and its report).
    `Tests/Support/MADTestSupport.h` is the GNUstep `Testing.h` glue, shared
    by every framework's suites.
*   **`build/`** -- CMake output; gitignored by the repo's `build/` pattern.

## Adding the next framework

The recipe MADFoundation was built with, in the order it was done:

1.  **Source list.** `cmake/<Name>Sources.cmake` sets `<NAME>_SOURCES`: the
    implementation files the framework needs on Linux, grouped, with every
    excluded file named and a one-line reason (the shape of
    `MADFoundationSources.cmake`; MAD's is the inverse — 150 included, the 31
    exclusions named by group). Keep it in step with `MAD_LINUX.md` §4.
2.  **Include shim and library.** `mad_make_include_shim(<Name> <source-dir>)`,
    then `mad_add_framework(<library> <SOURCES_VAR> <test> ...)`. The function
    adds the compat prelude, builds the library ARC, and links the tests
    whole-archive (Apple's `-ObjC`) so categories survive the static archive.
    Two frameworks need more: MADSqlite3 and MADTds get a second shim
    directory for the library headers they expose as their own
    (`<MADSqlite3/sqlite3.h>`, `<MADTds/sybdb.h>`), and MAD's shim is a
    directory of symlinks because its Xcode target flattens every header as
    `<MAD/Foo.h>`.
3.  **Tests.** Port the framework's Xcode suite into `Tests/`, one stand-alone
    executable per suite, and pass the names to `mad_add_framework`; ctest and
    `build.sh`'s MADTEST/NEED summary follow from that. `MADTestSupport.h`
    carries the Foundation and dispatch imports the suites use.
4.  **Self-contained headers.** The prelude supplies only the compat shims, so
    every header and source must import what it uses. The check: compile each
    header as a one-line translation unit with only that shim as prelude, and
    repeat for the sources -- every failure names a
    missing import. Inside the toolchain image, with the repo mounted at
    `/repo`:

        SRC=/repo/MADFoundation/Source
        mkdir -p /tmp/audit/shim && ln -sfn "$SRC" /tmp/audit/shim/MADFoundation
        clang $(gnustep-config --objc-flags) -fobjc-arc -fsyntax-only \
            -I /tmp/audit/shim -I /repo/Linux/Compat \
            -include NSOperation+Name.h \
            -D__unused=__attribute__\(\(unused\)\) tu.m

    where `tu.m` is `#import <MADFoundation/Foo.h>` for a header, or the
    source file itself. Only the files Phase C excludes may fail.
5.  **Verify.** `./Linux/build.sh` from the repo root: image builds, subset
    compiles and links, every test executable passes. A GNUstep divergence is
    either fixed, recorded as a `MAD_NEED` with a reason, or asserted
    per-platform with a comment -- never silently skipped. The known
    divergences are listed in [`README.md`](README.md); the iOS simulator suite
    is the regression gate for any platform guard the port adds.

## Conventions and hazards

*   Tests use GNUstep's `Testing.h`, which is manual-retain-release: test
    translation units build with `-fno-objc-arc` while the library stays ARC.
    `MADTestSupport.h` wraps it with failure-latching `MAD_PASS`/`MAD_PASS_EQUAL`,
    a counted, non-failing `MAD_NEED`, and `MAD_SKIP` for the suites that skip
    when a live database is unreachable (skips are counted separately and are
    never needs).
*   Test files also compile with MRC, so object-typed `__block` captures must
    `retain` explicitly (the ARC-compiled library balances its own copies out
    from under them otherwise).
*   The library links whole-archive: categories in a static archive are
    otherwise dropped, the way Apple's `-ObjC` prevents.  The driver archives
    are whole-archived from `mad` for the same reason -- a driver's work is its
    categories -- and the compat shims are one archive (`madcompat`) shared by
    every executable.  A framework archive that is *not* whole-archived links
    silently without its categories; that is not a warning, it is a crash at
    the first message send (see README.md).
*   Iterating on one test in the existing image, without rebuilding it: mount
    the repo and a persistent build dir, then build just the target --
    `docker run --rm -v "$PWD":/repo -v /tmp/x-build:/build -w /tmp
    mad-linux:phase-b bash -c 'cmake -S /repo/Linux -B /build
    -DCMAKE_BUILD_TYPE=Debug && cmake --build /build --target <Test>
    -j"$(nproc)" && /build/<Test>'` (the Docker CLI lives at
    `/Applications/Docker.app/Contents/Resources/bin` when it is not on
    `PATH`).  `./Linux/build.sh` remains the canonical gate: the image copies
    the sources at build time, so `--test` alone re-runs the old binaries, and
    an edit only reaches the image through a rebuild.
*   The C libraries are built into `/usr/local` by `lib/libraries.sh`; a new
    dependency means a pin in `libraries.conf` and a `build_<name>` function
    there, not an edit to the Dockerfile.
*   **Header imports must match the file's case exactly.**  The Mac's filesystem
    is case-insensitive, the image's is not: `#import <MAD/RptqDocument+extras.h>`
    compiles here and is a fatal error there (`MADOperationRefreshInitialize.m`
    was written that way in the app target for years).  When a file moves into
    this build, check its imports; the check is a script away — list each
    framework's header names, compare every `<Framework/Name>` import against
    them, and any near-miss is the bug.
*   `Compat/` is the only place a platform gap may be answered without a
    framework edit. A gap that needs a source guard instead is `#if __APPLE__`
    (never a `TARGET_OS_*` spelling GNUstep does not define), with a comment
    naming what the Apple branch does.
*   `toolchain.conf` component names must be valid shell identifiers
    (underscores, not dashes) — they become shell variable and function names.
*   When a component's build needs a new flag, change `lib/toolchain.sh` (the
    per-component function) and re-run `--rebuild`: that layer is only
    invalidated by `toolchain.conf` and `lib/`, never by source edits.

## Verification

`./Linux/build.sh` from the repo root is the whole check: image builds, subset
compiles and links, all test executables pass. `--probe` prints the environment
report; `--info` prints the clang and GNUstep versions and flags. The iOS
simulator suite is the regression gate for the framework's platform guards.
