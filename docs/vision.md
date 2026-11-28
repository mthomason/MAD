---
layout: default
title: "The direction"
description: "MAD's direction: from reports to composable data objects, an embeddable engine, and AI-authored documents."
---

# The Direction: From Reports to Composable Data

Updated 2026-11-27. This page states the direction MAD is designed to grow
into. It separates what ships today from what is proposed, and it links the
public design records rather than the internal working notes: the
[composition guide](composition.html), the
[data-object design](developers/data-object.html), the
[multi-source reports](developers/multi-source.html), and the
[format specification](README.html).

## What exists today

A `.mad` document is a report's **definition**: the schema snapshot, the
query graph (tables, joins, predicates, groupings), and the banded layout
tree. On refresh the engine compiles the graph to SQL, reads the rows once,
and materializes them in a companion SQLite cache (`.maddb` + `.mdcache`).
The row data stays outside the document on purpose; the definition stays
under 100 KB.

The engine already has the pieces a broader direction needs:

* An open, portable document format: a bzip2 tar archive holding a portable
  SQLite store, with no Apple framework required to open it.
* A query builder that compiles structured definitions to SQL, plus a SQL
  parser for statements entered directly.
* Four SQL drivers — MySQL, SQL Server, PostgreSQL, and SQLite — each
  returning a schema and rows as a table.
* Local SQLite materialization (`MADDataTableFast`) that makes groupings,
  aggregates, and repeated rendering practical on a phone.
* Same-document **composition**: a `.mad` document can hold a graph of
  reports — a **Result** plus its **sources** — where every node keeps its
  own query, connection, layout, and materialized table. The document
  declares the `query-composition` capability, and MAD Designer for macOS
  and Windows author and view every report in the graph.
* Native iOS and macOS applications, a native Windows application, and the
  same engine running headlessly on Linux and Windows through `mad serve`
  and the `mad` CLI.

One consequence is easy to miss: **a report is a function from data sources
to a table.** Every driver returns a schema and rows in table form, and a
report's output *is* a schema and rows in table form. The engine already
treats the two identically.

## Where it is going

The directions below build on the architecture above. Some of them ship
today — same-document composition is in MAD Designer for macOS and Windows
0.8 — and the sections say which parts are built and which remain proposals.

### Composable data objects

In a database, you select from base tables like `employee` or `sales_data`.
A report links multiple tables together, and its output is an ad hoc,
materialized SQLite table. **Within one document, composition now does
exactly that:** the Result queries its sources' materialized tables, and every
source is addressed as a table another report joins. A source is a complete
report — query, layout, and rows — not a bare table. See the
[composition guide](composition.html).

What is not built is a **stable identity shared across documents**, so a
report in one `.mad` can point at a report in another. The result cache is
keyed by a filename hash rather than an addressable identity, and
cross-document composition is deferred. Giving the output that identity would
extend the in-document graph into a portable semantic layer across files. The
[data-object design](developers/data-object.html) describes the model and what
formalizing it takes.

### Multi-source local materialization

Every driver materializes its result set into the same local SQLite table
representation. **This ships today inside one document:** a Composition Report
can join a PostgreSQL table to a SQL Server table to a MySQL table — combined
locally in SQLite without a federation server in the middle. Each source
understands its own data; MAD understands the resulting tables. The
[multi-source design](developers/multi-source.html) records the architecture;
same-document composition is built, while cross-document federation remains
ahead.

### Embedded and headless use

MAD need not be limited to applications named MAD. The same engine could be
embedded in other developers' products: an inventory system, a financial
application, a manufacturing tool, or an industry-specific management
system that needs queries, reports, exports, and operational summaries
without building a reporting subsystem from scratch.

The host application supplies data access, integration, and its own user
experience. MAD supplies reusable query, materialization, reporting, and
export capabilities. The driver seam is deliberately broad — a source needs
to provide a schema and rows, not necessarily a conventional SQL database —
so the same contract can accommodate relational databases, local
application data, structured files, and devices. Some of those sources have
drivers today; others would need one.

