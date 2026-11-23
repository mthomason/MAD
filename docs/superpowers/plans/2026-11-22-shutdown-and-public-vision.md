# Engine Shutdown Timeout and Public Vision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bound the Windows engine shutdown so an unresponsive engine is killed instead of hanging, and replace the public vision's named legacy-product framing with the broader composable-data, embedded-engine, and AI-authored direction in every language.

**Architecture:** The shutdown fix changes one client method and adds a test seam and a stub-process test; normal requests keep their current protocol. The vision work rewrites `docs/vision.md` and the index summary, translates them into the five languages, and adds one translated "The direction" card to the marketing site linking the language-specific vision page.

**Tech Stack:** C#/.NET 10, xUnit, Objective-C/Jekyll/Liquid for the docs site, Jekyll for the marketing site, Python 3 for the existing gates.

**Spec:** `docs/superpowers/specs/2026-11-22-shutdown-and-public-vision-design.md`

**Scope:** Two independent tracks. Track 1 is the Windows client shutdown. Track 2 is the public vision and its localization. Internal records are not rewritten.

## Global Constraints

- **Shutdown budget:** the shutdown response is bounded (5s default); a timeout kills the entire process tree; the caller returns. Do not add a general request timeout.
- **Normal shutdown unchanged:** a responsive engine still exits cleanly with exit code 0.
- **No third-party brand names on the public sites:** `Crystal`, `.rpt`, `SAP`, `Tableau`, `Power BI`, `Qlik`, `Looker`, and any other non-integrated product name are forbidden in `docs/vision.md`, `docs/index.md`, their translations, and the marketing pages.
- **Legacy conversion:** a generic mention of legacy report formats is allowed; no brand names and no replacement product name.
- **Internal records unchanged:** `docs/project/`, the archive, `MAD_FUTURE.md`, `TODO.md`, and engineering plans keep their Crystal Reports references.
- **Five languages:** `de`, `es`, `ja`, `pt-br`, `zh`; the docs translation contract applies. The marketing card links the matching language vision page (`/de/vision.html`, `/es/vision.html`, `/ja/vision.html`, `/pt-br/vision.html`, `/zh/vision.html`, or `/vision.html`).
- **One marketing card:** add a single "The direction" card to the existing "Build on MAD" section; do not add a second vision page.
- **No invented facts:** distinguish shipping capabilities from proposals; no timelines, guarantees, adoption claims, or new version numbers.
- **PR flow:** Reports uses a feature branch, `git commit -s`, DCO, Linux verification, and docs checks; the marketing repository uses a feature branch and PR against `main`.

## Review Focus

1. **A shutdown still hangs** when the response read never completes. Expected: the call returns within the budget and the process tree is gone. Pinned by the stub-process test in Track 1.
2. **A normal shutdown is broken** by the new timeout. Expected: the existing clean-shutdown test and exit code 0. Pinned by `Shutdown_ExitsCleanly_WithNoOrphanProcess`.
3. **One language keeps the Crystal framing** or a brand name. Expected: zero brand matches in every public vision/index. Pinned by the brand grep in Task 11.
4. **The vision overclaims**: a proposed direction reads as shipped. Expected: the current/future distinction is explicit. Pinned by the page's "What exists today" and "What this is not" sections.
5. **A marketing card links the wrong language** or breaks the page set. Expected: every card links its own language's vision; the page set and sitemap are unchanged. Pinned by the marketing checker.

---

## Task 0: Branch and record the design

- [ ] **Step 1: Create the shutdown branch**

```bash
git checkout master
git pull --ff-only
git checkout -b fix/engine-shutdown-timeout
```

- [ ] **Step 2: Commit the design and plan**

```bash
git add docs/superpowers/specs/2026-11-22-shutdown-and-public-vision-design.md \
	docs/superpowers/plans/2026-11-22-shutdown-and-public-vision.md
git commit -s -m "docs: record the shutdown and public-vision design and plan"
```

---

## Task 1: Add the bounded-wait helper and its tests

