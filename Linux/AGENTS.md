# Linux Agent Overview

## What this is

The Phase B Linux toolchain spike (see [`../MAD_LINUX.md`](../MAD_LINUX.md) §9 and
this directory's [`README.md`](README.md)). One Docker image builds libobjc2,
libdispatch and GNUstep from pinned sources on Ubuntu 24.04, compiles a
MADFoundation subset against them, and runs the Linux tests. It is a proof of
the environment; nothing here ships in the app and no CI consumes it yet
(Phase F does that).

## Layout

*   **`Dockerfile`** -- three stages: `toolchain-base` (Ubuntu + apt + compiler
    environment), `toolchain` (the four source builds from `toolchain.conf`),
    `build` (the repo compiled by `CMakeLists.txt`; `docker run` runs ctest).
*   **`toolchain.conf`** -- the pins, Compressor-`matrix.conf` style. The single
    place a component's version, source and hash lives.
*   **`build.sh`** -- the entry point. Host modes, plus the internal
    `--in-image configure|build|test|probe` steps the Dockerfile and CMD call.
*   **`lib/common.sh`**, **`lib/toolchain.sh`** -- fetch/build helpers and the
    per-component build knowledge, again mirroring Compressor.
*   **`CMakeLists.txt`** + **`cmake/MADLinuxFramework.cmake`** -- the build:
    the toolchain flags, the include shim, the prelude, and the one recipe
    (`mad_make_include_shim`, `mad_add_framework`, `mad_add_test`) every
    framework is added through. The per-framework source list lives beside it
    (`cmake/MADFoundationSources.cmake`, with per-file exclusion reasons).
*   **`Compat/`** -- the Linux-only shims: `MADCompat.h` (the force-included
    prelude, now only the `NSOperation+Name.h` shim) and
    `NSOperation+Name.h/.m` (the `name` property GNUstep lacks).
*   **`Tests/`** -- the ported MADFoundation suites and `ToolchainProbe.m` (the
    environment probe and its report). `Tests/Support/MADTestSupport.h` is the
    GNUstep `Testing.h` glue, shared by every framework's suites.
*   **`build/`** -- CMake output; gitignored by the repo's `build/` pattern.

## Adding the next framework

The recipe MADFoundation was built with, in the order it was done:

1.  **Source list.** `cmake/<Name>Sources.cmake` sets `<NAME>_SOURCES`: the
    implementation files the framework needs on Linux, grouped, with every
    excluded file named and a one-line reason (the shape of
    `MADFoundationSources.cmake`). Keep it in step with `MAD_LINUX.md` §4.
2.  **Include shim and library.** `mad_make_include_shim(<Name> <source-dir>)`,
    then `mad_add_framework(<library> <SOURCES_VAR> <test> ...)`. The function
    adds the compat prelude, builds the library ARC, and links the tests
    whole-archive (Apple's `-ObjC`) so categories survive the static archive.
3.  **Tests.** Port the framework's Xcode suite into `Tests/`, one stand-alone
    executable per suite, and pass the names to `mad_add_framework`; ctest and
    `build.sh`'s MADTEST/NEED summary follow from that. `MADTestSupport.h`
    carries the Foundation and dispatch imports the suites use.
4.  **Self-contained headers.** The prelude supplies only the `NSOperation`
    `name` shim, so every header and source must import what it uses. The
    check: compile each header as a one-line translation unit with only that
    shim as prelude, and repeat for the sources -- every failure names a
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
    `MADTestSupport.h` wraps it with failure-latching `MAD_PASS`/`MAD_PASS_EQUAL`
    and a counted, non-failing `MAD_NEED`.
*   Test files also compile with MRC, so object-typed `__block` captures must
    `retain` explicitly (the ARC-compiled library balances its own copies out
    from under them otherwise).
*   The library links whole-archive: categories in a static archive are
    otherwise dropped, the way Apple's `-ObjC` prevents.
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
