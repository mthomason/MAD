# Build Number and Build Identity — Design

**Date:** 2026-11-28
**Status:** Proposed — awaiting approval
**Baseline:** `feat/composition-engine-n-node` at `f7b11cfba`
**Supersedes:** the build-number and engine-revision values of
`2026-11-23-versioning-and-build-identity-design.md` §6.1–6.2. That document's
generated-identity, About, handshake, and compatibility decisions stand.

---

## 1. Intent and the why

The macOS About box reports:

```
Engine v9.1 (r4433) · unknown    Application v0.8
```

Every part misleads:

- `unknown` is the short source commit. The **MAD Designer Mac** Xcode target has
  no identity build phase, so no `MADBuildInfo.plist` is written. `./Mac/build.sh`
  writes one; Xcode does not. It will not correct itself at a tag.
- `r4433` is `Versions.yml engine_revision`, a frozen literal. It used to be the
  git commit count. HEAD is commit 5151; `v9.1.0-macos` was 4788; commit 4433 is
  from 2026-10-01. It names no source.
- `v0.8` is the tracked `Mac/Resources/Info.plist` because there is no build info
  to prefer.
- `macos_build`, `windows_build`, and `ios_build` (4434, 4434, 4433) are
  hand-typed and unrelated to git or to each other's platforms.

Two further defects surfaced in the audit:

- The iOS Run Script writes `MADBuildInfo` but never sets the built bundle's
  `CFBundleVersion`; `ios_build` only ever appears in About, never in the actual
  bundle.
- Neither the iOS nor the Mac Xcode target derives its version from the manifest;
  the tracked plists are authoritative and stale.

The goal is a build number that is useful and does not confuse: one that answers
"exactly what is running?" and that no one maintains per commit, push, or merge.

## 2. Decision

**The build number is derived from the source; it is never hand-sequenced.**

- **Build number** = `git rev-list --count HEAD` at build time.
- **Build identity** = the short source commit (8 hex), starred when the tree is
  dirty.
- `CFBundleVersion` (and the Windows package build) carries the build number; the
  engine's `rNNNN` becomes `r<build number>` — the same fact in the spelling the
  About box already uses.
- `Versions.yml` carries no build numbers. They are build products.
- The only release-time action is an iOS store floor (§4.6) and recording the
  published build for the docs site.

The commit count is the numeric projection of the commit history; the short hash
is the exact identity. They are two views of one fact, which is what "part of the
GitHub hash" should mean. A hash alone cannot be `CFBundleVersion` (Apple wants up
to three period-separated integers).

## 3. Goals, non-goals, anti-goals

**Goals**

1. No build number is edited by hand; no per-commit, per-push, or per-merge action.
2. Every About surface, the CLI, and the Windows engine handshake report a commit
   that resolves in the repository.
3. A macOS Xcode build reports the same identity as a `Mac/build.sh` build.
4. The iOS bundle's `CFBundleVersion` is the number About reports, and always
   exceeds the last submitted build.
5. The version manifest stays the single statement of *intended versions* and
   contains no per-build values.

**Non-goals**

- Changing the semantic versions (engine 9.1, app 0.8.0, iOS 9.0) or the
  container/store/protocol numbers.
- Changing the `v0.7.0` published tag or its assets.
- Redesigning the Windows protocol; `engine-info` keeps its shape, with
  `engineRevision` now derived.
- Populating identity for the Linux container's `mad` CLI (it reports `unknown`
  today; see §6).

**Anti-goals**

- A number that can be stale, fabricated, or disagree with the commit it names.
- A build that reports a number lower than one already submitted to the App Store.

## 4. Design

### 4.1 The manifest

Remove: `macos_build`, `windows_build`, `ios_build`, `engine_revision`.

Keep: `schema`, `next_release`, `next_tag`, `published_release`, `published_tag`,
`macos_app_version`, `windows_app_version`, `ios_app_version`, `engine_version`,
`published_engine_version`, `container_major`, `container_minor`,
`store_revision`, `serve_protocol_version`.

