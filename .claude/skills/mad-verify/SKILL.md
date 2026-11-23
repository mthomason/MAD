---
name: mad-verify
description: Route a MAD change to the cheapest verification that can pass or fail because of it. Use whenever you are about to claim a MAD change is complete, before a commit or pull request, or when asked what to run after editing a framework, the app, docs, localization, a build script, or a headless (Linux/Windows) source file. Covers the fast static checks, single-framework Apple suites, the artifact-vs-source distinction, the headless compile proof, and the PR-only Linux/DCO gates — so the full Linux build is not run after every edit.
---

# Verifying a MAD change

MAD has four verification tiers, and the expensive one is rarely the right one.
Run the cheapest tier that can actually fail because of the change. The full
Linux build is a **PR-time gate**, not an edit-time habit.

## Existing artifacts vs newly compiled source

This distinction catches more wasted work than any other:

| Command | Compiles your edit? |
|---|---|
| `xcodebuild test` / `xcodebuild build` | yes |
| `xcodebuild test-without-building` | no |
| `./Linux/build.sh --test` | **no** — re-runs the binaries in the existing image |
| `./Linux/build.sh` | yes — the Dockerfile does `COPY . /src` at build time |
| `./Mac/build.sh --no-frameworks` | yes (app), no (frameworks) |
| `./Mac/build.sh --smoke-test` | yes (app and smoke test) |
| `CLI/build.sh --no-frameworks` | yes (tool), no (frameworks) |
| `dotnet test Windows/...` | no (engine), yes (.NET app/client) |
| `gh pr checks --watch` | yes (CI) |

`./Linux/build.sh --test` is a re-run of the last image, not a test of the
working tree. An edit reaches the image only through a rebuild — see
`Linux/AGENTS.md` ("`--test` alone re-runs the old binaries").

## Tiers

| Tier | Cost | Use it for |
|---|---|---|
| 0 | seconds | docs, localization, source-list parity |
| 1 | minutes | one Apple framework, the app, or the CLI |
| 2 | minutes | compile one headless target |
| 3 | up to ~1h cold | the PR gate, release packaging, library verification |

### Tier 0 — static checks

```sh
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_site_facts.py --docs docs --repo .
python3 -I scripts/localization/audit.py
python3 -I scripts/localization/sync_catalog.py --check
python3 -I scripts/localization/check_translations.py
python3 -I scripts/dev/check_source_lists.py
```

The docs CI runs `check_translations.py --require-complete`; locally, omit
`--require-complete` while a translation is in progress. The Linux CI runs the
three `scripts/localization/` checks.

### Tier 1 — one Apple target

Pick a simulator by ID, never by a hardcoded UUID or a device name:

```sh
UDID="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ { print $2; exit }')"
test -n "$UDID"
export MAD_DERIVED_DATA="${MAD_DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData/Reports-shared}"
```

The shared `-derivedDataPath` is required: the frameworks reference each other
through `BUILT_PRODUCTS_DIR`.

```sh
# the touched framework's suite (scheme name == framework name)
xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "$MAD_DERIVED_DATA"

# the same framework built for native macOS, no simulator needed
xcodebuild build -workspace Reports.xcworkspace -scheme MADFoundation \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$MAD_DERIVED_DATA"

# the app, or the CLI, against the frameworks already built
./Mac/build.sh --no-frameworks
./CLI/build.sh --no-frameworks
```

`CLI/build.sh` without `--no-frameworks` builds the frameworks with a
name-based destination (`platform=iOS Simulator,name=iPhone 17`). On a machine
without that device, build the frameworks by UDID first (above), then use
`--no-frameworks`.

### Tier 2 — compile one headless target

The fast proof that a headless file compiles, without the full gate:

```sh
docker run --rm -v "$PWD":/repo -v /tmp/mad-build:/build -w /tmp \
  mad-linux:phase-b bash -c \
  'cmake -S /repo/Linux -B /build -DCMAKE_BUILD_TYPE=Debug && \
   cmake --build /build --target <Test> -j"$(nproc)" && /build/<Test>'
```

