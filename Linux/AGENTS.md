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
*   **`CMakeLists.txt`** + **`cmake/MADFoundationSources.cmake`** -- the subset
    list (with per-file reasons), the include shim, whole-archive linking and
    the ctest wiring.
*   **`Compat/`** -- the Linux-only shims: `MADCompat.h` (the force-included
    prelude) and `NSOperation+Name.h/.m` (the `name` property GNUstep lacks).
*   **`Tests/`** -- `MADTestSupport.h` (the GNUstep `Testing.h` glue),
    `ToolchainProbe.m` (the environment probe and its report), and the ported
    MADFoundation suites.
*   **`build/`** -- CMake output; gitignored by the repo's `build/` pattern.

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
*   A GNUstep divergence is either fixed, recorded as a `MAD_NEED` with a
    reason, or asserted per-platform with a comment — never silently skipped.
    The known divergences are listed in [`README.md`](README.md).
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
