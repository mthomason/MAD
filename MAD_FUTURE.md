# The Future of MAD — from document editor to data-object platform

Written 2026-10-04 against `master` at `c807eeb4d`. Speculative by design: this file is
a vision document, not a plan to be acted on. Where it touches real work it points at
the tracks that already exist (`MAD_FORMAT.md`, `MAD_STORE_MIGRATION.md`, `MAD_CLI.md`,
`ROADMAP.md` §3-5) so the two can be reconciled when the work is picked up.

---

## 1. The reframe

The user's prompt, compressed:

> Stop thinking of `.mad` as a report document the user views. Think of it as a data
> object. Think of the hidden file types. Think enterprise, where the file types may
> not even be exposed. Reports can be linked inside other reports the way tables are,
> so one query can span multiple data sources.

The architecture already agrees. A `.mad` file is not a document in the PDF sense; it
is a **definition** — schema snapshot, query graph, layout tree — under 80 KB, while
everything a report *displays* lives in companion files that are derived, disposable,
and regenerated on refresh (`MAD_FORMAT.md` §5). The split is already:

| Layer | Where it lives | What it is |
|---|---|---|
| The spec | inside the `.mad` | declarative: schema snapshot + query graph + layout tree |
| The materialization | `<hash>.maddb` + `<hash>.mdcache` | the result table: rows + result schema |
| The presentation | `<hash>*.madac` | pre-rendered pages, keyed by layout and page geometry |

So the reframe costs nothing architecturally. It is a change of what we *call* things
and what we *allow* them to do:

- **A report is a function from data sources to a table.** The query graph is the
  function body; the engine compiles it to SQL; the `.maddb`/`.mdcache` pair is the
  return value — a table with a schema, indistinguishable from any table a data source
  returns.
- **The engine can already host any table as a source.** Every data source driver
  returns a schema and rows in table form. A report's output *is* a schema and rows in
  table form. The only missing piece is **addressing**: nothing can point a query graph
  at another report's output, because that output is a cache keyed by a filename hash
  and not a first-class object.
- **Close that loop and the product changes kind.** If report R's output can be a table
  inside report R′, then reports compose, and the whole system becomes a **DAG of
  derived tables** — a semantic layer. One query against multiple data sources falls out
  for free: snapshot from MySQL, snapshot from SQL Server, joined in SQLite, displayed
  by a third report. No federation engine needed; the snapshots *are* the federation.

That single change — making the hidden cache a named, versionable, addressable object —
is the load-bearing idea this document is organized around. Everything else (web,
cloud, AI, money) is a consequence of it.

---

## 2. What the file type really is, and what the hidden types become

### 2.1 The `.mad` as a data object

As a data object, a `.mad` has four properties worth selling:

1. **Portable.** The container is bzip2 tar with a magic header (`MAD_FORMAT.md` §7);
   the store is moving to our own SQLite schema (`MAD_STORE_MIGRATION.md`, Phase C
   landed 2026-10-03, Phase D pending). No Apple dependency remains in the format once
   Phase D lands. A `.mad` opens wherever SQLite opens — which is everywhere.
2. **Small.** Under 80 KB for the shipping samples. The definition of a report is
   cheaper to move than the screenshot of one.
3. **Declarative and diffable.** Schema, query graph, layout tree — all structured, all
   versionable, all reviewable. A `.mad` is a *program* a human can audit. (This is
   the property AI will eat, §6.)
4. **Self-validating.** The engine generates the SQL, so the graph is checkable before
   any query runs. A corrupt `.mad` fails like a corrupt program, with a precise error
   — the CLI's exit codes are already this discipline (`MAD_CLI.md` §3).

The reframe in one sentence: **a `.mad` is source code; the companion files are its
build artifacts; the viewer is the runtime that executes it.** And like source code,
the artifact is portable across runtimes — iOS app, CLI, server, browser.

### 2.2 The hidden file types as products

The three companion kinds are documented but not specified (`MAD_FORMAT.md` §5.3).
Under the reframe each one becomes a product:

