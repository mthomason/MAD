# Phase 6a — Connection & document (design)

Date: 2026-11-19 · Branch: `windows-engine` · Author: Claude Code

## Intent

Give the WPF shell the connection & document layer the Mac app already has:
create a new `.mad` from a database connection (importing its schema), edit /
reconnect an existing document's connection, and save / save-as — on top of the
Phase 5 open / refresh / export slice. The connection assistant mirrors the Mac's
`MADMacConnectionWindowController`: a driver selector (SQLite / MySQL / Microsoft
SQL Server / PostgreSQL) with driver-specific fields, a Test Connection action
that reports the schema-table count, and a Create Document… / Save & Refresh action.

## Goals / non-goals

**Goals**

1. Create a `.mad` from a SQLite database (import schema); the result opens,
   describes columns/tables, and refreshes against the same database.
2. A connection assistant that shows/hides fields by driver exactly as the Mac does.
3. Test Connection connects and reports the schema-table count (or a clean error).
4. Save and Save As write the document, reusing the engine's `write`.
5. Credentials live in Windows Credential Manager and reach the engine as the
   protocol's existing `credentials` (`user:password`).
6. Recent files is a client-side list.
7. No crashes, no UI stalls, clean process lifecycle (Phase 5 shutdown preserved).

**Non-goals (deferred, unchanged):** PDF, barcodes, localization (6e), the Query /
Designer / Viewer feature work (6b–6d), the one-shot CLI verbs, Apple/Linux builds.

**Anti-goals:** a second engine implementation, a second schema/rows wire format,
silently reworking the Objective-C engine, an iOS-style file explorer, or a
launch-to-Open-File-Dialog flow.

## Constraints

- Reuse the existing engine and `serve` protocol; build on Phase 5's `EngineService`
  and MVVM. Do not redo them.
- `MADKeyChain` is excluded on Windows → use Windows Credential Manager in the app.
- English-only strings for now.
- Commit with `-s` to `windows-engine`, push to `origin`, keep DCO + Linux CI green,
  leave PR #32 draft, write the summary to `C:\dev\mad-win-reports\phase6a-summary.md`.

## Approaches — the one decision this sub-phase forces

The `serve` protocol (§6d) has `open`, `describe`, `query`, `refresh`, `export`,
`write`, `shutdown`. It has **no `create` and no `test-connection`**, even though the
engine already has `MADHeadlessDocument createDocumentAtURL:…` and `MADDatabase`
(connect → getTables → close). This is the genuine gap the prompt flags. Three ways
to close it:

- **A — Extend `serve` (chosen).** Add `create` and `test-connection`, plus
  `connection` (read a live document's connection, for edit-mode population) and
  `apply-connection` (apply a connection change to a live document), each a thin
  wrapper over an existing engine API in `CLI/Source/MADCLIServe.m`. Change `write`
  to serialize the live document so a connection edit is persisted. Shared source,
  gated by the Linux CI; no Apple/Linux behaviour change (the methods are additive).
- **B — One-shot CLI verbs** (`mad create`, `mad test-connection`) spawned as short
  processes. Avoids touching `serve`, but adds per-action process spawns, a second
  result channel (exit code + stdout), and does not compose with the long-lived
  session (create would still need a separate `open`).
- **C — Compose from existing methods.** Not viable: `open` needs a `.mad` file and
  there is no way to build or test a connection from raw fields today.

**Choice: A.** It is minimal and protocol-shaped, reuses the engine's own
`createDocumentAtURL:` / `MADDatabase` / `applyDatabaseConnection:`, and is what the
prompt anticipates ("keep any engine change minimal and protocol-shaped").

### Protocol addition (final shape)

Driver token is an explicit wire string: `sqlite3` | `mysql` | `sqlserver` | `postgres`.
Connection params are driver-specific and mirror the Mac form:

- `sqlite3`: `file`
- `mysql`: `host`, `port` (default 3306), `database`, `credentials`
- `sqlserver`: `host`, `port` (default 1433), `database`, `server` (optional, defaults to host), `credentials`
- `postgres`: `host`, `port` (default 5432), `database`, `credentials`

| method | params | result |
|---|---|---|
| `create` | `path`, `driver`, connection fields, `credentials` | `handle`, `filename`, `driver` (the created document, registered like `open`) |
| `test-connection` | `driver`, connection fields, `credentials` | `tableCount` |
| `connection` | `handle` | `driver`, `file`/`host`/`port`/`database`/`server` |
| `apply-connection` | `handle`, `driver`, connection fields, `credentials` | `{}` (updates the live document's connection) |
| `write` (changed) | `handle`, `out`, optional `reproducible` | `path`, `bytes` — now serializes the **live** document, not a re-open of `sourceURL` |

`credentials` is the existing `"user:password"` split (`MADCLIServeCredential`).
Errors use the existing exit codes: usage 1, database unreachable 3. The one-shot
`mad write --reproducible` verb and its byte digest are untouched; serve `write` has
no digest pin (the Phase 4 `Write_ProducesACopy` test only asserts a valid copy).

## The WPF architecture (my calls, correctable)

Building on Phase 5's `EngineService` / `DocumentViewModel` / hand-rolled MVVM:

- **`Models/ConnectionSpec.cs`** — a mutable connection spec + `ConnectionDriver`
  enum (Sqlite3/MySql/SqlServer/Postgres) with a wire-token mapping and per-driver
  port defaults. `ConnectionSpec` is what the form edits and the service serialises.
- **`EngineService` extensions** — `TestConnectionAsync`, `CreateAsync`,
  `ConnectionAsync`, `ApplyConnectionAsync`, `WriteAsync` (each a typed wrapper over
  `CallAsync`, mirroring the existing `OpenAsync`/`DescribeAsync` style).
- **`ICredentialStore`** + **`WindowsCredentialStore`** — a small abstraction over
  Windows Credential Manager (`CredReadW`/`CredWriteW`/`CredDeleteW`, CRED_TYPE_GENERIC),
  keyed by a stable connection key (`<driver>:<host>:<port>/<database>`). SQLite
  stores nothing. Tests use an in-memory fake.
- **`RecentFilesService`** — a client-side list persisted to `%APPDATA%\MAD\recent.json`
  (most-recent-first, capped at 10). Injected so tests can use a temp path.
- **`ConnectionWindowViewModel`** + **`ConnectionWindow.xaml`** — the connection
  assistant. A `ComboBox` for the driver; field visibility driven by three booleans
  (`IsSqlite`, `IsServer`, `IsSqlServer`) so SQLite shows only the file field, server
  drivers show host/port/database/credentials, and SQL Server additionally shows
  Server Instance — exactly the Mac's hide/show. Buttons: Test Connection, Create
  Document… / Save & Refresh (edit mode), Cancel; a status line for results.
- **`DocumentViewModel` extensions** — track `FilePath`; `SaveAsync`/`SaveAsAsync`
  (via `write`); `ApplyConnectionAsync` for the edit/reconnect path.
- **`MainWindowViewModel` / `MainWindow`** — a real File menu (New Document…, Open…,
  Save, Save As…, Database Connection…, Recent Files) and launch behaviour per the
  prompt: **launch into the main application with no document open and every
  document-dependent control disabled** (no auto-open, no Open-File-Dialog, no
  file-manager window). Only New Document…, Open… and About are enabled at launch.
  New Document… opens the connection wizard; Open… opens an existing `.mad`; a
  command-line path opens that document on startup (double-click association).
- **Workspace gating** — the Query / Designer / Viewer tabs and every document
  command (Refresh, Export, Save, Save As, Database Connection…) are disabled until
  `Document.HasDocument` is true, then enabled once the document has a connection.
  Phase 5 already builds all three workspaces (Query = schema + SQL, Viewer =
  rows/export, Designer = placeholder); 6a wires their enablement to the document
  state and adds the connection layer on top, leaving the Query/Designer feature work
  to 6b/6c.
- **`App.xaml.cs`** — handle the command-line document path; keep the Phase 5 clean
  shutdown path (`OnClosed` → `EngineService.DisposeAsync`) intact.

## Validation

Headless, through the engine, following the existing `Mad.Designer.Windows.Tests`
pattern (the London fixture and `chinook.sqlite3` at
`MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset/`):

- `create` from a temp copy of `chinook.sqlite3` → `describe` (11 Chinook tables) →
  `refresh` against the same database.
- `test-connection` against the same file → `tableCount` 11; a missing file → a clean
  error (no 0-byte file created).
- `write` → a valid copy; Save/Save As via the view model.
- Connection assistant field-visibility per driver; credential-store and recent-files
  round-trips (in-memory/temp-backed).

## What's left to the builder (plan level)

Exact `MADCLIServe.m` helper decomposition (build-connection helper shared by
`create`/`test-connection`/`apply-connection`; the concrete `MADHeadlessDocument`
live-write path with an Apple fallback), the precise P/Invoke surface for Credential
Manager, the XAML layout of the assistant, and the test fixtures.
