# TASKS.md

The engineering task queue for _MAD Designer_.

> **Agents: maintain this file, do not act on it.** Add, re-status, and link tasks as
> work proceeds, but do not start work on an entry just because it is listed here.
> Pick up a task only when the user asks for that task by name or number.

## How this relates to the other tracking files

Three files track work, and they are deliberately different things:

* `BUGS.md` — the **defect register**. Every confirmed wrong behaviour, with the test that
  pins it. Evidence, not a queue.
* `TODO.md` — the user's **product wishlist**. Features and ideas, written by hand.
* `TASKS.md` — this file, the **engineering queue**. What is actively being worked, in
  order, with enough context to start cold. Entries link to `BUGS.md` rather than
  restating it.

Status key: **Open** · **In progress** · **Blocked** · **Done**.

---

## 1. Keychain and credential flow — highest priority

**Status:** Open — the user has asked to return to this.

The user's words: *"It seems like this keychain flow is very important to getting right,
or no one will ever use the software."* Saving a database password is what makes a
document usable, so a broken prompt sequence blocks the whole product.

**What goes wrong today.** On create-document, the app presents **two competing
password prompts**:

1. The app's own `MADOperationPromptPolarQuestion` alert — "Save to Keychain" Yes/No.
2. The **system** Passwords-app sheet — "Update Password?" with *Not Now* / *Update* —
   which appears **on top** of the app's alert.

The user clicked *Update* on the system sheet, then *Yes* on the app's alert, and only
then did the document get created. Saving and deleting a password is otherwise broken.

**Where to look.**
* `MADFoundation/Source/MADKeyChain.m` — the `SecItem*` wrapper. Note it was recently
  fixed: `-deleteSavedPasswordForKey:error:` was swallowing failures and dereferencing a
  `NULL` error out-parameter. Deletion failures now surface, which may be part of the
  user-visible wonkiness.
* `MADDesigner/Source/` — `MADOperationKeyChainPut`, `MADOperationKeyChainGet`,
  `MADOperationKeyChainDeletePassword`, `MADOperationGetCredentials`, and the
  `MADOperationConditionPolarQuestionAffirmative` condition that gates them.

**Design question to settle with the user.** The duplicate prompt is almost certainly
because the app writes its own keychain item *and* iOS offers its own credential storage
for the same host. Decide which system owns the password:

* use the platform's AutoFill/`kSecClassInternetPassword` path and delete the app's own
  prompt, or
* keep the app's private keychain item and suppress the system sheet.

Do not guess which — this is a product decision.

**Evidence:** `MADDesigner/run.log`, the `MADOperationKeyChainPut` / `KeyChainGet` /
`KeyChainDeletePassword` / `GetCredentials` sequences around lines 380–570.

**Also worth checking while here:** the log line

```
MADOperationCreateDocument Keychain keys generated.
  MainKey (connStr):"(TDS)[localhost:localhost:1433]AdventureWorksLT2022"
```

names the host **twice** in one key. Confirm whether the connection-string formatter is
emitting a duplicated host, because every keychain key is derived from that string — a
wrong key means a saved password that can never be found again. Related: the accessor is
spelled `-[MADDatabase credentalsWithConnection:]`.

**Done when:** one prompt, save works, delete works, and the key round-trips identically
between save and lookup. See task 4 for the tests that must cover it.

---

## 2. A SQL Server connection that reports success and failure at the same time

**Status:** Fixed for the reporting half; the live connection itself is still unverified.

**What was wrong.** The SQL Server driver swallowed every failure past the connection
point. `MADDatabaseSQLServer -connectWithConnection:credentals:connectionError:` and
`-connect:andPassword:error:` built an `NSError` and never wrote it to the caller's
out-parameter, and `-executeQuery:withDataTable:andError:` ignored both. So
`MADOperationDatabaseTestConnection` saw `success = NO` with `error = nil`, logged

```
MADOperation <MADOperationDatabaseTestConnection> finish with 0 direct errors.
MADOperation <MADOperationDatabaseTestConnection> finishing with no errors.
...
MADOperationConditionResult: created 'failed' (not satisfied) for condition name:
    "MADOperationConditionTestConnectionSuccess"
```

— the operation reporting no errors while the condition consumed it and reported not
satisfied, which is the disagreement in the log.

**Now:** the three methods write the real error to the caller's `NSError **` (all three
are NULL-tolerant), so `MADOperationDatabaseTestConnection` records the failure and its
message, and `MADOperationConditionTestConnectionSuccess` — which reads `isSuccess` /
`error` through `MADOperationTestResults` — sees the same thing the operation does.
Covered by the `MADTdsClient` offline and live suites; see `BUGS.md`, MADTdsClient
entries for `-connectWithConnection:credentals:connectionError:`,
`-connect:andPassword:error:` and `-executeQuery:withDataTable:andError:`.

**Still open:** whether the connection *succeeds* against the development server is not
something the unit tests can answer — they skip without a server. That is a hand run, and
it now produces a real error message to go on if it fails. The
`[localhost:localhost:1433]` key oddity seen in the same log is a separate problem and
belongs to task 1.

---

## 3. Two fixes that need a human to confirm in the running app

**Status:** Open.

Both are already committed and unit-tested; only a live run can show they are right.

* [ ] **Keychain** — open and create a document, and check that no spurious error alert
      appears. (Overlaps task 1.)
* [ ] **File size** — the document info screen should now read `1.5 MB`, not `1 MB`. The
      `MTMath` conversion used integer division and truncated the fraction
      (`BUGS.md`, Already fixed → MADCocoaExtensions batch).

---

## 4. Unit and UI test coverage for the keychain flow

