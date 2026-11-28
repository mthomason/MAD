# Build Number and Build Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hand-maintained build numbers and the frozen `r4433` engine revision with a build number derived from git (`git rev-list --count HEAD`), generated into every build product, so every About surface names the commit it was built from.

**Architecture:** `Versions.yml` keeps only semantic versions and compatibility numbers. `scripts/dev/build-info.sh` computes `MADBuildNumber` and `MADEngineRevision` from git. Each platform build passes its own `MADAppBuild` (the count, or the floor-adjusted count on iOS). The Xcode identity phase is added to the Mac target and moved to the end of the iOS phases so it can set the built `Info.plist` after processing. The checker fails if a build literal returns.

**Tech Stack:** Bash, Python 3 (manifest checker and its tests), Objective-C (About surfaces), Xcode project file, PowerShell/C# (Windows), GitHub Actions YAML.

**Spec:** `docs/superpowers/specs/2026-11-28-build-number-design.md`

## Global Constraints

- Build number = `git rev-list --count HEAD` at build time. Never store it in `Versions.yml`.
- `Versions.yml` must not contain `macos_build`, `windows_build`, `ios_build`, or `engine_revision`.
- `MADEngineRevision` is `r<MADBuildNumber>` (e.g. `r5151`). `MADBuildNumber` is a new key in every generated identity file.
- `ios_build_floor` defaults to `"0"`; generated iOS build = `max(count, floor + 1)`.
- Semantic versions stay: engine `9.1`, macOS/Windows app `0.8.0`, iOS `9.0`; container `1.0`, store `2`, protocol `1`.
- A build with no identity file reports `unknown`, never a guess.
- Tabs for code spacing; one-line SPDX headers on new files.
- Every commit is signed off (`git commit -s`); the branch is `feat/composition-engine-n-node`.

## Review Focus

- **Xcode build of `MAD Designer Mac`** — must show the same revision/commit as `./Mac/build.sh`, not `unknown`. Pinned by Task 6's smoke assertion and Task 4's phase wiring.
- **Shallow clone** — `git rev-list --count HEAD` would be 1; the macOS CI job must fetch full history. Pinned by Task 6's workflow change.
- **iOS submission on an old/hotfix commit** — the generated build must exceed the last submitted build. Pinned by Task 4's floor test.
- **Dirty tree** — the identity must be starred, not silently clean. Already pinned by `build_info_test.py`'s dirty test (Task 2).
- **Build outside git** — must report `unknown`/`r0`, never a stale literal. Pinned by Task 2's outside-git test.

---

### Task 1: Manifest schema and checker

**Files:**
- Modify: `Versions.yml`
- Modify: `scripts/dev/versions.py`
- Test: `scripts/dev/versions_test.py`
- Modify: `CONTRIBUTING.md:70-88`

**Interfaces:**
- Consumes: nothing.
- Produces: `Versions.yml` keys `published_engine_revision` (required, `rN`) and `ios_build_floor` (required, integer string); no `*_build` or `engine_revision` keys. `versions.docs_projection(manifest)["engine_revision"]` reads `published_engine_revision`. `versions.check(repo_root)` flags any returned build literal.

- [ ] **Step 1: Update the tests to the new schema and add the drift cases**

In `scripts/dev/versions_test.py`:

Replace `MANIFEST` with:

```python
MANIFEST = """\
schema: "1"
next_release: "0.8.0"
next_tag: "v0.8.0"
published_release: "0.7.0"
published_tag: "v0.7.0"
macos_app_version: "0.8.0"
windows_app_version: "0.8.0"
ios_app_version: "9.0"
ios_build_floor: "0"
engine_version: "9.0"
published_engine_revision: "r4433"
container_major: "1"
container_minor: "0"
store_revision: "2"
serve_protocol_version: "1"
"""
```

In `make_repo`, remove the `MADGitCommitCount` line from the `MADMeta.plist` fixture, and keep `engine_revision: "r4433"` in the docs fixture.

Add these tests:

