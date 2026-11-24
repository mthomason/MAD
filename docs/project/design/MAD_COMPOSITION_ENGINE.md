---
layout: default
title: "Composite reports — engine generalization brief"
description: "The scoped engine change that replaces the two-input composition special case with the general N-node graph."
---

# Composite reports — engine generalization brief

**Target:** [`MAD_COMPOSITION_SPEC.md`](MAD_COMPOSITION_SPEC.md) is the contract this work
must satisfy — read it first; its §7 is the acceptance checklist. This brief scopes the
engine change only. Authoring UI, iOS/WPF surfaces, and cross-document references are out of
scope here.

## What is already correct and must not change

- Store revision 3 (`RptqQuery.name`, `RptqDocument.rootQuery`, `RptqQueryTable.upstreamQuery`,
  `outputIndex`/`outputKey`) and the container 1.1 + capability record. **No format change.**
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

## Out of scope (later)

Authoring UI (the "combine" flow, an N-source picker, the Outputs popover generalization),
iOS/WPF surfaces, cross-document references, and the still-open P4/P7/P8 follow-ups in
`MAD_QUERY_COMPOSITION.md`.
