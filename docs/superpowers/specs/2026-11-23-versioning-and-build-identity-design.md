# Versioning, Build Identity, and Document Compatibility — Design

**Date:** 2026-11-23
**Status:** Approved approach (user directed implementation); implementation in progress
**Baseline:** `master` at `e1abb7154`
**Related:** `docs/developers/drafts/MAD-Composition-Implementation-Plan.md` §0–1
(the draft is untracked and is input, not part of this change)

---

## 1. Intent and the why

Three things are currently untrustworthy:

1. **What version is supposed to ship.** The intended product, app, and engine
   versions live as scattered literals: the `v0.7.0` tag, `docs/_data/versions.yml`,
   a mirrored marketing file, `Mac/Resources/Info.plist`, `MADDesigner/Resources/
   Info.plist`, `MADDesigner/Resources/Assets/MADMeta.plist`, `Windows/package.ps1`,
   `Windows/App/.../Infrastructure/AppInfo.cs`, and `AboutViewModel.cs`. Some copies
   already disagree (the iOS bundle reports `9.0`, macOS and Windows report `0.7`).
2. **What was actually running.** `MADDesigner/buildcounter.sh`, the script that
   refreshed `MADMeta.plist`, is disabled (`exit 0` on line 3), so the bundled
   metadata still claims commit `8fc14434d` and `v9.0-dirty`. A bug report cannot
   resolve to a source commit. The Windows About screen hardcodes the engine
   identity instead of asking the `mad.exe` beside it.
3. **Whether a document can be read.** The container writer emits a `1.0` header,
   the app-side reader strips any `MADFILE` header without checking its version, the
   CLI reads the major word and ignores the minor word, and the store opens any
   `user_version` **newer** than it understands and runs schema creation first.
   Before composition adds new document content, an old or new reader must be able
   to say "I cannot read this" *before* it touches the file.

The purpose of this work is to leave one checked-in statement of intended versions,
a generated per-build identity that names the exact source commit, an additive
engine handshake, and a compatibility gate at both the container and store layers.
Composition itself is the next phase; this pass builds the seams it needs.

## 2. Goals

1. One checked-in release manifest for intended app and engine versions.
2. Generated build metadata (version, build, full commit, short commit, dirty flag,
   engine identity, protocol/format/store facts) written into build products, never
   into tracked plists.
3. About surfaces on macOS, iOS, and Windows that report the app build and the engine
   build actually running; Windows asks the engine it launched.
4. An additive `engine-info` method on `mad serve` carrying a protocol version and
   capabilities, with `mad version` as the one-shot equivalent.
5. Consistent `.mad` container header validation in the app and the CLI, with a clear
   upgrade message for unsupported versions.
6. Store opens that reject a newer `user_version` **before** schema creation or
   migration writes.
7. A checker (and its unit tests) that keeps the manifest, docs data, code constants,
   and package defaults in agreement; wired into the existing Linux docs job.

## 3. Non-goals and anti-goals

- **Not** implementing composition, the query graph, or a container `1.1`/store `3`.
  Container stays `1.0`; store stays `2`.
- **Not** changing the published `v0.7.0` tag, its assets, or the download links that
  advertise it.
- **Not** automatic flattening of unreadable documents. A reader that cannot interpret
  one refuses it.
- **Not** redesigning the Windows protocol. `engine-info` is additive; every existing
  request and response keeps its shape.
- **Anti-goal:** a build that silently reports a stale or fabricated commit. If the
  identity file is absent, "unknown" is the correct answer.

## 4. Constraints

- The branch is `chore/mad-verification-skills`; all work lands there. The
  `docs/developers/drafts/` document stays untracked.
- `CLAUDE.md` approval gate: architecture/format changes are approved in chat before
  the branch is pushed. Pushes of the branch with no PR run no CI.
- iOS stays on its `9.x` App Store line. The next iOS version/build is assigned only
  after verifying the last App Store submission; this pass records `9.0`.
- Source files that the Linux and Windows headless builds compile must keep
  compiling there (`Linux/cmake/*Sources.cmake`, `Windows/Engine/build.ps1`). This
  design adds **no new source files** to a headless framework: the new logic lives in
  existing `MADConstants.m` and `MADCLI.m` translation units.

## 5. Approaches considered

### 5.1 Where the canonical manifest lives

- **Root `Versions.yml`, generated/checked `docs/_data/versions.yml` (chosen).**
  Tooling reads it without reaching into `docs/`; the Jekyll data file remains a
  projection with the published-release values the site must advertise. A checker
  fails if the projection or any code surface drifts.
- `docs/_data/versions.yml` as the source. Fewer files, but build tooling in `Mac/`,
  `Windows/`, and `scripts/` would depend on a docs-site internal, and the file mixes
  published facts (download tag) with intended ones.
