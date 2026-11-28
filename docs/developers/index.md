---
layout: default
title: Developers
description: "Embed the MAD engine, use the mad CLI, read the data-object contract, and build the headless engine."
---

# Developers

MAD is an embedded relational reporting engine: a portable `.mad` document, a
first-party Objective-C engine, and a `mad` command-line tool that runs the same
engine headless on Linux and Windows. These pages are for people who want to
embed it, drive it from a script, add a data source, or build it from source.

## Start here

* [The `.mad` format specification](../README.html) — what a document is, the
  container, the store, and the normative `v1` target.
* [MAD Designer for macOS](../macos.html) — the native `AppKit` application.
* [MAD Designer for Windows](../windows.html) — the native WPF application.
* [Composition reports](../composition.html) — combine reports into one document;
  every source keeps its own query, layout, and data.
* [Vision](../vision.html) — reports as composable data sources.

## Engine and CLI

* [The `mad` command-line tool](cli.html) — open, inspect, query, refresh, and
  export a document without a UI.
* [The data object](data-object.html) — a report's definition, schema, and
  result set as one contract, and how composition realizes it.
* [Multi-source reports](multi-source.html) — reports as tables, and drivers
  for anything that returns a table; same-document composition is built.
* [Pasting SQL into the query designer](sql-entry.html) — the supported subset,
  the parser, and the apply path.

## Architecture

* [The MADDataTable architecture](architecture/data-table.html) — the
  data-table class cluster across the frameworks.
* [The MADModel layer](architecture/model-layer.html) — the document read-model
  over the `Rptq` entities.
* [MADArrayCaching](architecture/array-caching.html) — the render cache's
  disk-backed array.

## Build and test

* [Building the engine on Linux](build/linux.html) — the Docker build and the
  twelve headless frameworks.
* [Building the engine on Windows](build/windows.html) — the pinned Clang and
  GNUstep toolchain.
* [Portability and the native macOS application](build/macos.html) — the
  framework audit and the AppKit architecture.
* [The Compressor static-library build](build/libraries.html) — the third-party
  C libraries and how Xcode reaches them.
* [The headless PDF writer](build/pdf.html) — Cairo, FreeType, and
  deterministic export.

## Satellites and source

* [Satellite repositories](satellites.html) — how `mad-action` and the
  container image are published from this repository.
* [Source](https://github.com/mthomason/MAD) — the repository, issues, and the
  [contributing guide](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING.md).