- **`.maddb` + `.mdcache` → the Snapshot.** This pair *is* the report's output: rows
  plus the result-table schema, both already serialized portably (SQLite plus a plist
  whose schema is now documented). A named, versioned snapshot is:
  - **shareable without credentials or live access** — send a colleague the result of
    a query without sending them the database;
  - **auditable** — "what did the CFO's report say on the day Q3 closed?" becomes a
    question a snapshot store answers, not an argument;
  - **offline** — the packed-document question (`MAD_FORMAT.md` §8.3, `MAD_CLI.md`
    §8.2) gets answered *yes*, but as a distinct artifact rather than a `.mad`
    variant: the snapshot is the thing that travels, the `.mad` stays lean;
  - **an input to other reports** — the composition loop from §1.
- **`.madac` → pre-rendered pages.** A server that renders once and serves pages to
  many clients is exactly what the codebase already believes the cache is for: "the
  cache is the platform for future views" (`MAD_FORMAT.md` §5.1). In a web product the
  render cache stops being a device-local optimization and becomes the serving model.
  (It also inherits a defect that must not ship to the server: the key is the
  document's *filename*, not its content, so an edit under the same name serves stale
  pages — §5.3. Content-hash the key before any server renders.)
- **The cache directory → the materialization store.** One directory per
  `dataTableIdHash`, named by the app's own rule. On a server this becomes a content-
  addressed store keyed by document identity + content hash + page geometry, which is
  the shape every static-asset server already has.

The strategic point: **the file types are already the product line.** The company this
software could become sells three objects — definitions, snapshots, and rendered pages
— not "an app that makes reports."

---

## 3. The core technology this becomes

Put the pieces together and the center of gravity is: **a portable semantic-layer
artifact** — a declarative spec whose execution is deterministic SQL generation plus
materialized results in SQLite, with parametric presentation attached. That is the
space dbt (models built on models), Looker (explores), and Cube (semantic cubes)
occupy, each with a hole in it:

| | dbt | Looker | Cube | a `.mad`-centered platform |
|---|---|---|---|---|
| Data model is portable | partially (YAML/SQL) | no (locked to Looker) | partially | **yes** — one file, no server |
| Presentation travels with the model | no (BI tool bolted on) | partially (locked) | no | **yes** — layout is data, not screenshots |
| Output of one model is input to another | yes | yes | yes | **yes** — once snapshots are addressable |
| Offline / edge / embedded | no | no | no | **yes** — SQLite runs anywhere, including on device today |

Three differentiators are worth naming precisely because they are already true:

1. **Presentation is parametric, not a picture.** The layout tree (sections, elements,
   styles, geometry) travels in the definition. The same `.mad` renders as pages in
   UIKit today, as a PDF from the CLI, and as DOM/SVG in a future web viewer — because
   the layout is data that any renderer can consume, not a canvas state. This is rare:
   most BI dashboards are a server's opinion, not a portable object.
2. **SQL generation is deterministic and owned.** The engine writes the SQL from the
   graph; the user (or the AI, §6) never does. Validation happens at the graph level,
   before any query exists. This is the property that makes the format safe to expose
   to machines.
3. **The materialization format is already portable.** SQLite with an 8192-byte page
   size, the `.mdcache` schema documented, the quirks catalogued (`dataPercision`, the
   `~MTNull~` sentinel — `MAD_FORMAT.md` §5.3). DuckDB is the natural server-side
   successor for larger snapshots (it speaks SQLite's dialect well enough to be a
   drop-in for the big cases), but nothing forces that move until size demands it.

The industry name for a report that is also a table is **a semantic layer**; the
industry name for the artifact that defines one is **a model**. What this codebase is
quietly building is a model format that runs on a phone, a laptop, and a server, and
carries its own presentation. Nobody currently sells that combination.

---

## 4. The web version

### 4.1 Why it is closer than it looks

The data path is nearly UIKit-free already, and this is *measured*
(`MAD_CLI.md` §4): `MADDataStructures` 0/37 files, `MADFileManager` 0/31, `MADSqlite3`
0/65, `MADMySQL` 0/42, `MADTds`/`MADTdsClient` 0/3 and 0/9; `MAD` is 28/464 with the
UI parts identifiable by name. The CLI already runs the full path headlessly —
`inspect`, `query`, `refresh`, `export` all worked first try against both samples
(`ROADMAP.md` §3.1). The refresh orchestration (`MADOperationRefresh.m`, 131 lines,
zero UIKit symbols) is the CLI's refresh verb; it merely lives in the app target
(`ROADMAP.md` §3.4).

