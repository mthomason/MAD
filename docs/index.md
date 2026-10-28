---
title: MAD — Mobile Analytics Document
---

**A report is a file.**

MAD is an embedded reporting platform: the **MAD Designer** and **MAD
Viewer** apps for iOS, the headless engine that runs them, and the open
`.mad` document format. A `.mad` file holds a report's whole definition --
the query, its tables and joins, and the layout of its elements -- in under
100 KB. Anyone who can read the file can run the report against the
database and export it.

The code is at
[github.com/mthomason/MAD](https://github.com/mthomason/MAD), MIT-licensed;
the names and app artwork are not covered by that licence (see
[NOTICE](https://github.com/mthomason/MAD/blob/master/NOTICE)).

## See it

MAD Designer, from choosing a data source to reading the finished report in
MAD Viewer:

<video controls playsinline preload="metadata" width="360"
  poster="assets/app-preview-poster.png">
  <source src="assets/app-preview.mp4" type="video/mp4">
  Your browser does not support the video element; the
  <a href="assets/app-preview.mp4">app preview</a> is a plain MP4.
</video>

The same engine headless: `inspect`, `schema`, `query`, `refresh`, and
`export` through the `mad` CLI, with no database server and no credentials:

![The mad CLI inspecting, querying, refreshing and exporting a .mad document](assets/mad-cli-demo.gif)

The recording's [exported report](assets/london.html) is plain HTML, opened in
any browser.

## Why MAD

* **Written, not assembled.** The SQL generation, the data-table engine,
  the store, the layout model, and the renderer are first-party
  Objective-C across fourteen frameworks. Third-party code is limited to
  the wire -- MariaDB Connector/C, FreeTDS, libpq, SQLite -- and the barcode
  library. No reporting SDK is being resold.
* **Mobile-first, memory-budgeted.** A refresh reads the result set once
  into a SQLite row cache and computes from there, so aggregates and
  paginated rendering stay fast within a phone's memory.
* **Embeddable.** Eleven of the fourteen frameworks are UIKit-free and build
  headlessly. The `mad` CLI exposes the engine as verbs -- `inspect`,
  `schema`, `refresh`, `export` -- and drivers register themselves, so a
  new data source is a subclass, not a fork.
* **Portable.** The `.mad` container is a bzip2 tar archive holding a
  portable SQLite store; no Apple framework is required to open it. The
  headless build passes 1,303 tests on Linux, in Docker.

## The `.mad` format

The open specification, one chapter per file:

[What a document is](01-document.html) ·
[The container](02-container.html) ·
[The store](03-store.html) ·
[Reading and writing](04-reading-writing.html) ·
[Companion files](05-companion-files.html) ·
[Hazards](06-hazards.html) ·
[Normative `v1`](07-normative.html) ·
[Open questions](08-open-questions.html) ·
[Verification](09-verification.html)

## Using the engine

* [Build and test](https://github.com/mthomason/MAD#build-and-test) --
  the exact commands for the iOS suites and the Linux build.
* [The `mad` CLI](https://github.com/mthomason/MAD#try-it) -- inspect,
  refresh, and export a `.mad` from Docker in one line.
* [mad-action](https://github.com/mthomason/mad-action) -- run a checked-in
  `.mad` in GitHub Actions and upload its export; `mthomason/mad-action@v1`.
* [Driver-authoring tutorial](tutorials/driver-authoring.html) -- the
  intended first contribution: subclass `MADDatabase`, register the
  driver, return rows.

## The direction

[Vision](vision.html) -- a report's result table becomes a data source
for other reports, so one document can span several databases.

---

The **MAD Designer** app -- the report designer built on this engine -- has
its own site at [mad.everydayapps.com](https://mad.everydayapps.com/).
