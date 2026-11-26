---
layout: default
title: "Composite reports — the execution model"
description: "The normative contract for composite (multi-source) reports: a DAG of reports, children before parents, root last, every node a table and a report with its own layout."
---

# Composite reports — the execution model

**Status: normative.** This is the contract every composite-report implementation must
satisfy. Read this first. `MAD_QUERY_COMPOSITION.md` is the implementation plan and progress
record against it; the older design records ([`multi-source.md`](../../developers/multi-source.html),
[`data-object.md`](../../developers/data-object.html), [`vision.md`](../../vision.html)) record the
direction and rationale and are superseded by this file wherever they differ.

## 0. Decision record — a node is a report (final, 2026-11-26)

**This decision is final.** It supersedes every earlier statement that only the root is a
report — including the root-only wording in
[`multi-source.md`](../../developers/multi-source.html) §3.2 and the "independently rendered
subreports are deferred" line in `MAD_QUERY_COMPOSITION.md`. Do not reopen it as a design
question; the remaining work is implementation, not a choice.

Every node in a composite report — leaf or composing — is a **complete report**:

- its query definition, with its own database and credentials (leaf) or its child references
  (composing);
- its own materialized result table (already true; §2);
- its **own report layout** — the bands, rows, elements, and field bindings the Designer edits
  and the Viewer renders.

The **root** is the document's **default node**: the report the Viewer opens first, the one
print and export use when the user does not choose another, and the one `rootQuery` identifies.
It is not the only node that can be designed, viewed, printed, or exported.

Combining reports carries each child's layout with it. A child report is not reduced to a
table when it is imported: its definition, its layout, and its data-producing query come along,
and they are saved in the same `.mad` document. "Its data" means the node's result set,
materialized on refresh exactly like the root's; rows stay in companion storage and are not
embedded in the `.mad` (unchanged from a Standard Report).

**Consequences — these are requirements, not options:**

1. The store associates a layout with each node, not only with the document (a store
   revision; see §8 and `MAD_STORE_MIGRATION.md`).
2. `importQueryGraphFromContext:` copies the source's layout entities as well as its query
   graph, remapping field references.
3. `layout-model` and every layout mutation are query-scoped. The refresh walk already runs
   every node; each node's materialized table is readable for the Viewer.
4. A node with no layout (a query-only source) is still viewable as a table of rows. The
   Designer offers to author a layout for it.
5. The UI presents the graph as a set of reports. Selecting a node selects its query, its
   layout, and its rows in **every** workspace — Query, Designer, and Viewer.

The engine, store, import, and serve work is scoped in
[`MAD_COMPOSITION_NODE_VIEW.md`](MAD_COMPOSITION_NODE_VIEW.md). Until it lands, the Windows
Designer and Viewer temporarily show the Result and display a notice saying so; that is an
interim state, **not** the contract.

## 1. What a composite report is

A **composite report** is a directed acyclic graph of **queries**. Each node in the graph is
one query definition (`RptqQuery`) and produces exactly one materialized table. The graph has
one designated **root** (`RptqDocument.rootQuery`); the root is the document's **default
report and default output**. Every node materializes a table, and every node is itself a
report with its own layout (§0).

A node's query is one of two kinds:

- **Leaf.** Its tables are remote schema tables, and it owns one `RptqDatabase` (driver,
  connection, credentials). It is executed against that remote source — SQLite, MySQL,
  SQL Server, or PostgreSQL.
- **Composing.** Its tables are the outputs of other nodes (its children). It is executed
  against a local SQLite connection with each child's table attached. It references only
  children — never a remote table — because `ATTACH DATABASE` exists only inside SQLite, and
  because one rule ("a composing node's tables are its children") is simpler to build and to
  understand.

A composite report is **self-contained and portable**: every node's definition, layout, and
connection references live inside the one `.mad` file — the composite is a container for the
child reports it combines, not just their tables. A user does not design the whole graph up
front. The children start as ordinary reports; "combine" is how they are later brought
together into one composite `.mad` **with their layouts**.

"Data object" and "sub-report" in the older docs both mean **node**.

## 2. The invariant — the one fact everything else follows from

> **The output of every node — leaf or composing — is one ordinary materialized SQLite
> table (`.maddb` rows + `.mdcache` column map), identical in form to every other node's
> output.**

Because a composing node's output is itself an ordinary table, a composing node can be the
child of a higher composing node, to any depth. The graph is a DAG, not a tree: two nodes may
share one child, and that child is executed once.

For the same reason a whole composite report can be the child of another composite. Being
"the child" means its **graph comes along** — its leaves and its root join the parent's graph
— and the parent's composing node references the child composite's *root* output. It is not
wrapped as one opaque node.

