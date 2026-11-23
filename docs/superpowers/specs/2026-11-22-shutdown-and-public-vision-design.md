# Engine Shutdown Timeout and Public Vision — Design

**Date:** 2026-11-22
**Status:** Awaiting approval
**Repositories:** `mthomason/MAD` (docs + Windows client) and
`mthomason/mad.github.io` (marketing site)

---

## 1. Intent and the why

Two independent problems are addressed together because they share a
release window, not a code boundary.

1. **The Windows client can hang forever on shutdown.** `MadEngineClient.Shutdown()`
   sends `shutdown` with `CallOk`, which blocks on a synchronous stdout read
   with no timeout, and only then waits five seconds and kills the process. If
   the engine never answers, the client never reaches the kill. In CI this
   turned a 1m42s test failure into a 45-minute job timeout. The immediate
   cause of the red run was an intermittent export test, but the shutdown gap
   is what made it expensive.
2. **The public vision is framed around migrating from a named legacy
   product.** The current `docs/vision.md` has four directions, and the fourth
   is converting Crystal Reports (`.rpt`) files. The user wants the broader
   future direction the product actually has, keeps the capability in the
   internal backlog, and wants the public sites free of third-party brand
   names that the product does not already integrate.

## 2. Goals

1. Bound the engine shutdown: a normal shutdown still exits cleanly; an
   unresponsive engine is killed within a fixed budget, and the caller returns.
2. Prove the behavior with a test that starts an unresponsive stub process and
   asserts the process is gone and the call returned.
3. Rewrite the public vision as one coherent direction: a report is a
   function to a table; composable data objects; multi-source local
   materialization; an embedded/headless engine; presentation beyond paper;
   AI-authored documents; optional server/web deployment; and a generic
   legacy-source conversion possibility, with no third-party brand names.
4. Update the vision summary in `docs/index.md` to match.
5. Translate the revised vision and index summary into the five existing
   languages, with the same structure and no brand names.
6. Add one "The direction" card to the marketing site's "Build on MAD"
   section, linking the language-specific vision page, and translate it.
7. Leave all internal records (`MAD_FUTURE.md`, `TODO.md`, engineering plans)
   exactly as they are; Crystal Reports remains an internal backlog item and
   is not rewritten out of history.
8. Keep every existing gate green.

## 3. Non-goals

- Implementing any feature described in the vision.
- Removing Crystal Reports or `.rpt` references from internal engineering
  records, task queues, or the archive.
- Naming any third-party reporting product, cloud service, or competing tool
  on the public sites.
- Building a second, full vision page on the marketing site.
- Changing the app's feature set, supported databases, platforms, or versions.

## 4. Anti-goals

- A shutdown that still can block indefinitely on `ReadLine`.
- A general request timeout on every `mad serve` call; long exports should not
  acquire a new arbitrary deadline.
- A vision page that reads like a product roadmap, promises timelines, or
  claims future capabilities ship today.
- A translation that preserves the old Crystal framing in one language.
- A marketing card that links to the English vision from a translated page.

## 5. Constraints

- **Shutdown budget:** response wait and process-exit wait are bounded. A
  normal shutdown is unchanged. The new behavior is best-effort on failure and
  must not leave an orphan.
- **Tests:** the Windows client suite runs in the Windows verification
  workflow. The Mac has .NET 9; the projects target .NET 10, so the
  process-level test runs in CI (or on the Dell workstation). A pure helper
  can also be tested where .NET 10 is available.
- **Docs public set:** `docs/vision.md` and `docs/index.md` exist in English
  and five translations. The localization contract applies: translated
  pages mirror paths, code and identifiers are untouched, and structure
  counts match.
- **Marketing set:** five English pages plus the five translated pages.
  The new card is added to each language's `index.html`; the link points at
  the matching docs language (`/de/vision.html`, `/ja/vision.html`,
  `/pt-br/vision.html`, `/es/vision.html`, `/vision.html`).
- **Brand rule:** the public vision, index summary, and marketing card must
  not contain `Crystal`, `.rpt`, `SAP`, `Tableau`, `Power BI`, `Qlik`,
  `Looker`, or any other non-integrated product name. A generic phrase such
  as "legacy report formats" is allowed. The integrated SQL databases are not
  third-party product names in this sense and remain named where useful.
- **No invented facts:** distinguish shipping capabilities from proposals;
  no timelines, no release promises, no adoption claims.

## 6. Approaches considered

### 6.1 Shutdown

