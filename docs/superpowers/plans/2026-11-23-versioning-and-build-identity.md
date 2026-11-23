# Versioning and Build Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make one checked-in manifest the source of intended versions, generate an exact per-build identity into each product, report it in every About surface and the CLI, and refuse unreadable containers and newer stores before any write.

**Architecture:** A flat `Versions.yml` at the repository root is the single statement of intended versions. A Python checker keeps docs, plists, code constants, and package defaults in agreement. A shell generator turns the manifest plus `git` into `MADBuildInfo.plist`/`.json`, placed into build products only. `mad serve` gains an additive `engine-info` method and `mad version` is its one-shot form. Container and store readers validate before extracting or writing.

**Tech Stack:** Objective-C (ARC, iOS 15+/macOS 12+/GNUstep), Python 3 (stdlib only), Bash, PowerShell 7, .NET 10, SQLite.

**Spec:** `docs/superpowers/specs/2026-11-23-versioning-and-build-identity-design.md`

## Global Constraints

- Work on branch `chore/mad-verification-skills`; never commit to `master`.
- `docs/developers/drafts/` stays untracked and is not part of this work.
- Tabs for indentation in Objective-C, Bash, and PowerShell source; the Python
  checkers use tabs (match `scripts/docs/check_site_facts.py`).
- No new source files in a headless framework: the validator lives in
  `MAD/Source/MADConstants.m`, the CLI identity code in `CLI/Source/MADCLI.m`.
- Container stays major `1`, minor `0`; store stays `MADStoreCurrentVersion = 2`.
- iOS stays on `9.0`; the published release stays `v0.7.0` and its links unchanged.
- Every commit is signed: `git commit -s`.
- Mark deliberate unused code with the project's clang attributes (see root `CLAUDE.md`).

## Review Focus

- **A missing `MADBuildInfo` file.** Every reader must fall back or say `unknown`;
  none may crash or invent a commit. The task that adds each reader pins this.
- **A store already at a newer revision.** Opening it must make zero writes: no
  journal-mode change, no schema creation, no migration, no `user_version` update.
  Pinned in Task 3.
- **A container with a header the build does not know.** Both the app and the CLI
  must refuse it with an upgrade message and must not extract it. Pinned in Task 4.
- **A dirty working tree.** The identity must say `dirty: true` and the About
  surface must say `local build`; a dirty tree must never claim a clean commit.
  Pinned in Task 2.
- **An older engine with no `engine-info`.** The Windows About must show
  `unknown`, not fail the window. Pinned in Task 7.

---

### Task 1: The manifest and its checker

**Files:**
- Create: `Versions.yml`
- Create: `scripts/dev/versions.py`
- Create: `scripts/dev/versions_test.py`
- Modify: `docs/_data/versions.yml` (generated, version keys only)
- Modify: `.github/workflows/docs.yml:29-36`

**Interfaces:**
- Produces:
  - `parse_flat_yaml(path: str) -> dict[str, str]`
  - `load_manifest(repo_root: str) -> dict[str, str]`
  - `docs_projection(manifest: dict[str, str]) -> dict[str, str]` — the version-key
    subset of `docs/_data/versions.yml`
  - `check(repo_root: str) -> list[str]` — empty list means agreement
  - CLI: `versions.py check|docs|read KEY`

- [ ] **Step 1: Write `Versions.yml`**

Create the file with this exact content (the comment is the release checklist):

