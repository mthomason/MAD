# Documentation and Marketing Site Program — Design

**Date:** 2026-11-22
**Status:** Approved approach; awaiting design approval
**Repositories:** `mthomason/MAD` (`/Users/michael/Projects/Reports`, branch
`docs/documentation-changes`) and `mthomason/mad.github.io`
(`/Users/michael/Projects/mad.github.io`, branch `main`)
**Sites:** <https://docs.everydayapps.com> and <https://mad.everydayapps.com>

---

## 1. Intent and the why

The documentation site is already multilingual and technically deep, but the
marketing site is not, and the two have drifted apart. The repository's records
also need organizing, several public statements are now wrong, and the
application's new localization is not yet recorded anywhere public.

The purpose of this program is twofold:

1. **Make MAD adoptable by outside developers.** The apps are unsigned, so the
   first audience is developers willing to run an unsigned build, read the
   format, embed the engine, and contribute. The public face should lead with
   the format, the engine, the CLI, the build paths, and the source.
2. **Bring the public face up to date and make it consistent.** Two sites, six
   languages, one set of facts (versions, platforms, databases, release links,
   test counts, localization status), and nothing published that contradicts
   another page.

Success, concretely:

- A developer can arrive at either site in any of the five translated
  languages, download the current macOS or Windows build, reach the format
  specification, the CLI, the developer guides, and the source, and never see
  a stale version or a contradictory claim.
- Both sites build cleanly, every internal link resolves, every public page
  exists in every language, and code blocks are byte-identical across
  translations.
- The repository's internal records have a readable index and a directory
  structure that says what each record is for.
- The application's localization is stated publicly and accurately.

## 2. Goals

1. **Correctness pass.** Find and fix every wrong, stale, or contradictory
   public claim: versions, release URLs, platforms, database support, test and
   framework counts, App Store status, localization status.
2. **Localization of the marketing site.** Rebuild it as a Jekyll site with the
   same five translations as the docs: Simplified Chinese, Japanese, Brazilian
   Portuguese, German, Latin American Spanish. `privacy.html` is translated
   with an "English original prevails" notice.
3. **Public developer documentation.** Promote a curated set of the engineering
   records to a public `docs/developers/` section, translated into the same
   five languages. Move, do not copy.
4. **Repository organization.** Group `docs/project/` by role, add an index,
   and update every inbound link without deleting content.
5. **Record the app localization.** State, in the docs and on the marketing
   site, that the app UI ships in English plus the five translations, with the
   machine-assisted caveat the app already carries.
6. **One version truth.** `app 0.7` for macOS and Windows, `engine 9.0
   (r4433)`, the iOS App Store return in early 2027, and release `v0.7.0` as
   the download target — everywhere.
7. **Keep licensing text untranslated.** `LICENSE`, `NOTICE`, the licence
   bodies, and the third-party licence register stay English and verbatim.

## 3. Non-goals

- Translating `BUGS.md`, `BUGS_FIXED.md`, the engineering registers, the
  strategy/future/migration records, the localization plans, or the agent
  prompt. They are working records and stay English-only.
- Translating licence texts or the third-party licence register.
- Rewriting the technical content of any promoted document. The public edition
  gets front matter, link repair, removal of author-local artifacts, and a
  bounded factual-consistency pass (§6.1.1). The record's technical substance
  is preserved.
- Merging the two sites onto one domain.
- Redesigning the application itself.
- Cleaning up old Git branches in the marketing repository.

## 4. Constraints

- **Two repositories, two domains.** `Reports/docs` builds the documentation
  site; `mad.github.io` builds the marketing site. Both are served by GitHub
  Pages from Jekyll.
- **GitHub Pages plugin set.** Only plugins available to GitHub Pages may be
  used: `jekyll-seo-tag`, `jekyll-sitemap`, `jekyll-relative-links`,
  `jekyll-optional-front-matter`, `jekyll-readme-index`,
  `jekyll-default-layout`, `jekyll-titles-from-headings`. The docs site already
  uses these.
- **Five translations, same codes.** Directory names `zh`, `ja`, `pt-br`,
  `de`, `es`; BCP-47 tags `zh-CN`, `ja-JP`, `pt-BR`, `de-DE`, `es-419`;
  English is the source and `x-default`.