| Option | Trade-off | Verdict |
| --- | --- | --- |
| **A. Bound the shutdown response only** | Changes one method; normal requests keep their current semantics; a timeout kills the process tree and returns. | **Chosen** |
| B. Add a timeout to every `Call`/`SendRaw` | Broader safety, but long exports and refreshes could be cut off; changes the protocol contract. | Rejected. |
| C. Bound only `EngineService.DisposeAsync` | Fixes the test-host hang but leaves direct `MadEngineClient.Shutdown()` callers unbounded. | Rejected: the bug is in the client. |

### 6.2 Vision scope

| Option | Trade-off | Verdict |
| --- | --- | --- |
| **A. Full handoff shape** | Six forward directions plus the three roles; most accurate and most useful to developers; requires careful current/future labeling. | **Chosen** |
| B. Narrow to composable objects and multi-source | Less speculative, but drops the embedded, AI, and deployment directions the user wants. | Rejected. |
| C. Remove Crystal only | Smallest change, but leaves a thin vision and does not improve the product story. | Rejected. |

The user explicitly allowed a generic mention of legacy-source conversion;
it is included as a secondary possibility, not a headline direction, and no
brand names appear.

### 6.3 Marketing

| Option | Trade-off | Verdict |
| --- | --- | --- |
| **A. One "The direction" card** | Adds a direct path from the marketing site to the vision in every language; small translation surface. | **Chosen** |
| B. No marketing change | Leaves the marketing site without a vision entry point. | Rejected. |
| C. Full vision section/page | Duplicates the docs page and doubles the translation surface. | Rejected. |

## 7. The design

### 7.1 Bounded engine shutdown

`Windows/Client/Mad.Client/MadEngineClient.cs`:

- Keep the public `void Shutdown()` and make it call a bounded overload:
  `Shutdown(TimeSpan.FromSeconds(5))`.
- The bounded overload:
  1. Returns immediately if the process is null or has exited.
  2. Sends `shutdown` on a worker (`Task.Run(() => CallOk("shutdown"))`).
  3. Waits for the response up to the timeout.
  4. On timeout, kills the entire process tree.
  5. Waits for the process to exit for up to five seconds; kills again if
     needed.
  6. Swallows the worker's exception (a closed pipe after the kill is
     expected); shutdown is best-effort.
- A normal engine answers, exits, and the existing clean-shutdown test
  remains green.
- Do **not** add a timeout to `Call`/`SendRaw`.

Test seam:

- Add an internal constructor `MadEngineClient(ProcessStartInfo startInfo)`.
  The normal constructor continues to build the `mad.exe serve` start info.
- `Start()` uses the supplied start info when present; it does not append
  `serve` to a test-supplied command line.
- Add `<InternalsVisibleTo Include="Mad.Client.Tests" />` to
  `Windows/Client/Mad.Client/Mad.Client.csproj`.

Tests in `Windows/Client/Mad.Client.Tests/MadEngineClientTests.cs`:

- Keep `Shutdown_ExitsCleanly_WithNoOrphanProcess`.
- Add `Shutdown_WhenTheEngineDoesNotAnswer_ReturnsAndKillsTheProcess`:
  - Windows only (`if (!OperatingSystem.IsWindows()) return;`).
  - Start a stub via the internal constructor:
    `powershell.exe -NoProfile -Command "Start-Sleep -Seconds 60"` with
    redirected stdio.
  - Call `Shutdown(TimeSpan.FromMilliseconds(250))`.
  - Assert the call returned in less than five seconds and the stub process
    is gone (reuse `AssertProcessGone`).
- Add a small pure test for the timeout helper if the helper is extracted;
  it is optional and must not introduce a general request deadline.

### 7.2 Public vision page

Rewrite `docs/vision.md` in English with this shape:

1. **The direction: from reports to composable data.** The current
   report-as-table explanation stays the anchor.
2. **What exists today.** The portable `.mad` definition, the query graph,
   the local SQLite materialization, the four SQL drivers, the native apps,
   and the headless engine. State clearly what is shipping.
3. **Where it is going.** Six forward directions, each labeled as a
   proposal, not a shipped feature:
   - Composable data objects: a report's result becomes an addressable table
     other reports can query.
   - Multi-source local materialization: join independent sources in local
     SQLite without an external federation server.
   - Embedded and headless use: the engine inside other applications and
     devices, with `mad serve`, the CLI, and the driver seam.
   - Presentation beyond paper: interactive tables, native views,
     dashboards, and other presentations over the same data object.
   - AI-authored documents: a model proposes a structured document, the
     engine validates and executes it, and the user keeps an editable
     artifact.
   - Optional server and web deployment: self-hosted, browser-backed, or
     hosted, without redefining MAD as cloud-dependent.
   - A short secondary note: legacy report formats could be imported in
     future, without naming any product.