Translation: **the engine of the web version already exists and already runs without
a UI.** What a web version needs is (a) the engine on a server, (b) an HTTP layer over
the CLI's verbs, and (c) a browser UI that consumes the same document tree the app
consumes. Only (c) is genuinely new work. That claim is about the *engine*, not about
hosting: where the server runs, and everything the web adds around the engine, is §5.

### 4.2 Shape

**The plan is a clone.** Per the user: the web version is the full iOS app, not a
reduced viewer — the same three-tab experience (MAD Query, MAD Designer, MAD Viewer)
and the same file explorer, running in a browser. Every screen maps cleanly:

| iOS screen | Web equivalent |
|---|---|
| File explorer | a cloud catalog showing the same document metadata and create-document flow |
| MAD Query | the same graph builder — tables, joins, filters, groupings — writing the same query structure |
| MAD Designer | a zoomable canvas: absolutely-positioned section bands, drag between groups |
| MAD Viewer | paginated preview plus the refresh button, backed by the same snapshot store |

- **Server.** Swift on the server (Vapor or similar), linking the same
  `MADFoundation` / `MAD` / `MADSqlite3` / driver frameworks the app links — once the
  headless subset from `MAD_CLI.md` §4.2 is a real packaging boundary (Swift Package
  Manager is the natural vehicle). No port of SQL generation, no reimplementation of
  `MADDataTableFast`, no second source of truth for the format. The CLI's exit codes
  become HTTP status codes; its verbs become endpoints: `inspect` → metadata, `query`
  → SQL preview, `refresh` → the job queue, `export` → the rendering service.
- **Client.** The iOS designer is a zoomable scroll view holding nested collection
  views, with elements dragged between groups; its clone on the web is a canvas
  application — Figma-shaped, not form-shaped: absolutely-positioned bands (Report
  Header, Page Header, groups, Detail, footers), wheel/pinch zoom, HTML5
  drag-and-drop between sections. The viewer tab is a paginated preview rendering the
  same layout tree to DOM/SVG, with PDF from the server's export endpoint. The file
  explorer is a cloud catalog showing the same metadata the iOS one shows.
- **The contract is the document tree.** Both UIs are consumers of the same store
  schema (`MADStoreSchema` already drives the converter's attribute/edge lists —
  `MAD_STORE_MIGRATION.md` §7 Phase B). The browser never needs the engine's
  internals; it needs the document tree and the snapshot schema, both of which are
  already serializable.

A useful mental model: **the iOS app and the web app are two full clients of the
same engine** — one artifact, many runtimes, and two of those runtimes are complete
products, the same relationship a JAR or a PDF has to its viewers. The iOS client
keeps offline and touch; the browser client buys reach.

### 4.3 Phasing (sketched, to be reconciled with `ROADMAP.md` when picked up)

1. **The three seams** — driver registry (`ROADMAP.md` §5.1), export protocol
   (`ROADMAP.md` §5.2, text/JSON/CSV as new classes, not new switch arms), element
   protocol (`ROADMAP.md` §5.3). These are prerequisites for everything below, and
   the registry is what
   unblocks `MADOperationRefresh`'s move and any macOS build.
2. **Headless packaging** — `MADFoundation`/`MAD`/`MADSqlite3`/drivers as packages
   compiling without UIKit, per `MAD_CLI.md` §4.2, extended to Linux. The four
   UIKit-touching files in `MADFoundation` are already named and triaged.
3. **`mad` as a service** — HTTP API over the existing verbs; a job queue for
   refresh; the cache directory becomes the materialization store (§2.2), with
   content-hashed `.madac` keys.
4. **The clone, tab by tab** — catalog first, then MAD Viewer, then MAD Query, then
   the MAD Designer canvas. The clone is the target, not a wedge: feature parity
   with the iOS app, built in the order the tabs depend on each other — the viewer
   proves the document tree renders outside UIKit, the query tab proves graph
   editing, and the designer is the canvas on top.
5. **Composition** — snapshots as addressable tables (§1), then scheduling and
   lineage (which snapshot did this report read?).

The order respects what the existing documents already established: the CLI was never
a product, it was the instrument that made the data path visible; a web service is the
same instrument wearing an API, and only the browser UI is a product decision taken
later. What the instrument grows into is §4.4; where it runs, and what runs around
it, is §5.

### 4.4 The CLI's second act

Today the CLI is just for testing, and correctly so: it exists to make the document
visible with the app out of the way (`ROADMAP.md` Track 3). But an instrument is also
an embryo. What `mad` could become, in the order it would grow:

1. **The deployable engine.** The same binary is the natural unit of a server
   deployment: containerize `mad`, put a queue and an HTTP front door in front of it,
   and the web product's back end *is* the CLI grown up. The exit codes are already
   status codes; `--rows N` is already pagination; the verbs are already the API.
2. **The report pipeline runner.** Once snapshots are addressable (§1), reports form
   a DAG — and a DAG wants a runner. `mad run` refreshes a project's documents in
   dependency order, the way `dbt run` builds models: `.mad` files in git, `mad test`
   in CI, a manifest naming the project's documents, and a broken report fails the
   build. Reports-as-code. This is the single biggest step available: from "open one
   document" to "operate a catalog."
3. **The automation surface.** Cron jobs that refresh and email PDFs; scripts that
   shell out to render; other applications embedding reporting by calling one binary.
   This is the OEM story (§8.8) wearing a command line.
4. **The AI's hands.** In the reject-and-repair loop (§7) the model never talks to a
   database; it talks to the engine. The CLI is the most literal form of that
   conversation: `mad validate` on the model's draft, `mad refresh --dry-run`, exit
   codes as the error vocabulary. An agent that can run `mad` can already do real
   reporting work.

The progression is the same one the rest of this document traces: instrument →
engine → pipeline → platform.

---

## 5. Where it runs, and what runs around it

The user's question — *"this is why we would flush out the CLI, right?"* — is exactly
right. The CLI is the boundary that makes this section answerable: it is the one
surface through which the engine meets a platform, and every platform question is a
question about what stands on the other side of that surface.

### 5.1 The platform matrix

"Does this have to be hosted on a Mac?" No — but each candidate host has a different
price, and pretending otherwise is how server projects die. Today the only
server-shaped runtime is the iOS Simulator: the CLI builds for it and runs through
`simctl spawn`, which is also the only reason `mad export` can produce a PDF at all —
it borrows the simulator's UIKit for `UIPrintPageRenderer`. The honest matrix:

| Host | Engine | Rendering | Cost of getting there |
|---|---|---|---|
| macOS server | near-native — the headless subset is measured, not guessed (`MAD_CLI.md` §4) | CoreGraphics/PDFKit exist; still needs a non-UIKit print path | the headless packaging (§9 phase 3), the driver registry first |
| Linux server — the real hosting target | the core (SQL generation, `MADDataTableFast`, the store) is Foundation, not UIKit; Objective-C on Linux means GNUstep/libobjc2, which works with real friction | nothing Apple exists: pdfium, Skia, or render pages as HTML/SVG and let the client print | Compressor adds Linux rows — every vendored library is Linux-native C, so this is build-system work, not porting; the renderer is a genuine product decision |
| Browser — a fourth runtime for the *format* | no full engine, but a `.mad` is bzip2-tar-SQLite with a documented store schema; sql.js runs SQLite in WASM | DOM/SVG are native | a JS reader for the store schema — snapshot viewing can run with no server at all |
| Windows | the format docs already demand a reader on Windows (`MAD_FORMAT.md` §7); realistically a client, not a host | the same non-Apple renderer as Linux | last in line |

The framework-by-framework audit of what compiling on Linux actually takes — the
measured dependency matrix, the shim list, GNUstep's coverage risks, the toolchain,
and the phasing with a go/no-go checkpoint — is `MAD_LINUX.md`. Its recommendation,
in one line: keep the engine in Objective-C, compile it against GNUstep, and
integrate from other languages across the CLI boundary. The macOS-first path avoids
choosing; the Linux path does not. The CLI boundary is what makes either answer
revisable — which is precisely why it is flushed out *before* the platform is
chosen, not after.

### 5.2 What the web adds that the app never needed

The iOS app is single-user by design: keychain per device, documents per device,
permissions enforced by whoever holds the phone. The web product is multi-tenant
from day one, and none of the following exists in the codebase. All of it sits
*around* the engine, never inside it:

- **Users and identity.** Accounts, organizations, invitations, SSO (OIDC/SAML).
- **Permissions and access control.** Roles (viewer / designer / admin), per-document
  ACLs, schema-level grants — who may see which table moves from "the person holding
  the device" to "the policy server."
- **Licensing and billing.** Seats, feature tiers, metering (refreshes, snapshot
  storage, exports). This is the machinery behind §8.4-8.5's prices; it has no iOS
  counterpart and is real product work.