## 3. Execution contract

On refresh the engine runs the graph **topologically**:

1. Walk from the root to the leaves. A cycle is a design-time error that names the offending
   node (already enforced by `validateCompositionGraphWithError:`).
2. Run every node exactly once, in order: **every child before its parents; the root last.**
3. For each node, in order:
   - **Leaf** — compile its query with its own dialect, execute it against its own remote
     source with its own credentials, and materialize the result into a fresh table.
   - **Composing** — `ATTACH` each child's `.maddb` read-only into one local SQLite
     connection, compile the node's **own query** (its children are the tables; its joins,
     filters, and groupings apply as usual) against that connection, execute it, and
     materialize the result into a fresh table. A child's table exists because the child ran
     earlier in the walk.
4. Every node's table is published. The viewer, export, and print paths consume the
   **selected** node's table, defaulting to the root (§0). A node with no layout is still
   viewable as rows.

**Exactly N query executions for N nodes.** No node runs twice, and no node runs out of order.

### The N=3 instance

A report composed of two source reports is three nodes — two leaves and one root — and
executes **three** queries: leaf₁, then leaf₂, then the root against the attached pair. There
is no fourth query, and the root does **not** run against a remote database — it runs against
the local SQLite connection that has the two children attached.

## 4. Column identity and qualification

- A node's output columns are named by a stable `outputKey`, unique within that node's output.
  The physical cache column (`c<hash>`) is an implementation detail the compiler maps to.
- Inside a composing query, a child's column is referenced `<child-alias>.<outputKey>` and is
  always qualified by its child. An unqualified column is an error (ambiguous).
- **A node's public schema is its output columns.** A leaf's schema is the fields its parents
  need, projected on demand — a join key a parent references is projected even with no label.
  A composing node's schema is exactly its declared `outputKey` fields: a parent may reference
  any field of a leaf child, but only a field a composing child declares as an output.

## 5. Grouping, sorting, and aggregates

Grouping, sorting, and aggregates are computed **locally, over a node's materialized table**,
exactly as for a single-source report today. They are never pushed to a child's remote source.
A composing node's groupings apply to its own output, not to its children's.

## 6. Constraints

- A composing node references only child nodes, never a remote table. A remote table is
  wrapped in a leaf. (No mixed remote/local execution within one node.)
- Same-document composition only: every node's definition and layout lives in the one `.mad`
  file — a child is *contained* (embedded) in the composite, never referenced by an external
  path. Combining two reports means their definitions **and layouts** are brought into the
  composite's `.mad`. A reference to a node in a *different* file is out of scope and deferred.
  (The layout requirement is the §0 decision; it is not implemented yet, but it is part of the
  target contract.)
- `SQLITE_MAX_ATTACHED` is 10 on the engine build; a node with more than ten direct children
  is a design-time error in this milestone.

## 7. Conformance requirements

An implementation is correct only if all of these hold:

1. A composing node is a **general query** — any number of children, joined by the query's
   links, with arbitrary filters and groupings — compiled by the same compiler as any query.
   It is not a special-case join.
2. The walk is topological over the whole graph: children before parents, root last, each node
   exactly once.
3. A child that is itself a composing node is executed exactly like a leaf — it is just
   another node in the walk.
4. Each node materializes one table, published only when that node succeeds. A failed child
   fails the refresh and leaves the previous complete result of every node untouched (the
   root's and the other nodes').

## 8. Current implementation vs. this contract

The engine today implements the **N=3 special case** end to end: two leaves refresh, then a
composer string-generates a single left-outer join over the two attached tables. The root is
**not yet** compiled as a general query, and the walk is hardcoded to two leaves. The store
model already records N tables and N links (store revision 3); the two-input limitation is in
the executor (`MADComposer`, `MADOperationRefreshComposed`) and the authoring UI only.

The remaining work is to replace the two-input special case with the general walk of §3 and
make the composing root a compiled query over N attached children.
[`MAD_COMPOSITION_ENGINE.md`](MAD_COMPOSITION_ENGINE.md) scopes that engine change;
`MAD_QUERY_COMPOSITION.md` tracks the plan and its progress.

The **node-as-report** decision in §0 is also not implemented. The store still has one
document-level layout; `importQueryGraphFromContext:` drops a source's layout; `layout-model`
and its mutations resolve the root; and `refresh`/`export` read only the root. That work —
store revision, import, query-scoped layout and result reads, and the Windows/macOS surfaces —
is scoped in [`MAD_COMPOSITION_NODE_VIEW.md`](MAD_COMPOSITION_NODE_VIEW.md). The §3 execution
walk is unchanged by it: every node already materializes its own table.