```python
def test_check_rejects_manifest_build_literal(self):
    self.make_repo()
    self.write("Versions.yml", MANIFEST + 'macos_build: "5000"\n')
    problems = versions.check(str(self.root))
    self.assertTrue(any("macos_build" in problem for problem in problems), problems)

def test_check_rejects_meta_commit_count(self):
    self.make_repo()
    self.write("MADDesigner/Resources/Assets/MADMeta.plist", "\n".join([
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<plist version="1.0"><dict>',
        "<key>CFBundleShortVersionString</key><string>9.0</string>",
        "<key>MADGitCommitCount</key><string>4433</string>",
        "</dict></plist>",
        "",
    ]))
    problems = versions.check(str(self.root))
    self.assertTrue(any("MADGitCommitCount" in problem for problem in problems), problems)

def test_check_validates_ios_build_floor(self):
    self.make_repo()
    self.write("Versions.yml", MANIFEST.replace('ios_build_floor: "0"', 'ios_build_floor: "abc"'))
    problems = versions.check(str(self.root))
    self.assertTrue(any("ios_build_floor" in problem for problem in problems), problems)

def test_check_validates_published_engine_revision(self):
    self.make_repo()
    self.write("Versions.yml",
               MANIFEST.replace('published_engine_revision: "r4433"',
                                'published_engine_revision: "4433"'))
    problems = versions.check(str(self.root))
    self.assertTrue(any("published_engine_revision" in problem for problem in problems),
                    problems)
```

Also update `test_docs_projection_uses_published_values` to keep asserting `projection["engine_revision"] == "r4433"` (now sourced from `published_engine_revision`).

- [ ] **Step 2: Run the tests and confirm they fail for the right reason**

Run: `python3 -I scripts/dev/versions_test.py`
Expected: failures for the missing `*_build`/`MADGitCommitCount`/floor/revision checks; the fixture parse may also fail until `versions.py` requires the new keys.

- [ ] **Step 3: Implement the checker changes in `scripts/dev/versions.py`**

- Remove `"macos_build"`, `"windows_build"`, `"ios_build"`, `"engine_revision"` from `MANIFEST_KEYS`; add `"ios_build_floor"` and `"published_engine_revision"`.
- In `docs_projection`, set `engine_revision = manifest["published_engine_revision"]` (no `engine_revision` fallback).
- In `check`, after loading the manifest:
  - For each of `("macos_build", "windows_build", "ios_build", "engine_revision")`, if present in the manifest, append `"Versions.yml: %s is a build literal; build numbers are derived from git" % key`.
  - If `ios_build_floor` does not match `^\d+$`, append a problem naming `ios_build_floor`.
  - If `published_engine_revision` does not match `^r\d+$`, append a problem naming it.
- In the `MADMeta.plist` block, keep the engine version comparison; delete the `MADGitCommitCount`/`engine_revision` comparison and instead append a problem when `_plist_value(meta_path, "MADGitCommitCount")` is not `None`: `"MADDesigner/Resources/Assets/MADMeta.plist: MADGitCommitCount is a stale build-time value; remove it"`.

- [ ] **Step 4: Run the tests**

Run: `python3 -I scripts/dev/versions_test.py`
Expected: PASS.

- [ ] **Step 5: Update `Versions.yml`**

Remove `macos_build`, `windows_build`, `ios_build`, `engine_revision`. Add:

```yaml
ios_build_floor: "0"
published_engine_revision: "r4433"
```

Keep `published_engine_version: "9.0"`. Replace the release-time comment with: build numbers are the git commit count at build time and are not stored here; at release set `next_*`, bump semantic versions, set `published_engine_revision` to `r<count>`, publish, run `versions.py docs`; set `ios_build_floor` to the last submitted build only when a submission needs it.

- [ ] **Step 6: Update `CONTRIBUTING.md`**

Change the sentence listing "each desktop app's version and build ... the engine's version and revision" to "each app's semantic version, the iOS line, and the published engine's version and revision". Add one sentence: build numbers are derived from git at build time, a merge advances the number automatically, and only `ios_build_floor` is manual (at an App Store submission).

- [ ] **Step 7: Regenerate the docs projection and check**

Run:

```sh
python3 -I scripts/dev/versions.py docs
python3 -I scripts/dev/versions.py check
```

Expected: `docs/_data/versions.yml` keeps `engine_revision: "r4433"`; `check` prints nothing and exits 0.

- [ ] **Step 8: Commit**

```sh
git add Versions.yml CONTRIBUTING.md scripts/dev/versions.py scripts/dev/versions_test.py docs/_data/versions.yml
git commit -s -m "feat(versions): derive build numbers from git"
```

---

### Task 2: Build-info generator

**Files:**
- Modify: `scripts/dev/build-info.sh`
- Test: `scripts/dev/build_info_test.py`

**Interfaces:**
- Consumes: `Versions.yml` keys `engine_version`, `*_app_version`, container/store/protocol.
- Produces: generated plist/JSON keys `MADBuildNumber` (`"1"` in the one-commit test repo), `MADEngineRevision` (`"r1"`), `MADAppBuild` (the `--app-build` value, default = count).

- [ ] **Step 1: Update the tests**

In `scripts/dev/build_info_test.py`, replace `MANIFEST` with the Task 1 fixture (no `*_build`/`engine_revision`; add `published_engine_revision: "r4433"` and `ios_build_floor: "0"`).

In `test_plist_contains_identity_from_manifest`, add:

```python
self.assertEqual(values["MADBuildNumber"], "1")
self.assertEqual(values["MADEngineRevision"], "r1")
```

Keep `self.assertEqual(values["MADAppBuild"], "7")`.

In `test_json_matches_plist_fields`, add the same two assertions for the JSON values.

In `test_outside_git_reports_unknown`, add:

```python
self.assertEqual(values["MADBuildNumber"], "0")
self.assertEqual(values["MADEngineRevision"], "r0")
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `python3 -I scripts/dev/build_info_test.py`
Expected: FAIL — `MADBuildNumber` missing and `MADEngineRevision` is `r4433`.

- [ ] **Step 3: Implement in `scripts/dev/build-info.sh`**

- Delete `engine_revision="$(value engine_revision)"`.
- In the git block, compute `build_number="$(git -C "$manifest_root" rev-list --count HEAD 2>/dev/null || echo 0)"`; if it is not `^[0-9]+$`, set it to `0`; set `engine_revision="r${build_number}"`.
- Change the app-build default from `$(value macos_build)` to `${build_number}`.
- Add `<key>MADBuildNumber</key><string>${build_number}</string>` to the plist output and `"MADBuildNumber": "${build_number}",` to the JSON output.
- Update the header comment: the build number is the git commit count; the app version comes from the manifest.

- [ ] **Step 4: Run the tests**

Run: `python3 -I scripts/dev/build_info_test.py`
Expected: PASS.

- [ ] **Step 5: Commit**

```sh
git add scripts/dev/build-info.sh scripts/dev/build_info_test.py
git commit -s -m "feat(dev): generate the build number from the commit count"
```

---

### Task 3: macOS and CLI build scripts

**Files:**
- Modify: `Mac/build.sh:95-99`
- Modify: `CLI/build.sh:125-128`

**Interfaces:**
- Consumes: the count from git.
- Produces: `CFBundleVersion`/`MADAppBuild` equal to `git rev-list --count HEAD`.

- [ ] **Step 1: Change `Mac/build.sh`**

Replace the `app_build="$(python3 ... read macos_build)"` line with:

```sh
app_build="$(git -C "${REPO_ROOT}" rev-list --count HEAD 2>/dev/null || echo 0)"
```

Keep the `app_version` read from `macos_app_version`.

- [ ] **Step 2: Change `CLI/build.sh`**

Replace the `--app-build "$(python3 ... read macos_build)"` argument with:

```sh
--app-build "$(git -C "${REPO_ROOT}" rev-list --count HEAD 2>/dev/null || echo 0)"
```

- [ ] **Step 3: Verify**

Run:

```sh
git rev-list --count HEAD
git diff -- Mac/build.sh CLI/build.sh
```

Expected: the diff shows only the count substitution; the printed count matches the goal (currently 5151).

- [ ] **Step 4: Commit**

```sh
git add Mac/build.sh CLI/build.sh
git commit -s -m "build: use the git commit count for the macOS and CLI builds"
```

---

### Task 4: Xcode identity phase and `buildcounter.sh`

**Files:**
- Modify: `MADDesigner/buildcounter.sh` (full rewrite)
- Modify: `MADDesigner/MAD Designer.xcodeproj/project.pbxproj`
- Test: `scripts/dev/build_counter_test.py` (new)
- Modify: `.github/workflows/macos.yml`

**Interfaces:**
- Consumes: Xcode build settings `TARGET_BUILD_DIR`, `UNLOCALIZED_RESOURCES_FOLDER_PATH`, `INFOPLIST_PATH`, `PLATFORM_NAME`, `PROJECT_DIR`; `Versions.yml` `macos_app_version`, `ios_app_version`, `ios_build_floor`.
- Produces: `MADBuildInfo.plist` in the built bundle and `CFBundleShortVersionString`/`CFBundleVersion` set on the built `Info.plist`.

- [ ] **Step 1: Write the failing test `scripts/dev/build_counter_test.py`**

The test creates a temp repo with a `Versions.yml` (`macos_app_version: "0.8.0"`, `ios_app_version: "9.0"`, `ios_build_floor` as given), a one-commit git repo, a copy of the real `scripts/dev/build-info.sh` under `scripts/dev/`, and a fake `Products/App.app/Info.plist` with `CFBundleShortVersionString` `9.0` and `CFBundleVersion` `1`. It runs the real `MADDesigner/buildcounter.sh` with `PROJECT_DIR=<root>/app`, `TARGET_BUILD_DIR=<root>/Products`, `UNLOCALIZED_RESOURCES_FOLDER_PATH=App.app`, `INFOPLIST_PATH=App.app/Info.plist`, and `PLATFORM_NAME` set to `iphoneos` or `macosx`.

Assertions:

```python
# iOS with floor 5000, count 1
self.assertEqual(info["MADBuildNumber"], "1")
self.assertEqual(info["MADEngineRevision"], "r1")
self.assertEqual(info["MADAppBuild"], "5001")
self.assertEqual(built_plist["CFBundleVersion"], "5001")
self.assertEqual(info["MADAppVersion"], "9.0")

