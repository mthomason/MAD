---
layout: default
title: "Composite reports — the execution model"
description: "The normative contract for composite (multi-source) reports: a DAG of queries, children before parents, root last, every node a table."
---

# Composite reports — the execution model

**Status: normative.** This is the contract every composite-report implementation must
satisfy. Read this first. `MAD_QUERY_COMPOSITION.md` is the implementation plan and progress
record against it; the older design records ([`multi-source.md`](../developers/multi-source.html),
[`data-object.md`](../developers/data-object.html), [`vision.md`](../vision.html)) record the
direction and rationale and are superseded by this file wherever they differ.

## 1. What a composite report is

A **composite report** is a directed acyclic graph of **queries**. Each node in the graph is
one query definition (`RptqQuery`) and produces exactly one materialized table. The graph has
one designated **root** (`RptqDocument.rootQuery`); the root's materialized table is the
report's output.

A node's query is one of two kinds:

- **Leaf.** Its tables are remote schema tables, and it owns one `RptqDatabase` (driver,
  connection, credentials). It is executed against that remote source — SQLite, MySQL,
  SQL Server, or PostgreSQL.
- **Composing.** Its tables are the outputs of other nodes (its children). It is executed
  against a local SQLite connection with each child's table attached. It references only
  children — never a remote table — because `ATTACH DATABASE` exists only inside SQLite, and
  because one rule ("a composing node's tables are its children") is simpler to build and to
  understand.

A composite report is **self-contained and portable**: every node's definition lives inside
the one `.mad` file — the composite is a container for the child reports it combines. A user
does not design the whole graph up front. The children start as ordinary reports; "combine"
is how they are later brought together into one composite `.mad`.

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
4. The root's table is what the viewer, export, and print paths consume.

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
- Same-document composition only: every node's definition lives in the one `.mad` file — a
  child is *contained* (embedded) in the composite, never referenced by an external path.
  Combining two reports means their definitions are brought into the composite's `.mad`. A
  reference to a node in a *different* file is out of scope and deferred.
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
   fails the refresh and leaves the previous root result untouched.

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
