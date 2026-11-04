# Documentation Localization

The authoritative answer to "what should be translated, and for which language". It
records the contract: the set of public documents, the naming and front-matter rules, the
language switcher, what is deliberately out of scope, and how to add the next language.

This file is an internal record. It lives under `docs/project/`, which `docs/_config.yml`
excludes from the published site.

## Languages

| Code | BCP-47 tag | Jekyll `lang` | Jekyll `locale` | Website directory | Root-file suffix | Switcher label | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `en` | `en-US` | `en-US` (`site.lang`) | — | site root (`docs/`) | none | `English` | Source of truth |
| `zh` | `zh-CN` | `zh-CN` | `zh_CN` | `docs/zh/` | `_zh` | `简体中文` | Complete |
| `ja` | `ja-JP` | `ja-JP` | `ja_JP` | `docs/ja/` | `_ja` | `日本語` | Complete |
| `pt-br` | `pt-BR` | `pt-BR` | `pt_BR` | `docs/pt-br/` | `_pt-BR` | `Português (Brasil)` | Complete |
| `de` | `de-DE` | `de-DE` | `de_DE` | `docs/de/` | `_de` | `Deutsch` | Complete |
| `es` | `es-419` | `es-419` | `es_419` | `docs/es/` | `_es` | `Español` | Complete |

English is the source. A translation is complete when every document in the public set
below exists in it, and the validation checklist in this file passes.

The root-file suffix keeps its case: `README_pt-BR.md`, not `README_pt-br.md`. The
website directory is lower-case where the tag is not (`pt-br`, `de`, `ja`, `zh`), because
the directory is a URL path segment.

## The canonical public set

Six languages × 25 documents. A new public page must be added to every language at the
same time. A page that is missing from a language is not an error the switcher reports:
the per-page counterpart lookup falls back to that language's landing page, so the reader
silently lands somewhere else. Add the page rather than accept the fallback.

### Website pages (14, under `docs/`)

| English source | Served URL |
| --- | --- |
| `docs/index.md` | `/` |
| `docs/README.md` | `/README.html` |
| `docs/01-document.md` | `/01-document.html` |
| `docs/02-container.md` | `/02-container.html` |
| `docs/03-store.md` | `/03-store.html` |
| `docs/04-reading-writing.md` | `/04-reading-writing.html` |
| `docs/05-companion-files.md` | `/05-companion-files.html` |
| `docs/06-hazards.md` | `/06-hazards.html` |
| `docs/07-normative.md` | `/07-normative.html` |
| `docs/08-open-questions.md` | `/08-open-questions.html` |
| `docs/09-verification.md` | `/09-verification.html` |
| `docs/macos.md` | `/macos.html` |
| `docs/vision.md` | `/vision.html` |
| `docs/tutorials/driver-authoring.md` | `/tutorials/driver-authoring.html` |

Each translated page mirrors its source's path under the language directory:
`docs/de/01-document.md` serves `/de/01-document.html`, and `docs/es/01-document.md`
serves `/es/01-document.html`.

`docs/assets/london.html` is an exported sample report, not a documentation page, and is
not translated.

### Root and folder documents (11)

| English source | Translation naming |
| --- | --- |
| `README.md` | `README_<suffix>.md` |
| `CONTRIBUTING.md` | `CONTRIBUTING_<suffix>.md` |
| `CODE_OF_CONDUCT.md` | `CODE_OF_CONDUCT_<suffix>.md` |
| `SECURITY.md` | `SECURITY_<suffix>.md` |
| `Note from Author on Agentic Programming and LLMs.md` | `Note from Author on Agentic Programming and LLMs_<suffix>.md` |
| `CLI/Fixtures/README.md` | `CLI/Fixtures/README_<suffix>.md` |
| `Linux/README.md` | `Linux/README_<suffix>.md` |
| `Mac/README.md` | `Mac/README_<suffix>.md` |
| `MADFileManager/README.md` | `MADFileManager/README_<suffix>.md` |
| `MADTds/README.md` | `MADTds/README_<suffix>.md` |
| `satellites/mad-action/README.md` | `satellites/mad-action/README_<suffix>.md` |