- **The credential vault.** Server-side secrets per org, never on a device. The open
  keychain question (`ROADMAP.md`, decisions table) becomes the vault's question.
- **Audit and lineage.** Who ran what when; snapshot version history; the compliance
  answer from §2.2.
- **An API surface.** Keys, scopes, webhooks, embedding tokens for the OEM story
  (§8.8).
- **Content controls.** Scheduling, rate limits, snapshot retention, export rules.

The architectural point that makes all of it tractable: **every one of these attaches
at the CLI boundary.** `mad` stays dumb — authenticate, open, refresh, export — and
the platform layer answers *who may do which verb to which document*. A permission
denial is a new exit code; a metering event is a log line beside the run. The engine
never learns what an org is. That separation is why "flush out the CLI" is not a
detour from the web product — it is the web product's first and hardest architectural
decision, made in the cheapest possible place.

---

## 6. Enterprise and cloud

In an enterprise deployment the file types stop being files the way the iOS Files app
knows them:

- **The catalog replaces the file explorer.** A `.mad` becomes a row: name, owner,
  ACL, versions, the schema snapshot it was built against. The file remains the
  *serialization* — the object's portable form, the way a git blob is a commit's —
  but it is no longer the user's unit of interaction. Share-by-reference replaces
  share-by-airdrop.
- **The materialization store replaces refresh-on-demand.** The user's "hidden cache
  files that can be refreshed on demand" is, server-side, the whole product: a
  scheduler keeps snapshots warm; viewers read snapshots, never source databases.
  This is the cloud moat — the reason the hosted version is worth money is that it
  owns refresh, staleness, and rendering at scale, on behalf of hundreds of
  documents.
- **Credentials go to a vault, not a phone.** `MADKeyChain`'s descendant is a
  secrets manager; the open question of who owns the database password
  (`ROADMAP.md`, decisions table) becomes "which vault does the service use."
- **Audit falls out of snapshots.** Versioned snapshots answer the compliance
  question every regulated company eventually asks: what did this report show, to
  whom, on what date, from what data.
- **Licensing is already half-thought-through.** Shipping a server redistributes the
  vendored libraries in a new way; the LGPL obligations and the MySQL-to-MariaDB
  replacement in `THIRD_PARTY_LICENSES.md` / `LICENSE_COMPLIANCE_PLAN.md` are the
  existing record of exactly this problem. A service is the *friendly* case (linking,
  not conveying), but the obligations must be re-audited per deployment model before
  any server ships.

Two honest constraints to name: (1) PDF rendering is currently UIKit's
`UIPrintPageRenderer` (`MAD_CLI.md` §3) — today `mad export` produces a PDF only by
borrowing a simulator's UIKit, and the real renderer decision is §5.1; (2) the
two-pass pull-everything design assumes reports sized for people, not warehouses —
which is a feature to *keep*, since the product's whole stance is "reports, not
petabyte scans," but snapshot size caps and paging belong in the server design from
day one.

---

## 7. AI: what it takes for a model to make reports

The user's question: *what would it take to have GPT take user input and create
reports based on that?* The answer is short because the architecture is already the
right one: **the model never writes SQL, never draws pixels — it writes the graph.**

That division of labor is the entire trick:

- **The engine owns correctness.** SQL is generated from validated structures, so a
  bad model output fails at graph validation with a precise error — the same way a
  corrupt `.mad` fails today — instead of producing a subtly wrong query. No SQL
  injection surface exists because the model never touches SQL text.
- **The model owns intention.** "Sales by region for last quarter, totals in the
  report footer" becomes a query graph plus a layout tree. Both are already
  structured data, and `MADStoreSchema` — the schema driver that already walks every
  entity's attributes and edges for the converter — is one step from being the JSON
  Schema an LLM's structured output is validated against.
- **Grounding is cheap.** The document carries its own schema snapshot, under 80 KB
  total. The model grounds in that snapshot — via tool calls (`list_tables`,
  `describe_table`) or by having the snapshot in context — and never sees
  credentials, never touches the live database. The engine mediates all of it.
- **The loop is reject-and-repair.** Model emits graph JSON → store parser validates
  → precise errors return to the model → it repairs. The CLI's exit-code discipline
  (`MAD_CLI.md` §3) is exactly the error vocabulary this loop needs, and the 885-test
  suite is the harness that pins the validation.