- A plist or JSON manifest. Portable parsers exist, but YAML matches the docs data
  file already in use and stays readable in review.

### 5.2 How build identity reaches the binary

- **A generated `MADBuildInfo.plist`/`.json` placed beside the product by each build
  (chosen).** No source edits in the build phase, no tracked plist rewritten, and an
  older binary with no file reports "unknown" as required.
- Compile-time `-D` constants. Requires touching every build system (Xcode, CMake,
  MSBuild, PowerShell) and rebuilding the framework for each identity.
- Bundling only `CFBundleVersion`/commit count. Does not carry the full commit, the
  dirty flag, or the engine revision.

### 5.3 Engine handshake shape

- **A new `engine-info` serve method returning a versioned JSON object (chosen).**
  Additive; an older engine answers the existing unknown-method error, which the
  client reads as "identity unknown."
- Extending `open`. Couples identity to a document and cannot be asked before any
  document is open.
- A separate sidecar file only. Cannot tell the Windows shell which `mad.exe` it
  actually launched if the path was wrong or stale.

## 6. Design

### 6.1 The manifest — `Versions.yml` (repository root)

Flat keys, quoted strings, parseable by awk, Python `parse_flat_yaml`, and PowerShell:

```yaml
schema: "1"
next_release: "0.7.1"
next_tag: "v0.7.1"
published_release: "0.7.0"
published_tag: "v0.7.0"
macos_app_version: "0.7.1"
macos_build: "4433"
windows_app_version: "0.7.1"
windows_build: "4433"
ios_app_version: "9.0"
ios_build: "4433"
engine_version: "9.0"
engine_revision: "r4433"
container_major: "1"
container_minor: "0"
store_revision: "2"
serve_protocol_version: "1"
```

- `next_*` is the candidate stable release (`0.7.1`); `0.8.0` is the composition
  candidate and is noted in a comment, not a value.
- `published_*` stays `0.7.0`; every public download link and advertised version
  continues to resolve to it.
- iOS remains `9.0` with a release-time verification note. Build numbers are tracked
  per Apple platform, separately from public versions.
- A comment block states the release-time steps: bump `next_*`, bump the shipping
  platform's build, verify the App Store record, retag, update docs data.

### 6.2 Build identity — `MADBuildInfo.plist` / `MADBuildInfo.json`

Generated by `scripts/dev/build-info.sh` from `Versions.yml` + `git`:

| Key | Example |
| --- | --- |
| `MADAppVersion` | `0.7.1` |
| `MADAppBuild` | `4433` |
| `MADEngineVersion` | `9.0` |
| `MADEngineRevision` | `r4433` |
| `MADSourceCommit` | full 40-hex |
| `MADSourceCommitShort` | first 8 |
| `MADSourceDirty` | bool |
| `MADBuildDate` | ISO-8601 UTC |
| `MADServeProtocolVersion` | `1` |
| `MADContainerFormat` | `1.0` |
| `MADStoreRevision` | `2` |

- `--output PATH --format plist|json --app-version X --app-build N` overrides the
  platform-specific version/build selected from the manifest.
- Never writes `Versions.yml`, `MADMeta.plist`, or any tracked plist.
- Determinism: commit and date are from git/clock; the file is a build product, not
  source.

Placement:

- **macOS:** `Mac/build.sh` writes `${CONTENTS_DIR}/Resources/MADBuildInfo.plist`, and
  injects `CFBundleShortVersionString`/`CFBundleVersion` into the built (not tracked)
  `Info.plist`.
- **iOS:** `MADDesigner/buildcounter.sh` (already a Run Script phase on both app
  targets) writes `${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/
  MADBuildInfo.plist` and nothing else. It exits 0 outside Xcode, and no longer
  touches tracked plists.
- **Windows:** `Windows/package.ps1` generates `MADBuildInfo.json` into the publish
  directory and the app bundle; `Windows/Engine/build.ps1` places one beside
  `mad.exe` so the engine can answer for itself.

`MADMeta.plist` is reduced to static engine identity (engine version, revision,
product identifiers); build-time fields are removed because `MADBuildInfo` supersedes
them.

### 6.3 About surfaces

- **macOS** (`MADMacAboutWindowController`): engine line `Engine v9.0 (r4433) · abc12345`
  (append `· local build` when dirty); application line `Application v0.7.1 (4433) ·
  abc12345`. Reads `MADBuildInfo.plist`; falls back to `MADMeta.plist` and the bundle
  Info.plist; anything missing renders `unknown`.
- **iOS** (`MADAboutTableViewController` / `AppDelegate`): the engine version it shows
  today, plus the short commit and dirty marker from `MADBuildInfo.plist`;
  application version/build from the same file, falling back to the bundle.