These files sit outside the Jekyll source, so they are plain Markdown on GitHub. Each one
opens with the same language banner, with the current language in bold and the other
five in links, in the order `English`, `简体中文`, `日本語`, `Português (Brasil)`,
`Deutsch`, `Español`:

```markdown
**English** | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md) | [Deutsch](README_de.md) | [Español](README_es.md)
```

A new language adds one more entry to that banner in every existing file — six files per
document for the ten banner-bearing documents, 60 banner edits. (The author note is the
eleventh document and has no banner.)

## Naming and front matter

* **Website tree.** `docs/<lang>/<same relative path as the English source>`. `docs/zh/`,
  `docs/ja/`, `docs/pt-br/`, `docs/de/`, `docs/es/`.
* **Front matter.** Every translated website page carries an explicit `lang:` matching
  its BCP-47 tag (`zh-CN`, `ja-JP`, `pt-BR`, `de-DE`, `es-419`). `_config.yml` also applies a
  directory-wide default, but the explicit value is what the layout and the SEO tag read,
  and it keeps a page correct if it is ever moved.
* **Layout.** Keep `layout: default` exactly where the English source has it. The
  English `docs/index.md` has no `layout:` key — the `_config.yml` default supplies it —
  so a translation of that page should carry one only if it also adds `title`,
  `description`, and `image`. Match the source page's front matter shape.
* **`title` / `description`.** Translate them; they are the page `<title>` and the meta
  description, and the SEO tag publishes them.
* **Paths, identifiers, and code.** Never translate file paths, selector names, class
  names, SQL keywords, test names, or anything inside a code span or fenced block.
  Translating a path breaks the link and the byte-identity check.

## The language switcher

The switcher, the `hreflang` set, the translation notice, and the footer all live in
`docs/_layouts/default.html`; no page carries them itself.

* **Order**, fixed and identical in every language: `English`, `简体中文`, `日本語`,
  `Português (Brasil)`, `Deutsch`, `Español`. The current language is a
  `<span aria-current="page">`, not a link.
* **Counterpart lookup.** The layout strips the page's own language prefix to get
  `base_url`, appends each other language's prefix, and looks the result up in
  `site.pages` by `url`. A hit links to that exact page; a miss — the page is not
  translated yet — falls back to the other language's landing page (`/zh/`, `/ja/`,
  `/pt-br/`, `/de/`, `/es/`, or `/` for English).
* **`hreflang`.** `<link rel="alternate">` for `en`, `zh-CN`, `ja-JP`, `pt-BR`,
  `de-DE`, and `es-419`, plus a neutral `es` alternate pointing at the same Spanish URL
  and `x-default` pointing at the English URL. These use the same
  lookup-and-fallback result as the switcher, so a missing translation never produces a
  dead `hreflang`.
* **Translation notice.** Below the content, one sentence per language stating that the
  page is a translation of the English original and that the English text prevails, with
  a link back to the English counterpart. Present on translated pages only; English pages
  have none.
* **Footer.** "This site is open source. <Improve this page>", translated, linking to
  `https://github.com/mthomason/MAD/edit/master/docs/{{ page.path }}`.

## Exclusions

* **`docs/project/` and `docs/archive/` are internal records.** They are working notes,
  design documents, and registers — not part of the published site and not part of the
  translation contract. `docs/_config.yml` excludes them for every language tree
  (see below); do not translate them for a new language.
* **`docs/project/MAD_DATASOURCE_AND_CONNECTION_UX.md` is not translatable.** It is an
  agent prompt containing private instructions, not a record for a reader.
* **`LICENSE` and `NOTICE` are not translated**, and their terms are not altered. The
  site pages that reference them link to the English files on GitHub.
* **The application, its UI strings, and source comments are out of scope.** This
  contract covers documentation only.

### The legacy Chinese internal tree

`docs/zh/project/` (30 files) and `docs/zh/archive/` (1 file) are an existing translation
of the internal records, made before the policy above. **They are preserved as a legacy
artifact, not deleted.** No other language translates internal records.