- **Scrimpter gets its second life.** An unused scripting language is dead weight
  today; in an AI world a report DSL is the *textual form* of a document — the thing
  a model emits and a human reviews and diffs. LLMs are at their best emitting
  constrained languages, and "reports as code" is precisely what makes AI edits
  reviewable. This is the strongest candidate for resurrecting `Scrimpter`, and it is
  worth saying explicitly: the compiler that was built for human formula authors is
  the one an AI author needs too.

The product shape: a chat pane beside the designer — "make me a sales pipeline report
by owner and stage" → the canvas fills with the graph and layout, fully editable
afterward. Follow-ups mutate the same graph ("group by month instead", "add a total
row"). Every AI action lands as a normal edit, so undo, versioning, and diffs work
unchanged. Aggregates are computed by the engine on the row cache — the model is
never asked to do arithmetic on data, which is where current models quietly fail.

Costs are bounded by the snapshot: context is the schema (small), not the data. A
product improvement that compounds: let users annotate columns once ("this is the
revenue recognized in the booking month"), store the annotations in the schema
snapshot, and every future AI session inherits the vocabulary.

---

## 8. Ways to make money

The reframe turns one product into a catalog. In rough order of proximity:

1. **App Store, freemium.** Free viewer (including the currently-broken stand-alone
   viewer target, which is the natural free client — it opens snapshots and refreshes
   if allowed), paid designer. One-time or subscription, but the designer is the
   prosumer tool and the viewer is the wedge.
2. **Element and driver packs.** The three seams (`ROADMAP.md` §5.1-5.3) become the
   IAP catalog: chart elements, the barcode element (revive `MADBarcodes` as a paid
   element), and — the big one — drivers. Postgres alone would double the addressable
   market; then Snowflake, BigQuery, REST/JSON. Each is "subclass `MADDatabase`,
   return a schema" — which is also exactly the extensibility promise the project
   synopsis already makes.
3. **A driver marketplace.** Third-party `MADDatabase` subclasses with a revenue
   share. The extensibility story becomes a two-sided market; the registry (`ROADMAP.md` §5.1)
   is the store's shelf.
4. **MAD Server — the web version, self-hosted.** A full clone of the iOS
   experience in the browser. Annual license, per-seat or per-
   core, the classic enterprise BI price model (this is how SSRS-era companies and
   today's Looker/Cube/ThoughtSpot all bill). The buyer is a company with a
   SQL Server/MySQL estate drowning in ad-hoc query requests: MAD is governed
   self-serve BI — analysts get the schema and the graph builder, IT keeps the
   credentials, the semantic layer keeps one source of truth.
5. **MAD Cloud — the hosted version.** The materialization store, scheduling, and
   rendering are the SaaS moat (§5). Per-seat plus refresh/storage metering. The
   snapshot store makes churn painful in the good way: the longer the reports run,
   the more audit history the customer owns.
6. **The snapshot/data-product tier.** Selling the hidden file types themselves:
   snapshots shared outside the org, embedded as live report feeds in other tools,
   lineage and audit. "The report as an API" — export formats become content types,
   and the snapshot becomes a subscription resource.
7. **The AI tier.** Natural-language report building at a premium, priced to pass
   through token costs. This is the upsell that justifies the whole semantic layer:
   an AI that can only build reports it can validate is one enterprises will
   actually let near their data.
8. **Embedded/OEM.** White-label the engine and viewer to ISVs who need reporting
   inside their own products — the Telerik/Stimulsoft model. The CLI is already the
   shape of an SDK (§4.4), and the `.mad` being one small portable file is exactly
   what an embedded partner wants to ship.

One strategic fork belongs on the table: **is the format open?** An open `.mad`
spec with paid runtimes (app, server, AI) is the open-source-then-sell pattern that
built dbt, Superset, and Metabase — the format becomes a standard, and the money is
made in the engine, the hosting, and the marketplace. A closed format protects the
moat but caps the ecosystem. The v1 magic header (`MAD_FORMAT.md` §7) reads either
way; the decision is product strategy, and it should be made before the spec is
published, not after.

---

## 9. A plan for the code base

Grounded in what the existing documents already decided. Each step keeps the app
shipping and the suite green — which is the discipline this project has already
demonstrated end to end.

| Phase | Work | Grounding |
|---|---|---|
| 1 | Finish the store migration: Phase D (delete Core Data + iCloud, retire the converter and `MAD.momd` from the framework once legacy conversion dies) and the Phase C leftovers (§9.1 subentity fallback, the deferred hardening). | `MAD_STORE_MIGRATION.md` §7, `MAD_STORE_PHASE_C.md` §9 |
| 2 | The three seams: driver registry, export protocol (text exporter first, per the user's own order), element protocol design pass. Move `MADOperationRefresh` into `MAD` as part of the registry change — they are one change (`ROADMAP.md` §3.4). | `ROADMAP.md` §5 |
| 3 | Headless packaging: the four named UIKit files in `MADFoundation` triaged, frameworks built without UIKit, Swift Package Manager as the boundary. This is what turns the CLI's headless subset into a deployable engine. | `MAD_CLI.md` §4 |
| 4 | `mad` as a service: the CLI graduates from instrument to engine (§4.4) — HTTP layer over the verbs, job queue, materialization store with content-hashed render keys (fixing the filename-keyed staleness before a server can inherit it). | `MAD_CLI.md` §3, `MAD_FORMAT.md` §5.3 |
| 5 | Platform matrix: Compressor gains Linux rows for the vendored libraries (all of them are Linux-native C); the renderer decision replaces `UIPrintPageRenderer`; the service gets a real host. | §5.1 |
| 6 | Platform layer: identity, orgs, roles, ACLs, vault, licensing, audit — attached around the CLI, never inside the engine. | §5.2 |
| 7 | Snapshots as first-class: a named, versioned snapshot artifact (`.mad` + `.maddb` + `.mdcache`), answering the packed-document question with a distinct object rather than a format variant; then addressable snapshots inside query graphs — the composition loop from §1. | `MAD_FORMAT.md` §8.3 |
| 8 | The web clone: catalog, then the three tabs in dependency order, against the same document tree — feature parity with the iOS app as the stated target. | §4.3 |
| 9 | The AI layer: JSON Schema derived from `MADStoreSchema`, schema-snapshot grounding, the reject-and-repair loop, chat beside the canvas, and the Scrimpter revival as the textual form. | §7 |

Known risks, each already visible in the existing documents: the `{0, 0}` 6 MB of
stale render cache and the filename-keyed invalidation (`MAD_FORMAT.md` §5.3) become
real defects the moment a server renders for many clients; headless PDF rendering
needs a non-UIKit path (`MAD_CLI.md` §3); the hosting matrix and the renderer fork
(§5.1) are decisions, not defaults; the two-pass pull-everything model needs
snapshot caps at enterprise scale (§6); and the vendor licence obligations must be
re-audited per deployment model before any server ships
(`THIRD_PARTY_LICENSES.md`).

---

## 10. Decisions this vision implies

None of these block today's tracks; they are the forks the vision depends on, and
each has a natural answer:

1. **Is `.mad` a file or an object?** Both. The file is the portable serialization;
   in the cloud it is a row in a catalog whose serialization happens to be a file.
   The format documents already separate container from store, which is exactly the
   seam this needs.
2. **Does the packed variant exist?** Yes — but as the *snapshot* artifact, not a
   `.mad` variant. The definition stays lean; the data travels as its own object.
3. **Should content changes invalidate the render cache?** Yes, and the fix is the
   content-hash key — cheap, and mandatory before any server rendering.
4. **Is the format open?** The strategy fork from §8; decide before publishing the
   spec.
5. **What is the JSON export shape?** Answering this (`MAD_CLI.md` §8.3) is the same
   work as defining the snapshot's interchange form and the AI layer's structured
   output — one schema serves all three, so it should be designed once, in the open,
   rather than three times in private.
6. **Where does the server run first?** macOS hosting keeps one codebase and has a
   renderer today; Linux is the real hosting target but opens the Objective-C-on-Linux
   fork (§5.1). Recommendation: ship on macOS, keep the CLI boundary clean, and treat
   Linux as a tracked gap rather than a rewrite.

The through-line of all of it: this codebase is not building a report editor. It is
building a portable, composable, machine-checkable way to turn data sources into
derived data objects — and that is a thing the industry currently pays dbt, Looker,
Cube, and ThoughtSpot a great deal of money for, locked to their clouds. The version
of it that fits in an 80 KB file, runs on a phone, refreshes on a schedule, and
accepts edits from both a designer and a language model — that version doesn't exist
yet. That is the opening.