```yaml
# MAD version manifest — the one checked-in statement of intended versions.
# Tooling reads this file; scripts/dev/versions.py check keeps every other
# surface in agreement with it.  Change this file, not the copies.
#
# At release time: set next_release/next_tag to the number being shipped,
# bump the build of each platform that ships, verify the iOS App Store record
# before changing ios_app_version/ios_build, publish published_* to the new
# tag, then run: python3 -I scripts/dev/versions.py docs
#
# Candidate numbers: 0.7.1 for stabilization, 0.8.0 for composition.
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

- [ ] **Step 2: Write the failing tests in `scripts/dev/versions_test.py`**

Use the style of `scripts/docs/check_site_facts_test.py`: unittest, a temporary
tree, `write()` helper, `sys.path.insert(0, str(HERE))`, `import versions`.

Tests (names exact):

- `test_manifest_parses_flat_keys` — a temp manifest with `next_release: "0.8.0"`
  yields `{"next_release": "0.8.0"}` from `parse_flat_yaml`.
- `test_docs_projection_uses_published_values` — manifest with
  `published_release: "0.7.0"`, `published_tag: "v0.7.0"`, engine `9.0`/`r4433`
  projects to `macos_app_version == "0.7"`, `windows_app_version == "0.7"`,
  `release_tag == "v0.7.0"`, `engine_version == "9.0"`,
  `release_base_url == "https://github.com/mthomason/MAD/releases/download/v0.7.0"`.
- `test_check_reports_engine_mismatch` — a temp repo whose `MADMeta.plist` says
  `9.1` while the manifest says `9.0` returns a problem containing
  `MADMeta.plist`.
- `test_check_reports_docs_drift` — `docs/_data/versions.yml` with
  `release_tag: "v0.9.0"` returns a problem containing `docs/_data/versions.yml`.
- `test_check_reports_stale_windows_default` — `Windows/package.ps1` containing
  `[string]$Version = "0.7"` returns a problem containing `package.ps1`.
- `test_check_passes_on_agreement` — a complete temp tree returns `[]`.

- [ ] **Step 3: Run the tests to verify they fail**

Run: `python3 -I scripts/dev/versions_test.py`
Expected: FAIL (`ModuleNotFoundError: No module named 'versions'`).

- [ ] **Step 4: Implement `scripts/dev/versions.py`**

Stdlib only (`argparse`, `os`, `plistlib`, `re`, `sys`). Functions:

- `parse_flat_yaml(path)` — same algorithm as `check_site_facts.parse_flat_yaml`.
- `MANIFEST_KEYS` — the 17 keys in the file above.
- `load_manifest(repo_root)` — parse `Versions.yml`; missing keys raise
  `SystemExit` listing them.
- `_short_release(value)` — `"0.7.0"` → `"0.7"`.
- `docs_projection(manifest)` — returns exactly:
  `engine_version`, `engine_revision`, `macos_app_version`,
  `windows_app_version`, `ios_app_status` (`"between releases; returns early 2027"`),
  `release_tag`, `release_base_url`, leaving the count keys to the caller.
- `_replace_flat_values(path, prefix_comment, values)` — rewrites only the keys
  in `values`, preserving other lines and comments (used by `docs`).
- `check(repo_root)` — append a problem string for each of:
  - the manifest keys are complete;
  - `docs/_data/versions.yml` projection keys match (skip if the file is absent);
  - `MADDesigner/Resources/Assets/MADMeta.plist`
    `CFBundleShortVersionString`/`MADRevision` match `engine_version`/`engine_revision`;
  - `MAD/Source/MADConstants.m` has `MADFileFormatMajorVersion = <container_major>`
    and `MADFileFormatMinorVersion = <container_minor>`;
  - `MAD/Source/rptq/store/MADStoreSchema.m` has
    `MADStoreCurrentVersion = <store_revision>`;
  - `Windows/package.ps1` contains no `$Version = "` literal default (Task 7
    removes it) and mentions `Versions.yml`;
  - `Windows/App/Mad.Designer.Windows/Infrastructure/AppInfo.cs` contains no
    `const string Version = "v` (Task 7 removes it);
  - every `releases/download/vX.Y.Z` in `README.md`, `Mac/README*.md`,
    `translations/README*.md`, and `docs/**/*.md` equals `published_tag`;
  - every `MAD-Designer-Windows-X.Y(.Z).zip` in those files resolves to
    `published_release` (`0.7` or `0.7.0`).
- `main()` — `check` prints one `problem` per line and exits 1 when any;
  `docs` rewrites `docs/_data/versions.yml` and prints the path; `read KEY`
  prints the value.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `python3 -I scripts/dev/versions_test.py`
Expected: `OK`.