This direction also reaches beyond desktop software: an appliance or
industrial system with sufficient resources could use the engine locally to
turn measurements and maintenance records into diagnostic reports, without
continuous connectivity. It is not a claim that the full engine fits a tiny
microcontroller or a hard-real-time control loop.

### Presentation beyond paper

Banded pagination — Report Header, Page Header, Groupings, Detail, Footers —
was invented for printing on paper. A `.mad` layout is parametric data, and
the row cache is local SQLite, so paper pages are one presentation of the
data rather than its definition.

Keeping the definition and its materialized table separate makes other
presentations possible over the same data object: interactive tables and
data explorers, native application views, charts and dashboards,
application-embedded views, and browser-based viewers. Traditional
paginated reports remain important; the aim is to make them one useful
presentation among several, not to abandon them.

### AI-authored documents

MAD's declarative structure makes it suitable for a different model of
AI-assisted reporting. Rather than generating a picture of a chart, a model
could propose an actual MAD document: discover the available sources and
schema metadata, choose the relevant tables and fields, construct the query
graphs and relationships, propose a layout, and submit the result to the
engine for validation and execution.

The division of responsibility matters. The model interprets intent and
proposes a structured definition; MAD validates and executes it. The model
should produce query graphs and layout definitions rather than arbitrary
unchecked SQL, and the engine should remain responsible for SQL generation,
data access, and materialization.

The result would be a normal, editable `.mad` document rather than a
one-time answer. The query graph could be inspected, the joins and filters
edited, the presentation customized, the results refreshed without the
model, and the document reused elsewhere. That keeps the user in control of
the artifact and avoids making operation depend on the AI that authored it.
Authorization, validation, and data-protection controls would be part of
making this real; structural validation alone does not prove an analysis is
semantically correct.

### Optional server and web deployment

Native applications, embedded components, and headless execution should
remain first-class. A future service could add scheduling, document
catalogs, access controls, snapshot management, shared reports, and APIs,
and a browser-based designer could operate on the same document model as the
native clients.

The engine and the document format remain the common foundation. A customer
who needs local execution, private infrastructure, or offline operation
should not have to adopt a cloud deployment to benefit from the engine, and
a future web implementation should not fork the query semantics.

### Legacy report conversion

A future importer could bring definitions from legacy report formats into
open `.mad` files. That is a compatibility path for organizations with
long-lived report libraries, not the center of the direction and not a
replacement for the directions above.

## Three ways to use MAD

These are not separate products or separate codebases. They are different
uses of the same architecture, connected by the data-object model.

### MAD as an application

A complete query, design, and reporting experience for people who work
directly with their data, with native applications, document portability,
and practical reporting.

### MAD as an embedded engine

A reusable data access, query, materialization, and reporting component for
developers incorporating MAD into their own software or devices, with the
driver architecture, headless execution, reusable definitions, and local
processing as the emphasis.

### MAD as an AI-authored data platform

A system where people describe the information they need and a model
constructs validated MAD data objects and documents, with structured
generation, machine validation, and editable artifacts that remain useful
independently of the AI. This is a proposal; no AI authoring ships today.

## Why this matters

The problem is practical. Many organizations run substantial, long-lived
systems built around relational databases and specialized business
applications. They want reliable access to their own data, reports they can
maintain without repeated custom development, native tools with good user
experiences, control over credentials and where data is processed, continued
use of existing database infrastructure, and portability between platforms
and environments.

The hard part is usually getting the data into a reliable, usable form.
Presenting it is the final step. MAD invests in data acquisition, relational
modeling, materialization, and execution, and the interface sits on top of
that work rather than hiding it.

The value is positive: portability, local control, composability, reliable
processing, extensibility, and an approachable experience. A business should
be able to obtain useful answers from its data without accepting unnecessary
platform dependencies.

## What this is not

A promise, a roadmap with dates, or a claim that every proposal above ships.
This page records a direction. Same-document composition is built today; the
other directions still have to be designed, tested, and documented the way
everything else in the repository is, and some may change as they are built.

## The guiding principle

> **The document defines the work. The engine executes it. The presentation
> makes the result useful.**