Keep as a **published-release record**: `published_engine_revision` (today
`r4433`). It is not an input to any build; it records what the shipped artifact
reports and feeds the docs site. It is updated once, at release.

Add: `ios_build_floor: "0"` — the highest iOS `CFBundleVersion` already
submitted. The generated iOS build is `max(commit_count, ios_build_floor + 1)`. It
stays `0` unless a submission needs it (§4.6).

```yaml
schema: "1"
next_release: "0.8.0"
next_tag: "v0.8.0"
published_release: "0.7.0"
published_tag: "v0.7.0"
macos_app_version: "0.8.0"
windows_app_version: "0.8.0"
ios_app_version: "9.0"
engine_version: "9.1"
published_engine_version: "9.0"
published_engine_revision: "r4433"
ios_build_floor: "0"
container_major: "1"
container_minor: "0"
store_revision: "2"
serve_protocol_version: "1"
```

### 4.2 Generated identity

`scripts/dev/build-info.sh` gains the count and stops reading a build number from
the manifest:

| Key | Value |
| --- | --- |
| `MADAppVersion` | the platform's `*_app_version` |
| `MADAppBuild` | the platform build number passed in (count, or iOS floor-adjusted) |
| `MADBuildNumber` | `git rev-list --count HEAD` (**new**) |
| `MADEngineVersion` | `engine_version` |
| `MADEngineRevision` | `r<MADBuildNumber>` (**derived**, not manifest) |
| `MADSourceCommit` / `MADSourceCommitShort` / `MADSourceDirty` | from git |
| `MADBuildDate` | UTC now |
| `MADServeProtocolVersion` / `MADContainerFormat` / `MADStoreRevision` | from the manifest |

If git is unavailable, `MADBuildNumber` is `0`, the revision is `r0`, the commit
is `unknown`, and About says `unknown` — the existing "never invent" rule.

`--app-build` remains: macOS and Windows pass the count; iOS passes the
floor-adjusted count.

### 4.3 Platform builds

- **macOS (`Mac/build.sh`)** — `app_build` comes from the count, not
  `macos_build`; it sets the built `Info.plist` and `MADBuildInfo` from it.
- **macOS Xcode target** — add the identity Run Script phase to **MAD Designer
  Mac**, placed last so it runs after `Info.plist` processing and before signing.
  It writes `MADBuildInfo.plist` into
  `TARGET_BUILD_DIR/${UNLOCALIZED_RESOURCES_FOLDER_PATH}` and sets the built
  `Info.plist`'s `CFBundleShortVersionString` / `CFBundleVersion`. This removes
  `unknown`.
- **iOS (`buildcounter.sh`)** — compute `max(count, ios_build_floor + 1)`; write
  the identity and set the built `Info.plist`'s version/build. Move the phase to
  the end of the build phases for the same reason.
- **Windows (`package.ps1`, `Engine/build.ps1`)** — compute the count with
  `git rev-list --count HEAD`; use it for `MADAppBuild`,
  `MADEngineRevision = r<count>`, and the engine's `MADBuildInfo`. The manifest
  supplies only the semantic versions.
- **CLI (`CLI/build.sh`)** — pass the count as `--app-build`; `mad version` prints
  `engine 9.1 (r<count>) commit <short>`.

**CI history requirement.** Any job that generates a build number needs full git
history; a shallow clone makes the count wrong (depth 1 reports 1). `macos.yml`
runs `./Mac/build.sh --smoke-test`, so it gets `fetch-depth: 0`. The Windows
verification job downloads a prebuilt engine and does not package the app; the
image job does not yet ship identity (§6).

### 4.4 About surfaces

- **macOS** — `Engine v9.1 (r5151) · f7b11cfb*` and `Application v0.8.0 (5151)`.
  The commit appears once, on the engine line, because both artifacts come from
  one build. A missing identity file still renders `unknown`, but both build
  paths now write one.
- **iOS** — unchanged layout; the same derived revision and commit.
- **Windows** — the engine line from `engine-info`
  (`v9.1 (r5151) · f7b11cfb*`), the application line from `MADBuildInfo.json`
  (`v0.8.0 (5151) · f7b11cfb*`). They may differ, because the engine can be
  updated independently.