**Status:** Open — depends on the design decision in task 1.

The keychain is the one part of the flow with **no unit test at all**: the existing
`MADKeyChain` coverage stops at the wrapper, and
`BUGS.md` recorded the delete bug as *"inspection; not covered by a test — keychain
calls"*. That is not good enough for the path the whole product depends on.

Needed:
* Unit coverage for the `MADKeyChain` wrapper: add / read / update / delete, the
  not-found path, and the `NULL` error out-parameter. A test keychain service (a unique
  service string per run, deleted in teardown) keeps these off the developer's real
  credentials.
* Unit coverage for the credential operations — `MADOperationKeyChainPut` / `Get` /
  `DeletePassword`, `MADOperationGetCredentials` — and for
  `MADOperationConditionPolarQuestionAffirmative`.
* **UI test** for the prompt sequence itself, so "two alerts appear" is caught rather
  than discovered by hand. The app already has a `MADDesignerUITests` target.
* A round-trip test that saves a password and reads it back **through the same
  connection-string key** — this is what would have caught the
  `[localhost:localhost:1433]` oddity in task 1.

---

## 5. Caller analysis for the remaining BUGS.md findings

**Status:** Done — every area analysed, every decision recorded in `BUGS.md`.

The second pass covered the 52 findings left after MADFoundation and MADCocoaExtensions.
Each one was caller-analysed before it was touched, because some "confirmed" behaviour is
load-bearing — the `CGRectAdjustForScale` case, where the two callers split the
`zoomScale` domain between them, is the standing example.

The outcome split three ways:

* **43 fixed**, each with the pinning test flipped or added.
* **6 documented and deliberately left alone**, with an in-code comment naming the callers
  that depend on the behaviour: `MADFileManager` self-replacing metadata initialisers,
  `MADDatabaseSQLServer -runSQL:onDataTable:fieldKeys:process:` closing the process it was
  handed, and `-sqlSampleDataForField:andTable:` bypassing the base class's clause builders.
* **3 that needed the user's call**, all three decided: decimal-MB file sizes, the
  year/month/week timer fallthrough, and the modern date/time values — which at the time
  were typed but unfetched. The values were fetched on 2026-10-01 (Track 1.1 of
  `ROADMAP.md`), and getting them uncovered a second defect in the same record: the
  classic `DATETIME` cases had been adding a month that freetds had already added.
  Both are recorded in `BUGS.md`; `SYBDATETIME4`'s base-date arithmetic is newly open.

| Area | Open findings |
|---|---|
| `MADTdsClient` | 1 — `SYBDATETIME4` counts its days from the wrong epoch |
| MAD Designer (app) | 0 |
| `MADMySQL` | 0 |
| `MADFileManager` | 0 |
| `MAD` | 0 |
| `MADExplorer` | 0 |
| `MADAPI` | 0 |

`MADSqlite3` has none. Each area ended with the same three-part result the first pass
produced: defects fixed, load-bearing behaviour documented instead of changed, and
`BUGS.md` updated in place with the fix, its `Now:` line, and the test that covers it.

**One thing this pass did not settle:** every live-database finding was verified against
the offline suite or by reading the driver, not by a run against a real server. The
`MADMySQL` and `MADTdsClient` live suites skip when no server is reachable, so a
`scheme`-level green run does not mean the wire path was exercised.

---

## 6. Deferred by the user — the macOS library builds, and the declarative build system

**Status:** Deferred 2026-10-01. Not blocked, not dropped: waiting on the user's call to
resume, and recorded here so it is tracked intent rather than a thread that quietly ends.

These are `ROADMAP.md` §2.2 and §2.3, deferred in one decision. The user's words:

> *"let's skip section 2.2, The two real builds; we will build for MacOS later. We will also
> put off the declarative build system, though I believe it's important. This info should be
> stored in a plist or something, IDK. We need to keep track of them on some TODO list,
> which previous ones probably haven't been maintained."*

**What is deferred.**

*   **`ROADMAP.md` §2.2 — the two remaining macOS builds.** zlib/macOS and
    mysqlclient/macOS. Five of the eight library rows are already built; these two are not.
    `LIBRARIES.md` §3 has the matrix.
*   **`ROADMAP.md` §2.3 — the declarative build system.** `Compressor/matrix.conf`,
    `Compressor/build.sh`, a per-library `manifest.json`, and an XCFramework as the single
    artifact Xcode links. `LIBRARIES.md` §7.3 has the design.

**Why deferring is safe right now.** Neither is on the path to anything the user is doing
next. The `mad` CLI builds for the **iOS Simulator** and runs on the Mac through
`xcrun simctl spawn`, so it links the existing iOS artifacts unchanged — the CLI track needs
no macOS slice at all. And a *native* macOS binary is blocked by the UIKit imports in
`MADFoundation` (`ROADMAP.md` §4.2), which is upstream of the build wiring: even a perfect
matrix would not let a target compile for macOS today.

**What must not be lost.**

*   The user's "store it in a plist or something" is exactly what the `manifest.json` in
    §2.3 is. The design already answers the concern that prompted the deferral, so it should
    be read as confirming §2.3's shape rather than asking for a new one.
*   `ROADMAP.md` §2.1's third bullet is **not** cancelled by this. Adding `[sdk=macosx*]`
    search paths cannot work, because `PBXFileReference.path` names an iOS slice directly and
    is not SDK-conditional. The XCFramework in §2.3 remains the answer, whenever macOS work
    resumes.
*   The standing constraint still holds: nothing in `Compressor/library` is deleted until a
    replacement builds every combination. A deferral is not permission to prune.