**Files:**
- Create: `Windows/Client/Mad.Client/BoundedWait.cs`
- Create: `Windows/Client/Mad.Client.Tests/BoundedWaitTests.cs`
- Modify: `Windows/Client/Mad.Client/Mad.Client.csproj`

**Interfaces:**
- `internal static class BoundedWait` with `internal static bool Wait(Task task, TimeSpan timeout)`.
  - Returns `true` when the task completed (including faulted); `false` on timeout.
- `Mad.Client.Tests` can see it via `InternalsVisibleTo`.

- [ ] **Step 1: Add the friend assembly**

In `Windows/Client/Mad.Client/Mad.Client.csproj`:

```xml
  <ItemGroup>
    <InternalsVisibleTo Include="Mad.Client.Tests" />
  </ItemGroup>
```

- [ ] **Step 2: Write the failing tests**

Create `Windows/Client/Mad.Client.Tests/BoundedWaitTests.cs`:

```csharp
namespace Mad.Client.Tests;

public sealed class BoundedWaitTests
{
	[Fact]
	public void Wait_ReturnsFalse_WhenTheTaskDoesNotComplete()
	{
		var pending = new TaskCompletionSource();
		Assert.False(BoundedWait.Wait(pending.Task, TimeSpan.FromMilliseconds(100)));
	}

	[Fact]
	public void Wait_ReturnsTrue_WhenTheTaskCompletes()
	{
		var done = new TaskCompletionSource();
		done.SetResult();
		Assert.True(BoundedWait.Wait(done.Task, TimeSpan.FromSeconds(1)));
	}

	[Fact]
	public void Wait_ReturnsTrue_WhenTheTaskFaults()
	{
		var faulted = new TaskCompletionSource();
		faulted.SetException(new InvalidOperationException("closed"));
		Assert.True(BoundedWait.Wait(faulted.Task, TimeSpan.FromSeconds(1)));
	}
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run on .NET 10 (the Dell workstation or the Windows runner):

```powershell
dotnet test Windows/Client/Mad.Client.Tests/Mad.Client.Tests.csproj --nologo -v minimal
```

Expected: build error, `BoundedWait` does not exist. (The Mac has .NET 9 and cannot build `net10.0`.)

- [ ] **Step 4: Implement `BoundedWait`**

```csharp
namespace Mad.Client;

