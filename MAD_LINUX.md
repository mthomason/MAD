# Compiling the MAD Engine on Linux — a technical assessment

Written 2026-10-04 against `master` at `c807eeb4d`. The dependency audit (§4) and the
ecosystem research (§5-6) this document rests on were both produced the same day:
the audit by grepping every framework's source directory, the research from primary
sources (release notes, package repositories, project mailing lists). Where evidence
was thin, that is said. This document is the technical companion to `MAD_FUTURE.md`
§5.1, which sketched the platform matrix; this is the dive.

---

## 1. The question, answered

Can this compile on Linux? **Yes, conditionally — in both senses.**

- The code that must compile — the headless engine — is, by measurement, already
  nearly free of Apple dependencies. The two that remain (Core Data and
  UIKit/CoreGraphics) are either mid-migration or enumerated file-by-file, and
  neither sits on the refresh path.
- The ecosystem that must host it — Objective-C with Foundation on Linux — exists,
  is packaged in every major distribution, and runs a production groupware server
  today (SOGo, Debian-packaged against GNUstep Base 1.31.1). It is niche, its
  modern-API coverage is unverified at the margins, and its UIKit story does not
  exist — but this codebase does not need UIKit on Linux. It needs the engine.

The two asterisks: **GNUstep's Foundation is present-but-unverified** for the exact
APIs this code leans on hardest (`NSPredicate`/`NSExpression`, keyed archiving,
`NSURLSession`), and **there is no realistic UIKit on Linux** — which is fine,
because the audit shows the code already confines UIKit to named files, and the
rendering plan moves off UIKit anyway.

---

## 2. The two-product question: rewrite, or compile-and-call

The choice the user posed: rewrite everything in Python and maintain two products,
or compile once and have Python call the engine. The audit settles it.

**The engine is big.** The headless framework set — `MADFoundation` (65 h+m files),
`MADCocoaExtensions` (44), `MADDataStructures` (36), `MADFileManager` (30), `MADAPI`
(33), `MAD` (403), `MADSqlite3` (64), `MADMySQL` (41), `MADTds` (3), `MADTdsClient`
(8) — is roughly 727 files. A Python rewrite duplicates not just volume but
*behaviour that is pinned by tests and hard-won*: the SQL generator, the
`MADDataTableFast` ingest path (200,000 rows in 1.16 s, benchmarked), the drivers'
type mappings (SQL Server's modern date/time handling exists only because live tests
caught it twice), the null-sentinel family, the store reader. Two implementations of
that drift; the suite pins only one. That is not "two products," it is one product
and one liability.

**The integration surface already exists.** The CLI *is* the contract: `mad inspect` → metadata, `mad query` → SQL, `mad refresh` → rows, `mad export` → formats, with
exit codes distinguishing bad document (2) from unreachable server (3) from failed
query (4). A Python service calls it as a subprocess with `--format json` and gets
the report. Subprocess overhead is irrelevant at refresh timescales (the samples
refresh in 0.02-1.2 s; process spawn is ~10 ms). If in-process embedding is ever
measured to matter, the same sources can build a small C ABI library for
ctypes/CFFI — but that is optional, not a prerequisite.

**On the stated reason to prefer Python — driver hookup.** It is true that Python's
connector ecosystem is broad, and one `pip install` reaches databases this project
has no driver for. But for the sources that exist today the hookup is already
language-neutral: the MAD drivers sit on freetds and mysqlclient — the same C
libraries a Python or C program would link — and both build natively on Linux (§7).
Compiling the engine moves that hookup to Linux unchanged. Where Python genuinely
has an edge is *new* source types (Postgres, BigQuery, REST), and there the right
answer is the extensibility seam the project already promises: a `MADDatabase`
subclass that returns a schema and rows. A driver that speaks HTTP behaves
identically in Objective-C and Python; Python buys more pre-written connectors, not
an easier core.

**The honest trade, stated plainly:** this is a choice between maintaining *two
implementations* (Python + Objective-C) with permanent drift risk, and maintaining
*one implementation on a niche toolchain* (clang + libobjc2 + GNUstep) with
ecosystem risk. This document recommends the latter, with a measurable trigger to
revisit: §9 names the checkpoint. The one thing that makes the recommendation
binding is the **JSON export shape** — the Python contract is only as good as its
schema, and defining it is decision 1 in §10.

And if a rewrite ever does happen, the right language is Swift on Linux — not Python
— because the portable SQLite store (the Phase C work) is already a language-neutral
contract: whichever side writes the store, the other reads it.

---

## 3. What must compile, and what must not

