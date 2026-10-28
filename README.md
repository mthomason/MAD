# MAD (Mobile Analytics Document)

**A report is a file.**

MAD is a mobile analytic document designer: the **MAD Designer** app, where a
report is built, the **MAD Viewer** app, where it is read, and the portable
report-definition format plus the engine that renders it. A `.mad` document
holds the whole report — the query, its tables and joins, and the layout of
its elements — in one small file (under 100 KB), separate from the data it
displays. Anyone who can read the file can run the report, refresh it against
the database, and export it.

The repository is one self-contained project: the iPad/iPhone apps, fourteen
frameworks, the headless engine with its Linux build and test suite, the `mad`
command-line tool, and the build system that produces the third-party
libraries. It is published under the MIT licence; the `.mad` format is an open
specification (see [`docs/`](docs/)), though the project's names and app
artwork are not covered by the licence grant (see [`NOTICE`](NOTICE)).

## Why MAD

The engine is written by hand for the device it runs on:

* **Written, not assembled.** The SQL generation, the data-table engine, the
  store, the layout model, and the renderer are first-party Objective-C
  across the fourteen frameworks. Third-party code is limited to the wire --
  MariaDB Connector/C, FreeTDS, libpq, and SQLite -- plus the barcode library.
  No reporting SDK is being resold.
* **Mobile-first means memory-budgeted.** A refresh reads the result set
  once into a SQLite row cache and computes from there, so aggregates and
  paginated rendering stay fast within a phone's memory. The definition is
  the cheap part: a `.mad` is under 100 KB.
* **No reporting server required.** The definition travels and the device
  runs it -- native on Apple silicon, no tracking, no account. The headless
  half of the same stack compiles on Linux and passes 1,303 tests in Docker.

The technical documentation is also served as a website at
<https://docs.everydayapps.com>.