- **Reports PR flow.** Every change reaches `master` through a branch and PR,
  with `git commit -s`, the DCO check, and "Linux verification". Docs-only
  changes do not alter Linux sources, but the required checks still run.
- **Marketing repository flow.** Work on a feature branch and open a PR
  against `main`; the repository has no master ruleset recorded, so the same
  discipline is applied by hand.
- **Legal text.** The English privacy policy is authoritative. A translation
  must carry a visible notice that the English original prevails, and
  `AGENTS.md` must be updated to permit the translation.
- **Internal material must not be published.** `DEVELOPER.md` and
  `TEST-DB-INFO.md` are working notes; `MAD_DATASOURCE_AND_CONNECTION_UX.md` is
  a private agent prompt. They stay excluded. The **local Docker test
  credentials** (`root`/`root`, `sa`/`Root1@Root2`, `mad`/`mad_test_pw`) are
  intentionally public: they are deterministic values for throwaway local
  containers, and publishing them makes the test path reproducible for agents
  and other developers. They are not treated as a leak. The `docs/superpowers/`
  tree (specs and plans) is internal and must be excluded; today it is not.
- **Legacy trees are preserved.** `docs/zh/project/` and `docs/zh/archive/`
  are a frozen legacy snapshot. Their relative links may be repaired
  mechanically, but their content is not reworked and the tree is not deleted.
- **Byte-identical code.** Code spans and fenced blocks must not change in
  translation. The existing validation checklist enforces this.
- **Tabs** for indentation in code and configuration, per the repository's
  style.

## 5. Approaches considered and chosen

### 5.1 Marketing site build

| Option | Trade-off | Verdict |
| --- | --- | --- |
| **A. Rebuild as Jekyll** | One layout and include set; 6 pages × 6 languages with chrome written once; same switcher and `hreflang` pattern as the docs; still deployed by GitHub Pages. | **Chosen** |
| B. Keep static HTML | No build step, but 36 copies of the header, footer, analytics, consent, and switcher, and every future change is 36 edits. | Rejected: the translation work makes the duplication unmanageable. |
| C. Merge into the docs site | One deploy and one layout set, but loses the `mad.everydayapps.com` / `docs.everydayapps.com` split and requires redirects for every existing URL. | Rejected: the two domains are established and indexed. |

### 5.2 Which internal records become public

| Option | Trade-off | Verdict |
| --- | --- | --- |
| **A. Move a curated set into `docs/developers/`** | One source of truth per document; the page *is* the record; adds the material developers need. | **Chosen** |
| B. Publish in place under `docs/project/` | No move, but Jekyll excludes the whole tree and the URL would be wrong; un-excluding individual files is fragile. | Rejected. |
| C. Link to the records on GitHub | Cheapest, but English-only, un-navigable, and does not serve adoption. | Rejected. |

### 5.3 Repository organization

| Option | Trade-off | Verdict |
| --- | --- | --- |
| **A. Subfolders by role plus an index** | Readable tree; link repair is the cost, gated by a link check and a site build. | **Chosen** |
| B. Index only | Lower risk, but the flat 44-file directory stays hard to read. | Rejected: it does not achieve "well organized." |
| C. Move internal records out of `docs/` | Cleaner separation, but many links outside `docs/` point into it. | Rejected: disproportionate churn. |

### 5.4 Translation scope

| Bucket | Contents | Treatment |
| --- | --- | --- |
| **A. Public** | The existing 26-document set, the promoted developer set, and all marketing content pages including privacy | Translated into the five languages |
| **B. Licensing** | `LICENSE`, `NOTICE`, licence bodies, `THIRD_PARTY_LICENSES.md` | English only, verbatim |
| **C. Internal** | Registers, strategy/future/migration records, warnings, credentials, the agent prompt, localization plans, `docs/superpowers/` | English only, not published |

## 6. What gets built

### 6.1 Reports repository — public developer section

Create `docs/developers/` and **move** the following records into it. Each page
gets `layout: default`, `title`, and `description` front matter, a short
reader-facing introduction, and repaired links. The technical content is not
rewritten.

