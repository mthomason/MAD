# Documentation Site Program Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Reports repository's documentation site complete, correct, organized, leak-free, and fully translated, with a curated public developer section.

**Architecture:** Add three Python validation gates (links, translation parity, facts/leaks), fix the site's internal-tree leak, move thirteen engineering records into `docs/developers/`, organize the remaining internal records by role, and translate the new developer section into the five existing languages. The version facts are rendered from one data file; every current-state claim is corrected from a measured value.

**Tech Stack:** Markdown, Jekyll 4 with GitHub Pages plugins, Liquid, Python 3 (stdlib only), GitHub Actions, git.

**Spec:** `docs/superpowers/specs/2026-11-22-documentation-and-marketing-design.md`

**Scope:** This is Plan 1 of 2. It covers the Reports repository (`docs.everydayapps.com`). The marketing-site rebuild and its translations are Plan 2, which depends on the public URLs and version data produced here.

## Global Constraints

- **Five translations, same codes:** directory `zh` / tag `zh-CN`; `ja` / `ja-JP`; `pt-br` / `pt-BR`; `de` / `de-DE`; `es` / `es-419`. English is the source and `x-default`.
- **Measured facts:** 12 headless frameworks, 130 suites, 1,313 tests — confirmed from `ls Linux/cmake/*Sources.cmake` (12), `Linux/README.md` lines 8-11, and the latest green Linux run.
- **Version truth:** app `0.7` for macOS and Windows; engine `9.0` revision `r4433`; release tag `v0.7.0`; iOS between releases and returning early 2027.
- **Licensing stays English and verbatim.** `LICENSE`, `NOTICE`, `THIRD_PARTY_LICENSES.md`, and `LICENSE_COMPLIANCE_PLAN.md` are not translated. `MAD_FORMAT.md`, `THIRD_PARTY_LICENSES.md`, and `LICENSE_COMPLIANCE_PLAN.md` stay at the `docs/project/` root.
- **Internal records stay internal.** `docs/project/`, `docs/archive/`, `docs/superpowers/`, credentials (`DEVELOPER.md`, `TEST-DB-INFO.md`), and the agent prompt are never published or translated. `BUGS.md` and `BUGS_FIXED.md` are never translated.
- **Code is byte-identical in translation.** Paths, identifiers, SQL, brand names, and fenced blocks are copied exactly.
- **Move, do not copy.** A promoted record has one source file, in `docs/developers/`.
- **Tabs for indentation** in scripts and configuration. YAML is the exception: it forbids tab indentation, so data files use two spaces.
- **PR flow:** branch off `master`, commit with `git commit -s`, push, open a PR, watch DCO and Linux verification, rebase-merge.
- **No leaks:** the built site contains no `project`, `archive`, or `superpowers` tree, no credentials, no agent prompt, and no internal register.

## Review Focus

These are the failure modes most likely to reach a reader. Each is pinned by a check in the task that owns it.

1. **A moved record leaves a broken relative link** in the root translations, a framework README, the legacy Chinese tree, or the archive. Expected: every relative link resolves. Pinned by `check_links.py` in Tasks 8-11 and 21.
2. **Internal content is published** — a `project`/`archive`/`superpowers` page, a credential, or raw source Markdown. Expected: zero. Pinned by `check_site_facts.py --built` in Tasks 4 and 21.
3. **A translation drifts a code block or changes a heading/table/fence count.** Expected: byte-identical code and equal structure. Pinned by `check_translations.py` in Tasks 13-17 and 21.
4. **A stale fact survives in one language** — `1,303`, `126 test executables`, "eleven of the fourteen", `9.1`, "not yet localized". Expected: zero occurrences in public text. Pinned by the version-literal grep in Task 6 and by `check_site_facts.py` in Tasks 19 and 21.
5. **A new page is missing in one language**, so the switcher silently falls back to that language's home. Expected: every English public page has a counterpart in all five languages. Pinned by `check_translations.py --require-complete` in Task 21.

---

## Task 0: Commit the approved design and this plan

**Files:**
- Add: `docs/superpowers/specs/2026-11-22-documentation-and-marketing-design.md`
- Add: `docs/superpowers/plans/2026-11-22-documentation-site-program.md`

**Interfaces:**
- Consumes: the user's approval of the design.
- Produces: the design and plan recorded on the branch before implementation.

- [ ] **Step 1: Commit both documents**

```bash
git add docs/superpowers/specs/2026-11-22-documentation-and-marketing-design.md \
	docs/superpowers/plans/2026-11-22-documentation-site-program.md
git commit -s -m "docs: record the documentation and marketing design and plan"
```

Task 4 will exclude this tree from the published site; committing it keeps the
design and plan in the repository's history.

---

## Task 1: Repository-wide Markdown link checker

**Files:**
- Create: `scripts/docs/check_links.py`
- Test: `scripts/docs/check_links_test.py`

**Interfaces:**
- Consumes: nothing.
- Produces: `check_links(root: str) -> list[tuple[str, int, str]]`; CLI `python3 -I scripts/docs/check_links.py [--root PATH]` exits 1 when any relative Markdown link target is missing and prints `path:line -> target`.

- [ ] **Step 1: Write the failing tests**

Create `scripts/docs/check_links_test.py` using `unittest` and `tempfile.TemporaryDirectory`. The project runs tests with `python3 -I`, which keeps the script's directory off `sys.path`, so the test must insert its own directory before importing:

```python
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_links
```

Cover, with a `write(relpath, text)` helper in `setUp` that creates parent directories:

```python
def test_valid_relative_link(self):
	self.write("a.md", "[b](b.md)"); self.write("b.md", "# b")
	self.assertEqual(check_links.check_links(str(self.root)), [])

def test_broken_relative_link(self):
	self.write("a.md", "[b](missing.md)")
	self.assertEqual(check_links.check_links(str(self.root)), [("a.md", 1, "missing.md")])

def test_ignores_fenced_code(self):
	self.write("a.md", "```\n[x](missing.md)\n```\n")
	self.assertEqual(check_links.check_links(str(self.root)), [])

def test_ignores_external_anchor_and_mailto(self):
	self.write("a.md", "[x](https://e)\n[y](#a)\n[z](mailto:a@b)\n")
	self.assertEqual(check_links.check_links(str(self.root)), [])

def test_resolves_absolute_repo_path(self):
	self.write("sub/a.md", "[x](/b.md)"); self.write("b.md", "# b")
	self.assertEqual(check_links.check_links(str(self.root)), [])

def test_image_link(self):
	self.write("a.md", "![x](missing.png)")
	self.assertEqual(check_links.check_links(str(self.root)), [("a.md", 1, "missing.png")])

def test_anchor_is_stripped(self):
	self.write("a.md", "[x](b.md#s)"); self.write("b.md", "# b")
	self.assertEqual(check_links.check_links(str(self.root)), [])
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -I scripts/docs/check_links_test.py -v`
Expected: FAIL with `ModuleNotFoundError: No module named 'check_links'` or missing functions.