/// <summary>Waits for a task for a fixed period. A faulted task counts as
/// completed; a timeout returns false.</summary>
internal static class BoundedWait
{
	internal static bool Wait(Task task, TimeSpan timeout)
	{
		try
		{
			return task.Wait(timeout);
		}
		catch
		{
			return true;
		}
	}
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Expected: 3 tests pass.

- [ ] **Step 6: Commit**

```bash
git add Windows/Client/Mad.Client/Mad.Client.csproj \
	Windows/Client/Mad.Client/BoundedWait.cs \
	Windows/Client/Mad.Client.Tests/BoundedWaitTests.cs
git commit -s -m "test(client): add a bounded wait helper"
```

---

## Task 2: Bound the engine shutdown and test an unresponsive engine

**Files:**
- Modify: `Windows/Client/Mad.Client/MadEngineClient.cs`
- Modify: `Windows/Client/Mad.Client.Tests/MadEngineClientTests.cs`

**Interfaces:**
- `MadEngineClient` gains an internal constructor `MadEngineClient(ProcessStartInfo startInfo)` for tests; the public constructors are unchanged.
- `Shutdown()` calls `Shutdown(TimeSpan.FromSeconds(5))`.
- Internal `Shutdown(TimeSpan timeout)` returns after the bounded wait and a process-exit wait, killing the tree on timeout.

- [ ] **Step 1: Add the test start-info seam**

In `MadEngineClient`:
- Add `private readonly ProcessStartInfo? _testStartInfo;`
- Add the internal constructor:
  ```csharp
  internal MadEngineClient(ProcessStartInfo startInfo)
  {
  	_testStartInfo = startInfo;
  }
  ```
- In `Start()`, use `_testStartInfo ?? new ProcessStartInfo { ... }`. When the test start info is supplied, do not add the `serve` argument.

- [ ] **Step 2: Implement the bounded shutdown**

Replace the current `Shutdown()` body:

```csharp
private static readonly TimeSpan DefaultShutdownTimeout = TimeSpan.FromSeconds(5);

public void Shutdown() => Shutdown(DefaultShutdownTimeout);

internal void Shutdown(TimeSpan timeout)
{
	if (_process == null || _process.HasExited)
	{
		return;
	}

	try
	{
		Task response = Task.Run(() => CallOk("shutdown"));
		if (!BoundedWait.Wait(response, timeout))
		{
			try { _process.Kill(entireProcessTree: true); } catch { /* best effort */ }
		}
	}
	catch
	{
		/* best effort */
	}

	if (!_process.WaitForExit(5000))
	{
		try { _process.Kill(entireProcessTree: true); } catch { /* best effort */ }
	}
}
```

- [ ] **Step 3: Add the unresponsive-engine test**

Append to `MadEngineClientTests`:

```csharp
[Fact]
public void Shutdown_WhenTheEngineDoesNotAnswer_ReturnsAndKillsTheProcess()
{
	if (!OperatingSystem.IsWindows())
	{
		return; // the stub is a Windows PowerShell process
	}

	var startInfo = new ProcessStartInfo
	{
		FileName = "powershell.exe",
		Arguments = "-NoProfile -Command \"Start-Sleep -Seconds 60\"",
		RedirectStandardInput = true,
		RedirectStandardOutput = true,
		RedirectStandardError = true,
		UseShellExecute = false,
		CreateNoWindow = true,
	};

	var client = new MadEngineClient(startInfo);
	try
	{
		client.Start();
		int pid = client.Pid;
		Assert.True(pid > 0);

		var watch = Stopwatch.StartNew();
		client.Shutdown(TimeSpan.FromMilliseconds(250));
		watch.Stop();

		Assert.True(watch.Elapsed < TimeSpan.FromSeconds(5), $"shutdown took {watch.Elapsed}");
		AssertProcessGone(pid);
	}
	finally
	{
		client.Dispose();
	}
}
```

- [ ] **Step 4: Run the client tests**

```powershell
dotnet test Windows/Client/Mad.Client.Tests/Mad.Client.Tests.csproj --nologo -v minimal
```

Expected: all client tests pass, including `Shutdown_ExitsCleanly_WithNoOrphanProcess` and the new unresponsive test. The new test must not take 60 seconds.

- [ ] **Step 5: Commit**

```bash
git add Windows/Client/Mad.Client/MadEngineClient.cs \
	Windows/Client/Mad.Client.Tests/MadEngineClientTests.cs
git commit -s -m "fix(client): bound the engine shutdown and kill an unresponsive engine"
```

---

## Task 3: Validate the shutdown fix and open its PR

- [ ] **Step 1: Run the Windows client suite**

```powershell
dotnet test Windows/Client/Mad.Client.Tests/Mad.Client.Tests.csproj --nologo -v minimal
dotnet test Windows/App/Mad.Designer.Windows.slnx --nologo -v minimal
```

Expected: both suites pass; no orphan `mad.exe` or PowerShell stub remains.

- [ ] **Step 2: Push and open the PR**

```bash
git push -u origin fix/engine-shutdown-timeout
gh pr create --base master --head fix/engine-shutdown-timeout \
	--title "fix(client): bound the engine shutdown" \
	--body "Bounds the MadEngineClient shutdown response and kills an unresponsive engine instead of blocking forever. Adds a bounded-wait helper with unit tests and an unresponsive-stub process test. The normal clean-shutdown path is unchanged."
```

- [ ] **Step 3: Watch the checks and merge**

```bash
gh pr checks <n> --watch
gh pr merge <n> --rebase --delete-branch
```

Expected: DCO, Linux verification, Windows verification, macOS verification, and docs checks pass.

---

## Task 4: Rewrite the English vision and index summary

**Files:**
- Modify: `docs/vision.md`
- Modify: `docs/index.md`

**Interfaces:**
- Consumes: the handoff's direction and the existing report-as-table explanation.
- Produces: the public English vision with the six forward directions, three roles, current/future distinction, no brand names, and public developer links.

- [ ] **Step 1: Rewrite `docs/vision.md`**

Use this shape:
1. The direction: from reports to composable data; keep the report-as-table explanation.
2. What exists today: portable `.mad`, query graph, local SQLite materialization, four SQL drivers, native apps, headless engine.
3. Where it is going, each labeled as a proposal:
   - Composable data objects.
   - Multi-source local materialization.
   - Embedded and headless use.
   - Presentation beyond paper.
   - AI-authored documents.
   - Optional server and web deployment.
   - A short secondary note on generic legacy report conversion.
4. Three ways to use MAD: application, embedded engine, AI-authored platform.
5. Why this matters: reliable access, local control, portability, independence.
6. What this is not: no timelines or shipping claims.
7. The guiding principle: "The document defines the work. The engine executes it. The presentation makes the result useful."

Add `title: The Direction` and a `description` front matter. Link
`developers/data-object.html`, `developers/multi-source.html`, and the format
specification; do not link internal `docs/project/` records. Do not use
`Crystal`, `.rpt`, `SAP`, `Tableau`, `Power BI`, `Qlik`, or `Looker`.

- [ ] **Step 2: Update the index summary**

In `docs/index.md`, replace the vision sentence with the broader summary:
composable data objects, multi-source local materialization, the
embedded/headless engine, presentation beyond paper, and AI-authored
documents. No brand names.

- [ ] **Step 3: Run the checks**

```bash
rm -rf /tmp/madsite && (cd docs && jekyll build -d /tmp/madsite)
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_site_facts.py --docs docs --repo .
grep -rniE 'crystal|\.rpt\b|SAP|Tableau|Power BI|Qlik|Looker' docs/vision.md docs/index.md || true
```

Expected: build, links, facts pass; the brand grep is empty.

- [ ] **Step 4: Commit**

```bash
git add docs/vision.md docs/index.md
git commit -s -m "docs: rewrite the public vision around composable data and the embedded engine"
```

---

## Task 5: Add the English marketing card

**Files:**
- Modify: `/Users/michael/Projects/mad.github.io/index.html`

**Interfaces:**
- Consumes: the public vision page.
- Produces: one "The direction" card in the "Build on MAD" section.

- [ ] **Step 1: Add the card**

After the existing "Contribute" card in the "Build on MAD" section, add:

```html
<div class="audience-item">
	<h3><a href="https://docs.everydayapps.com/vision.html">The direction</a></h3>
	<p>From reports to composable data objects, an embedded engine, and AI-authored documents.</p>
</div>
```

- [ ] **Step 2: Build and check**

```bash
cd /Users/michael/Projects/mad.github.io
rm -rf _site && jekyll build -d _site
python3 -I scripts/check_site.py
grep -rniE 'crystal|\.rpt\b|SAP|Tableau|Power BI|Qlik|Looker' index.html || true
```

Expected: site checker passes; brand grep empty.

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -s -m "site: link the public vision from the developer section"
```

---

## Tasks 6-10: Translate the vision, index summary, and marketing card

One task per language: German, Spanish, Japanese, Brazilian Portuguese, and
Simplified Chinese. Each task edits both repositories.

| Task | Language | Vision page | Index summary | Marketing card link |
| --- | --- | --- | --- | --- |
| 6 | de | `docs/de/vision.md` | `docs/de/index.md` | `https://docs.everydayapps.com/de/vision.html` |
| 7 | es | `docs/es/vision.md` | `docs/es/index.md` | `https://docs.everydayapps.com/es/vision.html` |
| 8 | ja | `docs/ja/vision.md` | `docs/ja/index.md` | `https://docs.everydayapps.com/ja/vision.html` |
| 9 | pt-br | `docs/pt-br/vision.md` | `docs/pt-br/index.md` | `https://docs.everydayapps.com/pt-br/vision.html` |
| 10 | zh | `docs/zh/vision.md` | `docs/zh/index.md` | `https://docs.everydayapps.com/zh/vision.html` |

For each task:

- [ ] **Step 1: Rewrite the translated vision page** to mirror the English
  structure (same heading/table/fence counts), with the translated `title`,
  `description`, `lang`, and body. Keep technical identifiers, `.mad`,
  driver names, and code spans unchanged. No brand names.
- [ ] **Step 2: Update the translated index summary** to the same broader
  direction, with no brand names.
- [ ] **Step 3: Add the translated card** to the language's
  `index.html` in `/Users/michael/Projects/mad.github.io`, linking the
  language-specific vision URL.
- [ ] **Step 4: Run the checks**

```bash
python3 -I scripts/docs/check_translations.py --docs docs --require-complete --lang <code>
python3 -I scripts/docs/check_links.py
cd /Users/michael/Projects/mad.github.io
rm -rf _site && jekyll build -d _site
python3 -I scripts/check_site.py
grep -rniE 'crystal|\.rpt\b|SAP|Tableau|Power BI|Qlik|Looker' <lang>/vision.md <lang>/index.md <lang>/index.html || true
```

Expected: no missing/code/structure drift; links and site checks pass; brand
grep empty.

- [ ] **Step 5: Commit** in each repository with `-s`:
  `docs(<lang>): translate the revised public vision` and
  `site(<lang>): link the revised vision`.

---

## Task 11: Final validation and delivery

- [ ] **Step 1: Run the full docs gate**

```bash
rm -rf /tmp/madsite && (cd docs && jekyll build -d /tmp/madsite)
python3 -I scripts/docs/check_links.py
python3 -I scripts/docs/check_translations.py --require-complete
python3 -I scripts/docs/check_site_facts.py --docs docs --repo . --built /tmp/madsite
```

Expected: all zeros.

- [ ] **Step 2: Run the full marketing gate**

```bash
cd /Users/michael/Projects/mad.github.io
rm -rf _site && jekyll build -d _site
python3 -I scripts/check_site.py
python3 -I /Users/michael/Projects/Reports/scripts/docs/check_site_facts.py \
	--docs /Users/michael/Projects/Reports/docs --marketing .
```

Expected: all zeros.

- [ ] **Step 3: Brand sweep**

```bash
grep -rniE 'crystal|\.rpt\b|SAP|Tableau|Power BI|Qlik|Looker' \
	docs/vision.md docs/*/vision.md docs/index.md docs/*/index.md \
	/Users/michael/Projects/mad.github.io/*.html \
	/Users/michael/Projects/mad.github.io/*/index.html
```

Expected: no output. Internal `docs/project/` records are out of scope and
keep their references.

- [ ] **Step 4: Screenshots**

Capture the English and one translated home page at desktop width and
confirm the four "Build on MAD" cards, including "The direction"; open the
docs vision page in the same language.

- [ ] **Step 5: Delivery**

The shutdown PR from Task 3 is already open. Open the docs vision PR and the
marketing PR:

```bash
git push -u origin <docs-branch>
gh pr create --base master --head <docs-branch> \
	--title "docs: revise the public vision and its translations" \
	--body "Replaces the named legacy-product framing with the composable-data, embedded-engine, and AI-authored direction; updates the index summary and all five translations. No third-party brand names."

cd /Users/michael/Projects/mad.github.io
git push -u origin <marketing-branch>
gh pr create --base main --head <marketing-branch> \
	--title "site: link the revised public vision" \
	--body "Adds one translated 'The direction' card to the developer section, linking the matching language vision page."
```

- [ ] **Step 6: Watch the checks and merge**

```bash
gh pr checks <n> --watch
gh pr merge <n> --rebase --delete-branch
```

Expected: Reports DCO, Linux verification, docs checks; marketing site
checks. Verify the live vision pages and the marketing cards after the
Pages deployment.
