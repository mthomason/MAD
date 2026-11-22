# Future Features — the register of what the vision still requires

**Purpose:** the concrete capabilities the software must gain to reach the vision in
[`MAD_FUTURE.md`](../product/MAD_FUTURE.md) and [`docs/vision.md`](../../vision.md). This file is the
**agent-maintained** register of those features — the bridge between the user's wishlist and
the engineering queue. Unlike [`TODO.md`](TODO.md), which is the user's hand-written wishlist
and is not edited by agents, this file is where each vision item gets a durable entry once it
has (or is awaiting) a design.

**Date:** 2026-11-22. Created to hold the multi-source and non-SQL driver work designed in
[`MAD_MULTI_SOURCE.md`](../MAD_MULTI_SOURCE.md).

## How this relates to the other files

| File | What it is | Who maintains it |
|---|---|---|
| [`TODO.md`](TODO.md) | The user's product wishlist, written by hand | The user |
| [`MAD_FUTURE.md`](../product/MAD_FUTURE.md) | The vision: *why* and *what the software becomes* | Agents, as a record |
| Design docs (`MAD_DATA_OBJECT.md`, `MAD_MULTI_SOURCE.md`, …) | The *how*: contracts, code seams, phases | Agents |
| [`ROADMAP.md`](ROADMAP.md) | What gets picked up next, and in what order | Agents |
| [`TASKS.md`](TASKS.md) | The active engineering queue, in order | Agents |
| **This file** | The indexed register of vision-required features and their design/status | Agents |

An entry here is a pointer, not a plan: it names the feature, the design doc that grounds it,
and its status. Work is still picked up from `TASKS.md`/`ROADMAP.md`, never started from here.

**Status key:** `Designed` (has a design doc) · `Described` (shape recorded, no full design) ·
`Noted` (wishlisted, no design) · `Not started` (the work itself).

---

## 1. Multi-source reports — composable tables and subreports

- **What.** One `.mad` holds several report/query definitions (sub-reports); each runs to a
  SQLite table; a composing report joins those tables together (`ATTACH DATABASE`) and is
  executed bottom-up on refresh. Same-document first; cross-document deferred.
- **Design.** [`MAD_MULTI_SOURCE.md`](../MAD_MULTI_SOURCE.md) (whole);
  [`MAD_DATA_OBJECT.md`](../MAD_DATA_OBJECT.md) §4–5; [`docs/vision.md`](../../vision.md) §1–2.
- **Phases.** `MAD_MULTI_SOURCE.md` §8: 0 driver seam, 1 data-object contract, 2 query
  owns itself, 3 same-document composition, 4 cross-document (deferred).
- **Status.** `Designed`, `Not started`.

## 2. Non-SQL / API driver seam

- **What.** A driver receives a structured `MADQueryPlan` (tables, fields, links, predicates,
  limit/offset) instead of SQL text, and reports its abilities through a capabilities object,
  so the engine and UI stop hardcoding driver IDs and join rules.
- **Design.** [`MAD_MULTI_SOURCE.md`](../MAD_MULTI_SOURCE.md) §4.
- **Status.** `Designed`, `Not started` (Phase 0 — the independent first step).

## 3. Generic manifest-driven API driver

- **What.** One HTTP/JSON driver whose schema comes from a bundled source manifest (resources
  as tables, fields as columns, pagination rules); eBay Seller is the worked example.
- **Design.** [`MAD_MULTI_SOURCE.md`](../MAD_MULTI_SOURCE.md) §5.
- **Status.** `Designed`, `Not started` (Phase 5).

## 4. Extensible driver credentials

- **What.** A single JSON `options` column on the credential holds driver-specific parameters
  (OAuth client secret reference, refresh-token key, marketplace ID, sandbox flag); secrets
  stay in the Keychain. Avoids a new store column per driver.
- **Design.** [`MAD_MULTI_SOURCE.md`](../MAD_MULTI_SOURCE.md) §5, §6, §9.2.6.
- **Status.** `Designed`, `Not started`.

## 5. Plug-and-play driver system

- **What.** Install, register, and remove drivers at runtime, and add/remove them through the
  UI. A macOS/Linux/Windows/server feature; iOS keeps build-time-linked drivers.
- **Design.** [`MAD_MULTI_SOURCE.md`](../MAD_MULTI_SOURCE.md) §5.1 (shape recorded, not a full
  design).
- **Status.** `Described`, `Not started`.

## 6. Preview paging — browse the full result

- **What.** The sample-table preview pages through the full result instead of capping at
  ~512 rows.
- **Design.** [`MAD_MULTI_SOURCE.md`](../MAD_MULTI_SOURCE.md) §9.2.1; wishlisted in
  [`TODO.md`](TODO.md) §3.
- **Status.** `Noted`, `Not started`.

---

## Other vision areas awaiting a design

These are wishlisted in [`TODO.md`](TODO.md) (the user's file) and sketched in
[`MAD_FUTURE.md`](../product/MAD_FUTURE.md) but do not yet have a design doc. An agent gives each a
durable entry here when its design is written.

- **Legacy report import** — Crystal `.rpt`, SSRS `.rdl`, JasperReports `.jrxml` (`TODO.md` §2).
- **Beyond the paper paradigm** — native UI data views, charts, dashboards, KPI cards
  (`TODO.md` §3).
- **AI-assisted authoring** — natural-language → validated query graph/layout (`TODO.md` §4).
- **Export formats and headless engine** — `.xlsx`, `.docx`, headless PDF, more drivers
  (`TODO.md` §5).