- `MADMeta.plist` loses `MADGitCommitCount` (a stale build-time value).
  `MADRevision` stays as the legacy static identifier; it is not a build number
  and is not user-facing.

### 4.5 Checker and tests

- `versions.py` — drop `engine_revision` and `*_build` from the required keys and
  drop the `MADMeta` revision comparison; **fail if `*_build` or
  `engine_revision` reappears**, so the literals cannot return; validate that
  `ios_build_floor` is an integer and `published_engine_revision` is `r<N>`.
- `docs` projection — `engine_revision` comes from `published_engine_revision`;
  the public templates keep their shape.
- macOS smoke test — replace the `r4433` literal with an assertion against the
  packaged `MADBuildInfo.plist` (`MADEngineRevision == "r" + MADAppBuild` for the
  macOS build) and check the label contains that value.
- Windows `AboutViewModelTests` — replace the `r4433` fixtures with synthetic
  values.
- Python fixtures (`build_info_test.py`, `versions_test.py`) updated.

### 4.6 Release process

- **Per commit / push / merge: nothing.** A merge advances the count
  automatically; it is never edited.
- **At release:** bump `next_release` / `next_tag`, bump the shipping
  `*_app_version` if it changes, set `published_*` after publishing, set
  `published_engine_revision` to the shipped build, run `versions.py docs`, tag.
  The tag's commit fixes the build number; record it in the release notes if
  useful.
- **At an iOS submission:** if the count is not greater than `ios_build_floor`,
  set `ios_build_floor` to the last submitted build. The generated build becomes
  floor + 1. This is the only manual build-number action, and only when a
  submission needs it.

### 4.7 Worked example

At HEAD `f7b11cfba`, count 5151, clean tree:

| Artifact | Reports |
| --- | --- |
| macOS app | Engine v9.1 (r5151) · f7b11cfb; Application v0.8.0 (5151) |
| iOS app | Engine v9.1 (r5151) · f7b11cfb |
| Windows app | App v0.8.0 (5151) · f7b11cfb; Engine v9.1 (r5151) · f7b11cfb |
| `mad version` | MAD Designer engine 9.1 (r5151) commit f7b11cfb |

## 5. Approaches considered

- **A. Derived from source (chosen).** Count + short hash. No maintenance; exact;
  monotone on linear master. Costs: large numbers; requires full git history in
  CI; the iOS floor rule.
- **B. Calendar number (e.g. `20261128.1`).** Human-readable and monotone, but it
  names a date, not the code; branches collide; still needs the hash; more
  machinery.
- **C. Manual monotone counter in the manifest.** Keeps small numbers and full
  store control, but it is the scheme that produced `r4433`; it drifts unless
  cross-checked, and it cannot state what actually ran.

## 6. What is left to the implementer

- Confirm the Run Script phase runs after `Info.plist` processing for both app
  targets; if not, move it later or generate a build-settings xcconfig.
- Decide whether the Linux container writes `MADBuildInfo` for its CLI (today
  `mad version` says `unknown`); if yes, pass the count as an image build arg and
  add `fetch-depth: 0` to the image job.
- The exact wording if the commit is dropped from the macOS application line.
- Localization keys if "unknown" changes.

## 7. Verification

- `python3 -I scripts/dev/versions_test.py`,
  `python3 -I scripts/dev/build_info_test.py`, `versions.py check`.
- `./Mac/build.sh --smoke-test`: About shows the derived revision and commit; the
  packaged build info agrees with `git rev-list --count HEAD`.
- Xcode build of **MAD Designer Mac**: About shows the same identity (no
  `unknown`).
- iOS: a simulator build's `Info.plist` `CFBundleVersion` equals the About build;
  `ios_build_floor` respected in a unit test of the generator.
- Windows: `dotnet test Windows/App/Mad.Designer.Windows.slnx`;
  `mad.exe version`.
- `docs.yml` checker; the full Linux gate at the PR.