- [ ] **Step 3: Implement `check_links.py`**

Walk `*.md` under `root`, skipping `.git`, `ThirdParty`, `Compressor`, `Mac/build`, `.cli-deriveddata`, `docs/.jekyll-cache`, and `docs/_site`. For each file, track fenced-code state (```` ``` ````) and inline backtick spans, extract Markdown inline links `[text](target)` and images `![alt](target)`, ignore `http://`, `https://`, `mailto:`, `#`, `data:`, and `//`, strip query and fragment, resolve relative to the file, resolve `/`-prefixed paths from `root`, and report missing targets as `(relpath, line_no, target)`. Return findings sorted by path and line. The CLI prints `broken: N` and each finding, and exits 1 if `N > 0`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -I scripts/docs/check_links_test.py -v`
Expected: PASS, 7 tests.

- [ ] **Step 5: Record the current repository baseline**

Run: `python3 -I scripts/docs/check_links.py > /tmp/links-baseline.txt; cat /tmp/links-baseline.txt`
Expected: a `broken: N` line. Keep the file; Tasks 8-11 must reduce it to `broken: 0`.

- [ ] **Step 6: Commit**

```bash
git add scripts/docs/check_links.py scripts/docs/check_links_test.py
git commit -s -m "test(docs): add a repository-wide Markdown link checker"
```

---

## Task 2: Translation parity checker

**Files:**
- Create: `scripts/docs/check_translations.py`
- Test: `scripts/docs/check_translations_test.py`

**Interfaces:**
- Consumes: the public page tree under `docs/`.
- Produces: `public_pages(docs_root: str) -> list[str]`, `code_blocks(path: str) -> list[str]`, `structure_counts(path: str) -> tuple[int, int, int]`, and `check(docs_root: str, languages: list[str] | None = None) -> Findings`, where `Findings` has `missing`, `code_drift`, and `structure_drift` lists; CLI `python3 -I scripts/docs/check_translations.py [--docs docs] [--lang CODE] [--require-complete]` exits 1 on a missing counterpart, a code-block difference, or a structure-count difference.

- [ ] **Step 1: Write the failing tests**

Use the same `sys.path.insert` preamble as Task 1. In `setUp`, create `self.docs` as a temporary `docs/` directory and keep the `write(relpath, text)` helper. Cover:

```python
def test_public_pages_excludes_internal(self):
	self.write("docs/index.md", "# Home"); self.write("docs/project/BUGS.md", "# B")
	self.write("docs/superpowers/x.md", "# X"); self.write("docs/404.md", "# 404")
	self.write("docs/de/index.md", "# Start")
	self.assertEqual(check_translations.public_pages(str(self.docs)), ["index.md"])

def test_missing_counterpart_is_reported(self):
	self.write("docs/a.md", "# A\n")
	findings = check_translations.check(str(self.docs), languages=["de"])
	self.assertIn("a.md", findings.missing)

def test_code_block_drift_is_reported(self):
	self.write("docs/a.md", "```\nx\n```\n"); self.write("docs/de/a.md", "```\ny\n```\n")
	findings = check_translations.check(str(self.docs), languages=["de"])
	self.assertIn("a.md", findings.code_drift)

def test_structure_drift_is_reported(self):
	self.write("docs/a.md", "# A\n"); self.write("docs/de/a.md", "# A\n## B\n")
	findings = check_translations.check(str(self.docs), languages=["de"])
	self.assertIn("a.md", findings.structure_drift)

def test_identical_translation_passes(self):
	self.write("docs/a.md", "# A\n```\nx\n```\n"); self.write("docs/de/a.md", "# A\n```\nx\n```\n")
	findings = check_translations.check(str(self.docs), languages=["de"])
	self.assertEqual((findings.missing, findings.code_drift, findings.structure_drift), ([], [], []))

def test_lang_filter_checks_one_language(self):
	self.write("docs/a.md", "# A\n"); self.write("docs/de/a.md", "# A\n")
	findings = check_translations.check(str(self.docs), languages=["de"])
	self.assertEqual(findings.missing, [])
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -I scripts/docs/check_translations_test.py -v`
Expected: FAIL with missing functions.

- [ ] **Step 3: Implement `check_translations.py`**

`public_pages` walks `docs/**/*.md`, excludes `project`, `archive`, `superpowers`, `assets`, `_includes`, `_layouts`, `_data`, the five language directories, and `404.md`, and returns paths relative to `docs/`. For each English page and each language, the counterpart is `docs/<lang>/<relative path>`. `code_blocks` returns the exact lines inside fenced blocks, with the fence lines removed. `structure_counts` returns `(count of '^#', count of '^|', count of '^```')`. The CLI prints `missing:`, `code-drift:`, and `structure-drift:` sections and exits 1 on any. `--require-complete` treats a missing counterpart as a failure; without it, missing counterparts are still reported but only code/structure drift fails (used while a language is being filled in).

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -I scripts/docs/check_translations_test.py -v`
Expected: PASS, 6 tests.

- [ ] **Step 5: Record the current baseline**

Run: `python3 -I scripts/docs/check_translations.py --docs docs`
Expected: no code or structure drift for the existing 15 pages; missing lines only for pages not yet translated.

- [ ] **Step 6: Commit**

```bash
git add scripts/docs/check_translations.py scripts/docs/check_translations_test.py
git commit -s -m "test(docs): add a translation parity checker"
```

---

## Task 3: Facts and built-site leak checker

**Files:**
- Create: `scripts/docs/check_site_facts.py`
- Test: `scripts/docs/check_site_facts_test.py`

**Interfaces:**
- Consumes: `docs/_data/versions.yml`, the public docs tree, optionally the repository root documents and the marketing tree.
- Produces: `version_mismatches(docs_root: str, marketing_root: str) -> list[str]`, `banned_literals(root: str) -> list[str]`, and `built_leaks(built_root: str) -> list[str]`; CLI `python3 -I scripts/docs/check_site_facts.py [--docs docs] [--repo .] [--marketing PATH] [--built PATH]` exits 1 on a version-data mismatch, a banned stale literal in public text, or a leak in the built tree.

- [ ] **Step 1: Write the failing tests**

Use the same `sys.path.insert` preamble as Task 1. In `setUp`, create `self.docs`, `self.marketing`, and `self.built` as temporary directories, with the `write(relpath, text)` helper resolving paths under `self.root`. Cover:

```python
def test_matching_version_files_pass(self):
	self.write("docs/_data/versions.yml", 'engine_version: "9.0"\n')
	self.write("m/_data/versions.yml", 'engine_version: "9.0"\n')
	self.assertEqual(check_site_facts.version_mismatches(str(self.docs), str(self.marketing)), [])

def test_mismatched_version_files_fail(self):
	self.write("docs/_data/versions.yml", 'engine_version: "9.0"\n')
	self.write("m/_data/versions.yml", 'engine_version: "9.1"\n')
	self.assertEqual(check_site_facts.version_mismatches(str(self.docs), str(self.marketing)), ["engine_version"])

def test_banned_literal_in_public_text_fails(self):
	self.write("docs/index.md", "1,303 tests")
	self.assertIn("1,303", check_site_facts.banned_literals(str(self.docs)))

def test_banned_literal_in_internal_tree_is_ignored(self):
	self.write("docs/project/x.md", "1,303 tests")
	self.assertEqual(check_site_facts.banned_literals(str(self.docs)), [])

def test_built_site_internal_directory_fails(self):
	(self.built / "project").mkdir(parents=True)
	self.assertIn("project", check_site_facts.built_leaks(str(self.built)))

def test_built_site_credential_fails(self):
	self.write("built/a.html", "Root1@Root2")
	self.assertIn("credential", check_site_facts.built_leaks(str(self.built)))

def test_built_marketing_source_markdown_fails(self):
	self.write("built/AGENTS.md", "# internal")
	self.assertIn("AGENTS.md", check_site_facts.built_leaks(str(self.built)))
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -I scripts/docs/check_site_facts_test.py -v`
Expected: FAIL with missing functions.

- [ ] **Step 3: Implement `check_site_facts.py`**

Read the flat `key: "value"` pairs from `docs/_data/versions.yml` and the optional marketing `_data/versions.yml` with a small regex parser (no PyYAML). Compare every key present in both; report differences. Scan text files (`.md`, `.html`, `.yml`) in the public docs tree (excluding `project`, `archive`, `superpowers`, `assets`), the repository root documents when `--repo` is given (`README.md`, `translations/*.md`, `Mac/README*.md`, `Linux/README*.md`, `CLI/Fixtures/README*.md`, `MADFileManager/README*.md`, `MADTds/README*.md`, `satellites/mad-action/README*.md`), and the marketing tree when `--marketing` is given (excluding `.git`, `_site`, `img`, `css`, `js`). Banned literals: `v9.1.0-macos`, `9.1` as a whole word, `1,303`, `126 test executables`, `Eleven of the fourteen`, `not yet localized`, `instrumented but not localized`. `banned_literals` returns the literal strings found, so the tests can assert on them. When `--built` is given, assert the built tree contains no directory named `project`, `archive`, or `superpowers`; no file whose basename starts with `BUGS`, `TASKS`, `ROADMAP`, `DEVELOPER`, `TEST-DB-INFO`, or `MAD_DATASOURCE_AND_CONNECTION_UX`; no credential string `Root1@Root2` or `mad_test_pw`; and, when the built tree is the marketing site, no `.md` file. `built_leaks` returns one token per leak: `project`, `credential`, or the offending basename.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -I scripts/docs/check_site_facts_test.py -v`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add scripts/docs/check_site_facts.py scripts/docs/check_site_facts_test.py
git commit -s -m "test(docs): add a facts and leak checker"
```

---

## Task 4: Exclude internal agent records from the site

**Files:**
- Modify: `docs/_config.yml` (the `exclude` list)
- Create: `docs/superpowers/README.md`

**Interfaces:**
- Consumes: the existing `exclude` list.
- Produces: a built site with no `superpowers` tree.

- [ ] **Step 1: Add the exclusions**

In `docs/_config.yml`, extend `exclude` with:

```yaml
  - superpowers
  - "*/superpowers"
```

- [ ] **Step 2: Mark the tree internal**

Create `docs/superpowers/README.md`:

```markdown
# Internal agent records

This directory holds design specifications and implementation plans written by
the agent tooling. It is an internal record, not part of the published site.

`docs/_config.yml` excludes this tree, the same way it excludes
`docs/project/` and `docs/archive/`. Do not add it to the language set and do
not translate it.
```

- [ ] **Step 3: Build and verify no internal tree is published**

```bash
rm -rf /tmp/madsite
(cd docs && jekyll build -d /tmp/madsite)
find /tmp/madsite -type d \( -name project -o -name archive -o -name superpowers \) | wc -l
```

Expected: `0`.

- [ ] **Step 4: Run the leak checker**

Run: `python3 -I scripts/docs/check_site_facts.py --docs docs --built /tmp/madsite`
Expected: pass, no leaks.

- [ ] **Step 5: Commit**

```bash
git add docs/_config.yml docs/superpowers/README.md
git commit -s -m "docs: exclude internal agent records from the published site"
```

---

## Task 5: Add the canonical version and fact data

**Files:**
- Create: `docs/_data/versions.yml`

**Interfaces:**
- Consumes: `MADDesigner/Resources/Assets/MADMeta.plist`, `Mac/Resources/Info.plist`, `Linux/README.md`.
- Produces: flat Liquid keys `site.data.versions.engine_version`, `.engine_revision`, `.macos_app_version`, `.windows_app_version`, `.ios_app_status`, `.release_tag`, `.release_base_url`, `.headless_frameworks`, `.linux_suites`, `.linux_tests`.

- [ ] **Step 1: Verify the measured values**

```bash
grep -A2 'CFBundleShortVersionString' MADDesigner/Resources/Assets/MADMeta.plist
grep -A2 'CFBundleVersion' MADDesigner/Resources/Assets/MADMeta.plist
ls Linux/cmake/*Sources.cmake | wc -l
sed -n '8,11p' Linux/README.md
gh run list --workflow linux.yml --limit 1 --json conclusion,headSha,createdAt
```

Expected: `9.0`, `4433`, `12`, `130 suites, 1,313 tests`, and a green run.

- [ ] **Step 2: Create `docs/_data/versions.yml`**

```yaml
# Canonical facts for the documentation site. The engine values come from
# MADDesigner/Resources/Assets/MADMeta.plist; the app versions from
# Mac/Resources/Info.plist and the Windows release. Change them here, not in
# page text. The marketing repository keeps a matching copy in
# _data/versions.yml; change both together.
engine_version: "9.0"
engine_revision: "r4433"
macos_app_version: "0.7"
windows_app_version: "0.7"
ios_app_status: "between releases; returns early 2027"
release_tag: "v0.7.0"
release_base_url: "https://github.com/mthomason/MAD/releases/download/v0.7.0"
headless_frameworks: 12
linux_suites: 130
linux_tests: 1313
```

- [ ] **Step 3: Validate the YAML**

Run: `ruby -ryaml -e 'p YAML.load_file("docs/_data/versions.yml")'`
Expected: the parsed hash, no exception.

- [ ] **Step 4: Commit**

```bash
git add docs/_data/versions.yml
git commit -s -m "docs: add canonical version and fact data"
```

---

## Task 6: Render the docs pages' versions from the data file

**Files:**
- Modify: `docs/index.md`, `docs/macos.md`, `docs/windows.md`
- Modify: `docs/zh/{index,macos,windows}.md`, `docs/ja/{index,macos,windows}.md`, `docs/pt-br/{index,macos,windows}.md`, `docs/de/{index,macos,windows}.md`, `docs/es/{index,macos,windows}.md`

**Interfaces:**
- Consumes: the `site.data.versions` keys from Task 5.
- Produces: rendered pages that contain `app 0.7 / engine 9.0 (r4433)` without a hardcoded copy.

- [ ] **Step 1: Replace the version literals**

In each page, replace the literal version phrase with Liquid, using the app version that matches the page:

```liquid
app {{ site.data.versions.macos_app_version }} / engine {{ site.data.versions.engine_version }} ({{ site.data.versions.engine_revision }})
```

Use `windows_app_version` on the Windows page. Replace hardcoded release URLs with `{{ site.data.versions.release_base_url }}` followed by the asset name (`/MAD-Designer-macOS.dmg`, `/MAD-Designer-macOS.zip`, `/MAD-Designer-Windows-0.7.zip`, `/London.mad`, `/Music.mad`).

- [ ] **Step 2: Build and verify the rendered text**

```bash
rm -rf /tmp/madsite
(cd docs && jekyll build -d /tmp/madsite)
grep -Rho 'app 0\.7 / engine 9\.0 (r4433)' /tmp/madsite --include='*.html' | wc -l
grep -rn '9\.0 (r4433)' docs/index.md docs/macos.md docs/windows.md docs/*/index.md docs/*/macos.md docs/*/windows.md | wc -l
```

Expected: the first count is at least 18 (three pages × six languages); the second is `0`.

- [ ] **Step 3: Commit**

```bash
git add docs/index.md docs/macos.md docs/windows.md docs/zh docs/ja docs/pt-br docs/de docs/es
git commit -s -m "docs: render app and engine versions from the shared data file"
```

---

## Task 7: Organize `docs/project/` by role

**Files:**
- Create: `docs/project/README.md`
- Move: the internal records into `registers/`, `product/`, `design/`, `build/`, `localization/`, `agents/`
- Modify: every file with a relative link to a moved record

**Interfaces:**
- Consumes: the link checker from Task 1.
- Produces: `docs/project/README.md` and the subfolder tree in the spec §6.2; `MAD_FORMAT.md`, `THIRD_PARTY_LICENSES.md`, and `LICENSE_COMPLIANCE_PLAN.md` remain at the root.

- [ ] **Step 1: Record the baseline**

```bash
python3 -I scripts/docs/check_links.py > /tmp/links-before-project.txt
cat /tmp/links-before-project.txt
```

- [ ] **Step 2: Create the subfolders and move the records**

```bash
mkdir -p docs/project/{registers,product,design,build,localization,agents}
git mv docs/project/BUGS.md docs/project/BUGS_FIXED.md \
	docs/project/TASKS.md docs/project/TODO.md docs/project/ROADMAP.md \
	docs/project/FUTURE_FEATURES.md docs/project/registers/
mv docs/project/WARNINGS_INVENTORY.md docs/project/WARNINGS_PLAN.md \
	docs/project/registers/
git mv docs/project/APPSTORE.md docs/project/MAD_STRATEGY.md \
	docs/project/MAD_FUTURE.md docs/project/product/
git mv docs/project/MAD_SCRIPTING.md docs/project/MAD_STORE_MIGRATION.md \
	docs/project/MAD_STORE_PHASE_C.md docs/project/MIGRATION_KICKOFF.md \
	docs/project/design/
git mv docs/project/DEVELOPER.md docs/project/build/
mv docs/project/TEST-DB-INFO.md docs/project/build/
git mv docs/project/LOCALIZATION.md docs/project/MAD_APP_LOCALIZATION.md \
	docs/project/localization/
git mv docs/project/MAD_DATASOURCE_AND_CONNECTION_UX.md docs/project/agents/
```

Do not move `MAD_FORMAT.md`, `THIRD_PARTY_LICENSES.md`, or `LICENSE_COMPLIANCE_PLAN.md`.

`WARNINGS_INVENTORY.md`, `WARNINGS_PLAN.md`, and `TEST-DB-INFO.md` are gitignored local-only files, so they use plain `mv` and remain untracked. Say so in the index.

- [ ] **Step 3: Write the index**

Create `docs/project/README.md` with one section per bucket. Each record gets one line: its link, a one-sentence purpose, and its status. State which records are promoted to the public site and where. State that `MAD_FORMAT.md` is a stable pointer and that the two licensing files stay at the root because `NOTICE` links `THIRD_PARTY_LICENSES.md` by path. State that `registers/`, `product/`, `design/`, `build/`, `localization/`, and `agents/` are internal and English-only. Do not link to `docs/developers/` pages that do not exist yet; name the promoted records in plain text now and add their public links in Tasks 8-10. Do not link to the gitignored local-only files (`WARNINGS_INVENTORY.md`, `WARNINGS_PLAN.md`, `TEST-DB-INFO.md`); name them in plain text so the CI link checker does not fail on a file that is absent from a fresh checkout.

- [ ] **Step 4: Repair every broken link**

```bash
python3 -I scripts/docs/check_links.py
```

Fix each finding by updating the link target to the new path. Expect references in root `AGENTS.md`, `README.md` and `translations/`, the framework `AGENTS.md` files, `Linux/`, `Windows/`, `Mac/`, the docs pages in every language, and the legacy `docs/zh/project/` tree. Re-run until the output is `broken: 0`.

- [ ] **Step 5: Build and verify the tree**

```bash
rm -rf /tmp/madsite
(cd docs && jekyll build -d /tmp/madsite)
find docs/project -maxdepth 1 -type f | sort
python3 -I scripts/docs/check_site_facts.py --docs docs --built /tmp/madsite
```

Expected: the root files are `README.md`, `MAD_FORMAT.md`, `THIRD_PARTY_LICENSES.md`, `LICENSE_COMPLIANCE_PLAN.md`; the leak check passes.

- [ ] **Step 6: Commit**

```bash
git add -A docs/project AGENTS.md README.md translations Linux Windows Mac CLI satellites docs
git commit -s -m "docs: organize the internal records by role and add the index"
```

---

## Task 8: Promote the five core design records

**Files:**
- Move: `docs/project/MAD_CLI.md` → `docs/developers/cli.md`
- Move: `docs/project/MAD_DATA_OBJECT.md` → `docs/developers/data-object.md`
- Move: `docs/project/MAD_MULTI_SOURCE.md` → `docs/developers/multi-source.md`
- Move: `docs/project/MAD_SQL_ENTRY.md` → `docs/developers/sql-entry.md`
- Move: `docs/project/SATELLITE_REPOS.md` → `docs/developers/satellites.md`

**Interfaces:**
- Consumes: the measured facts from Task 5 and the link checker from Task 1.
- Produces: five public pages with `layout: default`, `title`, and `description` front matter.

- [ ] **Step 1: Move the files**

```bash
mkdir -p docs/developers/architecture docs/developers/build
git mv docs/project/MAD_CLI.md docs/developers/cli.md
git mv docs/project/MAD_DATA_OBJECT.md docs/developers/data-object.md
git mv docs/project/MAD_MULTI_SOURCE.md docs/developers/multi-source.md
git mv docs/project/MAD_SQL_ENTRY.md docs/developers/sql-entry.md
git mv docs/project/SATELLITE_REPOS.md docs/developers/satellites.md
```

- [ ] **Step 2: Add front matter and a reader introduction**

Add to the top of each file:

```yaml
---
layout: default
title: "<title>"
description: "<description>"
---
```

Use exactly:

| File | `title` | `description` |
| --- | --- | --- |
| `cli.md` | `The \`mad\` command-line tool` | `Open, inspect, query, refresh, and export \`.mad\` documents without a UI.` |
| `data-object.md` | `The data object` | `A report's definition, schema, and result set as one contract.` |
| `multi-source.md` | `Multi-source reports` | `Reports as tables, and drivers for anything that returns a table.` |
| `sql-entry.md` | `Pasting SQL into the query designer` | `The supported SQL subset, the parser, and the apply path.` |
| `satellites.md` | `Satellite repositories` | `How \`mad-action\` and the container image are published from this repository.` |

Below the front matter, add two or three sentences telling a reader what the page is for and where to start. Do not change the technical body.

- [ ] **Step 3: Apply the factual-consistency pass**

Update only current-state claims:

- Replace current-state "ten headless frameworks" in `MAD_CLI.md` (around line 308) with `12`.
- Replace current-state test and suite counts (`1,303`, `126 test executables`, "ten") with `1,313`, `130 suites`, and `12` where the claim describes the tree today.
- Keep explicitly dated historical statements as history.
- Rewrite author-local `/Users/...` paths and private branch names to repository-relative or public guidance.
- Replace links to internal registers with public links where one exists, or a plain sentence where none does. Do not link credentials or the agent prompt.

- [ ] **Step 4: Repair links, update the index, and verify**

Update `docs/project/README.md` so the five moved records point at their new public pages. Then:

```bash
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_site_facts.py --docs docs
rm -rf /tmp/madsite
(cd docs && jekyll build -d /tmp/madsite)
test -f /tmp/madsite/developers/cli.html
```

Expected: `broken: 0`, no banned literals, and the five pages built.

- [ ] **Step 5: Commit**

```bash
git add docs/developers docs/project
git commit -s -m "docs(developers): publish the core design records"
```

---

## Task 9: Promote the five build records

**Files:**
- Move: `docs/project/MAD_LINUX.md` → `docs/developers/build/linux.md`
- Move: `docs/project/MAD_WINDOWS.md` → `docs/developers/build/windows.md`
- Move: `docs/project/MAD_MACOS.md` → `docs/developers/build/macos.md`
- Move: `docs/project/LIBRARIES.md` → `docs/developers/build/libraries.md`
- Move: `docs/project/MAD_PDF_LINUX.md` → `docs/developers/build/pdf.md`

**Interfaces:**
- Consumes: the measured facts from Task 5.
- Produces: five public build pages.

- [ ] **Step 1: Move and add front matter**

```bash
git mv docs/project/MAD_LINUX.md docs/developers/build/linux.md
git mv docs/project/MAD_WINDOWS.md docs/developers/build/windows.md
git mv docs/project/MAD_MACOS.md docs/developers/build/macos.md
git mv docs/project/LIBRARIES.md docs/developers/build/libraries.md
git mv docs/project/MAD_PDF_LINUX.md docs/developers/build/pdf.md
```

Add `layout: default`, `title`, and `description`:

| File | `title` | `description` |
| --- | --- | --- |
| `linux.md` | `Building the engine on Linux` | `The Docker build, the twelve headless frameworks, and their suites.` |
| `windows.md` | `Building the engine on Windows` | `The pinned Clang and GNUstep toolchain and the native Windows engine build.` |
| `macos.md` | `Portability and the native macOS application` | `The framework portability audit and the AppKit application architecture.` |
| `libraries.md` | `The Compressor static-library build` | `The third-party C libraries, how they are built, and how Xcode reaches them.` |
| `pdf.md` | `The headless PDF writer` | `The Cairo and FreeType stack, font mapping, and deterministic PDF export.` |

- [ ] **Step 2: Apply the factual-consistency pass**

- `linux.md`: the known "ten" current-state claims at approximately lines 296, 322, 408, and 452 become `12`; read each in context and keep explicitly dated history.
- `macos.md`: the "eleven" current-state claim at approximately line 56 becomes `12`.
- Replace current suite/test counts with `130 suites` and `1,313 tests`.
- Keep the dated status lines; add the public-edition note: "Written on the original date; current-state facts reconciled 2026-11-22."
- Remove author-local paths and private branch names.

- [ ] **Step 3: Repair links, update the index, and verify**

Update `docs/project/README.md` for the five moved build records. Then:

```bash
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_site_facts.py --docs docs
rm -rf /tmp/madsite
(cd docs && jekyll build -d /tmp/madsite)
for f in linux windows macos libraries pdf; do test -f "/tmp/madsite/developers/build/$f.html" || echo "missing $f"; done
```

Expected: `broken: 0`, no banned literals, no "missing" lines.

- [ ] **Step 4: Commit**

```bash
git add docs/developers docs/project
git commit -s -m "docs(developers): publish the build records"
```

---

## Task 10: Promote the three architecture records

**Files:**
- Move: `docs/project/MADDataTable_Architecture_Report.md` → `docs/developers/architecture/data-table.md`
- Move: `docs/project/MADModel_Layer.md` → `docs/developers/architecture/model-layer.md`
- Move: `docs/project/MAD_ARRAY_CACHING.md` → `docs/developers/architecture/array-caching.md`

**Interfaces:**
- Consumes: the measured facts from Task 5.
- Produces: three public architecture pages.

- [ ] **Step 1: Move and add front matter**

```bash
git mv docs/project/MADDataTable_Architecture_Report.md docs/developers/architecture/data-table.md
git mv docs/project/MADModel_Layer.md docs/developers/architecture/model-layer.md
git mv docs/project/MAD_ARRAY_CACHING.md docs/developers/architecture/array-caching.md
```

Add:

| File | `title` | `description` |
| --- | --- | --- |
| `data-table.md` | `The MADDataTable architecture` | `The data-table class cluster across the frameworks and its decoupling plan.` |
| `model-layer.md` | `The MADModel layer` | `The document read-model over the Rptq entities, and how it is kept current.` |
| `array-caching.md` | `MADArrayCaching` | `The disk-backed, append-only array behind the report render cache.` |

- [ ] **Step 2: Apply the bounded pass and repair links**

Apply only §6.1.1 corrections (versions, platform/database lists, counts, localization status, author-local paths), and update `docs/project/README.md` for the three moved architecture records. Then run:

```bash
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_site_facts.py --docs docs
rm -rf /tmp/madsite
(cd docs && jekyll build -d /tmp/madsite)
```

Expected: `broken: 0`, no banned literals, and the three pages in the build.

- [ ] **Step 3: Commit**

```bash
git add docs/developers docs/project
git commit -s -m "docs(developers): publish the architecture records"
```

---

## Task 11: Add the developer hub and section navigation

**Files:**
- Create: `docs/developers/index.md`
- Modify: `docs/_layouts/default.html`
- Modify: `docs/index.md`
- Modify: `docs/README.md`

**Interfaces:**
- Consumes: the thirteen pages from Tasks 8-10.
- Produces: `/developers/` and a section nav on every page.

- [ ] **Step 1: Write the hub**

Create `docs/developers/index.md` with:

```yaml
---
layout: default
title: Developers
description: "Embed the MAD engine, use the mad CLI, read the data-object contract, and build the headless engine."
---
```

Body sections and links: **Start here** (format spec `/README.html`, macOS guide `/macos.html`, Windows guide `/windows.html`); **Engine and CLI** (`cli.html`); **Embedding and architecture** (`data-object.html`, `multi-source.html`, `sql-entry.html`, `architecture/data-table.html`, `architecture/model-layer.html`, `architecture/array-caching.html`); **Build and test** (`build/linux.html`, `build/windows.html`, `build/macos.html`, `build/libraries.html`, `build/pdf.html`); **Satellites** (`satellites.html`); **Source** (GitHub repository, issues, contributing). Each link gets a one-line description.

- [ ] **Step 2: Add the section navigation to the layout**

In `docs/_layouts/default.html`, after the language-switcher `<nav>`, add a second `<nav class="section-nav">` with four links. The labels per language are:

| Language | Format | Apps | Developers | Vision |
| --- | --- | --- | --- | --- |
| English | Format | Apps | Developers | Vision |
| zh | 格式 | 应用 | 开发者 | 愿景 |
| ja | フォーマット | アプリ | 開発者 | ビジョン |
| pt-BR | Formato | Aplicativos | Desenvolvedores | Visão |
| de | Format | Anwendungen | Entwickler | Vision |
| es | Formato | Aplicaciones | Desarrolladores | Visión |

Targets: Format → `/README.html` (or `/zh/README.html` etc.), Apps → `macos.html`, Developers → `developers/`, Vision → `vision.html`, each relative to the current language root. Use the existing `is_zh`/`is_ja`/`is_pt`/`is_de`/`is_es` flags.

- [ ] **Step 3: Link the hub from the landing pages**

Add a "Developers" section to `docs/index.md` and a "Developer documentation" line to `docs/README.md`, linking `/developers/`.

- [ ] **Step 4: Verify**

```bash
rm -rf /tmp/madsite
(cd docs && jekyll build -d /tmp/madsite)
grep -c 'section-nav' /tmp/madsite/index.html
test -f /tmp/madsite/developers/index.html
python3 -I scripts/docs/check_links.py
```

Expected: at least `1` nav; the hub exists; `broken: 0`.

- [ ] **Step 5: Commit**

```bash
git add docs/developers/index.md docs/_layouts/default.html docs/index.md docs/README.md
git commit -s -m "docs: add the developer hub and section navigation"
```

---

## Task 12: Update the localization contract

**Files:**
- Modify: `docs/project/localization/LOCALIZATION.md`

**Interfaces:**
- Consumes: the 29-page public set (15 existing + 13 records + the hub).
- Produces: the contract and validation checklist that the translation tasks follow.

- [ ] **Step 1: Update the counts and tables**

Change "Six languages × 26 documents" to "Six languages × 40 documents". Change the website-pages count from 15 to 29. Add the 14 developer pages to the website table with their served URLs (`/developers/`, `/developers/cli.html`, and so on). Update the total documents count to 40.

- [ ] **Step 2: Update the validation checklist**

Change the "Each language serves its 14 pages" line to the correct 29. Add a step that runs `python3 -I scripts/docs/check_translations.py --require-complete`. Add a step that runs `python3 -I scripts/docs/check_links.py`.

- [ ] **Step 3: Update the adding-a-language steps**

Change the page count from 14 to 29, add the `developers/` tree to the translation set, and mention the `docs/_data/versions.yml` values are rendered, not translated.

- [ ] **Step 4: Verify**

```bash
python3 -I - <<'PY'
import sys
sys.path.insert(0, "scripts/docs")
import check_translations
print(len(check_translations.public_pages("docs")))
PY
python3 -I scripts/docs/check_translations.py --docs docs --lang de
```

Expected: `29`; the German check reports only the developer pages not yet translated.

- [ ] **Step 5: Commit**

```bash
git add docs/project/localization/LOCALIZATION.md
git commit -s -m "docs(localization): extend the contract to the developer section"
```

---

## Task 13: Translate the developer section into Simplified Chinese

**Files:**
- Create: `docs/zh/developers/index.md` and the thirteen mirrored pages under `docs/zh/developers/`

**Interfaces:**
- Consumes: the English pages from Tasks 8-11 and the glossary in `MAD_APP_LOCALIZATION.md` §12.
- Produces: 14 translated pages with `lang: zh-CN`.

- [ ] **Step 1: Mirror the paths**

Create the same relative paths as the English tree:

```text
docs/zh/developers/index.md
docs/zh/developers/cli.md
docs/zh/developers/data-object.md
docs/zh/developers/multi-source.md
docs/zh/developers/sql-entry.md
docs/zh/developers/satellites.md
docs/zh/developers/build/{linux,windows,macos,libraries,pdf}.md
docs/zh/developers/architecture/{data-table,model-layer,array-caching}.md
```

- [ ] **Step 2: Translate the content**

Add `lang: zh-CN` to the front matter and translate `title`, `description`, and the body. Keep every fenced code block, path, identifier, SQL keyword, brand name, and format specifier byte-identical. Use the glossary terms (`查询`, `数据源`, `分组`, `聚合`, `谓词`, `联接`, `带区`, `报表`, `工作区`, `查看器`).

- [ ] **Step 3: Run the checks**

```bash
python3 -I scripts/docs/check_translations.py --docs docs --require-complete --lang zh
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_site_facts.py --docs docs
```

Expected: no code or structure drift; no broken links; no banned literals.

- [ ] **Step 4: Commit**

```bash
git add docs/zh/developers
git commit -s -m "docs(zh): translate the developer section"
```

---

## Task 14: Translate the developer section into Japanese

**Files:**
- Create: `docs/ja/developers/` mirroring the same 14 paths.

**Interfaces:**
- Consumes: the English pages and the glossary.
- Produces: 14 pages with `lang: ja-JP`.

- [ ] **Step 1: Mirror and translate**

Follow Task 13 Steps 1-2 with `lang: ja-JP`. Use the glossary (`クエリ`, `データソース`, `グループ化`, `集計`, `述語`, `結合`, `バンド`, `レポート`, `ワークスペース`, `ビューア`).

- [ ] **Step 2: Run the checks**

```bash
python3 -I scripts/docs/check_translations.py --docs docs --require-complete --lang ja
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_site_facts.py --docs docs
```

- [ ] **Step 3: Commit**

```bash
git add docs/ja/developers
git commit -s -m "docs(ja): translate the developer section"
```

---

## Task 15: Translate the developer section into Brazilian Portuguese

**Files:**
- Create: `docs/pt-br/developers/` mirroring the same 14 paths.

**Interfaces:**
- Consumes: the English pages and the glossary.
- Produces: 14 pages with `lang: pt-BR`.

- [ ] **Step 1: Mirror and translate**

Follow Task 13 Steps 1-2 with `lang: pt-BR`. Use the glossary (`consulta`, `fonte de dados`, `agrupamento`, `agregado`, `predicado`, `junção`, `faixa`, `relatório`, `área de trabalho`, `visualizador`).

- [ ] **Step 2: Run the checks**

```bash
python3 -I scripts/docs/check_translations.py --docs docs --require-complete --lang pt-br
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_site_facts.py --docs docs
```

- [ ] **Step 3: Commit**

```bash
git add docs/pt-br/developers
git commit -s -m "docs(pt-BR): translate the developer section"
```

---

## Task 16: Translate the developer section into German

**Files:**
- Create: `docs/de/developers/` mirroring the same 14 paths.

**Interfaces:**
- Consumes: the English pages and the glossary.
- Produces: 14 pages with `lang: de-DE`.

- [ ] **Step 1: Mirror and translate**

Follow Task 13 Steps 1-2 with `lang: de-DE`. Use the glossary (`Abfrage`, `Datenquelle`, `Gruppierung`, `Aggregat`, `Prädikat`, `Join`, `Band`, `Bericht`, `Arbeitsbereich`, `Betrachter`).

- [ ] **Step 2: Run the checks**

```bash
python3 -I scripts/docs/check_translations.py --docs docs --require-complete --lang de
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_site_facts.py --docs docs
```

- [ ] **Step 3: Commit**

```bash
git add docs/de/developers
git commit -s -m "docs(de): translate the developer section"
```

---

## Task 17: Translate the developer section into Latin American Spanish

**Files:**
- Create: `docs/es/developers/` mirroring the same 14 paths.

**Interfaces:**
- Consumes: the English pages and the glossary.
- Produces: 14 pages with `lang: es-419`.

- [ ] **Step 1: Mirror and translate**

Follow Task 13 Steps 1-2 with `lang: es-419`. Use the glossary (`consulta`, `origen de datos`, `agrupación`, `agregado`, `predicado`, `unión`, `banda`, `informe`, `espacio de trabajo`, `visor`).

- [ ] **Step 2: Run the checks**

```bash
python3 -I scripts/docs/check_translations.py --docs docs --require-complete --lang es
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_site_facts.py --docs docs
```

- [ ] **Step 3: Commit**

```bash
git add docs/es/developers
git commit -s -m "docs(es): translate the developer section"
```

---

## Task 18: Record the application localization

**Files:**
- Modify: `docs/project/localization/MAD_APP_LOCALIZATION.md`
- Modify: `docs/index.md`, `docs/macos.md`, `docs/windows.md`
- Modify: their five translations under `docs/zh/`, `docs/ja/`, `docs/pt-br/`, `docs/de/`, `docs/es/`

**Interfaces:**
- Consumes: the measured catalog state (796 entries, five translations, 62 do-not-translate).
- Produces: a completion record and a public Languages section in six languages.

- [ ] **Step 1: Update the internal record**

Change the headline status from "instrumented but not localized" to a completion record: all translatable UI strings are translated into `de`, `es`, `ja`, `pt-BR`, and `zh-Hans` on iOS, macOS, and Windows; 62 catalog entries are intentionally untranslated (SQL identifiers, data-type and font names, brand names, licence text, format samples); translations are machine-assisted; the About screens carry the notice. Keep the historical phase statuses below as history.

- [ ] **Step 2: Add the public Languages section**

Add this paragraph, in English and each translated page's language, to `docs/index.md`, `docs/macos.md`, and `docs/windows.md` (and their five counterparts):

> **Languages.** The application UI is available in English, Simplified Chinese, Japanese, Brazilian Portuguese, German, and Latin American Spanish. Translations are machine-assisted and may contain errors; report them at <https://github.com/mthomason/MAD/issues>.

Translate the sentence; keep the URL and language names as written where the UI language names are customary.

- [ ] **Step 3: Verify**

```bash
grep -rinE 'not yet localized|instrumented but not localized' docs | grep -v '/project/' | grep -v '/archive/' | grep -v '/superpowers/'
python3 -I scripts/docs/check_site_facts.py --docs docs
rm -rf /tmp/madsite
(cd docs && jekyll build -d /tmp/madsite)
```

Expected: no output from the first grep; the facts check passes; the build succeeds.

- [ ] **Step 4: Commit**

```bash
git add docs
git commit -s -m "docs: record the application's UI localization"
```

---

## Task 19: Correct the remaining stale facts

**Files:**
- Modify: `docs/index.md` and its five translations
- Modify: `README.md`, `translations/README_*.md`
- Modify: any other public page the facts checker reports

**Interfaces:**
- Consumes: the measured facts (12 / 130 / 1,313) and the facts checker.
- Produces: zero banned literals in public text.

- [ ] **Step 1: Replace the framework and test counts**

- `Eleven of the fourteen` → `Twelve of the fourteen`.
- `1,303` → `1,313`.
- `126 test executables` → `130 suites`.
- Any "eleven headless" current-state phrase → `twelve`.
Do the same in every translated copy.

- [ ] **Step 2: Check the platform and database lists**

Ensure every public page that lists the app platforms names iOS, macOS, Windows, and headless Linux, and every database list names PostgreSQL, MySQL/MariaDB, Microsoft SQL Server, and SQLite.

- [ ] **Step 3: Verify**

```bash
python3 -I scripts/docs/check_site_facts.py --docs docs --repo .
grep -rnE '1,303|126 test executables|Eleven of the fourteen|v9\.1\.0-macos|not yet localized' docs README.md translations | grep -v '/project/' | grep -v '/archive/' | grep -v '/superpowers/'
rm -rf /tmp/madsite
(cd docs && jekyll build -d /tmp/madsite)
```

Expected: the facts check passes; the grep produces no output; the build succeeds.

- [ ] **Step 4: Commit**

```bash
git add docs README.md translations
git commit -s -m "docs: correct the framework and test counts everywhere"
```

---

## Task 20: Run the documentation checks in CI

**Files:**
- Create: `.github/workflows/docs.yml`

**Interfaces:**
- Consumes: the three scripts and their tests.
- Produces: a `docs checks` job on push and pull request.

- [ ] **Step 1: Write the workflow**

Create `.github/workflows/docs.yml` with a job named `docs checks` on `push` and `pull_request` to `master`. Steps: checkout, `actions/setup-python` with Python 3, run each test file with `python3 -I`, run `check_links.py`, run `check_translations.py --require-complete`, run `check_site_facts.py --docs docs --repo .`. Do not add it to the required checks; DCO and Linux verification remain the required gates.

- [ ] **Step 2: Validate the YAML and run the commands locally**

```bash
ruby -ryaml -e 'YAML.load_file(".github/workflows/docs.yml")'
python3 -I scripts/docs/check_links_test.py
python3 -I scripts/docs/check_translations_test.py
python3 -I scripts/docs/check_site_facts_test.py
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_translations.py --require-complete
python3 -I scripts/docs/check_site_facts.py --docs docs --repo .
```

Expected: YAML parses; all tests pass; all checks pass.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/docs.yml
git commit -s -m "ci(docs): run the link, translation, and fact checks"
```

---

## Task 21: Final validation and delivery

**Files:**
- No new files; fixes only if a check fails.

**Interfaces:**
- Consumes: everything above.
- Produces: a green PR merged to `master`.

- [ ] **Step 1: Run the complete validation**

```bash
rm -rf /tmp/madsite
(cd docs && jekyll build -d /tmp/madsite)
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_translations.py --require-complete
python3 -I scripts/docs/check_site_facts.py --docs docs --repo . --built /tmp/madsite
find /tmp/madsite -type d \( -name project -o -name archive -o -name superpowers \) | wc -l
for d in zh ja pt-br de es; do
  diff <(cd /tmp/madsite && find . -name '*.html' -not -path './assets/*' -not -path './404.html' \
          -not -path "./$d/*" -not -path './zh/*' -not -path './ja/*' -not -path './pt-br/*' \
          -not -path './de/*' -not -path './es/*' | sort) \
       <(cd /tmp/madsite/$d && find . -name '*.html' | sort)
done
```

Expected: the build exits 0; `broken: 0`; no missing translations or drift; no banned literals; `0` internal directories; the per-language diff is empty.

- [ ] **Step 2: Review the diff**

```bash
git status --short
git diff --stat master
```

Confirm that every moved record is a rename, no file was deleted, and the three anchors are still at the `docs/project/` root.

- [ ] **Step 3: Push and open the PR**

```bash
git push -u origin docs/documentation-changes
gh pr create --base master --head docs/documentation-changes \
	--title "docs: complete, organize, and translate the documentation site" \
	--body "Implements the Reports half of the documentation and marketing program. Adds the developer section, organizes the internal records, fixes the site leak, translates the new pages into the five languages, and corrects the measured version and test facts."
```

- [ ] **Step 4: Watch the required checks and merge**

```bash
gh pr checks <n> --watch
gh pr merge <n> --rebase --delete-branch
```

Expected: DCO, Linux verification, and `docs checks` pass; the merge is rebase and the branch is deleted.

- [ ] **Step 5: Verify on `master`**

```bash
git checkout master
git pull
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_translations.py --require-complete
python3 -I scripts/docs/check_site_facts.py --docs docs --repo .
```

Expected: all checks pass on the merged `master`.