| Framework | Needed headless | Why / why not |
|---|---|---|
| `MADFoundation` | yes | the base: operations, URL factory, keychain (excludable), logging |
| `MADCocoaExtensions` | yes | helpers used everywhere (11 UIKit files, but excludable ones) |
| `MADDataStructures` | yes | 0 Apple imports; 3 C++ files (needs libc++) |
| `MADFileManager` | yes | 0 Apple imports; cloud coordinator excluded (iCloud is being deleted in Phase D anyway) |
| `MADAPI` | yes | connection layer; 3 UIKit files are view controllers, not headless |
| `MAD` | yes | the hard one: 29 UIKit, 34 CoreData, 15 CoreGraphics of 403 |
| `MADSqlite3` | yes | 0 Apple imports; `MADArrayCaching` (the `.madac` store) is 100% clean |
| `MADMySQL` | yes | 0 Apple imports |
| `MADTds` / `MADTdsClient` | yes | 0 Apple imports |
| `MADExplorer` | no | file-explorer UI (19 of 32 files import UIKit) |
| `MADBarcodes` | no | unused and unmaintained |
| `MADFeedback` | no | unused and unmaintained |
| `Scrimpter` | no | 0 Apple imports, but unused |
| `MADDesigner` (app) | no | 302 UIKit files; the UI stays on Apple platforms |

Dependency direction: everything sits on `MADFoundation`; the drivers subclass
`MADDatabase` in `MAD`, while `MAD`'s `Constructor` files import the drivers — the
known cycle (`ROADMAP.md` §3.4). The driver registry (`ROADMAP.md` §5.1) matters to
Linux twice over: it breaks that cycle and it is what lets a Linux build link
drivers as plugins rather than as a hard-imported pile.

---

## 4. The measured audit

Files importing each Apple framework, per framework source directory (a file
importing several UIKit headers counts once):

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

The long tail outside the pillars, each with a disposition:

| Item | Sites | Disposition |
|---|---|---|
| `os_log` (everything funnels through `madlog.h`, two copies) | 9+15+4+2+… files import the shim | rewrite one ~20-line header against syslog/printf; no other call site changes |
| `asl.h` (deprecated Apple System Log) | `MADocument.m:107`, `RptqDocumentElement+Extras.m:60` | swap to the madlog shim |
| `copyfile.h` | `MADArchiveManager.m:14`, `madtar.m:18` | POSIX rename/link |
| `mach/machine/vm_param.h` (page size) | `MADocument.m:108` | `getpagesize()` |
| `CFNetwork`/`CFHost` reverse DNS | `BDHost.m` (1 file) | `getaddrinfo` |
| `NSMetadataQuery` cloud coordinator | `MADFileManager` (3 files) | exclude — iCloud is deleted in Phase D |
| `Security.framework` / `SecItem` | `MADKeyChain.m`, `MADOperationKeyChainGet.m` + test | exclude — the refresh path takes credentials from an operation dependency, never the keychain; the CLI already substitutes `--credentials` |
| `AppKit` guard in `MADApplication.m` | 1 file | add a `TARGET_OS_LINUX` branch |
| `UIScreen` scale in `MADURLFactory.m:32` | 1 line | return 2.0 |
| `UIApplication` background task in `MADOperation.m:549-563` | 1 guarded feature | `#if` out |
| CoreFoundation (`CFNumber`/`CFData`/`CFString`, toll-free bridging) | ~25 sites across MAD, MADFoundation, MADSqlite3 | GNUstep equivalents / mechanical rewrite; CoreBase (GNUstep's CF clone) is immature, do not rely on it |
| UIKit value transformers (`MADColorTransformer`, `MADLocaleTransformer`, `MADPngImageTransformer`) | 3 files, currently dragged across the CLI's target boundary | **die with Phase D** — the store migration converts transformables to portable scalars |

SystemConfiguration: zero occurrences. CommonCrypto: zero in frameworks (app-only,
receipt validation). `@import`: zero — everything is `#import`, which is what
GNUstep wants.

---

## 5. The three pillars

### 5.1 Core Data — the in-flight migration is the lever

34 MAD files import Core Data; `MADocument` is a `UIManagedDocument`; the store is a
compiled `MAD.momd`; `MADAtomicStore` sits underneath. None of that exists on Linux,
and none of it needs to — because the project is already replacing it: `MAD_STORE_MIGRATION.md`
Phase C landed 2026-10-03, and `RptqStoreContext.h` declares "Nothing here imports
Core Data." Phase D deletes `UIManagedDocument`, the value transformers, the
`.xcdatamodel`, and the iCloud machinery — which simultaneously kills several §4
items (the value transformers, the cloud coordinator, the `MAD.momd` the CLI
currently copies out of the app bundle).

**Finishing Phase C and D is the single highest-leverage step toward Linux**, and it
is work the project already owns for portability, not Linux-specific effort. One note from the migration plan: old documents from the
iCloud era are retrieved by the user through the iOS Files app and converted on open
(`MADStoreConverter`) — the iCloud machinery is not needed to retrieve them, so
Phase D's deletion of it strands nothing.

### 5.2 UIKit / CoreGraphics — 29 files, most of them trivial

The 29 MAD UIKit files break down as:

| Kind | Count | Disposition |
|---|---|---|
| `CGGeometry` structs (`CGRect`/`CGSize`/`CGPoint`) | 15 files | plain structs — replicate the definitions; zero drawing |
| `UIEdgeInsets` in the formatter | ~3 files | replace with the struct math |
| `UIFont`/`UIColor`/`UIImage` in model/layout code | several | lightweight equivalents for metrics and stored styles |
| `UIActivityItemProvider` / share-sheet | 2 files | not headless — exclude |
| `UIScreen`/`UIApplication` | 2 files | one-liners, §4 |
| `MADPrintPageRenderer` + `UIGraphics` PDF contexts | the export seam | **the real work** — see below |
| `MADocument`'s `UIManagedDocument` base | the document class | dies with Phase D |

Notable good news: `MADReportFormatter.m`'s UIKit use is effectively vestigial
(one `UIEdgeInsetsMake`, one unused `UIPrintInteractionController` import), and
`MADArrayCaching` — the `.madac` rendered-page store — is 100% UIKit/CoreData-free
already. It compiles on any ObjC Foundation today.

**The renderer decision.** CoreGraphics PDF contexts have no Linux equivalent. The
staging that costs least: data-path verbs green first; `export --format json` /
`--format csv` next (pure Foundation — and these are the formats a Python caller
wants anyway); HTML/SVG pages next (no native dependencies); PDF last, by putting a
cairo or libharu writer behind the same `MADPrintPageRenderer` drawing loop, or by
keeping PDF rendering on macOS workers while Linux serves data and pages. The
`--deterministic` flag the CLI already byte-patches into PDFs is the seed of a
cross-platform renderer test.

### 5.3 Foundation on GNUstep — exists, verified in part, risky at the margins

What the research verified, from primary sources:

- **GNUstep Base 1.31.1** (2025-02-28) is current; master is active (notable
  NSURLSession work merged 2026-08). Release cadence is slow — roughly annual.
- Present and functional: `NSJSONSerialization`, `NSUUID`, `NSRegularExpression`
  (ICU), `NSISO8601DateFormatter`, `NSDateFormatter` (ICU-backed — `libicu-dev` is a
  required build dependency), `NSOperationQueue`, property lists, `NSXML*`
  (libxml2), keyed archiving aiming at Apple XML compatibility.
- **`NSURLSession` is the weak spot**: shipped 1.31.0 as "new experimental
  implementation," explicitly not a supported class; the 2026 de-blocking work
  (building without blocks) is merged but stabilisation is unfinished. Do not build
  the Linux product on it — prefer direct driver connections (which is what
  refresh does anyway) or libcurl.
- **`libdispatch` is optional by GNUstep's own policy** — the base maintainer calls
  it "not in a state where it's portable/reliable enough" to depend on. This
  codebase uses dispatch widely (`dispatch_once`, `dispatch_sync`, semaphores).
  swift-corelibs-libdispatch is C and callable from ObjC (with
  `OS_OBJECT_HAVE_OBJC_SUPPORT=1`), and the *core* used here is the stable part —
  but treat dispatch as a shim-able layer, not a given.
- **CoreBase** (GNUstep's CoreFoundation clone) is immature — the build guide says
  not to rely on it. The ~25 CF sites get GNUstep equivalents instead.
- **Unverified at the margins, and load-bearing here:** `NSPredicate`/`NSExpression`
  (13+ import sites in MAD), `unarchivedObjectOfClass:` (iOS 11+ API — GNUstep
  coverage varies), `NSOperation`+KVO behaviour. Presence is proven; behavioural
  parity is not. This is the honest risk, and it is exactly what the fixtures in §8
  exist to test.

**The existence proof:** SOGo, an Objective-C groupware server, ships in Debian
sid hard-depending on `gnustep-base-runtime (>= 1.31.1)` — GNUstep Foundation
running as a production daemon at scale. Darling drives libobjc2. Non-GUI ObjC
tooling on Linux is normal, not exotic.

---

## 6. Toolchain and ecosystem

- **Runtime: libobjc2 2.3** (2025-09-16) — the only way to get modern Objective-C
  on Linux. ARC, blocks, weak references, `@synchronized`, non-fragile ivars, the
  gnustep-2.0 ABI. **ARC requires clang + libobjc2**, and the mainstream distro
  packages build GNUstep against the GCC runtime without ARC — so the build
  environment is assembled from source (or Fedora's libobjc2 packaging), not from
  Debian's defaults. This is a real operational commitment.
- **Blocks**: libobjc2 2.3 can consume swift-corelibs-libdispatch's BlocksRuntime;
  `libblocksruntime-dev` is also packaged. The code's blocks are standard.
- **Exceptions**: clang + libobjc2 gives native unwinder-based exceptions; GNUstep's
  two exception mechanisms must not be mixed in one executable — build everything
  with the native path.
- **No clang modules / `@import` support** — and the codebase already uses `#import`
  everywhere, so this costs nothing.
- **UIKit on Linux: confirmed absent.** The user's memory of Microsoft is WinObjC —
  the Windows Bridge for iOS, a deliberately partial UIKit subset on Windows, last
  pushed 2022, archived 2025-05-28. Chameleon (UIKit on macOS) died in 2015.
  `gnustep/libs-uikit` (June 2026) is a 26-commit experiment with one star. The
  lesson to take from even Microsoft abandoning the idea: **do not port UIKit.**
  The audit shows why this project doesn't have to — UIKit is already confined to
  named files, and everything headless renders through data, not views.
- **Testing: no XCTest for ObjC on Linux** (swift-corelibs-xctest is Swift-only).
  GNUstep's own `gnustep-tests` + `Testing.h` is the zero-dependency unit runner;
  UnitKit is archived. The real acceptance layer is §8's fixtures, not unit tests.
- **Crypto and secrets**: no CommonCrypto port (the GNUstep project's own advice is
  `#ifdef` to OpenSSL or GnuTLS); no keychain (the functional analog is
  libsecret/Secret Service, or keyutils for session secrets) — and per §4 the
  headless engine needs neither.

---

## 7. The C libraries — the easy part, with one licence blocker

Every vendored library is portable C with an upstream autoconf/cmake build:

| Library | Version | Licence | Linux build |
|---|---|---|---|
| sqlite3 | 3.53.3 | public domain | native; format-pinning flags already live in `Compressor/sqlite3.xcconfig` |
| zlib | 1.3.2 | Zlib | native |
| openssl | 3.5.9 | Apache-2.0 | native |
| bzip2 | 1.0.8 | BSD-like | native |
| libpng | 1.6.59 | PNG Reference v2 | native |
| libarchive | 3.8.9 | BSD-2 | native |
| freetds | 1.4.27 | LGPL-2.0+ | native (recipe has a BSD `sed -i ''` nit to fix) |
| mysqlclient | 8.4.10 | **GPL-2.0 + FOSS exception** | native — **but GPL is a shipping blocker for a proprietary binary**; MariaDB Connector/C (LGPL-2.1) is the already-named replacement in `LICENSE_COMPLIANCE_PLAN.md` |
| zint | 2.16.0 | BSD-3 | native (unused barcode backend) |

Plus the in-tree C (`miniz`, `madmath`, `madpng`, `madtar`, `madlib` — all portable,
all permissively licensed). Only Compressor's *packaging* layer is Apple-specific
(`xcrun`, `-isysroot`, `lipo`, `xcodebuild -create-xcframework`); a Linux driver
drops all of it, runs the same upstream builds natively, and finishes with plain
`ar` + include install. The iOS-specific complexity (mysqlclient's two-stage
host-tools build, freetds's per-platform generated header) *disappears* on native
builds. One flag from the audit: the Karl Kraft MySQL connector is unlicensed —
replace it with the MariaDB move, don't ship it.

---

## 8. The build and test plan

- **Build system**: CMake for the ten headless frameworks plus the CLI — one flag
  set (`clang`, `-fobjc-arc`, `-fblocks`, GNUstep's `gnustep-config --objc-flags`).
  The `.momd`-copying dance in `CLI/build.sh` disappears with Phase D, and
  `REFRESH_SOURCES`' reach across the target boundary disappears with the
  `MADOperationRefresh` move (`ROADMAP.md` §3.4).
- **Acceptance layer**: the round-trip fixtures in `MAD_CLI.md` §6, run on Linux
  and byte-compared against the macOS/simulator run — container fidelity, v0
  readability, cache-free round trip, exit codes. The row cache and JSON/CSV output
  are byte-comparable; PDF is structurally comparable only until one renderer
  exists. These fixtures are also the *coverage test for GNUstep Foundation*: run
  them early, triage every failure, and the §5.3 unknowns resolve themselves
  empirically instead of by reading API indexes.
- **CI**: a Linux job in the test matrix running the fixtures; the suite stays the
  simulator suite it is today.

### 8.1 The deployment path: containers, not cross-compilation

How does this actually get built and shipped?

- **Do not cross-compile from macOS.** An Objective-C runtime plus GNUstep Base is
  host-coupled — cross-compiling it against a Linux sysroot from a Mac is a research
  project, not a build step. The iOS app stays built by Xcode on the Mac; the Linux
  engine is *built on Linux*.
- **Docker is the build environment.** One Dockerfile, two stages: a toolchain stage
  that source-builds clang + libobjc2 2.3 + GNUstep Base (required for ARC — §6), and
  a build stage that runs the Compressor Linux driver for the C libraries (§7), then
  CMake for the ten frameworks and the CLI. The same image doubles as the CI
  environment and the deployment artifact.
- **Which Linux to support: one baseline, in a container.** Pick a single baseline —
  Debian stable or an Ubuntu LTS — and build there, because the real compatibility
  constraint is glibc: everything linked is built from source except the libc, so
  "supported Linux" means "the glibc of the image we ship." Building on the oldest
  glibc you accept is the rule. Shipping a container means any Docker-capable host
  runs the product without a distro matrix.
- **The workflow is the script-and-compile you are already used to, automated.**
  `git clone` on the Linux builder → Compressor recipes build sqlite, zlib, openssl,
  bzip2, libpng, libarchive, freetds and MariaDB from source → CMake compiles the
  frameworks with one flag set → link `mad` → run the round-trip fixtures (above) →
  tag the image. A GitHub Actions ubuntu runner is the standard place for this to
  happen on every commit.
- **macOS's role.** The Mac remains the development host for the app, the simulator
  CLI, and the reference fixture outputs. The two platforms are joined by git and by
  the fixtures' byte-comparison — the Linux build is *checked against* the Mac's
  outputs, which is the portability guarantee made executable.

---

## 9. Effort and phasing

Buckets, in the order they should be taken:

| Phase | Work | Character |
|---|---|---|
| A | Finish Phase C + D of the store migration | already-owned portability work; removes Core Data, iCloud, value transformers, `.momd` — the single biggest Linux lever |
| B | Toolchain spike: a Dockerfile that source-builds clang + libobjc2 + GNUstep Base; compile a MADFoundation subset | proves the environment and becomes the build/CI image; days |
| C | The §4 shim list | bounded and enumerated — madlog, asl, copyfile, vm_param, CFHost, MADApplication, UIScreen, background-task, ~25 CF sites, exclusions |
| D | **The checkpoint**: data-path verbs green on Linux — `inspect`, `schema`, `query`, `refresh` against both samples, fixtures byte-compared | if this is not green after C, the GNUstep Foundation tail is bigger than estimated, and *that* is the moment to revisit the rewrite question — not before |
| E | Export: JSON/CSV (the Python contract), then HTML/SVG pages, then the PDF decision (cairo/libharu vs macOS-side rendering) | pure Foundation first; renderer last |
| F | Compressor Linux driver (native builds, matrix column, MariaDB swap, freetds sed fix) + CMake polish + CI row + the deployable image | mechanical, licence-gated |

Ordering rationale: A is owned work, B is cheap and de-risks everything, C is
enumerable, and D is the honest go/no-go. Nothing in E or F is needed to *answer*
the question; they are needed only to *ship*.

**Phase A status (2026-10-06).** Core Data is out of the MAD framework: `MADocument` is a
`UIDocument`, the legacy converter and the compiled model live in the application target
behind `MADLegacyStoreConversion`, a converted document prunes its Core Data files, and the
framework/MADDesigner sweep removed the remaining imports, types and dead code. The value
transformers, the explorer's cloud pane, and the iCloud entitlements are kept by user
decision — they are app-side, so they do not block the headless build; the file manager's
cloud code stays where it is, unused (per the user: not needed for headless mode). What
remains before B is whatever §4 file-level exclusions the toolchain spike proves necessary.

**Phase B status (2026-10-06).** The toolchain spike is green on the
`linux-port` branch, merged to `master` 2026-10-16 (`524e0d86e`):
`Linux/` builds one Docker image — Ubuntu 24.04 with the distro
clang 18 (the "from source" requirement in §6 is about GNUstep being built against
libobjc2, not about LLVM), plus source-built libobjc2 2.3, libdispatch 6.1.3,
gnustep-make 2.9.3 and gnustep-base 1.31.1, pinned in `Linux/toolchain.conf` —
compiles 23 of MADFoundation's 27 implementation files and `madlib.c` against
GNUstep, and runs 15 test executables (14 ported suites and a toolchain probe)
inside it: all pass, with 5 recorded needs and 10 probe report items.
`./Linux/build.sh` is the entry point; the iOS suite stayed green (118 tests) as
the proof that the six small platform guards the work required are behaviour-neutral
on Apple.

The probe retires most of §5.3's risk list for the Foundation the engine actually
uses: ARC and weak zeroing, blocks, exceptions, `@synchronized`, KVO (manual and
dependent keys), `NSOperation` state-machine KVO, `NSPredicate
predicateWithFormat:@"error != nil"` (MAD's exact predicate), dispatch including
the main queue draining under a plain executable, JSON, dates, plists, sort
descriptors, streams and keyed archiving on the permissive path all pass. Two gaps
are recorded, not hidden: GNUstep's archiver has no secure-coding support
(`requiringSecureCoding:YES` returns nil; the permissive path round trips), and
GNUstep's `NSOperationQueue` removes its `isReady` observation on every
notification while MADOperation's state machine used to notify `isReady` more
than once per enqueue — the second removal raised, so a MADOperation could not
be enqueued on Linux. That is settled (2026-10-06, `linux-port`, now in `master`):
MADOperation drives the state advance explicitly from `-willEnqueue` and sends
KVO for `isReady`/`isExecuting`/`isFinished` only on real value changes, so the
queue sees one notification, as on Apple; the Linux tests assert it plainly on
both platforms and the needs dropped to 3. The mechanism is written up in
`Linux/README.md` alongside the excluded files and the smaller shims
(`NSOperation.name`, `qualityOfService`, `NSDataWritingFileProtection*`,
`QOS_CLASS_DEFAULT`, app-group containers). The file-level exclusions Phase A anticipated turned out to be exactly
the four §4 files (`BDHost`, `MADApplication`, `MADKeyChain`, `MADURLFactory`); the
self-contained-header cleanup the prelude used to paper over is done (2026-10-06):
every header and source in the Linux build imports what it uses, and
`Linux/Compat/MADCompat.h` is down to the one real platform gap, `NSOperation`'s
`name` property.

**Phase C status (2026-10-06).** The §4 shim list is cleared and the build is no
longer a spike: all ten headless frameworks of §3's table compile and link
inside the image — MADFoundation 26 of 27 files, MADDataStructures 17,
MADFileManager 10 of 11, MADCocoaExtensions 7 of 17, MADAPI 8 of 11,
MADSqlite3 26, MADTds 1, MADTdsClient 4 of 5, MADMySQL 18 of 19, MAD 150 of
181 — and their suites run under ctest: 114 executables (1098 tests), all
green, with 6 recorded needs, each being Apple-only machinery (Core Data, the
compiled model, `MADocument`, the converter) named in `Linux/README.md`. The
coverage master merged on 2026-10-10 (~100 Xcode test files) is ported in
full — 55 new executables, suite for suite — and the merge found two Apple-side
defects, both fixed and in `BUGS.md`: the framework targets had dropped
`$(inherited)` from their preprocessor defines (DEBUG was dead in every
framework Debug build), and MAD's document fixtures shared one store across
runs. A libraries
layer (`Linux/libraries.conf`, `Linux/lib/libraries.sh`) builds sqlite3,
openssl, freetds, zlib, bzip2, libarchive and mysqlclient natively into the
image (§7's C libraries; nothing ships). The long-tail items went the way §4
predicted — the `asl.h`/`vm_param.h` imports were vestigial, `copyfile(3)`
became POSIX, `CFHost` became `getaddrinfo`, the CF sites became a
`CFNumberGetValue` shim — and the UIKit/CoreGraphics tail is excluded
file-by-file with reasons, not ported (§5.2's disposition; `MADocument`, a
UIDocument, and `MADReportFormatter` wait for Phase D, which is the CLI's
problem as much as the platform's). MAD's suites found three more divergences,
all fixed or shimmed and written down in `Linux/README.md`: the runtime's BOOL
encoding (`'C'` off Apple), `class_getProperty()`'s missing superclass walk
(both fixed in `RptqObject`), and a stub `+propertyListWithStream:`
(shimmed). The test-coverage port added three more, likewise fixed or shimmed:
`NSOperation.asynchronous`/`-isConcurrent` (a Compat category — without it a
finishing async operation raised out of `-dealloc`), `-coordinateAccessWithIntents:`
(its GNUstep implementation faults; the Compat category calls the accessor on
the queue), and scheme-less URLs from `MADURLFactory` (now
`+fileURLWithPath:`, which un-parked five coordinator tests). One divergence stays pinned rather than fixed: GNUstep's
`-localizedCaseInsensitiveCompare:` is case-sensitive, so MADSqlite3's
registered collation orders text differently than on Apple. The live
`MADTdsClientLiveTests` suite runs green from inside
the image against the SQL Server container (29/29), so the driver path is
exercised on Linux, not just compiled. Phase D — the CLI and the data-path
verbs — is the next step and the go/no-go.

**Phase D status (2026-10-16).** The checkpoint is met: `mad` builds inside the
image from `CLI/Source` (the same sources the iOS-Simulator tool is built from),
links the ten frameworks, and runs the data path there. `inspect` reports both a
legacy v0 sample and a portable v1 fixture; `schema` and `query` produce the same
answers as the Mac's tool (byte-identical for `schema`); `refresh` fills the row
cache on the Sqlite3 sample and is byte-identical to the Mac's cache when compared
by field name (76 rows, 21 columns); and against live servers from inside the
image, `mad refresh` pulled 50 rows from MySQL 8.4 (`employees`, a prepared-
statement fetch) and 20 from SQL Server 2022 (`AdventureWorksLT2022`, over
freetds). The live suites agree — `MADMySQLLiveTests` 44/44 and
`MADTdsClientLiveTests` 29/29 in the same image — and the ctest run is 117
executables, 1153 tests, 6 needs, all green.

Two things had to be settled to get there, both recorded in `Linux/README.md`:

1. **The document question (§5.1, §9 Phase D).** `MADocument` is a `UIDocument`,
   so it cannot come along. The user's choice (2026-10-16) was a headless document
   path, not a `UIDocument` shim in `Compat` and not a split of `MADocument`: the
   data half of a document is now a protocol, `MADDocumentDataProtocol`, which
   `MADocument` conforms to (every member was already one of its accessors) and
   `MADHeadlessDocument` implements over the same `MADDocumentStore` the app's
   document uses. The refresh chain — moved into `MAD` with the driver registry
   (`ROADMAP.md` §3.4, §5.1) — takes the protocol, so both platforms run the same
   `MADOperationRefresh`; its one render-side branch is `#if __APPLE__`, and
   `mad export` (PDF, Core Graphics) stays on Apple, which is §5.2's staging.
2. **The driver registry (§3, §5.1).** The constructor no longer imports MySQL
   and TDS: each driver registers itself in `+load` and the constructor looks it up
   by type. On Linux the driver archives are whole-archived, because a driver's
   work is reached through *categories* and a category is a message send the
   linker cannot see — the CLI aborted on MySQL until that was fixed (§ the
   compat-archive note in `Linux/README.md`).

The GNUstep divergences the CLI added: the directory enumerator
(`-enumeratorAtURL:…` yields URLs with the containing directory stripped —
measured, and the CLI's member list uses `-subpathsAtPath:` instead), and the
SELECT-list column order, which was set order and therefore differed from Apple's
(same fields, same rows; noted in `Linux/README.md`). **Settled 2026-10-16**, with
the JSON export shape decision (§10.1 below): the order is defined as the column
alias in both SQL builders, so the generated SQL, the row cache and every export
agree on both platforms (BUGS.md, the SELECT-list entry; the order tests in
`Linux/Tests/MADQuerySelectExpressionTests.m`).

**Phase E status (2026-10-16, first half).** The export seam is real and the
Foundation formats run here. `MADReportExporting` + `MADReportExporterRegistry` are
the driver registry's shape (an implementation protocol, `+load` registration, a
lookup by name), and `mad export` picks a format through them, so a new format is a
new class (`MAD_CLI.md` §5.3, ROADMAP.md §5.2). `text`, `csv` and `json` are pure
Foundation and produce **byte-identical output on Linux and on Apple** for the London
fixture — measured with `sha256sum` on the Mac's tool and the image's (§ the CLI
section of `Linux/README.md`; `Linux/Tests/MADReportExporterTests.m` pins the same
bytes with an FNV-1a checksum). The JSON shape is decided (§10.1): `json` is the data
contract — the query's columns in alias order, the rows, the SQL, the driver — and
`json-report` is the same document with the rendered report's sections as an extra
member, the user's choice on 2026-10-16: pages, sections in draw order, and each
line's kind, frame and resolved text, built from the renderer's own page walk with
nothing drawn — so it cannot drift from what a PDF shows. It needs the render half,
so it registers everywhere and reports why it cannot run here. That walk is
`MADPrintPageRenderer -buildPageAtIndex:context:inPageRect:`, which takes a nullable
context: the PDF path passes its own and draws as before, and json-report passes NULL;
the render half's first protocol, `MADDocumentRenderProtocol`, is what the format asks
the document for. The remaining half of Phase E — the report member on Linux and
HTML/SVG — is the render half's move to Linux, which the user's renderer decision
(HTML/SVG next, PDF last, §10.2) puts on the HTML step. `pdf` is still the CLI's own
arm; it becomes an exporter with that same step.

---

**Phase E status (2026-10-16, second half: the writer).** The `.mad` writer runs on
Linux and both platforms write the same bytes.  `MADArchiveManager.reproducible` is the
opt-in mode the user chose (fixed time 2001-01-12T00:00:00Z, uid/gid 0, sorted member
walk; ordinary saves keep the filesystem's metadata), `MADHeadlessDocument` grew
`-writeToURL:reproducible:error:` (the app's save without the UIDocument parts), and
`mad write` is the verb that reaches it on both platforms.  Measured: the London
fixture written on the Mac and in the image is the same 16,243-byte file, sha256
`22dd3123…`; `Linux/Tests/MADArchiveManagerTests.m` pins the bytes, the round trip and
the mode.  Two Linux-only defects were in the way and are fixed (`BUGS.md`, the
byte-identity entry): the walk that never terminated, and `dirname(3)`/`basename(3)`
truncating the caller's archive path on glibc.  What the comparison covers is the
container: the members are the fixture's own bytes.  A Linux writer that *creates* a
store extends it to the store layer.

**Phase E status (2026-10-16, third part: the render half, and HTML).** The render
half moved to Linux, and it moved as a conformance rather than a fork.  The user's
answer on the shape was "one formatter, not two paths, and they should render the
same", so:

* `MADReportFormatter` takes `id <MADDocumentRenderProtocol>`; the protocol grew the
  four members the formatter reads (`filename`, `storeContext` — it used to ask for
  MADocument's `-managedObjectContext` — `database`, `resetSectionLayoutManagers`)
  and inherits the data, cache and report-data-source protocols the formatter assigns
  from the document.
* The page walk moved out of `MADPrintPageRenderer` into `MADReportPageBuilder`, a
  plain Foundation class: the same read transaction per page, the same element
  references, the same one line representation per element, with the drawing now a
  block the caller passes (the renderer passes one that draws; the formats pass none).
  The builder also owns the render side's geometry (US Letter, the 1pt trim) and the
  preparation sequence (sort the rows, size the formatter, format), which were copied
  in the CLI's PDF arm and json-report.
* `MADDocumentRenderDataSource` is the one implementation of the render half's reads —
  `MADPrintPageRendererDataSourceProtocol` and `MADReportFormatterDataSource` over a
  document — and both `MADocument` and `MADHeadlessDocument` answer by asking it.  The
  bodies are MADocument's, moved; the app's pages read exactly what they read before.
* `MADHeadlessDocument` conforms to `MADDocumentRenderProtocol`, so a document with no
  window now formats and walks.  `MADOperationRefreshInitialize`'s render branch keys
  on the protocol instead of on `[doc isKindOfClass: [MADocument class]]`.
* The element family compiles headless: `MADPrintPageElement`'s initialisers are
  Foundation (the text is resolved there), and only the `-drawInRect:` bodies and the
  image's `UIImage` are `#if __APPLE__`.  `MADElementStylizedText` stays Apple's — it
  is drawing, not layout.

**Pagination needs no text engine**, measured rather than assumed: a section's display
height comes from `MADSectionLayout` (stored rect + margin + padding + border), which
is in the Linux build and has been since Phase C, so the page breaks are the same
everywhere.  Text metrics enter only when an element is *drawn*, and the renderer
draws with `NSLineBreakByTruncatingTail` — one line, clipped — which CSS spells
`white-space: pre; overflow: hidden; text-overflow: ellipsis`.  Nothing wraps, so there
is no wrap model to port; no font engine was added.

**`mad export --format json-report` runs here**, on the same walk, and the frames it
reports are now *page* coordinates (the element's frame offset by its section), which
is what a renderer or a browser needs.

**Two new formats, both on both platforms** (the user chose both): `html` is the
facsimile — one CSS page box per walked page, every element absolutely positioned at
its frame with its resolved text and its stored font, size, traits and alignment; a
browser prints it to the same pages the PDF has.  `html-flow` is the same report
reflowable — `<section>`s, a `<table>` per section, one `<td>` per element, the page
furniture emitted once; a reading view, while `--format json` stays the data contract.
Both are one UTF-8 file with an embedded `<style>` and no script; the facsimile's CSS
is the 20 lines above plus a positioning rule, and the flow file's styles are a
generated class table (nine classes for the London fixture).

**`pdf` is on the seam**: `MADReportExporterPDF` registers everywhere, its body is
Apple's (Core Graphics + `MADPrintPageRenderer`), and off Apple it answers
`+isAvailable NO` with the reason.  The CLI has no local arms left.  The move is
byte-neutral: the deterministic export of the London sample is the same 43,177-byte,
5-page PDF before and after (`sha256 3eb2f1c4…` on both), measured by building the
previous commit's CLI and comparing.

**What the cross-platform comparison says.** The text of every line, every frame,
every font, the page count and the file structure are identical on Apple and Linux for
the London fixture — measured by diffing the two `html` files.  The one difference is
currency formatting: GNUstep's `NSNumberFormatterCurrencyStyle` renders no fraction
digits for any locale and puts a space after the symbol ("$ 0.99" where Apple writes
"$0.99"), so 180 lines differ by that one space.  The formatter was still improved:
it now takes the locale *and* the decimal count from the document's numeric format
(the store keeps both) instead of the process locale, which is what makes the two
platforms agree on everything except that space — and fixes a real defect in the
meantime (a document designed in one locale rendered in another).  Recorded in
`BUGS.md`; closing it means formatting money portably, which is its own piece of work.

## 10. Decisions for the user

1. **The JSON export shape** (`MAD_CLI.md` §8.3, `MAD_FUTURE.md` §10.5) — this is
   the Python contract; decide it first, because everything in §2 hangs off it.
   **Decided 2026-10-16: both, the report half as its own format.** `--format json`
   is the data contract — an envelope (format id, document/driver, the SQL, the row
   count), `columns` (key, name, table, type), and `rows` as one object per row with
   JSON-typed values — and `--format json-report` is that document plus a `report`
   member (the rendered sections). With it, the SELECT list's order is defined as the
   column alias, sorted, so the generated SQL, the row cache and every export agree on
   both platforms (BUGS.md, the SELECT-list entry — previously set order). The data
   half is built (`MADReportExporterJSON`, both platforms); the report member waits
   for the render half.
2. **Renderer staging** — HTML/SVG first, PDF last, or macOS-side PDF workers?
   **Decided 2026-10-16: HTML/SVG next, PDF last.** No Linux PDF renderer and no
   macOS-side workers: the HTML step is also where the render half
   (`MADReportFormatter`) moves to Linux, which `json-report` and testing want too.
   `pdf` stays the CLI's Apple-side arm until then.
   **Done 2026-10-16 (the HTML step).** The render half is on Linux and `mad export`
   has no local arms: `pdf` is a registered exporter whose body is Apple's, and it
   says why off Apple.  The user's further decision the same day: the Linux PDF writer
   is the *next* step, not part of this one, because the HTML facsimile's page boxes are
   the geometry a Linux writer has to reproduce and make its test.  The writer's shape
   is recorded here for that step: **Cairo (drawing, PDF surface) + Pango (layout,
   wrapping) + FreeType/HarfBuzz**, the stack GTK/WebKit/Firefox use and the closest
   Linux has to Core Graphics + Core Text — C APIs called from Objective-C the way
   freetds and sqlite3 already are, so no Impl wrapper is needed.  Licences: Cairo
   LGPL-2.1/MPL-1.1 dual, Pango LGPL-2.1, HarfBuzz MIT, FreeType FTL/GPLv2-dual; the
   project already ships LGPL (FreeTDS, `LICENSE_COMPLIANCE_PLAN.md` §4) and the Linux
   image is a server build, so it is a known class of obligation.  `libharu` is the
   permissive alternative but has no layout engine; Skia is the closest in capability
   but a heavy C++ build.  **Not achievable: byte-identical PDFs across platforms** —
   Core Graphics' writer cannot be reproduced — so the target is the same pages, boxes,
   text and fonts, with metric-compatible substitutes for Apple's fonts
   (`MADFont`'s default family is Helvetica Neue, which Linux does not have).
3. **mysqlclient → MariaDB Connector/C timing** — the GPL blocker gates any shipped
   binary; the replacement is already named in `LICENSE_COMPLIANCE_PLAN.md`.
4. **Toolchain policy** — source-built clang/libobjc2/GNUstep (needed for ARC) is a
   maintenance commitment; accept it or stay on macOS hosts.
5. **The rewrite trigger** — phase D of §9 is the measurable checkpoint; until it
   fails, the recommendation stands: one Objective-C engine, called from Python
   across the CLI boundary.
6. **The build baseline** — Docker on a Debian-stable or Ubuntu-LTS base, built on
   Linux rather than cross-compiled from macOS (§8.1). The choice sets the supported
   glibc floor, so make it once and deliberately.
