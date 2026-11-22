# MAD Designer — Strategic Analysis and the Path Forward

**Prepared 2026-10-22 by Claude Code, at the user's request; extended the same day with
the platform discussion (drivers as anything that returns a table, user-installable
drivers, display surfaces as a fourth seam, the macOS/Windows placement).** This file is
an analysis deliverable, not a project document: it makes no code changes and may be
edited or deleted freely. It reads the state of the repository (`master` at `774a52b70`)
and the tracking/design documents, and answers five questions honestly:

1. What is this project worth, and should it continue?
2. What is the best path to the web front end — the stated primary goal?
3. How does it make money: open source, enterprise sale, or something else?
4. What are the most important tasks, in order?
5. What features and modernizations matter most?

Every judgement below is the author's; where the repository's own records disagree, that is
said. No sycophancy: the weakest claims in the existing documents are named in §4.

---

## 1. The verdict, up front

**Do not abandon this project. But change its framing.**

The engineering assets are rare and real: a 147k-line Objective-C codebase whose headless
engine — SQL generation, the portable store, the result-table cluster, both wire drivers —
**already compiles, tests and runs on Linux** against live MySQL and SQL Server, with
~1,200 Linux-side tests and ~2,000 iOS-side tests green, and byte-identical cross-platform
output for the document writer and seven export formats. Very few solo-built systems reach
that state; almost none do it with this documentation discipline. Throwing that away would be
a genuine loss.

The framing that must change is the category ambition. "World-class BI platform" read as
*compete with Power BI, Tableau, Looker, Metabase and Superset* is not a realistic outcome
for one developer and an AI pair, in a market dominated by companies with hundreds of
engineers and sales forces (Power BI alone holds ~27% category share; the open-source slice
is already well served by Metabase and Superset). The honest version of the goal is:

> **World-class in a niche the incumbents structurally cannot occupy: portable, on-prem,
> embeddable reporting whose artifact — the `.mad` — is an 80 KB, diffable, git-able,
> deterministic file that runs on a phone, a laptop and a server, renders identically
> everywhere, and whose data layer is anything that can return a table — a database, a
> Web service, the user's own server.**

That niche is real, it is unclaimed, and this codebase is closer to it than anything else on
the market (§6). The plan in `MAD_FUTURE.md` already describes it; what that document calls
"a model format that runs on a phone, a laptop, and a server, and carries its own
presentation" is exactly the position. What `MAD_FUTURE.md` does not contain — and what this
report adds — is the sequencing discipline: the project's current trajectory is
**upstream-of-customers**, and the single greatest risk is not technical failure but another
year of infrastructure excellence with zero external signal.

---

## 2. What the project is, measured

### 2.1 The repository

- 4,792 commits, first commit 2012-01-02 — a 14-year codebase, single author.
- Activity pattern: heavy 2015–2017 (the original build-out), near-dormant 2018–2024
  (~30 commits in 5 years), revival 2024-07 (v9.0, "back to the App Store"), then a
  transformation beginning 2026-09: **298 commits in October 2026 alone**, almost all of
  them agent-assisted, test-first feature work (Linux port, export seam, barcode
  reintegration, SQL entry — `TASKS.md` §7–§16).
- ~147,000 lines of first-party source across 13 frameworks plus the app (63k lines in
  `MADDesigner` alone); ~62,000 lines of test code.
- The `Compressor/` directory carries the vendored library build tree (7.4M lines of C in
  build artifacts — the build system is the largest single "component" on disk).

### 2.2 Where the engineering stands (all of this is already landed on `master`)

| Area | State |
|---|---|
| Bug register | `BUGS.md`: 76 entries, 56 fixed and archived; of the rest, 12 are documented deliberate non-defects; ~4–8 genuinely open defects remain (`SYBDATETIME4` epoch, four `MADMySQL` items, eight `MADFileManager` items, the render-cache staleness mechanism) |
| Portable store | Phases A–D landed: `MADocument` is a `UIDocument`, the store is the project's own SQLite schema, Core Data survives only in the app-side legacy converter (`TASKS.md` §9) |
| Build system | Compressor matrix + XCFrameworks done; all nine vendored libraries at current versions; fresh-clone simulation green (`TASKS.md` §6, Phases 0–7) |
| Linux port | Phases A–F of `MAD_LINUX.md` done: ten frameworks compile against GNUstep/libobjc2 inside a pinned Docker image; 124 test executables green; `mad` CLI builds and runs in a 283 MB runtime image; live MySQL (44/44) and SQL Server (29/29) refreshes from inside the container (`MAD_LINUX.md` §9, `Linux/README.md`) |
| Extensibility seams | Driver registry (`ROADMAP.md` §5.1) and export registry (`§5.2`) landed: seven export formats (`pdf`, `html`, `html-flow`, `text`, `csv`, `json`, `json-report`), the first six byte-identical on Apple and Linux |
| Reproducibility | `mad write --reproducible` writes the same 16,261-byte `.mad` on both platforms, pinned by a Linux test |
| SQL entry | Phases A–D merged `c48a39fb7`: paste-a-SELECT support, parser/resolver/compiler, golden SQL tests, persisted `sqlSourceText` (`MAD_SQL_ENTRY.md`) |
| Barcodes | `MADBarcodes` modernized on zint 2.16.0, element always available (`TASKS.md` §15) |

### 2.3 What the next stretch of work is, per the queue