Two English files under `docs/project/` have no Chinese counterpart and must not get one:
`MAD_DATASOURCE_AND_CONNECTION_UX.md` (an agent prompt with private instructions) and
this manifest (added after the tree was frozen).

The tree is a **one-time snapshot**, not a maintained mirror:

* It was reconciled once, on 2026-11-03, against the two entries `3c9e86e03` added —
  `docs/zh/project/BUGS.md` and `docs/zh/project/BUGS_FIXED.md` now match the English
  structure (73/73 `###` headings and 516/516 bullets in `BUGS.md`; 169/169 headings and
  957/957 bullets in `BUGS_FIXED.md`).
* It does not track future changes to the English internal records. Do not open a task to
  keep the internal records current in five languages; the English files are the record.
* If the tree is ever removed, removing it is a deliberate decision for the user, not a
  cleanup an agent performs.

### Site exclusions in `_config.yml`

```yaml
exclude:
  - project
  - archive
  - "*/project"
  - "*/archive"
```

The bare entries cover the English root; the globs cover every language directory,
including ones added later. Jekyll matches exclude entries with `File.fnmatch?`, where
`*/project` matches `zh/project` (and, in Ruby's default matching, directories nested
deeper), but not the root `project`, which the bare entry covers. Both Jekyll 4.x (used
locally) and the Jekyll 3.9.x that GitHub Pages runs honour this form.

## Validation checklist

Run from the repository root unless a step says otherwise.

1. **Build the site.**

   ```sh
   rm -rf /tmp/madsite && cd docs && jekyll build -d /tmp/madsite; cd ..
   ```

   The build must exit 0. Deprecation warnings from `jekyll-theme-primer` are expected.

2. **Check internal links and images.** Zero broken internal `href`/`src` across the
   built site. Localized pages point at language-suffixed screenshots
   (`macos-native-mad-query-de.png`, `...-pt-BR.png`, `...-zh-CN.png`); the English
   pages and `README.md` keep the unsuffixed copies. A new language supplies its two
   screenshots in the same pass as its pages.

   ```sh
   python3 - <<'PY'
   import os, re
   from urllib.parse import urlparse, unquote
   site, pat, bad = '/tmp/madsite', re.compile(r'(?:href|src)="([^"]*)"'), []
   for root, dirs, files in os.walk(site):
       dirs[:] = [d for d in dirs if not d.startswith('.')]
       for name in filter(lambda n: n.endswith('.html'), files):
           page = os.path.join(root, name)
           html = open(page, encoding='utf-8').read()
           for m in pat.finditer(html):
               t = m.group(1)
               if not t or t.startswith(('http://', 'https://', 'mailto:', '#', 'data:', '//')):
                   continue
               p = unquote(urlparse(t).path)
               c = os.path.normpath(os.path.join(site, p.lstrip('/')) if p.startswith('/') else os.path.join(root, p))
               if os.path.isdir(c): c = os.path.join(c, 'index.html')
               if not os.path.exists(c): bad.append((os.path.relpath(page, site), t))
   print(f'broken: {len(bad)}')
   for b in bad: print(' ', b[0], '->', b[1])
   PY
   ```

   Expected: `broken: 0`.

3. **Check the excluded trees are not published.**

   ```sh
   find /tmp/madsite -type d \( -name project -o -name archive \) | wc -l   # 0
   ```

4. **Check every public page exists in every language.** Compare the English page set
   against each language directory:

   ```sh
   for d in zh ja pt-br de es; do
     echo "== $d"
     diff <(cd /tmp/madsite && find . -name '*.html' -not -path './assets/*' -not -path "./$d/*" \
             -not -path './zh/*' -not -path './ja/*' -not -path './pt-br/*' -not -path './de/*' \
             -not -path './es/*' | sort) \
          <(cd /tmp/madsite/$d && find . -name '*.html' | sort)
   done
   ```

   Expected: no output for any language. Each language serves its 14 pages (the English
   set includes `/assets/london.html`, the sample report, which is excluded here).