# macOS with floor 5000 (ignored), count 1
self.assertEqual(info["MADAppBuild"], "1")
self.assertEqual(built_plist["CFBundleVersion"], "1")
self.assertEqual(info["MADAppVersion"], "0.8.0")
self.assertEqual(info["MADEngineRevision"], "r1")
```

Skip the class with `unittest.skipUnless(os.path.exists("/usr/libexec/PlistBuddy"), ...)` so the file is safe to run anywhere.

- [ ] **Step 2: Run the test and confirm it fails**

Run: `python3 -I scripts/dev/build_counter_test.py`
Expected: FAIL — the current script reads `ios_build` (removed) and never sets the built `Info.plist` version.

- [ ] **Step 3: Rewrite `MADDesigner/buildcounter.sh`**

Keep the exit-0 guard outside Xcode. Then:

1. `PROJECT_DIR` default; `REPO_ROOT="$(cd "${PROJECT_DIR}/.." && pwd)"`; `MANIFEST="${REPO_ROOT}/Versions.yml"`.
2. `manifest_value` as today.
3. `build_number="$(git -C "${REPO_ROOT}" rev-list --count HEAD 2>/dev/null || echo 0)"`; validate `^[0-9]+$`, else `0`.
4. If `PLATFORM_NAME` starts with `macosx`: `app_version="$(manifest_value macos_app_version)"`; `app_build="$build_number"`.
   Otherwise: `app_version="$(manifest_value ios_app_version)"`; `floor="$(manifest_value ios_build_floor)"`; default/validate `floor` to `0`; if `build_number > floor` then `app_build="$build_number"` else `app_build="$((floor + 1))"`.
5. Write `MADBuildInfo.plist` to `${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/MADBuildInfo.plist` via `"${REPO_ROOT}/scripts/dev/build-info.sh" --format plist --output ... --app-version ... --app-build ...`.
6. If `${TARGET_BUILD_DIR}/${INFOPLIST_PATH}` exists, use `/usr/libexec/PlistBuddy` to `Set :CFBundleShortVersionString "$app_version"` and `Set :CFBundleVersion "$app_build"`.

Update the header comment accordingly.

- [ ] **Step 4: Run the test**

Run: `python3 -I scripts/dev/build_counter_test.py`
Expected: PASS (2 cases).

- [ ] **Step 5: Wire the Xcode project**

In `MADDesigner/MAD Designer.xcodeproj/project.pbxproj`:

1. Add `4C9A00092EA0000000000001 /* Build Identity */,` as the last entry of the **MAD Designer Mac** target's `buildPhases`.
2. Add the phase object in the `PBXShellScriptBuildPhase` section, matching the existing style:

```text
		4C9A00092EA0000000000001 /* Build Identity */ = {
			alwaysOutOfDate = 1;
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Build Identity";
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "\"${PROJECT_DIR}/buildcounter.sh\"\n";
		};
```

3. Move the existing `4C13394018026433004F61CA /* Run Script */` from the **MAD Designer** target's phase list to the end (after `4C29162B24AC75E400EC794B /* Embed Frameworks */`).
4. Move `4CF3B6EC18046614004BE0AC /* ShellScript */` from the **MAD Viewer** target's phase list to the end (after `4C3DCBD91BCA00F500ABE231 /* Embed Frameworks */`).

- [ ] **Step 6: Verify the script standalone and the project parses**

Run:

```sh
python3 -I scripts/dev/build_counter_test.py
xcodebuild -workspace Reports.xcworkspace -list >/dev/null
```

Expected: PASS; `xcodebuild -list` exits 0 and still shows `MAD Designer Mac`.

- [ ] **Step 7: Add the test to the macOS workflow**

In `.github/workflows/macos.yml`, after the toolchain step (or beside the other fast checks), add:

```yaml
      - name: Test the build counter
        run: python3 -I scripts/dev/build_counter_test.py
```

- [ ] **Step 8: Commit**

```sh
git add MADDesigner/buildcounter.sh MADDesigner/'MAD Designer.xcodeproj'/project.pbxproj scripts/dev/build_counter_test.py .github/workflows/macos.yml
git commit -s -m "build(xcode): generate the build identity in both app targets"
```

---

### Task 5: About surfaces and static metadata

**Files:**
- Modify: `Mac/Source/MADMacAboutWindowController.m:133-140`
- Modify: `MADDesigner/Source/MADAboutTableViewController.m:230-242`
- Modify: `MADDesigner/Source/AppDelegate.m:87-91`
- Modify: `MADDesigner/Resources/Assets/MADMeta.plist`

**Interfaces:**
- Consumes: `MADBuildInfo.plist` keys `MADEngineRevision` (`r<N>`), `MADAppBuild`, `MADEngineVersion`, `MADAppVersion`.
- Produces: engine line `Engine v9.1 (r5151) · f7b11cfb`; application line `Application v0.8.0 (5151)`; `unknown` when no identity file.

- [ ] **Step 1: Update `MADMacAboutWindowController.buildTextForBundle:`**

Return `MADBuildInfo.plist`'s `MADEngineRevision` directly when present (it already carries the `r`); otherwise return `@"unknown"`. Delete the `MADGitCommitCount` fallback.

- [ ] **Step 2: Update `MADAboutTableViewController.buildText`**

Keep the `revision · commit` format when both are present. Change the fallback to `@"unknown"`; delete the `bundleGitCommitCount` call.

- [ ] **Step 3: Remove the unused `bundleGitCommitCount`**

Delete `+ (NSString *)bundleGitCommitCount` from `MADDesigner/Source/AppDelegate.m` (it has no other caller and no header declaration).

- [ ] **Step 4: Remove the stale key from `MADMeta.plist`**

Delete the `MADGitCommitCount` key and its `<string>4433</string>` value.

- [ ] **Step 5: Verify**

Run:

```sh
grep -rn "MADGitCommitCount\|bundleGitCommitCount" --include='*.m' --include='*.h' --include='*.plist' .
python3 -I scripts/dev/versions.py check
```

Expected: no source/plist hits; `check` exits 0.

- [ ] **Step 6: Commit**

```sh
git add Mac/Source/MADMacAboutWindowController.m MADDesigner/Source/MADAboutTableViewController.m MADDesigner/Source/AppDelegate.m MADDesigner/Resources/Assets/MADMeta.plist
git commit -s -m "fix(app): report the derived revision instead of a stale build count"
```

---

### Task 6: macOS smoke assertion and CI history

**Files:**
- Modify: `Mac/Tests/MADMacSmokeTest.m:2125-2140`
- Modify: `.github/workflows/macos.yml`

**Interfaces:**
- Consumes: the packaged app's `MADBuildInfo.plist` and the About labels.
- Produces: the smoke test proves the packaged build info agrees with the About line and that `unknown` is absent.

- [ ] **Step 1: Replace the pinned `r4433` assertion**

In the About assertion block, read the packaged app's identity before the `if`:

```objc
NSString *identityPath = [packagedAppBundle pathForResource:@"MADBuildInfo" ofType:@"plist"];
NSDictionary *identity = identityPath.length > 0 ? [NSDictionary dictionaryWithContentsOfFile:identityPath] : nil;
NSString *revision = identity[@"MADEngineRevision"];
NSString *build = identity[@"MADAppBuild"];
if (![revision isKindOfClass:[NSString class]] || ![build isKindOfClass:[NSString class]] ||
    ![revision isEqualToString:[@"r" stringByAppendingString:build]]) {
    fprintf(stderr, "FAIL: packaged build identity is inconsistent: revision='%s' build='%s'\n", ...);
    return 71;
}
```

Then in the existing `if`, replace `containsString:@"r4433"` with `containsString:revision` and add a failure condition `[aboutWC.versionLabel.stringValue containsString:@"unknown"]`.

- [ ] **Step 2: Run the smoke test**

Run: `./Mac/build.sh --smoke-test`
Expected: PASS; the About line shows the derived `r<count>` and the commit, with no `unknown`.

- [ ] **Step 3: Fetch full history in the macOS CI job**

In `.github/workflows/macos.yml`, change the checkout step to:

```yaml
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
```

- [ ] **Step 4: Commit**

```sh
git add Mac/Tests/MADMacSmokeTest.m .github/workflows/macos.yml
git commit -s -m "test(mac): assert the derived build identity in About"
```

---

### Task 7: Windows package and engine identity

**Files:**
- Modify: `Windows/package.ps1:73-76,197-240`
- Modify: `Windows/Engine/build.ps1:1488-1530`
- Test: `Windows/App/Mad.Designer.Windows.Tests/AboutViewModelTests.cs:38-51`

**Interfaces:**
- Consumes: `git rev-list --count HEAD`, `Versions.yml` semantic versions.
- Produces: `MADBuildNumber`, `MADAppBuild`, `MADEngineRevision = r<count>` in `MADBuildInfo.json` and the engine's `MADBuildInfo.plist`; engine verification compares to `r<count>`.

- [ ] **Step 1: Update the Windows About test fixtures**

In `About_UsesTheEngineIdentityItWasGiven`, replace the literal `r4433`/`4433`/`9.0` with `r5151`/`5151`/`9.1`:

```csharp
var engine = new EngineInfo(1, "9.1", "r5151", "abc", "abc12345", false,
    new[] { "engine-info" });
var build = new BuildInfo("0.8.0", "5151", "9.1", "r5151", "abc", "abc12345", false);

var about = new AboutViewModel(build, engine);

Assert.Contains("v9.1", about.EngineVersion);
Assert.Contains("r5151", about.EngineVersion);
Assert.Contains("abc12345", about.EngineVersion);
Assert.Contains("0.8.0", about.ApplicationVersion);
Assert.Contains("5151", about.ApplicationVersion);
```

- [ ] **Step 2: Update `Windows/package.ps1`**

After `$Version` is resolved, compute:

```powershell
$BuildNumber = ((& git -C $RepoRoot rev-list --count HEAD 2>$null | Out-String).Trim())
if ($BuildNumber -notmatch '^\d+$') { $BuildNumber = "0" }
```

Change `$EngineVersion` to `"$(Get-ManifestValue 'engine_version') (r$BuildNumber)"`.

In the `$info` hashtable, set `MADAppBuild = $BuildNumber`, `MADEngineRevision = "r$BuildNumber"`, and add `MADBuildNumber = $BuildNumber`.

In the verification, replace the `engine_revision` comparison with `if ($engineInfo.engineRevision -ne "r$BuildNumber") { throw ... }`.

- [ ] **Step 3: Update `Windows/Engine/build.ps1`**

In the identity block, add:

```powershell
$buildNumber = "0"
$counted = (& git -C $RepoRoot rev-list --count HEAD 2>$null | Out-String).Trim()
if ($LASTEXITCODE -eq 0 -and $counted -match '^\d+$') { $buildNumber = $counted }
```

Replace the manifest reads for `MADAppBuild` and `MADEngineRevision` with `$buildNumber` and `r$buildNumber`, and add `MADBuildNumber`.

- [ ] **Step 4: Verify on Windows (workstation or CI)**

Run:

```powershell
dotnet test Windows/App/Mad.Designer.Windows.slnx --nologo -v minimal
.\Windows\Engine\build.ps1
.\Windows\Engine\build\mad.exe version --json
```

Expected: tests pass; `mad version --json` reports `engineRevision` `r<count>` and `sourceCommit` matching `git rev-parse HEAD`; packaging (when run) passes the engine verification.

- [ ] **Step 5: Commit**

```sh
git add Windows/package.ps1 Windows/Engine/build.ps1 Windows/App/Mad.Designer.Windows.Tests/AboutViewModelTests.cs
git commit -s -m "build(windows): derive the package and engine build number"
```

---

### Task 8: Verification pass and PR update

**Files:**
- No code changes; run the gates and update the PR.

- [ ] **Step 1: Run the fast checks**

```sh
python3 -I scripts/dev/versions_test.py
python3 -I scripts/dev/build_info_test.py
python3 -I scripts/dev/build_counter_test.py
python3 -I scripts/dev/versions.py check
```

Expected: all pass.

- [ ] **Step 2: Run the Apple suite(s) touched by the change**

Run the `MAD` and `MAD Designer` suites against an available simulator using the shared derived-data path (see `AGENTS.md` § Testing), and `./Mac/build.sh --smoke-test`.

Expected: green.

- [ ] **Step 3: Confirm no stale literals remain**

```sh
grep -rn "r4433\|macos_build\|windows_build\|ios_build\|engine_revision" --exclude-dir=.git --exclude-dir=build .
```

Expected: only the design/plan documents and historical docs/plans mention them; no code, manifest, or test pins one.

- [ ] **Step 4: Push and update the PR**

```sh
git push -u origin feat/composition-engine-n-node
gh pr view --json number,title --jq '.number'
gh pr edit <n> --body "<updated summary including the build-number change>"
```

Expected: the existing PR is updated; no merge. The Linux and DCO gates run on the PR.

---

## Self-Review

- **Spec coverage:** §4.1 Task 1; §4.2 Task 2; §4.3 Tasks 3, 4, 7; §4.4 Task 5; §4.5 Tasks 1, 2, 4, 6; §4.6 Task 1 (docs) and Task 8; §4.7 verified by the smoke test. The Linux CLI identity is a documented non-goal (§6) and is not a task.
- **Step scan:** every step names a file, a command, or an exact value; no "handle edge cases" placeholders.
- **Type consistency:** `MADBuildNumber`, `MADEngineRevision` (`r<N>`), `MADAppBuild`, `published_engine_revision`, `ios_build_floor` are spelled identically in every task.
- **Review Focus:** the five failure modes are pinned by the tasks named in the header.
- **Proportion:** the plan is longer than the spec because it covers four build systems and nine files; the code steps give signatures, keys, and exact values rather than bodies.