- **Windows** (`MainWindow` → `AboutViewModel`): the application identity comes from
  `MADBuildInfo.json`; the engine identity comes from `EngineService.EngineInfoAsync()`
  against the engine process the app launched. If the engine does not answer, the
  engine line reads `unknown`. `AppInfo.Version` and the hardcoded
  `v9.0 (r4433)` in `AboutViewModel` are removed; the About tests assert the new
  wiring instead of the old literal.

### 6.4 `engine-info` and `mad version`

`mad serve` gains one method name, `engine-info`, with no document dependency:

```json
{ "id": 1, "ok": true, "result": {
  "protocolVersion": 1,
  "engineVersion": "9.0",
  "engineRevision": "r4433",
  "sourceCommit": "<40-hex>",
  "sourceCommitShort": "abc12345",
  "sourceDirty": false,
  "capabilities": ["open","describe","query","refresh","export","write",
                   "query-model","layout-model","sql-entry","engine-info"]
}}
```

- Unknown values are `null`, never invented. An older engine's
  `unknown method` error is treated by the client as "identity unknown."
- `mad version [--json]` prints the same object for scripts and package
  verification; it is the CLI's identity surface the draft asks for.
- The Windows client adds `EngineInfoAsync()` (returns a nullable record) to
  `EngineService`/`MadEngineClient`; nothing existing changes.

### 6.5 Container validation

- `MADConstants.h` gains a shared validator:
  `BOOL MADFileFormatHeaderIsSupported(const uint8_t *bytes, NSUInteger length,
  NSError **error)`. It accepts a absent header (v0 legacy), `1.0`, and any `1.x`
  with `x <= current minor`; it rejects `major > 1` or `minor > current` with
  `MADFileFormatErrorDomain` and a message naming the document's format and the
  upgrade action.
- `MADArchiveManager` gains `-unarchiveWithError:`; `-unarchive` calls it. The
  existing callers in `MADocument`, `MADHeadlessDocument`, and the legacy converter
  pass their error out. `strippedArchiveURL` validates before stripping.
- `MADCLIContainer` uses the same validator, reads major **and** minor, and returns
  the bad-document error before extraction.

### 6.6 Store revision gate

`MADStore-openWithError:` reads `PRAGMA user_version` on the freshly opened
connection, **before** `journal_mode`, `createSchemaSQL`, or any migration:

- `version > MADStoreCurrentVersion` → close, return
  `MADStoreErrorUnsupportedVersion` ("This document was written by a newer version
  of MAD Designer (store revision N). Upgrade to open it.").
- `version == 0` → treat as 1 (existing rule), then create/migrate as today.
- Nothing is written on the rejection path; a test asserts the file's
  `user_version` and `sqlite_master` are unchanged.

### 6.7 Checker and CI

`scripts/dev/versions.py`:

- `check` — asserts agreement between `Versions.yml` and: `docs/_data/versions.yml`,
  `MADDesigner/Resources/Assets/MADMeta.plist`, `MADConstants.m` container words,
  `MADStoreSchema.m` revision, `Windows/package.ps1` (no stale literal defaults),
  and public download links in `README.md`/`docs/` (they must use
  `published_tag`/`published_release`, not `next_*`).
- `docs` — regenerates `docs/_data/versions.yml` from the manifest's published values
  in the existing key names.
- `read KEY` — the one-key accessor used by shell tooling.

`scripts/dev/versions_test.py` covers parsing, projection, and each drift case.
`docs.yml` runs both the unit tests and `check` on every PR.

## 7. What is left to the implementer

- Exact placement of the Run Script output in the iOS product, verified by a build.
- Whether the Windows About can await `engine-info` in its current event path; if
  not, show `unknown` and fill asynchronously.
- The release-time checklist text (bump `next_*`, builds, tag, docs) in
  `Versions.yml` and `CONTRIBUTING.md`.
- Any localization keys added for "unknown" / "local build" in the About surfaces.

## 8. Verification

- `python3 -I scripts/dev/versions_test.py` and `versions.py check`.
- `build-info.sh` in both formats, with a clean tree and a dirty tree.
- `MAD` suite: store-revision rejection (no writes), container-header acceptance and
  rejection, legacy fixture still opens.
- CLI build on macOS; `mad version --json`; `mad serve` `engine-info`; a `.mad` with
  an unsupported header refused before extraction.
- macOS `./Mac/build.sh --smoke-test`; the About window shows version/build/commit.
- Windows: `.NET` tests for `AboutViewModel`/`EngineService`; package verification
  runs the bundled `mad.exe version` and compares it to `Versions.yml` (run on the
  workstation; CI fetches the published engine asset until a candidate lane exists).
- Full Linux verification remains the PR gate; this pass adds no headless source
  files, so the local fast checks are the source-list checker plus the suites above.