Run: `python3 -I scripts/dev/versions.py check`
Expected: exit 0 (the Windows checks will fail until Task 7; if so, keep
Task 7's two checks pending and note it in the commit, then finish them there).

- [ ] **Step 6: Regenerate the docs projection**

Run: `python3 -I scripts/dev/versions.py docs`
Expected: `docs/_data/versions.yml` unchanged except formatting (published
values already match).

- [ ] **Step 7: Wire the tests into CI**

Add to `.github/workflows/docs.yml` after the existing checker tests:

```yaml
          python3 -I scripts/dev/versions_test.py
```

and after “Check facts and leaks”:

```yaml
      - name: Check the version manifest
        run: python3 -I scripts/dev/versions.py check
```

- [ ] **Step 8: Commit**

```bash
git add Versions.yml scripts/dev/versions.py scripts/dev/versions_test.py \
        docs/_data/versions.yml .github/workflows/docs.yml \
        docs/superpowers/specs/2026-11-23-versioning-and-build-identity-design.md \
        docs/superpowers/plans/2026-11-23-versioning-and-build-identity.md
git commit -s -m "chore: add the version manifest and its checker"
```

---

### Task 2: Build identity generator

**Files:**
- Create: `scripts/dev/build-info.sh`
- Create: `scripts/dev/build_info_test.py`

**Interfaces:**
- Produces: `build-info.sh --output PATH --format plist|json [--app-version V]
  [--app-build N] [--manifest PATH]`.
- Emitted keys: `MADAppVersion`, `MADAppBuild`, `MADEngineVersion`,
  `MADEngineRevision`, `MADSourceCommit`, `MADSourceCommitShort`,
  `MADSourceDirty`, `MADBuildDate`, `MADServeProtocolVersion`,
  `MADContainerFormat`, `MADStoreRevision`.

- [ ] **Step 1: Write the failing tests in `scripts/dev/build_info_test.py`**

unittest; invoke the script with `subprocess.run`, a temp manifest, and a temp
git repository (`git init`, one commit, `git -c user.email=... commit`).

- `test_plist_contains_identity_from_manifest` — write manifest with
  `macos_app_version: "0.8.0"`, run with `--app-version 0.8.0 --app-build 7
  --format plist`, load with `plistlib`; assert `MADAppVersion == "0.8.0"`,
  `MADAppBuild == "7"`, `MADEngineVersion == "9.0"`, `MADEngineRevision ==
  "r4433"`, `MADContainerFormat == "1.0"`, `MADStoreRevision == "2"`,
  `MADServeProtocolVersion == "1"`, and `len(MADSourceCommit) == 40`.
- `test_json_matches_plist_fields` — same manifest, `--format json`; assert the
  JSON object has the same keys and values.
- `test_dirty_tree_is_marked` — after the commit, write an untracked file; assert
  `MADSourceDirty is True`.
- `test_outside_git_reports_unknown` — a temp dir that is not a repository;
  assert `MADSourceCommit == "unknown"`, `MADSourceCommitShort == "unknown"`,
  `MADSourceDirty is False`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -I scripts/dev/build_info_test.py`
Expected: FAIL (script missing).

- [ ] **Step 3: Implement `scripts/dev/build-info.sh`**

POSIX `bash`, `set -euo pipefail`, tabs. Parse the manifest with
`awk -F': *' '$1==k {gsub(/"/,"",$2); print $2; exit}'`. Look for `Versions.yml`
at `$(git rev-parse --show-toplevel 2>/dev/null || pwd)/Versions.yml` unless
`--manifest` is given. Read `git rev-parse HEAD`, `git status --porcelain`;
on any git failure use `unknown`/`unknown`/`false`. `MADBuildDate` is
`date -u +%Y-%m-%dT%H:%M:%SZ`. Write `.tmp.$$` then `mv` to the output path.

`--format plist` emits an XML plist 1.0 dictionary with strings for every key
and `<true/>`/`<false/>` for `MADSourceDirty`. `--format json` emits a compact
object with `"MADSourceDirty": true/false`.

Values that require XML escaping: none in the fixed set (commit hex, versions,
dates, true/false); if `unknown` is used it needs no escaping.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -I scripts/dev/build_info_test.py`
Expected: `OK`.

- [ ] **Step 5: Spot-check both formats on this checkout**

```bash
./scripts/dev/build-info.sh --output /tmp/identity.plist --format plist \
  --app-version "$(python3 -I scripts/dev/versions.py read macos_app_version)" \
  --app-build "$(python3 -I scripts/dev/versions.py read macos_build)"
./scripts/dev/build-info.sh --output /tmp/identity.json --format json
plutil -p /tmp/identity.plist; cat /tmp/identity.json
```

Expected: the same fields in both; `MADSourceCommit` is this branch's HEAD.

- [ ] **Step 6: Wire the test into CI**

Add `python3 -I scripts/dev/build_info_test.py` beside the versions test in
`.github/workflows/docs.yml`.

- [ ] **Step 7: Commit**

```bash
git add scripts/dev/build-info.sh scripts/dev/build_info_test.py .github/workflows/docs.yml
git commit -s -m "chore: generate build identity from the manifest and git"
```

---

### Task 3: Reject a newer store before any write

**Files:**
- Modify: `MAD/Source/rptq/store/MADStore.h:36-42`
- Modify: `MAD/Source/rptq/store/MADStore.m:77-125`
- Test: `MAD/MADTests/MADStoreMigrationTests.m` (append one test)

**Interfaces:**
- Produces: `MADStoreErrorUnsupportedVersion` in `MADStoreErrorCode`.
- Consumes: existing helpers `SQLiteExecute(NSURL *, NSString *)`,
  `SQLiteUserVersion(NSURL *)`, and the temp-URL helper in that test file.

- [ ] **Step 1: Write the failing test**

Append to `MADStoreMigrationTests.m`:

```objc
- (void)testAStoreFromANewerBuildIsRefusedBeforeAnyWrite {
	NSURL *url = [self temporaryStoreURL];
	XCTAssertTrue(SQLiteExecute(url, [NSString stringWithFormat:
		@"%@ PRAGMA user_version = %ld;", MADVersionOneSchemaSQL,
		(long)(MADStoreCurrentVersion + 1)]));

	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertFalse([store openWithError:&error]);
	XCTAssertEqualObjects(error.domain, MADStoreErrorDomain);
	XCTAssertEqual(error.code, MADStoreErrorUnsupportedVersion);

	// Nothing was created, migrated, or versioned by the failed open.
	XCTAssertEqual(SQLiteUserVersion(url), MADStoreCurrentVersion + 1);
	XCTAssertFalse(SQLiteExecute(url, @"CREATE TABLE probe (x);"));
	XCTAssertTrue([self tableNamed:@"RptqDocument" existsAtURL:url]);
}
```

(Use the file's existing temp-URL / table-inspection helpers; add a private
`-tableNamed:existsAtURL:` if none exists. Do not create a new test file.)

- [ ] **Step 2: Run the test to verify it fails**

Run the MAD suite with the simulator id from
`xcrun simctl list devices available`:

```bash
xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
  -destination 'platform=iOS Simulator,id=<device-udid>' \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-shared \
  -only-testing:MADTests/MADStoreMigrationTests
```

Expected: FAIL (`MADStoreErrorUnsupportedVersion` undeclared, or open returns YES).

- [ ] **Step 3: Add the error code**

In `MADStore.h`:

```objc
	MADStoreErrorUnwritableAttribute,
	MADStoreErrorUnsupportedVersion,
```

- [ ] **Step 4: Gate the open**

In `MADStore.m`, inside `-openWithError:` after `self.database = database;` and
**before** the `PRAGMA journal_mode` line:

```objc
	// A store written by a newer build must be refused before the journal mode,
	// schema creation, or migration writes anything.  Version 0 is an unversioned
	// store and means version 1 (see -migrateIfNeededWithError:).
	NSInteger storedVersion = [self readUserVersionWithError:error];
	if (storedVersion < 0) { [self close]; return NO; }
	if (storedVersion == 0) storedVersion = 1;
	if (storedVersion > MADStoreCurrentVersion) {
		if (error) {
			*error = MADStoreError(MADStoreErrorUnsupportedVersion,
				[[NSString alloc] initWithFormat:
					@"This document was written by a newer version of MAD Designer "
					@"(store revision %ld). Upgrade MAD Designer to open it.",
					(long)storedVersion]);
		}
		[self close];
		return NO;
	}
```

`readUserVersionWithError:` is already declared below in the same @implementation;
move its declaration above `-openWithError:` only if the compiler requires it
(it is an instance method on the same class, so it does not).

- [ ] **Step 5: Run the test to verify it passes**

Run the command from Step 2. Expected: `MADStoreMigrationTests` passes,
including the four existing versioning tests.

- [ ] **Step 6: Commit**

```bash
git add MAD/Source/rptq/store/MADStore.h MAD/Source/rptq/store/MADStore.m \
        MAD/MADTests/MADStoreMigrationTests.m
git commit -s -m "fix(store): refuse a newer store revision before any write"
```

---

### Task 4: Container header validation in the app and the CLI

**Files:**
- Modify: `MAD/Source/MADConstants.h:22-25`
- Modify: `MAD/Source/MADConstants.m:15-17`
- Modify: `MAD/Source/MADArchiveManager.h`
- Modify: `MAD/Source/MADArchiveManager.m:332-370`
- Modify: `MAD/Source/MADocument.m:463`
- Modify: `MAD/Source/MADHeadlessDocument.m:211`
- Modify: `MADDesigner/Source/MADStoreLegacy/MADStoreConverter.m:295`
- Modify: `CLI/Source/MADCLIContainer.m:95-120`
- Test: `MAD/MADTests/MADDocumentTests.m` (append three tests)

**Interfaces:**
- Produces:
  - `FOUNDATION_EXPORT NSString * const MADFileFormatErrorDomain;`
  - `FOUNDATION_EXPORT BOOL MADFileFormatHeaderIsSupported(const uint8_t *bytes,
    NSUInteger length, NSError * __autoreleasing *error);`
  - `- (BOOL)unarchiveWithError:(NSError * __autoreleasing *)error;`
    (the existing `-unarchive` delegates to it).

- [ ] **Step 1: Write the failing tests**

Append to `MADDocumentTests.m`:

```objc
- (void)testContainerHeaderAcceptsVersionOneZero {
	NSError *error = nil;
	uint8_t header[16] = { 'M','A','D','F','I','L','E',0, 1,0, 0,0, 0,0,0,0 };
	XCTAssertTrue(MADFileFormatHeaderIsSupported(header, sizeof(header), &error));
	XCTAssertNil(error);
}

- (void)testContainerHeaderRefusesANewerMajor {
	NSError *error = nil;
	uint8_t header[16] = { 'M','A','D','F','I','L','E',0, 2,0, 0,0, 0,0,0,0 };
	XCTAssertFalse(MADFileFormatHeaderIsSupported(header, sizeof(header), &error));
	XCTAssertEqualObjects(error.domain, MADFileFormatErrorDomain);
	XCTAssertTrue([error.localizedDescription containsString:@"Upgrade"]);
}

- (void)testContainerHeaderRefusesANewerMinor {
	NSError *error = nil;
	uint8_t header[16] = { 'M','A','D','F','I','L','E',0, 1,0, 1,0, 0,0,0,0 };
	XCTAssertFalse(MADFileFormatHeaderIsSupported(header, sizeof(header), &error));
	XCTAssertEqualObjects(error.domain, MADFileFormatErrorDomain);
}

- (void)testContainerHeaderTreatsNoMagicAsLegacy {
	uint8_t bytes[16] = { 0 };
	XCTAssertTrue(MADFileFormatHeaderIsSupported(bytes, sizeof(bytes), NULL));
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the MAD suite with `-only-testing:MADTests/MADDocumentTests`.
Expected: FAIL (function undeclared).

- [ ] **Step 3: Implement the validator**

In `MADConstants.h`, beside the constants:

```objc
FOUNDATION_EXPORT NSString * const MADFileFormatErrorDomain;

/// YES for a v0 document (no magic), the current 1.0 header, and any 1.x with
/// x <= the current minor.  A newer major or minor fills `error` with an
/// upgrade message.  The header is 16 bytes: 8 magic, two little-endian
/// version words, four flag bytes.
FOUNDATION_EXPORT BOOL MADFileFormatHeaderIsSupported(const uint8_t *bytes,
													  NSUInteger length,
													  NSError * __autoreleasing *error);
```

In `MADConstants.m`:

```objc
NSString * const MADFileFormatErrorDomain = @"MADFileFormatErrorDomain";

BOOL MADFileFormatHeaderIsSupported(const uint8_t *bytes, NSUInteger length,
									NSError * __autoreleasing *error) {
	if (length < MADFileFormatHeaderLength) return YES;	// a v0 body
	if (memcmp(bytes, MADFileFormatMagic, 8) != 0) return YES;	// v0, no header
	uint16_t major = (uint16_t)(bytes[8] | (bytes[9] << 8));
	uint16_t minor = (uint16_t)(bytes[10] | (bytes[11] << 8));
	if (major < MADFileFormatMajorVersion ||
		(major == MADFileFormatMajorVersion && minor <= MADFileFormatMinorVersion)) {
		return YES;
	}
	if (error) {
		*error = [NSError errorWithDomain: MADFileFormatErrorDomain code: 1
								 userInfo: @{ NSLocalizedDescriptionKey:
			[[NSString alloc] initWithFormat:
				@"This document was written by a newer version of MAD Designer "
				@"(format %u.%u). Upgrade MAD Designer to open it.", major, minor] }];
	}
	return NO;
}
```

Include `<string.h>` if `memcmp` is not already available; `MADConstants.m`
currently has no imports beyond Foundation — add `#import <string.h>`.

- [ ] **Step 4: Route the app reader through it**

In `MADArchiveManager.h` add:

```objc
/// Like -unarchive, but reports why an unsupported container was refused.
- (BOOL)unarchiveWithError:(NSError * __autoreleasing *)error;
```

In `MADArchiveManager.m`, make `-unarchive` call `-unarchiveWithError:NULL`. In
`-strippedArchiveURL`, before stripping:

```objc
	if (!MADFileFormatHeaderIsSupported(data.bytes, data.length, NULL)) return nil;
```

and add a sibling `- (BOOL)validateHeaderWithError:(NSError **)error` that reads
the first 16 bytes and calls `MADFileFormatHeaderIsSupported`; call it at the top
of `-unarchiveWithError:` and return NO before extraction on failure.

Update the three callers (`MADocument.m:463`, `MADHeadlessDocument.m:211`,
`MADStoreConverter.m:295`) to use `-unarchiveWithError:` and propagate the error
where they already carry one; `MADocument`/`MADHeadlessDocument` log the message.

- [ ] **Step 5: Route the CLI through it**

In `MADCLIContainer.m`, replace the magic branch:

```objc
	if (memcmp(bytes, MADCLIMagic, sizeof(MADCLIMagic)) == 0) {
		NSError *formatError = nil;
		if (!MADFileFormatHeaderIsSupported(bytes, header.length, &formatError)) {
			if (error) *error = MADCLIContainerError(MADCLIExitBadDocument,
													 formatError.localizedDescription);
			return nil;
		}
		container.formatVersion = (MADCLIFormatVersion)MADCLIReadUInt16LE(bytes + 8);
		container.formatFlags = MADCLIReadUInt32LE(bytes + 12);
	} else {
		container.formatVersion = MADCLIFormatVersion0;
		container.formatFlags = 0;
	}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run the MAD suite `-only-testing:MADTests/MADDocumentTests`.
Expected: PASS.

Build the CLI to prove the shared header compiles there:

```bash
./CLI/build.sh
```

Expected: exit 0.

- [ ] **Step 7: Commit**

```bash
git add MAD/Source/MADConstants.h MAD/Source/MADConstants.m \
        MAD/Source/MADArchiveManager.h MAD/Source/MADArchiveManager.m \
        MAD/Source/MADocument.m MAD/Source/MADHeadlessDocument.m \
        MADDesigner/Source/MADStoreLegacy/MADStoreConverter.m \
        CLI/Source/MADCLIContainer.m MAD/MADTests/MADDocumentTests.m
git commit -s -m "fix(container): validate the .mad header before extracting"
```

---

### Task 5: `engine-info`, `mad version`, and identity placement

**Files:**
- Modify: `CLI/Source/MADCLI.h`
- Modify: `CLI/Source/MADCLI.m`
- Modify: `CLI/Source/main.m:28-39`
- Modify: `CLI/Source/MADCLIServe.m:111-146, 2188-2270`
- Modify: `CLI/build.sh`
- Test: `Windows/Client/Mad.Client.Tests/MadEngineClientTests.cs`

**Interfaces:**
- Produces:
  - `FOUNDATION_EXPORT NSDictionary * MADCLIBuildInfo(void);` — reads
    `MADBuildInfo.plist` from the executable's directory; `nil` if absent.
  - `int MADCLIRunVersion(MADCLIInvocation *invocation);`
  - serve method `"engine-info"` returning the fields in the design §6.4.

- [ ] **Step 1: Write the failing .NET test**

In `MadEngineClientTests.cs` add a test that starts the built engine and asks
for `engine-info`, skipping when the engine is not built (follow the file's
existing skip helper):

```csharp
[Fact]
public void EngineInfo_ReportsAProtocolVersionAndCapabilities()
{
	using var client = StartEngineOrSkip();
	var info = client.EngineInfo();
	Assert.Equal(1, info.ProtocolVersion);
	Assert.False(string.IsNullOrEmpty(info.EngineVersion));
	Assert.Contains("engine-info", info.Capabilities);
}
```

Add the typed call and `EngineInfo` record to `MadEngineClient`:

```csharp
public sealed record EngineInfo(int ProtocolVersion, string? EngineVersion,
	string? EngineRevision, string? SourceCommit, string? SourceCommitShort,
	bool? SourceDirty, IReadOnlyList<string> Capabilities);

public EngineInfo EngineInfo()
{
	var result = Call("engine-info", new Dictionary<string, object?>()).EnsureOk().Result;
	...
}
```

Read `protocolVersion`, `engineVersion`, `engineRevision`, `sourceCommit`,
`sourceCommitShort`, `sourceDirty`, and the `capabilities` array, tolerating
`null` for every field and a missing `capabilities` member.

- [ ] **Step 2: Run the test to verify it fails**

Run (on Windows, or document that it cannot run on this host):

```powershell
dotnet test Windows/Client/Mad.Client.Tests --filter EngineInfo
```

Expected: FAIL (unknown method `engine-info`).

- [ ] **Step 3: Implement the identity reader and the command**

In `MADCLI.m` (already in every CLI source list):

- `MADCLIBuildInfo(void)` — resolve the executable's directory from
  `[[NSBundle mainBundle] executablePath]`, falling back to
  `/proc/self/exe` on non-Apple or `argv[0]` stored in a static by `main`.
  Return `[NSDictionary dictionaryWithContentsOfURL:.../MADBuildInfo.plist]`.
- `MADCLIRunVersion(MADCLIInvocation *)` — build the dictionary in the design's
  §6.4 shape. Missing file → every identity field `NSNull`; `protocolVersion`
  from `MADServeProtocolVersion` in the file or `0`; `capabilities` is the fixed
  list: `open, describe, query, refresh, export, write, query-model, layout-model,
  sql-entry, engine-info`. With `--json` (check `invocation.options[@"json"]`),
  print one compact JSON object and a newline; otherwise print
  `MAD Designer engine <version> (<revision>) commit <short>` plus
  `local build` when dirty.

Declare both in `MADCLI.h`.

In `main.m`, add `version` to the dispatch before `help`:

```objc
		if ([invocation.command isEqualToString: @"version"])	return MADCLIRunVersion(invocation);
```

- [ ] **Step 4: Add the serve method**

In `MADCLIServe.m`, add `MADCLIServeMethodEngineInfo = @"engine-info"`; add a
`MADCLIServeEngineInfo(id requestID)` that reuses the same dictionary as
`mad version`; dispatch it before `open` (it needs no document).

- [ ] **Step 5: Place the identity file beside `mad`**

In `CLI/build.sh`, after the CLI is linked, run:

```bash
"${REPO_ROOT}/scripts/dev/build-info.sh" --format plist \
	--output "${BUILD_DIR}/MADBuildInfo.plist" \
	--app-version "$(python3 -I "${REPO_ROOT}/scripts/dev/versions.py" read macos_app_version)" \
	--app-build "$(python3 -I "${REPO_ROOT}/scripts/dev/versions.py" read macos_build)"
```

Where `BUILD_DIR` is the script's own output directory (use its existing
variable). `MADCLIBuildInfo` looks beside the executable, which is in that
directory.

- [ ] **Step 6: Verify on this host**

```bash
./CLI/build.sh
./<cli-output>/mad version --json
printf '%s\n' '{"id":1,"method":"engine-info"}' '{"id":2,"method":"shutdown"}' | ./<cli-output>/mad serve
```

Expected: the JSON object with `protocolVersion: 1` and a 40-hex
`sourceCommit`; the serve response mirrors it.

- [ ] **Step 7: Commit**

```bash
git add CLI/Source/MADCLI.h CLI/Source/MADCLI.m CLI/Source/main.m \
        CLI/Source/MADCLIServe.m CLI/build.sh \
        Windows/Client/Mad.Client/MadEngineClient.cs \
        Windows/Client/Mad.Client.Tests/MadEngineClientTests.cs
git commit -s -m "feat(cli): report engine identity and add engine-info to serve"
```

---

### Task 6: Apple build integration and About surfaces

**Files:**
- Modify: `Mac/build.sh:85-95, 150-170`
- Modify: `MADDesigner/buildcounter.sh` (rewrite)
- Modify: `MADDesigner/Resources/Assets/MADMeta.plist`
- Modify: `Mac/Source/MADMacAboutWindowController.m:116-135, 581-600`
- Modify: `MADDesigner/Source/AppDelegate.m:80-103`
- Modify: `MADDesigner/Source/MADAboutTableViewController.m:219-276`
- Test: `MADDesigner/Targets/MADDesignerUnitTests/MADDesignerUnitTests.m`

**Interfaces:**
- Produces: `+ (NSDictionary *)buildInfoForBundle:(nullable NSBundle *)bundle`
  on `AppDelegate`; `MADMacAboutWindowController` uses the same file directly.
- Consumes: `MADBuildInfo.plist` keys from Task 2.

- [ ] **Step 1: Write the failing app test**

Append to `MADDesignerUnitTests.m`:

```objc
- (void)testBuildInfoIsUnknownWhenTheFileIsAbsent {
	NSBundle *bundle = [NSBundle bundleForClass: [self class]];
	XCTAssertNil([AppDelegate buildInfoForBundle: bundle]);
}

- (void)testBuildInfoReadsTheBundledPlist {
	// The app target runs the generated MADBuildInfo.plist phase; if this build
	// has none, the first test pins the fallback and this one is skipped.
	NSDictionary *info = [AppDelegate buildInfoForBundle: nil];
	if (info == nil) {
		XCTSkip(@"MADBuildInfo.plist is not in this build");
	}
	XCTAssertNotNil(info[@"MADSourceCommitShort"]);
	XCTAssertNotNil(info[@"MADAppVersion"]);
}
```

- [ ] **Step 2: Run it to verify it fails**

Run:

```bash
xcodebuild test -workspace Reports.xcworkspace -scheme "MAD Designer" \
  -only-testing:MADDesignerUnitTests \
  -destination 'platform=iOS Simulator,id=<device-udid>' \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-shared
```

Expected: FAIL (`buildInfoForBundle:` undeclared).

- [ ] **Step 3: Add the bundle reader**

In `AppDelegate.m`:

```objc
/// The generated per-build identity (MADBuildInfo.plist), or nil when this
/// build did not produce one.  Never rewrites a tracked plist.
+ (NSDictionary *)buildInfoForBundle:(nullable NSBundle *)bundle {
	NSBundle *resolved = bundle ?: [NSBundle mainBundle];
	NSString *path = [resolved pathForResource: @"MADBuildInfo" ofType: @"plist"];
	return path ? [NSDictionary dictionaryWithContentsOfFile: path] : nil;
}
```

Declare it in `AppDelegate.h` beside the other `+` helpers.

Update `MADAboutTableViewController` to show the engine line as
`v<engine> (<revision>) · <short commit>` and append `· local build` when
`MADSourceDirty` is true; add the application version/build line from the same
dictionary. Use `unknown` for missing values.

- [ ] **Step 4: Update the macOS About**

In `MADMacAboutWindowController`, read `MADBuildInfo.plist` from `_resourceBundle`
first; fall back to `MADMeta.plist` and the bundle Info.plist. Keep
`versionTextForBundle:`/`buildTextForBundle:` names and add
`+ (NSString *)commitTextForBundle:` returning `unknown` when missing.
Compose the engine label as `v9.0 (r4433) · abc12345` plus `· local build`
when dirty; compose the application label as `v0.7.1 (4433)`.

- [ ] **Step 5: Generate the file in both Apple builds**

`Mac/build.sh`: after the Info.plist sed step, inject the built plist's version
and build with `PlistBuddy`, and run:

```bash
"${REPO_ROOT}/scripts/dev/build-info.sh" --format plist \
	--output "${RESOURCES_DIR}/MADBuildInfo.plist" \
	--app-version "$("${REPO_ROOT}/scripts/dev/build-info.sh" ... )"
```

(Use `python3 -I scripts/dev/versions.py read macos_app_version` and
`read macos_build` as in Task 5.)

Rewrite `MADDesigner/buildcounter.sh` so it:

- exits 0 immediately when `TARGET_BUILD_DIR` or
  `UNLOCALIZED_RESOURCES_FOLDER_PATH` is unset (standalone runs);
- selects `ios_app_version`/`ios_build` from `Versions.yml`;
- writes `${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/MADBuildInfo.plist`
  via `scripts/dev/build-info.sh`;
- never reads or writes `Resources/Info.plist` or `Assets/MADMeta.plist`.

Reduce `MADMeta.plist` to `CFBundleShortVersionString` (`9.0`),
`CFBundleVersion` (`4433`), `MADRevision` (`r4433`), and the identifier/name keys.
Remove `MADBuildDate`, `MADBuildNumber`, `MADGitBranch`, `MADGitCommitCount`,
`MADGitCommitHash`, `MADGitDescribe`, `MADGitDirty`, `MADVersionFromTag`, and
`MADTrademark` only if nothing reads them — grep first; `AppDelegate` still
reads `MADGitCommitCount` only through the now-removed About fallback, so remove
that accessor too.

- [ ] **Step 6: Run the test and the Mac build**

Run the app suite from Step 2, then:

```bash
./Mac/build.sh --no-frameworks
plutil -p "Mac/build/MAD Designer.app/Contents/Resources/MADBuildInfo.plist"
```

Expected: PASS; the plist carries this checkout's commit.

- [ ] **Step 7: Commit**

```bash
git add Mac/build.sh Mac/Source/MADMacAboutWindowController.m \
        MADDesigner/buildcounter.sh MADDesigner/Resources/Assets/MADMeta.plist \
        MADDesigner/Source/AppDelegate.h MADDesigner/Source/AppDelegate.m \
        MADDesigner/Source/MADAboutTableViewController.m \
        MADDesigner/Targets/MADDesignerUnitTests/MADDesignerUnitTests.m
git commit -s -m "feat(app): report the exact build identity in About"
```

---

### Task 7: Windows identity, About, and package verification

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/Infrastructure/BuildInfo.cs`
- Modify: `Windows/App/Mad.Designer.Windows/Infrastructure/AppInfo.cs`
- Modify: `Windows/App/Mad.Designer.Windows/ViewModels/AboutViewModel.cs`
- Modify: `Windows/App/Mad.Designer.Windows/MainWindow.xaml.cs:39`
- Modify: `Windows/App/Mad.Designer.Windows/Engine/EngineService.cs`
- Modify: `Windows/App/Mad.Designer.Windows.Tests/AboutViewModelTests.cs`
- Modify: `Windows/package.ps1:38-45, 150-200`
- Modify: `Windows/Engine/build.ps1` (after linking `mad.exe`)

**Interfaces:**
- Consumes: `MadEngineClient.EngineInfo()` from Task 5.
- Produces: `BuildInfo.Load()` returning a record with `AppVersion`,
  `AppBuild`, `SourceCommit`, `SourceCommitShort`, `SourceDirty`, `EngineVersion`,
  `EngineRevision` (all nullable); `AboutViewModel.AccountFor(...)` or a
  constructor accepting the two records.

- [ ] **Step 1: Write the failing .NET tests**

Replace the hardcoded assertions in `AboutViewModelTests.cs`:

```csharp
[Fact]
public void About_ShowsUnknownWhenTheEngineDoesNotAnswer()
{
	var about = new AboutViewModel(BuildInfo.Missing, engine: null);
	Assert.Equal("unknown", about.EngineVersion);
	Assert.Equal("unknown", about.ApplicationVersion);
}

[Fact]
public void About_UsesTheEngineIdentityItWasGiven()
{
	var engine = new EngineInfo(1, "9.0", "r4433", "abc", "abc", false,
		new[] { "engine-info" });
	var build = new BuildInfo("0.7.1", "4433", "abc", "abc", false, null, null);
	var about = new AboutViewModel(build, engine);
	Assert.Contains("r4433", about.EngineVersion);
	Assert.Contains("0.7.1", about.ApplicationVersion);
}
```

- [ ] **Step 2: Run to verify failure**

```powershell
dotnet test Windows/App/Mad.Designer.Windows.Tests --filter About
```

Expected: FAIL (constructors missing).

- [ ] **Step 3: Implement `BuildInfo.cs`**

Static `Load()` reads `MADBuildInfo.json` from `AppContext.BaseDirectory`,
returns `Missing` on any error, and exposes nullable strings parsed with
`JsonDocument`. No exceptions escape.

- [ ] **Step 4: Wire the About**

`AppInfo.Version` becomes `BuildInfo.Load().AppVersion ?? "unknown"` (remove the
`const`). `AboutViewModel` takes `(BuildInfo build, EngineInfo? engine)` and
formats:

- `ApplicationVersion`: `v<version> (<build>) · <short>`, appending ` · local build`
  when dirty, or `unknown`.
- `EngineVersion`: `v<version> (<revision>) · <short>` from the engine record,
  or `unknown` when the engine did not answer.

`MainWindow.xaml.cs` starts the engine (existing path), calls
`EngineService.EngineInfoAsync()` inside a try/catch, and constructs the
`AboutViewModel`; a failure passes `null`. Guard against a slow engine by
showing the window after the call completes or immediately with `unknown` and
filling later — pick the simpler path and keep the window responsive.

- [ ] **Step 5: Generate and verify package metadata**

`Windows/package.ps1`:

- remove the `$Version = "0.7"` / `$EngineVersion = "9.0 (r4433)"` defaults;
- read `Versions.yml` with a small `Get-ManifestValue` function;
- default `$Version` to `windows_app_version`, `$EngineVersion` to
  `"<engine_version> (<engine_revision>)"`;
- pass `-p:Version=$Version` to `dotnet publish` so the assembly identity agrees;
- write `MADBuildInfo.json` into the publish directory (the same keys as
  `build-info.sh`) before zipping;
- after assembling `Windows/Engine/build`, run `mad.exe version --json`, parse
  it, and throw if `engineVersion`, `engineRevision`, or `sourceCommit` disagrees
  with the manifest/HEAD. This is the "verify the package against the engine it
  actually bundles" check.

`Windows/Engine/build.ps1` writes `MADBuildInfo.plist` beside `mad.exe` after
the link step, using the same manifest values.

- [ ] **Step 6: Run the tests on Windows**

```powershell
dotnet test Windows/App/Mad.Designer.Windows.Tests
pwsh -File .\Windows\package.ps1
```

Expected: tests pass; packaging reports the manifest versions and the bundled
engine identity matches.

- [ ] **Step 7: Commit**

```bash
git add Windows/App Windows/package.ps1 Windows/Engine/build.ps1
git commit -s -m "feat(windows): read the real engine identity and verify the package"
```

---

### Task 8: Documentation, registers, and full verification

**Files:**
- Modify: `CONTRIBUTING.md` (add the version manifest and release checklist pointer)
- Modify: `README.md` (only if the build notes need the checker command)
- Modify: `docs/project/registers/BUGS.md` / `BUGS_FIXED.md` (record the store and
  container defects fixed)
- Modify: `docs/project/registers/TASKS.md` (re-status this work)
- Modify: root `CLAUDE.md` if the manifest or scripts belong in Related Documents

- [ ] **Step 1: Document the workflow**

Add to `CONTRIBUTING.md`: `Versions.yml` is the source of truth; run
`python3 -I scripts/dev/versions.py check` before a release PR; run
`python3 -I scripts/dev/versions.py docs` after changing a published version;
build products carry `MADBuildInfo` and tracked plists are never rewritten.

- [ ] **Step 2: Record the defects**

Move the store-version and container-version entries (if present in
`docs/project/registers/BUGS.md`) to `BUGS_FIXED.md` with their `Now:` lines and the
commit hashes, leaving one-line index entries. If no such entry exists, add a
fixed entry describing the new behavior and the tests that pin it. Do not touch
`TODO.md`.

- [ ] **Step 3: Run the focused checks**

```bash
python3 -I scripts/dev/versions_test.py
python3 -I scripts/dev/build_info_test.py
python3 -I scripts/dev/versions.py check
python3 -I scripts/docs/check_site_facts_test.py
python3 -I scripts/docs/check_site_facts.py --docs docs --repo .
python3 -I scripts/dev/check_source_lists_test.py
python3 -I scripts/dev/check_source_lists.py
```

Expected: all pass.

- [ ] **Step 4: Run the Apple suites the change touches**

```bash
xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
  -destination 'platform=iOS Simulator,id=<device-udid>' \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-shared
xcodebuild test -workspace Reports.xcworkspace -scheme "MAD Designer" \
  -only-testing:MADDesignerUnitTests \
  -destination 'platform=iOS Simulator,id=<device-udid>' \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-shared
./Mac/build.sh --smoke-test
```

Expected: all green.

- [ ] **Step 5: Route the completion claim through `mad-verify`**

Invoke the `mad-verify` skill and follow its routing before claiming the work
complete or opening a PR. The Linux and DCO checks are the PR gates; this pass
adds no headless source files, so the local fast checks above are the source
proof.

- [ ] **Step 6: Report and commit**

Report what changed, what ran on each platform, and every remaining packaging
or compatibility decision (the iOS App Store verification, the Windows
workstation run, and the release-number choice `0.7.1` vs `0.8.0`). Commit:

```bash
git add CONTRIBUTING.md README.md docs/project/registers
git commit -s -m "docs: record the versioning and build-identity workflow"
```