4. **Three ways to use MAD.** Application, embedded engine, AI-authored
   platform; one architecture, three delivery models.
5. **Why this matters.** The customer problem: reliable access to existing
   business data, local control, portability, and independence from
   proprietary services. Positive framing, not a protest.
6. **What this is not.** No timelines, no guarantees, no claim that the
   proposed directions ship.
7. **The guiding principle.** "The document defines the work. The engine
   executes it. The presentation makes the result useful."

Remove the page's links to internal working records
(`docs/project/product/MAD_FUTURE.md`, `docs/project/registers/TODO.md`).
Link the public developer pages instead:
`developers/data-object.html`, `developers/multi-source.html`, and the
format specification.

Add `title` and `description` front matter so the page has a real title and
social metadata; the translations carry translated versions plus their
`lang` tag.

### 7.3 Index summary

Replace the Crystal sentence in `docs/index.md` (and the five translations)
with a summary of the broader direction: composable data objects,
multi-source local materialization, the embedded/headless engine,
presentation beyond paper, and AI-authored documents. No brand names.

### 7.4 Marketing card

Add one card to the existing "Build on MAD" section of `index.html` and each
translated `index.html`:

```html
<div class="audience-item">
  <h3><a href="https://docs.everydayapps.com/vision.html">The direction</a></h3>
  <p>From reports to composable data objects, an embedded engine, and
  AI-authored documents.</p>
</div>
```

The translated pages link `/de/vision.html`, `/ja/vision.html`,
`/pt-br/vision.html`, `/es/vision.html`, or `/vision.html`, and translate the
label and sentence. The marketing site's existing page set, sitemap, and
links remain unchanged otherwise.

### 7.5 Localization

- Update `docs/vision.md` and `docs/index.md`, then each of
  `docs/<lang>/vision.md` and the vision line in `docs/<lang>/index.md`.
  One drafting agent per language, accepted by
  `check_translations.py --require-complete --lang <code>`.
- Update the marketing card in the five translated `index.html` files. One
  card per language; the marketing `check_site.py` and cross-repo fact check
  remain the gates.
- The English and translated pages must contain no third-party brand names;
  the brand grep is run over the public set after each language.

### 7.6 Validation

**Shutdown**
- The Windows client suite: the existing clean-shutdown test and the new
  unresponsive-stub test.
- Windows verification (the job that exposed the hang).
- No orphan `mad.exe`/stub process after the test.

**Docs**
- `jekyll build`.
- `check_links.py` (`broken: 0`).
- `check_translations.py --require-complete` (`missing/code/structure` all 0).
- `check_site_facts.py --docs docs --repo .` (versions, banned literals,
  moved paths, leaks).
- Brand grep over `docs/vision.md`, `docs/*/vision.md`, `docs/index.md`,
  `docs/*/index.md`: zero `Crystal|.rpt|SAP|Tableau|Power BI|Qlik|Looker`.
- The public vision page still distinguishes shipping from proposed.

**Marketing**
- `jekyll build -d _site`.
- `check_site.py` (`broken/missing/source-markdown/sitemap` all 0).
- Cross-repo facts against the Reports repository.
- Brand grep over the marketing pages: zero third-party product names.
- Screenshots of the English and one translated home page showing the four
  "Build on MAD" cards.

## 8. Delivery

1. **Shutdown:** a Reports branch and PR; the Windows client tests and the
   Windows verification job.
2. **Docs vision:** a Reports branch and PR with the English page, the index
   summary, and the five translations; docs checks and Linux verification.
3. **Marketing card:** a marketing branch and PR with the English card and
   five translations; site checks and live verification.

The three deliveries are independent. The shutdown PR can land first; the
docs and marketing PRs can land together.

## 9. What is left to the builder

- The exact vision prose and the final card wording.
- Whether the optional timeout-helper unit test is worth extracting; the
  process-level test is required.
- The exact placement of the card within the existing "Build on MAD" grid.
- The final translations, within the existing glossary and the
  machine-assisted policy.

## 10. Decision record

| Decision | Choice |
| --- | --- |
| Shutdown fix | Bound the shutdown response only; kill the tree on timeout |
| Shutdown test | Unresponsive stub process on Windows; keep the clean-shutdown test |
| Vision scope | Full handoff shape, all six directions and three roles |
| Legacy conversion | Generic mention allowed; no brand names |
| Third-party names | No non-integrated product names on public sites; internal records unchanged |
| Marketing | One "The direction" card linking the language-specific vision page |
| Translations | Five languages for docs vision/index and the marketing card |
| Delivery | Separate PRs for shutdown, docs vision, and marketing card |
