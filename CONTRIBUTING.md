# Contributing to MAD Designer

Thanks for being here. The project is a report *definition* engine — one
`.mad` file holds a whole report, and the engine renders it — and the seams
for new work are the point: a new database driver, a new document element, a
new export format. The driver-authoring tutorial
([`docs/tutorials/driver-authoring.md`](docs/tutorials/driver-authoring.md))
walks through the first one; it is the intended first contribution.

## Prerequisites

* **macOS with Xcode** — the iOS side is a workspace of thirteen frameworks
  plus the app, built for iOS 15 and later. The frameworks are Objective-C.
* **Docker** — the headless engine's Linux build: one image that source-builds
  the Objective-C toolchain (libobjc2, libdispatch, GNUstep) and the C
  libraries, compiles the ten headless frameworks, and runs their suites.
* No database server is needed to contribute: the live MySQL and SQL Server
  suites skip when no server is reachable, and `DEVELOPER.md` documents the
  Docker containers that supply them.

## Getting started

1. Fork the repository and clone your fork.
2. Build and test before you change anything, so you know the baseline:

   ```sh
   # iOS: any framework's suite, against the iOS Simulator
   xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
       -destination 'platform=iOS Simulator,id=<device-udid>' \
       -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-shared
   ```

   ```sh
   # Linux: the whole headless engine — 123 test executables, 1,262 tests
   ./Linux/build.sh
   ```

   `DEVELOPER.md` has the full command matrix, the shared DerivedData path the
   frameworks expect, and the test-database setup.
3. Pick something. A new driver, an element, or an issue labelled
   "good first issue". Small is good: the review culture here is exact.

## The test-first rule

**Write the failing test first.** This is the project's culture, not a
suggestion: the test pins the behaviour before the code exists, and the fix is
the change that turns it green. For format or data work, snapshot the
pre-change fixture rather than generating the expected value with new code —
the fixture is the witness that the behaviour was real.

The loop, in order:

1. Add a failing test that states the behaviour you intend.
2. Run it; watch it fail for the right reason.
3. Implement, then make it green.
4. Run the whole suite — iOS *and* `./Linux/build.sh` if you touched anything
   the Linux build compiles (see `Linux/cmake/*Sources.cmake`). Every commit
   must leave every suite green.

The Linux suites record known platform divergences as `NEED` lines rather than
silently skipping them — a new `NEED` must carry a reason, and a divergence
that isn't either fixed or recorded is a failing change.

## Style

* Tabs, not spaces. Comments where they earn their place, not everywhere.
* Deliberately-unused code is marked with the clang `unused` attribute at the
  declaration — an unmarked unused warning means the code is dead.
* New files carry the one-line header, `Copyright © 2012-2026 Michael
  Thomason. SPDX-License-Identifier: MIT` (`//` for source, `#` for scripts).
* `BUGS.md` records open defects with the tests that pin them; when you fix
  one, the entry moves to `BUGS_FIXED.md` — a fix that isn't recorded didn't
  happen.

## Developer Certificate of Origin

This project requires a DCO sign-off instead of a CLA. Every commit must end
with:

    Signed-off-by: Name <email>

(`git commit -s` adds it.) By adding the line you certify, under
[developercertificate.org](https://developercertificate.org), that you wrote
the change or have the right to contribute it under the project's licence
(MIT, see `LICENSE`). The DCO check runs on the pull requests once the
repository is published on GitHub.

## Pull requests

* One concern per PR. Keep the commits reviewable; the project's history is a
  record, not a scratchpad.
* Fill in the PR template — the test-first checklist is there for the
  reviewer, and "not applicable" answers are fine where they're true.
* A PR that touches the Linux build must show `./Linux/build.sh` green in its
  own branch.

## Issues

Bug report and driver-proposal templates are under
[`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/). Security issues go to
the private path in [`SECURITY.md`](SECURITY.md), never to a public issue.

## Help

Ask in an issue (or the discussions board once it opens). The maintainer
answers every issue; the project is a solo effort growing into a community,
so a clear question that shows what you tried gets the fastest answer.