The target names and the Docker Desktop path fallback are in `Linux/AGENTS.md`
("Conventions and hazards"). For a compile-only proof, build the framework
library target — the lower-case framework name (`madfoundation`, `mad`, …).
Do not conclude that the full build is the only local proof: this bind-mounted
run compiles the changed translation unit in minutes. `./Linux/build.sh --test`
is **not** a substitute: it re-runs the old binaries.

### Tier 3 — PR, release, libraries

```sh
./Linux/build.sh                      # image build + all headless suites
./Linux/build.sh --verify             # runtime image + CLI end to end
./Mac/build.sh --smoke-test --package # macOS app + zip + dmg
./Compressor/build.sh --verify --all --platforms ios,simulator,macosx
```

Windows engine builds are workstation tasks, not routine local checks:

```powershell
pwsh -File .\Windows\Engine\build.ps1          # elevated workstation
dotnet test Windows/App/Mad.Designer.Windows.slnx
dotnet test Windows/Client/Mad.Client.Tests    # against a prebuilt mad.exe
```

Run Tier 3 once before the PR, or when the user asks. Do not run it after every
edit or commit. The first run includes a 15–25 minute toolchain stage; Docker
caches that layer, so a source-only rebuild is shorter than the cold CI figure
of about an hour.

## Route by what changed

| Changed | Run |
|---|---|
| `docs/**`, root `*.md` | Tier 0 docs |
| `*.xcstrings`, `*.strings`, `*.storyboard`, `*.xib` | Tier 0 localization + Tier 1 app |
| `Linux/cmake/*.cmake`, `Windows/Engine/cmake/*.cmake` | Tier 0 parity; Tier 2/3 if a source changed |
| `MAD*/Source/**` named in a source inventory | Tier 1 (that framework) + Tier 2, Tier 3 Linux before the PR |
| `MADDesigner/Source/**`, `Mac/Source/**` (not headless) | Tier 1 app; `./Mac/build.sh --smoke-test` for macOS |
| `Compressor/matrix.conf`, `lib/recipes/**` | library rebuild + `--verify`, then the consuming suite |
| `Windows/**` | Windows .NET tests; engine `build.ps1` on the workstation |

The 12 headless frameworks are listed in `mad-headless-port`. A change to a
file in one of their inventories has a second gate: Linux verification.
`MADExplorer`, `MADFeedback`, the iOS app, and the Mac app are Apple-only.

## PR readiness

- Required checks are **Linux verification** and **DCO** (`AGENTS.md`).
- Every commit needs `Signed-off-by:` — commit with `git commit -s`.
- `macOS verification` and `Windows verification` are advisory today.
- The `docs checks` workflow also runs on PRs that touch docs; it is not in the
  required ruleset, but it is the gate for those edits.
- The PR-template checklist is at `.github/PULL_REQUEST_TEMPLATE.md`:
  failing test first, fixture snapshots, whole suite green, `NEED` reasons,
  SPDX header on new files, unused code marked with the clang attribute, and a
  fixed `BUGS.md` entry moved to `BUGS_FIXED.md`.
- Watch and merge only when the required checks are green:
  `gh pr checks <n> --watch`, then `gh pr merge <n> --rebase --delete-branch`.

## Reference map

- `AGENTS.md` — testing, the PR flow, the approval gate.
- `docs/project/build/DEVELOPER.md` — the command matrix and the test databases.
- `.github/workflows/linux.yml`, `macos.yml`, `windows.yml`, `dco.yml` — what CI actually runs.
- `Linux/AGENTS.md`, `Windows/AGENTS.md`, `Mac/README.md`, `Linux/README.md`, `Windows/README.md`.
- `scripts/dev/check_source_lists.py` — the Linux/Windows inventory parity check.

## Do not

- Run the full Linux build after every edit or commit.
- Treat `./Linux/build.sh --test` as a test of new source.
- Hardcode a simulator UUID, a DerivedData hash, or a home directory.
- Expect a database server: the live suites skip when none is reachable. Use
  `127.0.0.1`, not `localhost`, for the MySQL suite.