`TASKS.md` open entries, in file order: **§1–4 keychain/credential flow** (the product
blocker, see §4.1), §6 residual build work, §10 third-party licence compliance (blocked on
an owner decision), §13 warning cleanup (app and MAD remain), §14 formatter performance
(the per-row page-index copy, an O(rows²/page) allocation), plus the deferred Linux PDF
writer (`MAD_PDF_LINUX.md`, blocked on the user's research) and the deferred Phase E of SQL
entry.

---

## 3. The genuine assets — what this project has that competitors don't

These are the load-bearing claims for every recommendation that follows. All five are
*measured*, not aspirational.

1. **The engine runs on Linux today, against real databases.** The honest go/no-go in
   `MAD_LINUX.md` §9 (Phase D) was met and passed on 2026-10-16: `mad` builds in the image,
   refreshes 50 rows from MySQL 8.4 and 20 from SQL Server 2022 over the wire, and the two
   live suites pass from inside the container. The toolchain risk that could have killed the
   web goal — Objective-C on GNUstep — is de-risked by 123 green test executables, not by
   hope. The remaining risk is *maintenance* of a niche toolchain (§12), not *whether it
   works*.

2. **Byte-identical, cross-platform, deterministic output.** The same `.mad` writes the same
   bytes on both platforms; `json`, `csv`, `text`, `html`, `html-flow` and `json-report`
   exports are digest-identical. This is the single most unusual property of the codebase —
   it means the format is *specifiable* and the renderer is *testable*, which is precisely
   what an open spec (§8) and an embedded-OEM offer (§6.2) need as proof.

3. **The `.mad` format is a real product artifact.** A portable container (bzip2-tar with a
   v1 magic header), a documented SQLite store schema, and companion files whose formats are
   documented (`MAD_FORMAT.md` §5). Reports-as-code — the property the dbt generation pays
   for with YAML, but with presentation attached and no server required.

4. **The test discipline.** ~2,000 iOS test methods across 12 suites (MAD alone: 696),
   123 Linux executables / ~1,200 tests, live database suites that skip rather than fail,
   golden-SQL tests, round-trip fixtures, benchmarks on the ingest path. This is the
   moat's foundation: every external claim (portability, determinism, correctness) is
   executable, not asserted.

5. **The documentation.** `MAD_FORMAT.md`, `MAD_DATA_OBJECT.md`, `MAD_LINUX.md`,
   `ROADMAP.md`, `TASKS.md`, `BUGS.md` and the rest form the best-documented solo project of
   its size the author has seen. These documents are not overhead; they are the sales
   collateral and the AI-assistability substrate (§11.5).

6. **The agent workflow itself.** The October 2026 velocity — four substantial features in
   three weeks, each test-first and merge-gated — is the proof that one developer plus Claude
   Code can ship at a small-team rate. This is the scaling mechanism the whole plan depends
   on, and it is worth stating explicitly: the strategy is *not* "solo developer vs. the BI
   industry"; it is "one developer with a 10× force multiplier vs. a niche."

7. **The platform is already half-real, not promised.** The extensibility the project
   synopsis names — new database types (subclass `MADDatabase`), new export formats, new
   element types — now has a registry for the first two and a working example of the third
   (the barcode element). Because a driver's contract is *"return a schema and rows in
   table form"* and the execution seam is typed `id <MADDataTableWriting>`
   (`MAD_DATA_OBJECT.md` §3.3), a driver can front anything that can be made to look like
   a table: a Web 2.0 REST service, the user's own server, a file. That is the platform
   story in one sentence, and it changes the market position (§6): this is not "BI for
   MySQL/SQL Server shops," it is a reporting platform whose data layer is pluggable.
   The one gap between the promise and the platform is named in §4.7.

---

## 4. The honest liabilities

### 4.1 The shipped product is blocked by a bug the project itself rates highest

`TASKS.md` §1: the double keychain prompt on document creation, with the user's own words —
*"It seems like this keychain flow is very important to getting right, or no one will ever
use the software."* **It has been open since before September 2026, while the last three
weeks of work went to barcodes and SQL entry.** None of the recent work is wasted — but the
sequencing is evidence of the pattern named in §1: the project gravitates to the deep,
satisfying, upstream problem and away from the small, dull, customer-facing one. That is the
single most important behavioural finding of this analysis. The fix is a decision plus a
small amount of code (`TASKS.md` §1 names the design question: platform AutoFill vs. the
app's own keychain item); the tests in §4 are already specified.

### 4.2 No distribution, no discoverability, no revenue path

- The App Store listing is not findable by web search under "MAD Designer" — the name
  collides with MIDI Designer and generic "MAD" noise, and nothing about the app surfaces.
  Whatever v9.0's install base is, it is not discoverable, which caps it near zero as a
  channel today.
- There is no monetization in the app (`TODO.md`: "Add store / monetization pathway" is
  Secondary) and no pricing anywhere in the documents.
- The product is **not for sale** and has no US customer base (confirmed by the user,
  2026-10-22). The positive signal that exists is qualitative: the user has shown the
  software to people and it was genuinely useful to them. That is real early validation
  of the core loop — connect, query, design, view — and it is the seed of the
  design-partner recruitment in §6.2; it is not revenue, not a channel, and not yet a
  market.

### 4.3 The engine covers two sources; the market speaks three

MySQL, SQL Server, SQLite. **No PostgreSQL** — the default choice of the entire
open-source/self-host BI audience (Superset itself requires Postgres; Metabase's community
runs on it). `TODO.md` correctly lists "every other datasource" as an ambition, but
Postgres is not "another datasource" — it is *the* addressable-market lever. One driver
(and the registry makes it an additive framework, not a core edit) roughly doubles the
market the engine can serve, and it is the cheapest possible proof that the extensibility
promise in the project synopsis is real.

### 4.4 The product gaps vs. any BI tool a buyer has seen

- **No charts in reports.** The query visualization canvas exists; report elements are
  labels, data labels, aggregates, barcodes, images. Every competitor's first screen has a
  chart. `TODO.md` lists "chart type" as Future. This is the single biggest parity gap in
  the product.
- **No dashboards** (multi-report composition) and **no runtime parameters** (refresh
  "as of last month" without editing the design). Neither exists in the store model or any
  design document.
- **No scheduling/delivery** — the classic BI wedge ("email me the PDF Monday 7am") is a
  server-side feature the CLI is already 90% shaped for.
- The stand-alone viewer target does not link (`ROADMAP.md` §2.1) and what it should be is
  an unmade product decision.
- UI tests are effectively broken (the XCUITest environment sees an empty accessibility
  tree — `TASKS.md` §16 Phase D's recorded gap).

### 4.5 The web product's missing 80% is not the engine

`MAD_FUTURE.md` §4.1 is right that the engine already runs without a UI, and its §5.2 list is
the honest catalogue of what does **not** exist anywhere in the codebase: identity, orgs,
roles, ACLs, a credential vault, licensing/billing, scheduling, audit, an API surface with
keys and scopes. Every one of those is product work that agents can help build but no
engineering elegance can skip. A multi-tenant web product is not "the CLI with HTTP" — it is
a platform around the CLI. §7 sequences this so the platform is built **after** external
signal exists, not before.

### 4.6 Licence hygiene is real and unfinished

`TASKS.md` §10 / `LICENSE_COMPLIANCE_PLAN.md`: `mysqlclient` 8.4.10 is GPLv2 — a shipping
blocker for any proprietary binary, including the Linux runtime image **the moment it is
distributed**; three committed components carry no licence grant at all (the Karl Kraft
MySQL connector, `NSData+AES256`, `NSOperation+Advanced`). All are named, all have
replacement plans, none is done. None of this blocks *development*; all of it blocks
*shipping or publishing* anything server-side. The MariaDB Connector/C swap is the one
real piece of work (27 `mysql_*` entry points, same C API).

### 4.7 The "anything that returns a table" promise has one real hole

The extensibility story is true at the execution layer — `MADDatabase`'s abstract seam is
`executeSQL:fieldKeys:onConnection:intoResultTable:withError:` and the destination is any
writable table — but the *compilation* layer is shared: `MADQueryFull` compiles the query
graph to one SQL text per driver (`MAD_DATA_OBJECT.md` §3.2). For a REST or Web 2.0
driver, the natural input is the graph (tables, fields, predicates, groups), not SQL
text; such a driver today would have to parse SQL back out of the string it was handed.
The fix is a per-driver compilation hook — the same shape the user sketched in `TODO.md`
for Salesforce SFQL back in 2012 — and it belongs in the engine-contract stage (Stage 1,
§7.2) so that "install a driver" in the server product means "install a driver for
anything," not "for SQL databases that happen to match our dialects."

A second, smaller consequence for the server: **a user-installed driver is arbitrary code
in the server process.** The registry's `+load` registration and the Linux whole-archive
linking (`MAD_LINUX.md` §9 Phase D) work for trusted, first-party drivers. A driver
marketplace (`MAD_FUTURE.md` §8.3) needs an answer to plugin trust — signing, sandboxing,
or running drivers in isolated worker processes at the CLI boundary — before it can
exist. That is a Stage 4 concern, but it must be designed into the API, not bolted on
after drivers are installed in production.

---

## 5. The market reality (2026)

The claims below are from the research performed for this report; sources are listed at the
end.

- **BI is consolidated.** Power BI (~27% share) and Tableau (~18%) dominate; the
  consolidation trend is toward analytics *embedded in other applications* rather than
  standalone tools. Standalone BI for a newcomer is a red ocean.
- **Open-source/self-host BI is served.** Metabase (AGPL open-core, ~$85–100/mo cloud
  entry, embedded React SDK as a real business) and Superset (Apache-2.0, Preset the
  commercial sponsor) already occupy "self-host BI," each with real ops burden (Postgres +
  Redis + workers) and real feature gaps (Metabase's governance is paid-tier; Superset's
  usability is technical). Both are *server-bound and dashboard-shaped*: neither produces a
  portable, diffable, embeddable report artifact. That is the crack.
- **Embedded analytics is a large, real market** — estimates range $11B–$91B for 2026
  depending on the firm's definition, all pointing up — served by OEM vendors (Telerik,
  Stimulsoft, Logi) whose model is ISVs embedding reporting inside their own products. The
  `.mad` + CLI + engine *is* an OEM SDK in shape. The missing ingredient for this market is
  a sales channel, which is why §6.2 recommends the route that does not require building one
  from nothing.
- **Mobile BI is a real niche with a real trend** — 67% of enterprises rate mobile analytics
  access important, the segment is forecast at ~21% CAGR, and the leaders' mobile apps
  (Power BI Mobile, Tableau Mobile) are companions, not designers. Mobile-first newcomers
  (Anywhere BI, Zing Data, both 2026) prove demand and also prove the competitive threat:
  AI-native mobile BI is forming while this project has no web presence at all.
- **Reports-as-code is a respected, growing subculture** (dbt's model — portable,
  versionable definitions with the heavy lifting owned by an engine) — and it is exactly the
  architecture this codebase has, with one addition dbt lacks: presentation attached.

The honest reading: the market is hostile to *another BI tool* and structurally
unoccupied for *a portable reporting artifact with an engine attached*.

---

## 6. The value scenarios, ranked honestly

### 6.1 App Store (keep doing; it is not the business)

Realistic outcome: low revenue, low risk. Mobile BI *design* on iPad is a prosumer niche,
and the product is **not currently for sale — the App Store listing has lapsed and
renewing the developer account awaits funds** (2026-10-24). So the first monetization
milestone here is *renewal plus* listing it (free viewer, paid designer, or paid at
all), not optimizing price. This scenario does **not** gate the open-source launch
(Appendix A): the App Store audience and the open-source audience barely overlap, and
the app returns as a later chapter — renew, fix the keychain bug (§9), release — at
which point it is its own small announcement to a community that already exists. The
app's eventual role is a **flagship and a billboard**: a demo a potential OEM partner or
design customer can touch. Freemium viewer + paid designer, priced low ($10–20 one-time
or $2–3/mo), is the ceiling-appropriate model; treat revenue as lead generation, not
income.

### 6.2 Embedded / OEM licensing (best fit for the technology; slowest to first revenue)

The engine, the `.mad` format, the CLI and the export formats together *are* an SDK for
ISVs who need self-serve reporting inside their own products — the Telerik/Stimulsoft
model, on a smaller, more focused surface: "your customers' reports are a portable file,
rendered by your app through our engine." The driver seam makes this pitch stronger than
a fixed-source engine: an ISV can front its *own* product's data with a driver — "your
customers report on your platform's data through a driver you write" — which is the
"anything that returns a table" promise wearing a contract. The realistic route for one
developer is **not** building an OEM sales organization — it is 1–3 design-partner ISVs
(vertical SaaS with a SQL Server/MySQL estate: ERP, field service, practice management),
found by inbound content and the open engine (§8), on rev-share or annual licence terms.
Expected outcome: $0 for a year or more, then sticky, high-margin licensing revenue; or
acquisition interest from exactly the embedded-analytics vendors whose products this would
complement.

### 6.3 Open-core self-hosted server (the strategic direction; the dbt/Metabase pattern)

Open the format spec and the engine; keep the designer app and the server paid. This is the
only scenario in which "world-class" has any plausible route for a solo developer: the
portable artifact spreads through the data/analytics-engineering community the way dbt
models and Metabase dashboards did, and the commercial product is the *hosted/enterprise*
layer (scheduling, vault, ACLs, audit — `MAD_FUTURE.md` §5.2's list) that self-hosters
eventually buy. User-installable drivers complete the picture: the server product becomes
a platform whose data layer the customer extends (drivers for their internal services,
Web APIs, files) — the same plugin flywheel that grew Metabase — and a driver marketplace
(`MAD_FUTURE.md` §8.3) is the natural third revenue line once the ecosystem exists.
Expected outcome: 12–24 months of near-zero revenue while the artifact finds its
community, then either a small durable business or a strong acquisition position.
The licence hygiene work (§4.6) is the *prerequisite*, and it is already planned.

### 6.4 Closed-format enterprise sale (not recommended)

Selling a closed-format, proprietary BI server against Metabase/Superset/Power BI without a
sales force, a brand, or a community is the scenario with the worst odds. The moat a closed
format buys is worth nothing until someone wants the format, and nobody will have heard of
it. The one closed thing that *is* worth money is the designer experience — keep that
proprietary.

### 6.5 Abandonment — not now, but with defined criteria

The assets in §3 are too strong and the carrying cost too low to abandon while the work is
enjoyable. But the honest terminal question should be scheduled, not deferred: **if there
is no external signal by end of 2027** (no paying users, no OEM design partner, no
meaningful community traction on an open engine), then the project's value is portfolio
and passion — a legitimate outcome, at which point open-sourcing everything is the
terminal value play, not a failure. §12 states the trigger precisely.

---

## 7. The web front end: current state and the concrete plan

### 7.1 Current state, in one paragraph

The hard 80% of the web goal is already done: the engine runs headlessly on Linux against
real databases, with a runtime Docker image and byte-identical exports. What remains is
(a) the product platform around the engine — none of which exists — and (b) the browser
UI — none of which exists. The cheapest, highest-signal web artifact is therefore **not**
the full clone `MAD_FUTURE.md` §4.3 describes as the end state; it is a *viewer server*
built on artifacts that already exist (`json`, `html`, `html-flow` are already the API
payloads), with the full three-tab clone as the long-run destination.

### 7.2 The staged plan

**Stage 0 — hygiene and the business fork (weeks, mostly decisions).**
- Fix the keychain/credential flow (`TASKS.md` §1–4) — the shipped product's blocker.
- Make the open/closed decision (§8) — it changes licence work and marketing.
- MariaDB Connector/C swap + the three unlicensed rewrites (`LICENSE_COMPLIANCE_PLAN.md`
  §3) — required before *publishing* the image or any server binary.
- Content-hash the render-cache key (`MAD_FORMAT.md` §8.4) — a known stale-page mechanism
  that must not be inherited by a server that renders for many clients.

**Stage 1 — the engine contract (`MAD_DATA_OBJECT.md` phases 1–2).**
Split SELECT-list construction from execution; add the describe/execute protocols; make the
query own itself (retire the three hardwiring points named in `MAD_DATA_OBJECT.md` §3.6).
No store change, no UI change, provable by existing suites. This is what turns "the CLI's
verbs" into "the server's API" — the document's own §6 makes exactly this point: the CLI is
a *client* of the engine, and the entry point is the missing piece. Weeks, not months.

**Stage 2 — MAD Server v0 (the viewer server).**
A thin service in front of `mad` (the subprocess shape `MAD_LINUX.md` §2 already
recommends, or a small linked daemon if measured to matter): a document catalog, `refresh`
behind a trivial queue, and `export` serving `html`/`html-flow`/`json` to the browser.
**Single-user first** — no orgs, no ACLs, no billing; those are Stage 4 and they are
gated on external signal. Linux PDF stays deferred (`MAD_PDF_LINUX.md`): browser-print of
the HTML facsimile covers every human case; only unattended server PDF needs the writer.

**Stage 3 — the web viewer UI.**
File list, paginated viewer, refresh button, export. This is the minimum product-facing
web artifact, and it is weeks-to-months of work because the server is already serving the
payloads. This is also the artifact a design partner or OEM prospect can be shown.

**Stage 4 — the platform layer — only after signal.**
Identity, orgs, roles, ACLs, vault, scheduling, metering (`MAD_FUTURE.md` §5.2). This is
the largest single block of new product surface in the entire plan, and building it before
anyone has asked for it is the most expensive mistake available. `MAD_FUTURE.md` §5.2's own
architecture note is right that all of it attaches *around* the CLI boundary — which is why
it can wait.

**Stage 5 — the web designer, tab by tab.**
Query tab first (the differentiator), designer canvas last (the most expensive UI work —
a Figma-shaped canvas is months). Feature parity with the iOS app is the *vision*; it must
not be the MVP bar.

**Parallel track — the Postgres driver.** The one engine-side investment with
disproportionate market effect (§4.3); also the cleanest public proof of the extensibility
promise when the engine opens.

### 7.3 macOS and Windows, honestly placed

- **macOS is close, cheap, and not a detour.** The app already ships "My Mac (Designed
  for iPad)" (`CLAUDE.md`), so a Mac presence exists today. The meaningful next Mac step
  is a *native* macOS `mad` (no simulator dance): the macOS slices for every vendored
  library already build (Compressor Phase 4–5), and the one remaining blocker is the
  UIKit imports in `MADFoundation`'s four triaged files (`ROADMAP.md` §2.1 third bullet)
  — the same headless-target surgery Linux already proved, on an easier platform (Apple
  Foundation, no GNUstep). A native macOS *app* beyond Designed-for-iPad is an
  AppKit/Catalyst rewrite of 63k lines and is not worth it; the web client is the desktop
  app.
- **Windows is served, not ported.** The engine runs in Docker, which Windows hosts
  natively; the web client runs in a browser, which Windows has. A native Win32 port is
  a non-starter on the evidence: Microsoft's own WinObjC bridge was archived 2025
  (`MAD_LINUX.md` §6), and the format documents' "reader on Windows" obligation
  (`MAD_FORMAT.md` §7) is satisfiable by a browser/SQLite-WASM reader long before any
  native port. Windows is a *deployment target* of the web product, never a port.

---

## 8. Open or closed? — the fork, with a recommendation

`MAD_FUTURE.md` §8 ends with this fork un-decided ("is the format open?"), and its §10.4
says to decide *before* the spec is published. This report's recommendation:

- **Open the format spec** (`MAD_FORMAT.md` is nearly publishable as-is). A published,
  versioned spec is marketing that compounds and costs nothing to give away — and it is the
  credibility the OEM story (§6.2) and the reports-as-code community (§5) both require.
- **Open the engine and the CLI under a permissive licence (Apache-2.0)** once Stage 0's
  licence hygiene lands. The engine's *existence* is the pitch; giving it away is the
  distribution channel a solo developer cannot otherwise buy. The open-core economics
  (Metabase: AGPL core, paid enterprise tier) are proven in exactly this market.
- **Keep proprietary: the MAD Designer app** (the designer experience is the only thing a
  closed moat actually protects) **and the server's platform layer** (the Stage 4 list —
  vault, ACLs, scheduling, audit — which is precisely what self-hosters pay for).

This is the dbt/Metabase/Superset pattern, applied to a codebase whose licence state is
already audited and whose test discipline can back every claim the spec makes. The
alternative — closed everything — caps the ecosystem at one person's sales capacity, which
is the binding constraint of the entire project.

---

## 9. The most important tasks, in order

1. **Keychain/credential flow (`TASKS.md` §1–4).** The user's own words say it blocks the
   product. It is a decision plus days of work plus already-specified tests. Do it now —
   before any further upstream work — because its continued deferral is the clearest
   evidence of the §1 risk pattern.
2. **The open/closed decision (§8).** A business decision, not code; it gates licence work
   and every piece of marketing.
3. **Licence hygiene (`TASKS.md` §10).** MariaDB swap + three rewrites. Gates publishing
   the Linux image and any server binary; the plan exists (`LICENSE_COMPLIANCE_PLAN.md`
   §3); it is honest mechanical work with real tests behind it.
4. **The engine contract (`MAD_DATA_OBJECT.md` phases 1–2), plus the per-driver
   compilation hook (§4.7).** The prerequisite for the server's API shape; no behaviour
   change; weeks. The hook is small, but it is what makes "install a driver" mean
   *anything*, not just another SQL dialect.
5. **Viewer server + web viewer (Stage 2–3).** The first web artifact with a face.
6. **Postgres driver (parallel).** The market lever.
7. **Report-level charts.** The single biggest product-parity gap vs. every BI tool a
   buyer has seen; the element seam (`ROADMAP.md` §5.3, still design-only) is the vehicle.
8. **Formatter performance (`TASKS.md` §14.1).** The per-row page-index copy is a real
   O(rows²/page) defect; fix before a server renders large reports.
9. **Stand-alone viewer decision.** Fix or delete it; as `MAD_FUTURE.md` §8.1 notes, it is
   the natural free client in a freemium App Store model.
10. **Everything else in the queue** (warning cleanup §13, SYBDATETIME4, MADFileManager
    items, SQL entry Phase E, Linux PDF writer) — real work, none of it on the critical
    path to value.

---

## 10. Features and modernizations that matter — and the ones that don't

**Do:**
- Postgres driver (market); charts (product parity); runtime parameters (any real reporting
  product needs them); scheduled delivery (the wedge); AI report-building on the
  `MAD_FUTURE.md` §7 reject-and-repair pattern (a genuine differentiator the architecture
  is already shaped for — the model writes the graph, the engine validates, and the user's
  agent fluency is exactly the skill it needs).
- Keep Objective-C. **Do not rewrite in Swift or Python.** The Linux checkpoint has passed;
  the two-implementation drift risk (`MAD_LINUX.md` §2's core argument) is real and the
  rewrite trigger is already defined (§9 Phase D failing). The codebase's "old language"
  is not a liability; it is the platform bet that already paid.
- Treat **display surfaces as a fourth seam.** The render pipeline is printer-first by
  design — page counting and grouped page breaks, the genuinely hard part — but a
  "modern" display (continuous, responsive, interactive) is not a UI rewrite; it is a
  *renderer* beside the exporters. The section layout and element walk are already
  platform-neutral (`MADReportPageBuilder` + `MADDocumentRenderDataSource`), `html-flow`
  is already the first non-page-shaped render, and the exporter registry's shape applies
  unchanged. The honest sub-task inside it: element types need a per-surface render
  contract (today `-drawInRect:` is UIKit's and the HTML exporter draws text boxes only),
  so a modern display and the Linux PDF writer share the same seam work.
- Finish the warning sweep (`TASKS.md` §13, app + MAD) — cheap, mechanical, keeps the
  analyzer signal meaningful.
- Reconsider CI. The 2026-10-17 decision against it was reasonable for a proof-of-concept;
  it is wrong for a two-platform byte-identity product. One GitHub Actions job running
  `./Linux/build.sh --verify` per push turns "the outputs agree" from a manual ritual into
  a gate, and it costs a few hours of YAML. The iOS suite stays the simulator job it is.
- Content-hash the render-cache key before any server rendering (Stage 0).
- Modernize the app's dead weight on the existing latitude: `MTPaper` (~70 files) is a
  known mess, `MADFeedback` is unused, `Scrimpter` is parked. Behaviour-safe cleanup is
  welcome per the project's own rules — but none of it before items 1–3 above.

**Don't:**
- Don't build the multi-source/subreport rig (`MAD_DATA_OBJECT.md` §5 — deliberately
  unscheduled; the composition story sells better once one product ships).
- Don't build Stage 4 (the platform layer) before external signal — it is the most
  expensive unforced error in the plan.
- Don't chase byte-identical PDFs on Linux (`MAD_PDF_LINUX.md` already says why it is
  impossible); browser-print covers humans, and structural equivalence is the right bar.
- Don't port UIKit anywhere (`MAD_LINUX.md` §6: even Microsoft abandoned that idea).
- Don't let dashboards, dashboards-with-parameters, warehouse scale, or AI eat the
  roadmap: the product's stance — "reports sized for people, not petabyte scans" — is a
  feature, and `MAD_FUTURE.md` §6 already says to keep it.

---

## 11. Marketing ideas that cost almost nothing

1. **Docs-as-marketing: publish the format spec.** `MAD_FORMAT.md` is ~90% of a
   launch-quality spec. "A report that fits in 80 KB, runs on a phone, a laptop and a
   server, and renders byte-identically everywhere" is a Show-HN-grade hook, aimed at the
   dbt/analytics-engineering crowd that already pays for portable, diffable, engine-owned
   definitions.
2. **The CLI as the demo.** A Docker one-liner (`docker run … mad inspect sample.mad`) is
   a better demo than any landing page, and it already exists as `Linux/verify-cli.sh`'s
   fixture set. Ship the image publicly (after the MariaDB swap) as the "try the engine"
   artifact.
3. **Fix the name.** "MAD Designer" is unsearchable (§4.2) and collides with a MIDI app.
   The server/open-engine product needs a distinct, searchable name; the format can be the
   brand (".mad reports"). Cheap, one-time, compounding.
4. **The on-prem/privacy wedge.** "BI that runs where your data lives — no cloud egress,
   no warehouse copy." The engine literally runs on-device on an iPad today; that is a
   security story regulated industries (healthcare, field services, manufacturing) will
   hear and Power BI Mobile will not make.
5. **The embedded pitch, targeted.** Vertical-SaaS ISVs with SQL Server/MySQL estates:
   "self-serve reporting inside your product; your customers' reports are a file, not a
   screenshot." Design-partner terms to the first two; case study is the second customer's
   price.
6. **The AI angle, later.** The `MAD_FUTURE.md` §7 loop (model emits graph JSON, engine
   validates, precise errors, repair) is one of the strongest AI-reporting architectures
   anywhere, and the user is already an expert at directing it. Mobile AI-BI newcomers
   (Anywhere BI, Zing Data) are validating demand right now; the wedge is "an AI that can
   only build reports it can validate."
7. **App Store as billboard** (after the keychain fix): free viewer, cheap designer, the
   sample reports as the demo. Expected revenue is small; expected *role* is first contact
   for OEM prospects.

---

## 12. Risks, named, and the abandonment trigger

1. **The upstream trap (highest probability).** The project keeps improving infrastructure
   forever — more byte-identity, more format work, more seams — because that is where the
   fun and the measurable wins are, while the keychain bug stays open and no one outside
   the repo ever sees the product. Countermeasure: items 1–3 of §9 have dates, and Stage 3
   (web viewer) has a deadline on the calendar, not in the queue.
2. **The niche-toolchain bus factor.** libobjc2 + GNUstep + CMake + Compressor is a stack
   exactly one person in the world maintains, on purpose. If the user stops, the project
   stops; open-sourcing the engine (§8) is also the recruitment channel that mitigates
   this.
3. **Competitive response.** Success in embedded/reports-as-code invites feature-matching
   from Metabase/Superset (both already have embedding APIs). The moat is the portable
   artifact + determinism + on-prem story — real, but thin; speed of the open spec matters
   more than secrecy.
4. **Licence exposure.** Publishing the Linux image before the MariaDB swap makes the GPL
   question real (§4.6). Stage 0 closes this; nothing server-side should ship before it.
5. **Scale ceiling.** The two-pass pull-everything model caps data size by design. Keep it
   (reports, not warehouses) and put snapshot caps in the server from day one
   (`MAD_FUTURE.md` §6's own constraint).
6. **The abandonment trigger, stated once:** by end of 2027, if none of — a paying user, an
   OEM design partner, meaningful traction on the open engine — has occurred, accept the
   project's terminal value as portfolio and passion, open-source the remainder, and stop
   investing. Not before: the assets in §3 are too strong, and the next 12 months are the
   cheapest possible test of the thesis in §5.

---

## 13. Summary

| Question | Answer |
|---|---|
| Abandon? | No. Assets are rare and measured; carrying cost is low. Re-test at end of 2027. |
| Direction | Open-core platform: open format + engine, proprietary app + server; user-installable drivers as the ecosystem flywheel; OEM licensing as the revenue route; App Store as the flagship. |
| Web goal | Engine: done and proven on Linux. Remaining: engine contract → single-user viewer server → web viewer UI → (signal-gated) platform layer → designer clone last. |
| Next task | Fix the keychain/credential flow (`TASKS.md` §1–4). Then the open/closed decision. Then licence hygiene. |
| Biggest product gaps | Postgres, charts, runtime parameters, scheduling, the per-driver compilation hook, a modern (non-printer) display surface, a working/distributed presence. |
| Biggest modernization wins | Keep ObjC; CI for the byte-identity gate; warning sweep; render-cache content hash; kill or fix the stand-alone viewer. |
| Biggest risk | Not failure — it is succeeding at the wrong thing: another year of upstream excellence with zero external signal. |

---

## Appendix A — The open-source playbook (2026-10-23)

The practical answers to "what do I open, when, and how." One developer, new to open
source: the whole design principle here is *minimum machinery*.

**One repo, everything open, under MIT.** The public repo is this repository, scrubbed
(§A.4): all thirteen frameworks, Compressor, `Linux/`, `CLI/`, the app, the docs, the
tests. The only thing ever kept private is the future **MAD Server platform layer**, which
gets its own private repo from its first day — that is where proprietary code lives, and
the open-core line is drawn there, not through the app. Do **not** split into engine+app
repos now: a split is a permanent tax (dual CI, cross-repo versioning, split PRs) paid
against an uncertain benefit. The app's source is not the moat — the App Store position
and the discipline are — and an open iPad designer is free marketing to exactly the
audience the project wants. A split can be revisited only if the app ever needs closed
components.

**Licence: MIT.** Simplest to administer, maximally permissive for the embedded/OEM buyers
the strategy targets, and it lets the private server reuse everything trivially. Apache-2.0
if a patent grant is wanted (more text, slightly better for enterprise); **not** GPL/AGPL —
copyleft requires enforcement capacity a solo developer does not have, and it repels the
ISVs §6.2 depends on. The `.mad` format is published as a free spec, with a one-line note
that the name is not covered by the code licence.

**What must happen before the repo goes public, in order:**

1. **Licence hygiene** (`TASKS.md` §10): the MariaDB Connector/C swap and the three
   unlicensed rewrites (Karl Kraft connector, `NSOperation+Advanced`, `NSData+AES256`).
   Contributors will not touch a repo containing unlicensed third-party code — it is a
   legal risk to *them*, so this is the true step one.
2. **Headers:** an SPDX line on every first-party file (scriptable pass, ~1,500 files;
   ideal agent work). One `LICENSE` file (MIT text); publish `THIRD_PARTY_LICENSES.md`
   and the FreeTDS LGPL notices alongside it.
3. **History scrub — required, measured.** `.git` is 683 MB: the old vendored trees
   (`3rdPartyProjects/`, `Compressor/source/`, the 1,797 legacy artifacts) still live in
   history. A `git filter-repo` pass over those paths shrinks the public repo to
   first-party code and removes old vendored GPL source from the public history — a
   provenance win, not just a size win. Keep the 14-year first-party history; it is part
   of the story. Verify `TEST-DB-INFO.md` / `run.log` never entered history (checked
   2026-10-23: clean) and grep for anything credential-shaped.
4. **CI, because publication changes the no-CI decision.** One GitHub Actions job running
   `./Linux/build.sh --verify` on every push, with a green badge in the README. An open
   repo without CI reads as abandoned before it launches. (An iOS-suite job on a macOS
   runner can come later.)
5. **The public surface:** rewrite the README (the current one is five lines) around the
   pitch below; `CONTRIBUTING.md` with the build commands and the project's test-first
   rule; `SECURITY.md`; `CODE_OF_CONDUCT`; issue templates (bug, driver proposal); PR
   template; DCO sign-off instead of a CLA.
6. **The name, decided before launch** (§11.3) — renaming after a community forms is
   painful, and "MAD Designer" is not searchable.
7. Optional but cheap: a lawyer's glance at `LICENSE_COMPLIANCE_PLAN.md` before the flip.

**The offer.** Yes — an open-source launch needs an offer, and it is **not** the web
product. The offer is three artifacts that already exist: (1) the published format spec
(`MAD_FORMAT.md` as a docs site), (2) the runnable engine — one `docker run … mad inspect
London.mad` command plus the sample documents, published as an image (after item 1), and
(3) the proof — byte-identical output across platforms, 123 green Linux tests, 14 years
of history. The App Store app is **not** part of the launch: the listing has lapsed and
its renewal awaits funds (2026-10-24), and the two audiences barely overlap. It returns
as a later chapter — renew, fix the keychain bug, release — as its own announcement to a
community that by then exists. The pitch in one line: **"a report is a file."**

**When.** As soon as items 1–6 land — roughly 3–6 weeks of part-time work. Two reasons
not to wait for the web designer: launches are one-shot (you get one Show HN), and the
story is already crisp; and opening *before* the web version means the community can help
build it, which is the burden-sharing motive itself. The realistic sequence: hygiene →
headers/scrub → CI + public surface → launch → then the driver tutorial and the web
server as community-visible work.

**Community, with honest math.** Open sourcing does not create a community; adoption
does, and adoption follows the launch by months. Zero contributors for the first several
months is the normal curve. The flywheel specific to this project is the
**driver-authoring tutorial** ("write a MAD driver in an afternoon" — the seams are
already real): each driver is a contribution that expands the platform, and the Postgres
driver is the flagship example — built in public, or labelled a first-class first
contribution. The ongoing job: answer every issue, cut monthly releases, keep GitHub
Discussions open. Launch venues: Show HN, r/selfhosted, r/dataengineering, the dbt
community, LinkedIn for the enterprise angle. Expectation to hold: the immediate payoff
of open-sourcing is distribution and inbound interest (OEM inquiries, design partners);
shared development burden is the 6–12+ month dividend, not the launch-day one.

## Sources (market research, 2026-10-22)

- Embedded analytics market sizing: [The Business Research Company via GII](https://www.gii.tw/report/tbrc1973443-embedded-analytics-global-market-report.html), [Research and Markets](https://www.researchandmarkets.com/reports/5767496/embedded-analytics-market-report), [Research Nester](https://www.researchnester.com/reports/embedded-analytics-market/8549), [Stratistics MRC](https://www.giiresearch.com/report/smrc2075074-embedded-analytics-market-forecasts-global.html)
- Open-source BI licensing/models: [Metabase vs Superset 2026 (elest.io)](https://blog.elest.io/apache-superset-vs-metabase-vs-redash-which-open-source-bi-tool-to-self-host-in-2026/), [Tasrie IT Services 2026 comparison](https://tasrieit.com/blog/best-free-open-source-bi-tools-2026), [open-source analytics payment models (Monetizely)](https://www.getmonetizely.com/articles/what-payment-models-work-best-for-open-source-data-analytics-tools)
- Mobile BI market: [SNS Insider mobile BI forecast (GlobeNewswire)](https://www.globenewswire.com/fr/news-release/2026/04/08/3269944/0/en/Mobile-BI-Market-Size-to-Hit-USD-134-04-Billion-by-2035-Driven-by-Real-Time-Analytics-and-Cloud-Based-Data-Access-Report-by-SNS-Insider.html), [BI apps for iPad (Slashdot)](https://slashdot.org/software/business-intelligence/ipad/), [Anywhere BI (Product Hunt)](https://www.producthunt.com/p/anywhere-bi), [BI options for iPhone (GetApp)](https://www.getapp.com/business-intelligence-analytics-software/business-intelligence/os/iphone/)
