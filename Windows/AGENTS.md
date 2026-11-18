# Windows Agent Overview

## What this is

The headless engine's native Windows build (see [`MAD_WINDOWS.md`](../docs/project/MAD_WINDOWS.md)
and this directory's [`README.md`](README.md)). It compiles the engine's
Objective-C frameworks against GNUstep Base with Clang, the Windows sibling of
the Linux build. Nothing here ships in the app yet; the WPF shell is a later
phase. The first increment builds MADDataStructures and MADFoundation and runs
a smoke test.

## Layout

*   **`Engine/toolchain.conf`** — the toolchain pins, the single place the
    recipe is written down: the pinned `tools-windows-msvc` commit, Clang
    20.1.8 / lld / VS 2026 / the Windows SDK, the STL gate override, and the
    seven pinned GNUstep component revisions.
*   **`Engine/toolchain/`** — the reproducible toolchain build:
    `bootstrap.ps1` (clone the pinned driver, apply the patches, build into the
    prefix) and the two patch files it applies:
    *   `stl-gate-override.patch` — appends `-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH`
        to the driver's `scripts/sdkenv.bat` (the VS 2026 STL gate).
    *   `revision-pins.patch` — sets `TAG=` in the driver's `phases/*` to the
        seven known-good revisions (the floating-master regression).
*   **`Engine/build.ps1`** — the entry point: prerequisite check, idempotent
    toolchain bootstrap, the framework build, and the smoke test.
*   **`Engine/cmake/<Name>Sources.cmake`** — the per-framework source lists and
    exclusion reasons, mirroring `Linux/cmake/`. These are the canonical file
    inventory; `build.ps1` reads them back so the two cannot drift.
*   **`Engine/Compat/`** — the Windows shims, a copy of `Linux/Compat` adapted
    for Windows: `syslog.h` (no-op), `pthread.h` (`CRITICAL_SECTION` mutex),
    the `NSData+ReadingOptions` shim dropped, the `NSPropertyListSerialization+Stream.m`
    import fixed, and `MADCompat.h` (the force-included prelude) with the
    `<endian.h>` block dropped.
*   **`Engine/Tests/`** — the smoke test (`smoke.m`).
*   **`Engine/build/`** — build output (gitignored): clang objects, `smoke.exe`,
    the toolchain clone, and the include-shim junctions.
*   **`global.json`** — pins .NET 10 LTS for the future WPF app.
*   **`App/`** — the WPF shell (a later phase; not created yet).

## How the build works

`build.ps1` drives Clang directly — it does **not** go through CMake's
Objective-C language. CMake's Objective-C support on Windows is broken for the
GNU-driver clang + MSVC target: its link probe passes GNU-ld flags
(`--out-implib`, `-nostdlib`) to `lld-link` and appends `.lib` to library names
already prefixed with `-l`. The proven recipe is direct `clang` invocations
(the viability phase's `compile-mad.sh` / `link-and-run.sh`), and `build.ps1`
is that recipe cleaned up. The `cmake/*.cmake` lists stay CMake-ready so a
real CMake build can consume them once CMake's Windows ObjC support lands.

## Conventions and hazards

*   The one shared-source change this increment required (the `madlib.c`
    `itoa`/`ltoa`/`ultoa` → `mad_*` rename) is portable and behaviour-neutral on
    Apple/Linux; it is enumerated in `docs/project/MAD_WINDOWS.md` §5. The
    `NSPropertyListSerialization+Stream.m` `NSData.h` import lives in the
    `Windows/Engine/Compat` copy, not in shared source. Prefer a
    `Windows/Engine/Compat` shim before editing a shared framework source; a gap
    that needs a source guard is `#if __APPLE__` (never a `TARGET_OS_*` spelling
    GNUstep does not define).
*   `Engine/Compat/` mirrors `Linux/Compat/`. When a Linux shim changes, port
    the change to the Windows copy (or record why it does not apply).
*   `.mm` files compile with `-std=gnu++20` and
    `-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH`; `MADVectorBool.mm` also gets
    `-fno-objc-arc` (the file enforces it itself). `madlib.c` compiles as
    Objective-C (`-x objective-c`, manual-retain-release) because it uses
    `#import`.
*   The toolchain build must run elevated (it installs into `C:\GNUstep`), from
    the `vcvars64` environment, with the `BASH` setting, by absolute
    `build.bat` path, without editing `PATH`.
*   Do not change the compiler, STL, or Visual Studio/SDK without a new
    viability test — they are the environment, not a knob.

## Verification

`pwsh -File .\Windows\Engine\build.ps1` from an elevated prompt is the whole
check: toolchain bootstrap (idempotent) + framework build + smoke test, exiting
non-zero on any failure. The smoke test prints `SMOKE RESULT: 0 failure(s)` and
exits 0. The Linux CI and the Apple suites are the regression gates for the
shared-source change this tree makes.
