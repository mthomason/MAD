# Linux — the Phase B toolchain spike

`MAD_LINUX.md` §9 Phase B: *"a Dockerfile that source-builds clang + libobjc2 +
GNUstep Base; compile a MADFoundation subset — proves the environment and becomes
the build/CI image."* This directory is that spike.

It builds one image from Ubuntu 24.04 with the distro clang and source-built
libobjc2 2.3, libdispatch 6.1.3, gnustep-make 2.9.3 and gnustep-base 1.31.1,
compiles **23 of MADFoundation's 27 implementation files** (plus `madlib.c`)
against GNUstep, and runs **15 test executables** — 14 ported suites and the
toolchain probe — inside the container. Nothing here ships in the app.

## Running it

	./Linux/build.sh              build the image, run the tests, exit with the result
	./Linux/build.sh --test       run the tests in the existing image
	./Linux/build.sh --probe      run only the toolchain probe, with its report
	./Linux/build.sh --info       print clang and gnustep-config from the image
	./Linux/build.sh --shell      interactive shell in the build image
	./Linux/build.sh --toolchain  build only the toolchain image (the cache base)
	./Linux/build.sh --rebuild    rebuild without cache
	./Linux/build.sh --clean      remove both images

Docker Desktop's CLI is not on `PATH` by default; `build.sh` finds it at
`/Applications/Docker.app/Contents/Resources/bin` and puts it (and the credential
helper beside it) on `PATH` for the run. The first build takes roughly 15–25
minutes and produces a ~2.5 GB image; later runs are cached — only the source
layer rebuilds.

## Pins

`toolchain.conf` is the single place a component's version, source and hash is
written down, in the same shape as `Compressor/matrix.conf`. git sources pin the
release tag *and* the commit checked out; the GNUstep tarballs carry sha256
values computed from `ftp.gnustep.org` (upstream publishes only PGP signatures).

	libobjc2      2.3      v2.3                 (github.com/gnustep/libobjc2)
	libdispatch   6.1.3    swift-6.1.3-RELEASE  (github.com/apple/swift-corelibs-libdispatch)
	gnustep-make  2.9.3    ftp.gnustep.org tarball
	gnustep-base  1.31.1   ftp.gnustep.org tarball

The library-combo is `ng-gnu-gnu` with runtime ABI `gnustep-2.2`, so everything
compiles with `-fobjc-runtime=gnustep-2.2` and ARC — the point of the spike.

## What compiles, and what does not

Compiled: the operation cluster (MADOperation, MADOperationQueue, MADGroupOperation,
MADBlockOperation, MADBlockObserver, the condition classes, MADExclusivityController,
MADNotificationProgress), the data classes (MADDataTable, MADDataTableVirtual,
MADDataColumn), MADCredential, MADDataType, MADProgress, MADStringUtilities,
NSData+Comparison, NSOperation+Advanced, madlog and madlib.

Excluded, all because their dependencies are Phase C work: `BDHost` (CFNetwork),
`MADApplication` (UIKit/AppKit), `MADKeyChain` (Security), `MADURLFactory`
(app-group containers; `MADApplication.h` *and*
`-containerURLForSecurityApplicationGroupIdentifier:`, which GNUstep does not
implement), and the umbrella `MADFoundation.h`.

The Linux build supplies three things without touching the framework's structure:
an include shim so the 108 `<MADFoundation/…>` self-imports resolve; a prelude
header (`Compat/MADCompat.h`) that force-includes Foundation, dispatch and an
`NSOperation` `name` category (Apple has the property, GNUstep does not); and
whole-archive linking, Apple's `-ObjC`, without which the framework's categories
are silently dropped from the static archive.

The framework itself gained six small platform guards (all `#if __APPLE__` or
`TARGET_OS_MACCATALYST || TARGET_OS_IOS`, Apple paths textually unchanged):
`madlog.h/.m` grow a printf/syslog branch, `MADOperation.m` guards its
background-task code and its `qualityOfService`-based `userInitiated` accessors,
`MADDataColumn.m` guards its CFNumber boxing, `MADDataTable.m` its iOS-only file
protection option, `MADOperationConditionResult.m` its `QOS_CLASS_DEFAULT`
queue, `MADExclusivityController.m` its dispatch-object `description`, and four
vestigial `<os/log.h>` imports were deleted. The iOS simulator suite is the
proof those are behaviour-neutral: 118 tests, 0 failures.

## GNUstep divergences the probe and tests found

* **NSOperationQueue and KVO — found here, fixed in MADOperation.** GNUstep's
  `NSOperationQueue` removes its `"isReady"` observation on every notification
  it receives, and it checks `isReady` once more after registering that
  observation. MADOperation used to advance its state machine from inside
  `-isReady` itself (through the KVO dependent keys of `state`), so the first
  readiness check fired the notification the queue was waiting for, and the
  second call then removed an observation that was already gone —
  `NSInvalidArgumentException`, and the operation never ran. MADOperation now
  drives the advance explicitly (`-willEnqueue` starts condition evaluation)
  and sends `will`/`didChangeValueForKey:` for `isReady`, `isExecuting` and
  `isFinished` only when each value actually changes, so the queue sees one
  `isReady` notification per enqueue, the way Apple's does. The Linux tests
  assert this plainly on both platforms; nothing is silenced, and the Phase D
  refresh path is no longer blocked by it.
* **Secure-coding archiving is absent.** `archivedDataWithRootObject:
  requiringSecureCoding:YES` returns nil with no error;
  `requiringSecureCoding:NO` plus the classic `unarchiveObjectWithData:` round
  trips fine. Neither `unarchivedObjectOfClass:fromData:error:` nor
  `unarchiveTopLevelObjectWithData:error:` exists.
* **Smaller gaps, shimmed or guarded:** `NSOperation.name` (category shim),
  `NSOperation.qualityOfService` (guarded), `NSDataWritingFileProtection*`
  (guarded), `containerURLForSecurityApplicationGroupIdentifier:` (absent — the
  reason MADURLFactory is excluded), `QOS_CLASS_DEFAULT` from `<sys/qos.h>`
  (absent).
* **Verified good:** ARC and weak zeroing, blocks, exceptions, `@synchronized`,
  KVO (manual and dependent keys), `NSOperation` state-machine KVO,
  `NSPredicate predicateWithFormat:@"error != nil"` (MAD's exact predicate),
  dispatch (once/queues/groups/semaphores), the main queue draining under a plain
  executable, JSON, UUID, dates, plists, sort descriptors, streams and keyed
  archiving on the permissive path. The full report is what `--probe` prints; its
  19 core checks gate the exit code, its 10 report items do not.

## Licences

Everything in the image is build tooling; nothing is linked into the app.
libobjc2 is MIT; libdispatch is Apache-2.0 with the Swift runtime exception;
GNUstep Base is LGPL-2.1-or-later; gnustep-make is GPL-3.0-or-later, and its
`Testing.h` (GPL-3.0-or-later) is compiled into the Linux test binaries — those
exist only inside this build image. Register entries in
`THIRD_PARTY_LICENSES.md`/`LICENSE_COMPLIANCE_PLAN.md` are Phase F work, at the
moment an image ships; `TASKS.md` §10 carries the flag.

## What this does not do yet

Phases C–F of `MAD_LINUX.md`: the rest of the §4 shim list (the CF sites,
CFNetwork, the remaining `madlog.h` copies), the CLI on Linux (the Phase D
checkpoint), export formats, the Compressor Linux driver and the CI row.