[![Linux verification](https://github.com/mthomason/MAD/actions/workflows/linux.yml/badge.svg)](https://github.com/mthomason/MAD/actions/workflows/linux.yml)

## See it

MAD Designer, from choosing a data source to reading the finished report in
MAD Viewer (28 seconds; [video](https://docs.everydayapps.com/assets/app-preview.mp4)):

[![MAD Designer app preview](docs/assets/app-preview-poster.png)](https://docs.everydayapps.com/assets/app-preview.mp4)

The same engine headless: `inspect`, `schema`, `query`, `refresh`, and
`export` through the `mad` CLI, with no database server and no credentials:

![The mad CLI inspecting, querying, refreshing and exporting a .mad document](docs/assets/mad-cli-demo.gif)

The recording's [exported report](https://docs.everydayapps.com/assets/london.html)
is plain HTML, opened in any browser.

## Try it

The headless engine runs the `mad` CLI in Docker. Pull the published image
and inspect one of the checked-in sample documents:

```sh
docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro ghcr.io/mthomason/mad \
    mad inspect /docs/London.portable.mad
```

Every verb works the same way — `schema`, `refresh`, `export` (HTML paged and
flow, text, CSV, JSON data and report; PDF refused on Linux by design for
now):

```sh
docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro ghcr.io/mthomason/mad \
    mad refresh /docs/Music.portable.mad
docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro -v "$PWD/out":/out ghcr.io/mthomason/mad \
    mad export /docs/London.portable.mad --format html --out /out/london.html
```

The published tags are `latest` and the commit's short SHA, built for
linux/amd64 by the publish workflow on every push to master. On Apple
silicon add `--platform linux/amd64` — Docker Desktop runs the tag under
emulation, and without the flag the pull fails (`no matching manifest`).
Building the image locally instead — a native arm64 `mad-cli:latest` — is
one command:

```sh
./Linux/build.sh --verify                 # build the toolchain and run the checks (~20 min first time)
```

The sample documents refresh against the Sqlite3 sample database that ships
inside the image; the MySQL, SQL Server, and PostgreSQL fixtures expect the
test servers from [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md).

## In CI

The [mad-action](https://github.com/mthomason/mad-action) GitHub Action runs a
checked-in `.mad` in a workflow and uploads its export as an artifact:

```yaml
- uses: mthomason/mad-action@v1
  with:
    command: export
    document: reports/sales.mad
```

It runs the published image, so the action and the CLI are the same engine.
The action is generated from [`satellites/mad-action/`](satellites/mad-action/)
here; [`docs/project/SATELLITE_REPOS.md`](docs/project/SATELLITE_REPOS.md)
records how the satellite is kept current.

## The `.mad` format

A `.mad` file is a bzip2-compressed tar archive holding the report's
*definition*: the query, its tables and joins, the report's sections and
elements, and the database schema snapshot. The row data a report displays is
**not** in the document — it is a derived cache, regenerated on refresh, and
deliberately kept outside the file. The format is fully specified in
[`docs/`](docs/): what ships today, the normative `v1` target, and the hazards
a second reader must handle. Both shipping samples are under 80 KB.

Where the format is designed to go -- a report's result table becoming a data
source for other reports, so one document can span several databases -- is
[`docs/vision.md`](docs/vision.md).

## Database drivers

MAD talks to databases through `MADDatabase` subclasses. Four drivers ship
today:

* **MySQL / MariaDB** — `MADMySQL`, over MariaDB Connector/C;
* **SQL Server** — `MADTdsClient`, over FreeTDS;
* **PostgreSQL** — `MADPostgres`, over `libpq`;
* **SQLite** — `MADSqlite3`, for sample documents and internal tables.

A driver is a framework that subclasses `MADDatabase` and registers itself —
the query designer and the engine never see the wire protocol. Writing one is
the intended first contribution (see the driver-authoring tutorial under
[`docs/tutorials/driver-authoring.md`](docs/tutorials/driver-authoring.md)).
The seam is real: the query designer auto-generates the SQL, so a user designs
a report without writing a statement, and the driver only has to execute it
and return rows.

## Embedding the engine

Eleven of the fourteen frameworks are UIKit-free and build headlessly. The `mad`
CLI above is that engine wearing a command line: the verb set -- `inspect`,
`schema`, `refresh`, `export` -- is the embedding surface, and an application
that links `MAD`, a driver framework, and `MADSqlite3` has reporting with no
server in the loop. Drivers register themselves, so adding a data source is a
subclass, not a fork (see
[`docs/tutorials/driver-authoring.md`](docs/tutorials/driver-authoring.md)).

## Build and test

The iOS side is a workspace of fourteen frameworks plus the apps. Run a
framework's suite against the iOS Simulator:

```sh
xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
	-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
```

(`MADMySQL`, `MADTdsClient`, and `MADPostgres` also carry live suites that talk
to a real database server and skip when one is not reachable — see
[`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md).)

The headless engine is verified the same way on Linux. From the repository
root, with Docker installed:

```sh
./Linux/build.sh       # build the toolchain image, compile the eleven frameworks, run the suites
```

This runs 126 test executables and 1,303 tests inside the container, and
`--verify` adds the CLI's end-to-end checks against the checked-in fixtures
and their pinned digests. See [`Linux/README.md`](Linux/README.md) for the
image, the pins, and the GNUstep divergences the port found.

## Support

MAD is free software and stays free. One maintainer keeps it: the design
documents, the two-platform test matrix, and the agent-driven development all
run on real time and API tokens. If MAD saves your team time, here is how to
give some of it back — and thank you either way:

* **[Sponsor the maintainer](https://github.com/sponsors/mthomason)** —
  one-time or monthly, GitHub Sponsors.
* **Send API credits.** The project is developed with AI agents; OpenAI,
  Anthropic, or agent-token credits go straight back into the work. Get in
  touch through the sponsor page or an issue.
* **[Contribute](CONTRIBUTING.md).** A database driver, a document element,
  an export format, or a fix — the seams are the point.

## Licence

MIT — see [`LICENSE`](LICENSE). The licence covers the software; the names
"MAD", "MAD Designer" and "MAD Viewer", the app icons and other product
artwork, and the app preview media are the author's and are excluded from it
(see [`NOTICE`](NOTICE)). Every third-party component, its licence, and what
shipping it obliges us to do is recorded in
[`docs/project/THIRD_PARTY_LICENSES.md`](docs/project/THIRD_PARTY_LICENSES.md).

## Export compliance

The MySQL, FreeTDS, and PostgreSQL drivers use OpenSSL/TLS; no custom
encryption is implemented. Under Apple's export compliance guidelines this is
exempt encryption, and the app sets `ITSAppUsesNonExemptEncryption = NO`.