5. **Check code blocks are byte-identical.** The code in a translation must not drift.
   Extract fenced blocks from the English file and its counterpart, then compare:

   ```sh
   awk '/^```/{f=!f; next} f' docs/07-normative.md            > /tmp/en.blocks
   awk '/^```/{f=!f; next} f' docs/de/07-normative.md         > /tmp/de.blocks
   cmp /tmp/en.blocks /tmp/de.blocks && echo identical
   ```

   Run it for every translated pair. Any difference is either a real code change that has
   not been mirrored, or a translation that touched code — both are defects.

6. **Check structural parity.** Headings, tables, and fences should line up per file:

   ```sh
   for f in docs/*.md; do
     t="${f/docs/docs/zh}"     # or ja/, pt-br/, de/, es/
     printf '%-40s en:%s/%s/%s  zh:%s/%s/%s\n' "$f" \
       "$(grep -c '^#' "$f")" "$(grep -c '^|' "$f")" "$(grep -c '^```' "$f")" \
       "$(grep -c '^#' "$t")" "$(grep -c '^|' "$t")" "$(grep -c '^```' "$t")"
   done
   ```

   Blank lines inside tables and intentional extra notes can add a heading or a row; read
   any delta rather than assuming it is none.

7. **Check the switcher and `hreflang`.** On a built page, the eight `rel="alternate"`
   links should point at six existing pages (`en`, `zh-CN`, `ja-JP`, `pt-BR`, `de-DE`,
   `es-419`), the neutral `es` alternate (the same Spanish URL), and `x-default`
   (English). Spot-check one page per language in both directions, and check that the
   fallback for an untranslated page lands on that language's landing page rather than
   a 404.

For the bug registers specifically, parity is a count check:

```sh
for f in docs/project/BUGS.md docs/zh/project/BUGS.md docs/project/BUGS_FIXED.md docs/zh/project/BUGS_FIXED.md; do
  printf '%s headings=%s bullets=%s\n' "$f" "$(grep -c '^### ' "$f")" "$(grep -c '^- ' "$f")"
done
```

## Adding the next language

Spanish (`es-419`, directory `docs/es/`, suffix `_es`, label `Español`) was the last one
added, on 2026-11-03, and followed these steps. The same steps apply to any language;
substitute its tag, directory, suffix, and label.

1. **Create `docs/<lang>/`** and translate the 14 website pages, mirroring the English
   relative paths. Each page gets its BCP-47 tag as `lang:` in its front matter — for
   Spanish, `lang: es-419` on every page.
2. **Add a `_config.yml` default** so pages without an explicit `lang` still resolve:

   ```yaml
     - scope:
         path: "es"
       values:
         lang: es-419
         locale: es_419
   ```

   The `*/project` and `*/archive` exclusions already cover the new directory.
3. **Add the layout branch** in `docs/_layouts/default.html`: an `is_es` flag, a
   `base_url` strip for `/es`, an `es` candidate and match with a `/es/` fallback, the
   `hreflang="es-419"` link (plus the neutral `hreflang="es"` alternate pointing at the
   same URL, when the variant is regional), the translation notice, and the footer string.
4. **Add the switcher entry in every existing branch.** The layout has one `<nav>` block
   per language (English, Chinese, Japanese, Portuguese, German, Spanish); each must list
   the new label in the fixed order, and the new block must list the other languages.
5. **Add the root files.** Eleven new files — `README_es.md`, `CONTRIBUTING_es.md`,
   `CODE_OF_CONDUCT_es.md`, `SECURITY_es.md`, the author note, and the six folder
   READMEs — and add the label to the banner of all 66 existing files (11 documents ×
   6 languages; the author note has no banner). Translate the titles and descriptions of
   the website pages as well.
6. **Update this manifest**: the languages table, the status column, the switcher order,
   the `hreflang` set, and this section.
7. **Validate**: build, links, page counts, code-block identity, heading/table/fence
   parity, and the switcher in all directions. A new language is not done until every
   check in the validation checklist passes for all seven.