| New public page | Source record |
| --- | --- |
| `docs/developers/index.md` | New hub page: what the engine is, how to embed it, where to start |
| `docs/developers/cli.md` | `docs/project/MAD_CLI.md` |
| `docs/developers/data-object.md` | `docs/project/MAD_DATA_OBJECT.md` |
| `docs/developers/multi-source.md` | `docs/project/MAD_MULTI_SOURCE.md` |
| `docs/developers/sql-entry.md` | `docs/project/MAD_SQL_ENTRY.md` |
| `docs/developers/satellites.md` | `docs/project/SATELLITE_REPOS.md` |
| `docs/developers/build/linux.md` | `docs/project/MAD_LINUX.md` |
| `docs/developers/build/windows.md` | `docs/project/MAD_WINDOWS.md` |
| `docs/developers/build/macos.md` | `docs/project/MAD_MACOS.md` |
| `docs/developers/build/libraries.md` | `docs/project/LIBRARIES.md` |
| `docs/developers/architecture/data-table.md` | `docs/project/MADDataTable_Architecture_Report.md` |
| `docs/developers/architecture/model-layer.md` | `docs/project/MADModel_Layer.md` |
| `docs/developers/build/pdf.md` | `docs/project/MAD_PDF_LINUX.md` |
| `docs/developers/architecture/array-caching.md` | `docs/project/MAD_ARRAY_CACHING.md` |

The public edition of each moved record must:

- Convert author-local artifacts (`/Users/...` paths, private branch names,
  working-directory instructions) to repository-relative or public guidance.
- Replace references to internal registers with public links where one exists,
  or with a plain sentence where none does. Do not link to credentials or the
  agent prompt.
- Keep the dated status line and make it a reader-facing "Status" note.
- Keep every technical claim, table, and code block intact, except where
  §6.1.1 requires a factual correction.
- Be listed in the new developer hub and in the docs landing page.

#### 6.1.1 The factual-consistency pass on promoted records

The records were written at different times and disagree with each other about
current state. Measured examples: `MAD_CLI.md` and `MAD_LINUX.md` say "ten"
headless frameworks, `MAD_MACOS.md` says "eleven", and the current tree and
`Linux/README.md` say twelve; the test counts differ in the same way. Publishing
them verbatim would put the old numbers back on the public site next to the
corrected ones.

The public edition therefore gets a bounded pass, limited to **current-state
claims**:

- Version numbers, release tags, and download URLs.
- Platform, database, and driver lists.
- Framework, suite, and test counts.
- Localization status.
- Absolute author-machine paths and private branch names.

