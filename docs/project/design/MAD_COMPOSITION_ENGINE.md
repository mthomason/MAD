---
layout: default
title: "Composite reports — engine generalization brief"
description: "The scoped engine change that replaces the two-input composition special case with the general N-node graph."
---

# Composite reports — engine generalization brief

**Target:** [`MAD_COMPOSITION_SPEC.md`](MAD_COMPOSITION_SPEC.md) is the contract this work
must satisfy — read it first; its §7 is the acceptance checklist. This brief scopes the
engine, store, and serve change. The authoring UI implementation and the cross-document
reference model are out of scope here, but the engine must support the final **node-as-report**
decision (spec §0) — see Change 4.

## What is already correct and must not change

- Store revision 3 (`RptqQuery.name`, `RptqDocument.rootQuery`, `RptqQueryTable.upstreamQuery`,
  `outputIndex`/`outputKey`) and the container 1.1 + capability record. **No format change is
  needed for the N-node execution change.** Change 4 (per-node layouts) does require a store
  revision; it is additive to this baseline.
- `outputKey` column identity and `<child-alias>.<outputKey>` → physical-column resolution.
- `MADDatabaseSqlite3 -attachReadOnlyDatabaseAtURL:asName:error:` — read-only attach, URI
  encoding, alias quoting, `LSASC` registration. Reuse as-is.
- Per-source connection/dialect/credential resolution (the `planForSource` logic in
  `MADOperationRefreshComposed`).
- Cycle / missing-reference validation (`RptqDocument -validateCompositionGraphWithError:`).
- Generation-pinned render/export, publish-once, failed-refresh-leaves-previous-result.

## The current special case to replace

- `MADComposer.m` string-generates a **two-input** join over `src0`/`src1` and `att0`/`att1`
  (`MADComposer.m:151-192`). It is not a general query.
- `MADOperationRefreshComposed` (`MADOperationRefresh.m:334-683`) hardcodes two sources:
  `hasQueryLinks.anyObject` (`:379`), left/right extraction (`:388-389`), and a two-step
  serial refresh (`:563-566`).

## Change 1 — topological walk over N nodes

In `MADOperationRefreshComposed`, replace the two-source path with a walk:

1. From `rootQuery`, collect every reachable node by following `upstreamQuery` edges.
2. Topologically order them — children before parents, root last. The cycle check already
   rejects cycles; a topological sort (`MTGraph` in `MADDataStructures`) produces the order.
3. Execute each node once, in order, keeping each node's published `MADDataResult` in a map
   keyed by node id until every parent that needs it has run, then discard it.

A leaf runs the existing remote-refresh path. A composing node (including a composing child)
runs Change 2 against its children's results. A node shared by two parents executes once and
its result is reused (diamond DAG).

## Change 2 — compile the composing root as a general query

The compiler already builds an arbitrary N-way FROM/JOIN from the query graph
(`MADQueryFull.m`). The only missing piece is **resolution**: when a `RptqQueryTable` has an
`upstreamQuery`, its table and fields must resolve to the attached child
(`<attach-alias>.<physical-column>`) instead of `<alias>.<remote-table>`. Add that resolver to
`MADQueryFull` (or a thin composing adapter over it) and compile the root against the local
SQLite connection that has its children attached. Delete the string-generated `MADComposer`
join — do not keep a second SQL path. The composer's physical-name helpers
(`physicalColumnForKey:inInput:`, `dataTypeForKey:`) fold into that resolver.

§7.1 is the hard requirement: a composing node is a general query — N children, joins,
filters, groupings — through this one compiler.

## Change 3 — attach N children read-only

Give the composing connection one read-only attach alias per child (bounded, generated
aliases) and resolve each child reference to `<alias>.<physical>`. More than
`SQLITE_MAX_ATTACHED` (10) direct children is a design-time error naming the node.

## Change 4 — every node is a report (final decision, spec §0)

The node-as-report decision is part of the engine target, not a later option. The execution
walk above is unchanged; what changes is what a node owns and what the read paths address.

1. **Store.** Give every `RptqQuery` its own layout: the five document sections move under a
   node, or a section gains an owning query. Migrate the current document sections onto the
   root, and create them when a source query is created or imported. This is a store revision
   (see [`MAD_STORE_MIGRATION.md`](MAD_STORE_MIGRATION.md)); the container already carries the
   capability record.
2. **Import.** `importQueryGraphFromContext:` copies the source's layout entities as well as
   its query graph, remapping field references. An imported report keeps its report.
3. **Serve.** `layout-model` and every layout mutation take the same optional `query` as the
   query-model methods; without it they resolve the root. A query-scoped result read (rows, or
   an `export` variant) reads the selected node's published table. `describe` is scoped the
   same way.
4. **Read paths.** Viewer, export, and print take a node, defaulting to the root. A node with
   no layout falls back to a row grid; its data still exists because every node materializes.

Scope and acceptance criteria live in
[`MAD_COMPOSITION_NODE_VIEW.md`](MAD_COMPOSITION_NODE_VIEW.md).

## Tests to add (Apple + Linux mirror; Windows where the source list includes them)

- **3-leaf root** — three SQLite sources, root joins all three; assert exact rows and column
  order.
- **Nested composer** — C1 = {A, B, R1}; C2 = {C1, D, R2}. Refreshing C2 runs A, B, R1, D, R2
  in that order.
- **Shared child (diamond)** — A used by two composing nodes; assert A runs once.
- **>10 direct children** — design-time error naming the node.
- Keep the existing two-input fixtures as regression, or migrate them to the general API and
  pin the same rows.

## Verification

`mad-verify` routes these: Apple `MAD` suite, the full `./Linux/build.sh`, and the Windows
source-list check. `MADComposer.m` and `MADOperationRefresh.m` compile headless, so the Linux
`MADQueryFullTests` / `MADReportExporterTests` mirrors apply. Any new `.m` file must be added
to both `Linux/cmake/MADSources.cmake` and `Windows/Engine/cmake/MADSources.cmake` (the
`check_source_lists.py` gate).

## Out of scope for this brief

The authoring-UI implementation (the "combine" flow, an N-source picker, the Columns popover
generalization), the iOS/WPF/macOS surface changes, cross-document references, and the
still-open P4/P7/P8 follow-ups in `MAD_QUERY_COMPOSITION.md`.

Per-node report rendering is **not** deferred: Change 4 is the engine half, and the UI half
(selecting a node in every workspace, per-node Designer/Viewer, the row-grid fallback) is
scoped in [`MAD_COMPOSITION_NODE_VIEW.md`](MAD_COMPOSITION_NODE_VIEW.md).