Each corrected page keeps its original date and gains a one-line public-edition
note: written on the original date, current-state facts reconciled on
2026-11-22. Statements that are explicitly historical ("at the time of
writing") stay as history and are not counted as current claims. No algorithm,
interface, architecture, or design decision is rewritten.

Then add the localized counterparts under `docs/zh/developers/`,
`docs/ja/developers/`, `docs/pt-br/developers/`, `docs/de/developers/`, and
`docs/es/developers/`, mirroring the paths. Translate the hub and all thirteen
pages.

**Navigation.** Add a small localized section navigation to
`docs/_layouts/default.html`: *Format · Apps · Developers · Vision*. The labels
are translated in the layout, like the switcher. The developer hub and the
docs landing page link to each other.

**Localization contract.** Update `docs/project/localization/LOCALIZATION.md`:
the public website set grows from 15 to 29 pages; the total moves from 26 to
40 documents; the "14 pages" line in the validation checklist becomes the
correct count; the adding-a-language steps include the `developers/` tree.

**Site exclusion bug.** `docs/_config.yml` does not exclude
`docs/superpowers/`, so the agent plans and specs are currently published —
the built site contains both rendered `superpowers/plans/*.html` and
`superpowers/specs/*.html` pages and their raw `.md` copies (the optional
front-matter plugin renders them). Add `superpowers` and `*/superpowers` to
`exclude`, and verify the built site contains no `project`, `archive`, or
`superpowers` directory in any language.

The tree itself stays in the repository as design and plan history, and gains a
`docs/superpowers/README.md` stating that it is internal and excluded. The
repository already treats `docs/project/` as internal-but-public; the defect
is publication, not version control. Making these records truly private would
be a repository-visibility decision, which is out of scope here.

**Fact corrections in existing pages** (all languages):

- Replace the framework/test-count claim with the measured values (see 6.4).
- Replace hardcoded version strings with the shared data file (6.4).
- Correct release links to `v0.7.0`.
- Add Windows wherever the app lineup is listed.
- Add the application-localization statement (6.3).
- Correct any remaining database-support or platform inconsistency.

### 6.2 Reports repository — reorganizing `docs/project/`

Move the remaining internal records into role-based subfolders and add
`docs/project/README.md` as the index. Proposed mapping:

```
docs/project/
  README.md                  the index: what each bucket is for, what is public
  MAD_FORMAT.md              stable pointer — stays at the root (see below)
  THIRD_PARTY_LICENSES.md    licensing anchor — stays at the root (see below)
  LICENSE_COMPLIANCE_PLAN.md licensing anchor — stays at the root
  registers/                 BUGS.md, BUGS_FIXED.md, TASKS.md, TODO.md,
                             ROADMAP.md, FUTURE_FEATURES.md,
                             WARNINGS_INVENTORY.md, WARNINGS_PLAN.md
  product/                   APPSTORE.md, MAD_STRATEGY.md, MAD_FUTURE.md
  design/                    MAD_SCRIPTING.md, MAD_STORE_MIGRATION.md,
                             MAD_STORE_PHASE_C.md, MIGRATION_KICKOFF.md
  build/                     DEVELOPER.md, TEST-DB-INFO.md
  localization/              LOCALIZATION.md, MAD_APP_LOCALIZATION.md
  agents/                    MAD_DATASOURCE_AND_CONNECTION_UX.md
```

**Stable anchors.** `MAD_FORMAT.md` is a deliberate pointer file — its own text
says it exists so references to it by name keep landing — and its relative
links only resolve at `docs/project/`. `THIRD_PARTY_LICENSES.md` is linked by
path from the root `NOTICE`, which is legal text that must not be edited. Both
stay where they are; the index explains why. `LICENSE_COMPLIANCE_PLAN.md` stays
beside them as part of the licensing pair.

`docs/archive/MAD_BARCODES.md`, the root `LICENSE`/`NOTICE`, and the legacy
`docs/zh/` trees stay where they are. No file is deleted.

**Old paths.** All in-repository references to a moved record are updated,
including the root translations, the framework READMEs, the legacy Chinese
tree, and the archive. External GitHub blob URLs to moved *internal* records
may 404; no redirect stubs are added for them, because the records are working
files, not public URLs, and stubs would clutter the new tree. The two legal
anchors and `MAD_FORMAT.md` do not move, so `NOTICE`, `CONTRIBUTING.md`,
`SECURITY.md`, and the archive keep their targets.

**Link repair.** Every inbound reference to a moved path must be updated:
`AGENTS.md`/`CLAUDE.md`, root `README.md` and its five translations, the
framework `AGENTS.md` files, `Linux/`, `Windows/`, `Mac/`, `CLI/`, the
satellites, the docs site pages in every language, and the legacy Chinese
`docs/zh/project/` links. A repository-wide relative-link checker is added to
the validation steps so a missed link fails the change.

**Index.** `docs/project/README.md` states each bucket's purpose, lists the
records with a one-line description and status, and names which records are
promoted to the public site (and where they moved).

### 6.3 Recording the application localization

The app UI ships in English, Simplified Chinese, Japanese, Brazilian
Portuguese, German, and Latin American Spanish on iOS, macOS, and Windows.
Every translatable UI string is translated; the 62 catalog entries marked
do-not-translate are SQL identifiers, data-type and font names, brand names,
licence text, and format samples. The translations are machine-assisted; the
app's About screen already says so.

- `docs/project/localization/MAD_APP_LOCALIZATION.md`: change the headline
  status from "instrumented but not localized" to a completion record, with the
  measured state (catalog entries, `.lproj` set, Windows resource
  dictionaries), and keep the historical phase statuses below it.
- `docs/index.md`, `docs/macos.md`, `docs/windows.md`, and their translations:
  add a short "Languages" section stating the six UI languages and the
  machine-assisted caveat, with a link to the issue tracker.
- Marketing `AGENTS.md` and `README.md`: remove "not yet localized."
- Marketing landing page: add localization to the feature set, not as a claim
  of human review.

### 6.4 Version and fact source of truth

Only these values are canonical:

| Fact | Value | Source of truth |
| --- | --- | --- |
| Engine version | `9.0` | `MADDesigner/Resources/Assets/MADMeta.plist` |
| Engine revision | `r4433` | same |
| macOS app version | `0.7` | `Mac/Resources/Info.plist` |
| Windows app version | `0.7` | Windows release metadata |
| Current release tag | `v0.7.0` | GitHub Releases |
| iOS App Store | Between releases; returns early 2027 | Release record |
| Databases | PostgreSQL, MySQL/MariaDB, Microsoft SQL Server, SQLite | Driver frameworks |
| Platforms | iOS/iPadOS, native macOS, native Windows, headless Linux | Repository |

Add `docs/_data/versions.yml` and a matching `_data/versions.yml` in the
marketing repository, and render the values through Liquid rather than
hardcoding them. The two files are copies; a header comment names
`MADMeta.plist` as the source and instructs that they change together.

**The cross-repository check.** Add `scripts/docs/check_site_facts.py` to this
repository. It accepts both site paths, compares the two `versions.yml` files,
and greps both trees for stale literals (`9.1`, `1,303`, `v9.1.0-macos`,
"not yet localized") and for the canonical facts that must appear together. It
runs manually, in the Reports CI against the docs tree, and in a small new
workflow in the marketing repository that checks out `mthomason/MAD` beside
`mad.github.io` and runs the same script. That workflow is the only new CI
dependency in the marketing repository; if it proves unavailable, the same
script remains the documented Phase 5 manual gate.

Measure, do not guess, the two drifting counts before publishing:

- The number of frameworks built headlessly on Linux (the repository says
  eleven in `README.md` and `docs/index.md`, twelve in `Linux/README.md` and
  `CLAUDE.md`).
- The Linux suite count (1,303 tests / 126 executables versus 130 suites /
  1,313 tests).

Correct the same claim in every language and in both sites from that
measurement.

### 6.5 Marketing repository — Jekyll rebuild

New structure, preserving every existing navigable HTML URL:

```
_config.yml
_layouts/default.html
_includes/head.html          SEO, Open Graph, hreflang, favicon, CSS
_includes/analytics.html     GA4 consent-mode defaults
_includes/header.html        logo, primary nav, language switcher
_includes/consent.html       localized consent banner markup
_includes/footer.html
_data/versions.yml
index.html                   English (served at /)
contact.html
mad-file-type.html
privacy.html
thanks.html
404.html
de/index.html  de/contact.html  de/mad-file-type.html
de/privacy.html  de/thanks.html
es/...  ja/...  pt-br/...  zh/...   (same five pages each)
css/style.css
js/main.js
js/consent.js
img/...
```

Details:

- `_config.yml`: `title`, `description`, `url: https://mad.everydayapps.com`,
  `plugins: [jekyll-seo-tag, jekyll-sitemap]`, per-directory `lang` defaults
  matching the docs, and `exclude` for `README.md`, `AGENTS.md`, `*.md`
  sources, and any scratch files. Keep `CNAME`, `robots.txt`,
  `site.webmanifest`.
- Each page carries `title`, `description`, `image`, `lang`, and
  `layout: default`. Remove the now-duplicated source files `privacy.md` and
  `mad-file-type.md`; update `README.md` to link the HTML pages. Their raw
  `/privacy.md` and `/mad-file-type.md` URLs are source-file artifacts, are
  disallowed by `robots.txt` today, and are intentionally allowed to 404. The
  canonical HTML URLs are preserved; "every public URL" in this design means
  every navigable HTML page.
- The hand-written `sitemap.xml` is deleted and regenerated by
  `jekyll-sitemap`. `404.html` sets `sitemap: false` and stays the single
  root 404 page, in English with a language list; per-language 404 pages are
  not built, because GitHub Pages serves only the root one.
- The switcher mirrors the docs: fixed order `English · 简体中文 · 日本語 ·
  Português (Brasil) · Deutsch · Español`, current language as
  `<span aria-current="page">`, counterpart lookup with a fallback to that
  language's landing page.
- `hreflang` for `en`, `zh-CN`, `ja-JP`, `pt-BR`, `de-DE`, `es-419`, plus
  neutral `es` and `x-default`. Each translated page carries a translation
  notice linking the English original.
- Analytics: one include instead of the inline snippet on every page. GA4
  property `G-SD849LC3MR` is unchanged. The consent banner markup is rendered
  by the layout in the page's language, and `consent.js` keeps its show /
  accept / decline behavior without holding any English copy.
- Contact form: per-language `_next` pointing at that language's `thanks.html`;
  labels and the Formspree notice translated.
- Privacy: the English page remains authoritative; each translation carries
  the "English original prevails" notice. `AGENTS.md` is updated from "must
  not be altered" to "the English text is authoritative; translations are
  faithful copies with the notice."

**Content updates on the English pages:**

- Hero: macOS and Windows downloads from `v0.7.0`, source, docs, sponsor.
  State that both desktop builds are unsigned and link the install guidance.
- Windows is added everywhere the app is described: hero, features, metadata,
  JSON-LD `operatingSystem`, gallery if screenshots exist.
- Databases: PostgreSQL, MySQL/MariaDB, Microsoft SQL Server, SQLite.
- Features gain the headless engine / `mad` CLI, the open `.mad` format, and
  the six UI languages.
- Developer call to action: format spec, developer hub, CLI, `mad-action`,
  contributing.
- iOS: between releases, returns early 2027; sponsorship funds it. Remove
  dead App Store badge references if any remain; keep the unused badge assets
  for the relaunch.
- A "developers first / unsigned builds" note explains why the download is
  not notarized and what to expect on first launch.
- JSON-LD `softwareVersion` becomes `0.7`; `license` and `isAccessibleForFree`
  are set truthfully.
- Footer links the docs site and the repository; the docs footer links back.
- Marketing `README.md` and `AGENTS.md` are rewritten to describe the Jekyll
  build, the five translations, the privacy translation policy, the current
  version facts, Windows, and the developer audience.

### 6.6 Translation method

- AI-drafted translations for the five languages, consistent with the
  app-localization decision (D14): no human native-speaker review is claimed,
  and no page says one happened. The app's machine-assisted notice and the
  public issue tracker are the correction path.
- The docs glossary in `MAD_APP_LOCALIZATION.md` §12 is the terminology
  contract for UI-adjacent terms. Marketing copy follows it for product terms.
- Paths, identifiers, code, SQL, brand names, and licence text are never
  translated. Format specifiers and code blocks are copied byte for byte.
- New pages are added in every language in the same change. The existing
  suffix and directory conventions are used exactly as the current contract
  specifies.

## 7. Validation

Every change runs the relevant subset, and the final delivery runs all of it:

1. **Docs build.** `jekyll build` exits 0.
2. **Internal links.** The existing link checker reports `broken: 0`, a
   repository-wide Markdown relative-link checker reports no missing targets
   after the moves, and the moved-path check reports no reference to a record's
   old path in any Markdown, source, script, or configuration file.
3. **Published tree — no leaks.** No `project`, `archive`, or `superpowers`
   directory in the built docs site in any language; no `DEVELOPER`,
   `TEST-DB-INFO`, `BUGS`, `TASKS`, `ROADMAP`, or agent-prompt file. The local
   Docker test credentials are intentionally present in the public Windows
   build guide and are not a leak. The marketing output contains no `README.md`,
   `AGENTS.md`, `privacy.md`, `mad-file-type.md`, or any other source
   Markdown.
4. **Page-set parity.** Every English public page has a counterpart in each of
   the five languages; the developer tree is included.
5. **Code identity and structure.** Fenced blocks are byte-identical; heading,
   table, and fence counts are read for every pair.
6. **Switcher and `hreflang`.** Spot-check both directions in every language,
   including the fallback for an untranslated page.
7. **Marketing build.** GitHub Pages-compatible Jekyll build exits 0; the
   generated sitemap contains every page and no source Markdown.
8. **Marketing links, switcher, `hreflang`, consent.** The same checks as the
   docs, plus the Formspree `_next` target for each language and the absence of
   source Markdown in the output.
9. **External release links.** Every download URL in both sites resolves.
10. **Fact checklist.** Versions, release tag, database list, platform list,
    test/framework counts, App Store status, localization status, licence
    statements. Both sites, every language, including every promoted page.
11. **Visual check.** Playwright screenshots of the marketing pages at desktop
    and mobile widths, per the marketing repository's own guidance.
12. **Reports gates.** The branch is signed (`git commit -s`), DCO and Linux
    verification pass, and the PR is rebase-merged.
13. **Cross-repository facts.** `scripts/docs/check_site_facts.py` passes with
    both site paths, locally and in the marketing workflow.

## 8. Delivery phases

1. **Phase 0 — baseline and data.** Add the version data files; measure the
   test and framework counts; correct the exclusion bug; write the internal
   index; record the fact checklist. No public content changes yet.
2. **Phase 1 — public developer section (English).** Create
   `docs/developers/`, move the thirteen records, apply the factual-
   consistency pass, repair links, add navigation and the hub, update the
   localization contract. Build and link-check.
3. **Phase 2 — docs translations and fact corrections.** Add the five
   translations of the developer set; refresh the existing pages for versions,
   counts, Windows, and the app localization note. Run the full docs
   validation.
4. **Phase 3 — marketing rebuild (English).** Introduce the Jekyll structure,
   move the pages, add the switcher and includes, update the content, and fix
   the version/release/Windows facts.
5. **Phase 4 — marketing translations.** Translate the five content pages,
   including privacy with the notice; update `AGENTS.md` and `README.md`; run
   the marketing validation.
6. **Phase 5 — final audit and delivery.** Cross-site consistency sweep, full
   validation, screenshots, PRs, and post-merge verification.

Phases 1-2 and 3-4 can overlap once Phase 0 lands, but the docs source of
truth should be green before marketing quotes it.

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Moving records breaks links in root translations, framework READMEs, and the legacy Chinese tree | Repository-wide link checker; mechanical link repair; no deletion; run before and after |
| Translation volume (~60 docs pages, ~25 marketing pages) invites drift | One change per language set; code/structure checks; add-in-same-change rule; glossary |
| GitHub Pages rejects a plugin or theme | Stay within the documented whitelist; build with the same plugin set locally before pushing |
| Privacy translation creates legal ambiguity | English page authoritative; visible notice; `AGENTS.md` policy updated |
| Formspree redirects break in translated contact pages | Set `_next` per language and test each form |
| Two `versions.yml` copies drift | Same-change rule, header comment, stale-literal grep in validation |
| Promoted documents continue to evolve after publication | The moved file is the only copy; edits happen in the public tree; internal records link to it |
| `docs/superpowers/` remains published by accident | Add the exclusion in Phase 0 and assert the built tree |
| Machine-assisted translations read as human-reviewed | Never claim review; keep the app's existing disclosure; link the issue tracker |

## 10. What is left to the builder

- The exact wording of the new marketing copy, the developer hub, and the
  navigation labels.
- The visual design of the rebuilt marketing pages (layout, hero, feature
  grid, gallery) within the existing brand guidelines.
- The Windows gallery capture: the first delivery uses the existing current
  macOS captures and points Windows readers at its guide until a capture
  exists.
- The final measured test/framework counts from Phase 0, and any wording that
  depends on them.
- Any record in the proposed subfolder mapping that the builder believes
  belongs in a different bucket, provided the index and links stay correct.

The four questions raised by the builder review are settled here: the
factual-consistency pass (§6.1.1), the stable anchors (§6.2), the old-URL
policy (§6.2, §6.5), and the cross-repository check (§6.4).

## 11. Decision record

| Decision | Choice |
| --- | --- |
| Marketing site build | Jekyll, same pattern as the docs |
| Public developer records | Curated set of thirteen, moved not copied |
| Promoted records | Bounded factual-consistency pass; technical substance preserved |
| Repository organization | Subfolders by role plus an index |
| Stable anchors | `MAD_FORMAT.md`, `THIRD_PARTY_LICENSES.md`, `LICENSE_COMPLIANCE_PLAN.md` stay at the `docs/project/` root |
| Old URLs | All in-repo links repaired; moved internal blob URLs may 404; marketing source `.md` URLs intentionally 404 |
| Cross-repository check | `scripts/docs/check_site_facts.py` plus a marketing workflow |
| Internal agent records | `docs/superpowers/` stays in the repository, excluded from the site |
| Test credentials | Local Docker values (`root`/`root`, `sa`/`Root1@Root2`, `mad`/`mad_test_pw`) are intentionally public and may appear in the developer docs |
| Translation scope | Public set translated; licensing and internal records English-only |
| Privacy policy | Translated with an "English original prevails" notice; `AGENTS.md` updated |
| App localization | Recorded as complete for all translatable strings; 62 entries intentionally untranslated (SQL identifiers, data-type/font names, brands, licence text, format samples), with the machine-assisted caveat |
| Version truth | app 0.7, engine 9.0 (r4433), release v0.7.0 |
| Domains | Kept separate |
