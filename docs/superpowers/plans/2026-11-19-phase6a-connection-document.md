# Phase 6a — Connection & document — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the WPF shell the connection & document layer — create a `.mad` from a database connection (importing its schema), edit/reconnect a document's connection, and save/save-as — on top of Phase 5's open/refresh/export, with launch-to-empty (all document controls disabled) and a connection wizard.

**Architecture:** Extend the `serve` protocol (`CLI/Source/MADCLIServe.m`) with four additive methods — `create`, `test-connection`, `connection`, `apply-connection` — each a thin wrapper over an existing engine API, and make `write` serialize the live document. On the .NET side, add a `ConnectionSpec` DTO, `EngineService` wrappers, a Windows Credential Manager store, a recent-files service, a connection-window view model + view, and wire the main window's File menu + workspace gating.

**Tech Stack:** Objective-C (GNUstep engine, `mad.exe`); C# / WPF / .NET 10 (`net10.0-windows`); xunit.

**Spec:** `docs/superpowers/specs/2026-11-19-phase6a-connection-document-design.md`

## Global Constraints

- Reuse the existing engine and `serve` protocol; build on Phase 5's `EngineService` / `DocumentViewModel` / MVVM — do not redo them.
- `MADKeyChain` is excluded on Windows → credentials live in Windows Credential Manager and reach the engine only as the protocol's `credentials` (`user:password`) string.
- Driver wire token is `sqlite3` | `mysql` | `sqlserver` | `postgres`; SQL Server's `MADDatabaseType` is `MADDatabaseTypeTDS`.
- English-only strings; PDF/barcodes/localization stay deferred; Apple/Linux builds and the one-shot CLI verbs stay untouched.
- Commit with `git commit -s` to `windows-engine`, push to `origin`, keep DCO + Linux CI green, leave PR #32 draft, write the summary to `C:\dev\mad-win-reports\phase6a-summary.md`.
- Engine rebuild command: `pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain` (elevated). .NET tests: `dotnet test <proj>` from `Windows/`.

## Review Focus

1. **Missing or 0-byte SQLite file** on `test-connection`/`create` → a clean error (code 3), no 0-byte `.mad` or `.sqlite3` artifact created, no crash.
2. **Server driver with no `host` or `database`** → a usage error (code 1) with a clear message, before any network attempt.
3. **`create` into a non-existent directory** → the parent directory is created (or a clean usage error), never a crash.
4. **Unknown/omitted `driver` token** → a usage error (code 1), never a crash or an accidental SQLite default.
5. **A document with no source database** (or a stale handle) on `connection`/`apply-connection` → a clean usage error, session keeps running.

---

### Task 1: Engine — `test-connection` and `create` methods

**Files:**
- Modify: `CLI/Source/MADCLIServe.m`
- Test: `Windows/Client/Mad.Client.Tests/MadEngineClientTests.cs`

**Interfaces:**
- Produces (engine, used by later tasks): `test-connection` → `{ "tableCount": <int> }`; `create` → `{ "handle": <int>, "filename": "<name>", "driver": "<display>" }`; shared helper `static MADDatabaseConnection *MADCLIServeBuildConnection(NSDictionary *params, MADCredential **outCredentials, NSError **error)`; wire tokens `sqlite3`/`mysql`/`sqlserver`/`postgres`.

- [ ] **Step 1: Add the imports and wire-token helpers to `MADCLIServe.m`**

Add `#import` for `<MAD/MADDatabase+Constructor.h>` (for `newDatabaseWithConnection:`), `<MAD/MADDatabaseConnectionsPropertiesURLProtocol.h>`, and the four connection headers `<MADSqlite3/MADDatabaseConnectionSqlite3.h>`, `<MADMySQL/MADDatabaseConnectionMySql.h>`, `<MADTdsClient/MADDatabaseConnectionSQLServer.h>`, `<MADPostgres/MADDatabaseConnectionPostgres.h>`. Add `static MADDatabaseType MADCLIServeDatabaseTypeForToken(NSString *token)` mapping `"sqlite3"→MADDatabaseTypeSqlite3`, `"mysql"→MADDatabaseTypeMySQL`, `"sqlserver"→MADDatabaseTypeTDS`, `"postgres"→MADDatabaseTypePostgres`, else `MADDatabaseTypeNotSet`. Add `static NSString *MADCLIServeTokenForDatabaseType(MADDatabaseType type)` (the inverse).

- [ ] **Step 2: Add `MADCLIServeBuildConnection`**

Mirror `MADMacConnectionWindowController buildConnectionWithCredentials:error:`. Read `driver` (string token), and per driver: SQLite reads `file` (string, must exist and be non-empty → else error code 1); server drivers read `host`/`database` (both required → else error code 1), `port` (int, default 3306 mysql / 1433 sqlserver / 5432 postgres), `server` (SQL Server only, defaults to host), and `credentials` (`user:password` via `MADCLIServeCredential`). Build the concrete connection: SQLite `[[MADDatabaseConnectionSqlite3 alloc] initWithUrl:]`; MySQL/Postgres `initWithHost:database:andPort:`; SQL Server `initWithHost:server:database:andPort:`. Return nil + `*error` (code 1) on bad params.

- [ ] **Step 3: Add `MADCLIServeTestConnection`**

Build the connection, then `MADDatabase *db = [MADDatabase newDatabaseWithConnection:conn]`, `id handle = [db connectWithConnection:conn credentals:creds connectionError:&err]`; on failure answer code `MADCLIExitDatabaseUnreachable` with `MADCLIDescriptionForError:`. On success `NSArray *tables = [db getTablesFromConnection:handle error:&err]`, `[db closeConnection:handle]`, and answer `{ @"tableCount": @(tables.count) }`.

- [ ] **Step 4: Add `MADCLIServeCreate`**

Read `path` (string, required); create the parent directory first with `[NSFileManager createDirectoryAtURL:[url URLByDeletingLastPathComponent] withIntermediateDirectories:YES ...]` (mirroring `MADCLIServeWriteCopy`), answering code 1 on failure. Build the connection. Call `[MADHeadlessDocument createDocumentAtURL:url withDatabaseConnection:conn credentials:creds error:&err]`; on nil answer code `MADCLIExitDatabaseUnreachable` for a connection failure, `MADCLIExitBadDocument` otherwise, with `MADCLIDescriptionForError:`. Allocate a fresh handle (same loop as `MADCLIServeOpen`), register a `MADCLIServeDocument` holding the created `MADHeadlessDocument` and `sourceURL = url`, and answer `{ handle, filename, driver }` using `MADCLIServeDriverName:`.

> Note: `MADCLIDocument` has no public initialiser to adopt a document. Add a tiny `-initWithDocument:sourceURL:` to `MADCLIDocument` so the created in-memory document (already connected) is adopted rather than re-read from disk.

- [ ] **Step 5: Register both methods in `MADCLIServeDispatch`**

Add `MADCLIServeMethodTestConnection = @"test-connection"` and `MADCLIServeMethodCreate = @"create"` constants and the two `else if` branches.

- [ ] **Step 6: Rebuild the engine**

Run: `pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain`
Expected: build completes, `Windows/Engine/build/mad.exe` regenerated, tests green.

- [ ] **Step 7: Add raw-protocol tests to `MadEngineClientTests.cs`**

Add a private `static string ChinookSqlite()` = `Path.Combine(RepoRoot(), "MADDesigner", "Resources", "Assets", "Samples.xcassets", "Data", "chinook.dataset", "chinook.sqlite3")`. Add tests:
- `TestConnection_Sqlite_ReportsElevenTables` — copy `ChinookSqlite()` to a temp `.sqlite3`, `client.CallOk("test-connection", Dict("driver","sqlite3","file",temp))`, assert `tableCount == 11`; delete temp.
- `TestConnection_MissingSqliteFile_IsDatabaseUnreachable` — `client.Call("test-connection", Dict("driver","sqlite3","file", <nonexistent temp path>))`, assert `Ok == false`, `Error.Code == 3`, and `File.Exists(nonexistent) == false`.
- `TestConnection_ServerMissingHost_IsUsageError` — `client.Call("test-connection", Dict("driver","mysql","database","employees"))`, assert `Ok == false`, `Error.Code == 1`.
- `TestConnection_UnknownDriver_IsUsageError` — `client.Call("test-connection", Dict("driver","oracle"))`, assert `Ok == false`, `Error.Code == 1`.
- `Create_FromSqlite_DescribesSchema` — temp `.mad` path + temp `.sqlite3` copy; `client.CallOk("create", Dict("path",mad,"driver","sqlite3","file",sqlite))`; assert `handle >= 0`, `driver == "Sqlite 3"`; then `CallOk("describe", Dict("handle", handle))` → `tables.GetArrayLength() == 11`.
- `Create_IntoNewDirectory_Succeeds` — a temp `.mad` path whose parent directory does not yet exist; `create` succeeds and `File.Exists(mad)` is true.

- [ ] **Step 8: Run the client tests**

Run: `dotnet test .\Windows\Client\Mad.Client.Tests` (from `Windows/Client`)
Expected: all tests pass including the three new ones.

- [ ] **Step 9: Commit**

```bash
git add CLI/Source/MADCLIServe.m CLI/Source/MADCLIDocument.h CLI/Source/MADCLIDocument.m Windows/Client/Mad.Client.Tests/MadEngineClientTests.cs
git commit -s -m "Phase 6a: serve create and test-connection methods"
```

---

### Task 2: Engine — `connection`, `apply-connection`, and live `write`

**Files:**
- Modify: `CLI/Source/MADCLIServe.m`
- Test: `Windows/Client/Mad.Client.Tests/MadEngineClientTests.cs`

**Interfaces:**
- Consumes: `MADCLIServeBuildConnection`, wire-token helpers (Task 1).
- Produces: `connection` → `{ "driver": <token>, "file" | "host"|"port"|"database"|"server" }`; `apply-connection` → `{}`; `write` now serializes the live document.

- [ ] **Step 1: Add `MADCLIServeConnection`**

Given `handle`, read `entry.document.document.database.databaseConnection`. If SQLite, read `file` from the `MADDatabaseConnectionsPropertiesURL` `databaseUrl.path`; else read `host`/`port`/`database`/`server` from `MADConnectionsPropertiesProtocol`. Answer `{ "driver": MADCLIServeTokenForDatabaseType(type), ... }`. Missing connection → code 1.

- [ ] **Step 2: Add `MADCLIServeApplyConnection`**

Build the connection, then verify it (connect → on failure code 3 → on success `closeConnection:`). Apply to the live document: if `entry.document.document` is a `MADHeadlessDocument`, call `applyDatabaseConnection:`; else call `updateDatabaseWithConnection:` (the protocol method). Answer `{}`.

- [ ] **Step 3: Change `MADCLIServeWriteCopy` to write the live document**

Replace the `MADHeadlessDocument documentWithContentsOfURL:entry.sourceURL` read with: `id<MADDocumentDataProtocol> proto = entry.document.document;` if it is a `MADHeadlessDocument`, write that live instance via `writeToURL:reproducible:error:`; otherwise (Apple) keep the re-open-from-`sourceURL` fallback. Keep the `out`/`reproducible` params and the `{path, bytes}` result unchanged.

- [ ] **Step 4: Register `connection` and `apply-connection` in `MADCLIServeDispatch`**

Add the two constants and `else if` branches.

- [ ] **Step 5: Rebuild the engine**

Run: `pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain`
Expected: build completes, tests green.

- [ ] **Step 6: Add raw-protocol tests to `MadEngineClientTests.cs`**

- `Connection_ReadsBackSqliteFile` — `create` from a temp chinook copy, then `client.CallOk("connection", Dict("handle", handle))` → `driver == "sqlite3"` and `file == <temp path>`.
- `Connection_UnknownHandle_IsUsageError` — `client.Call("connection", Dict("handle", 99999))`, assert `Ok == false`, `Error.Code == 1`.
- `ApplyConnection_ThenSave_PersistsNewDriver` — `create` a temp `.mad` from SQLite; `apply-connection` the same handle with a MySQL spec (`driver":"mysql","host":"127.0.0.1","port":3306,"database":"employees","credentials":"root:root"`) but a **bad** database to assert the connect-verify path errors (code 3) — do not assert success against live servers; separately, apply the same SQLite file back, then `write` to a temp path and assert the copy exists and is non-empty.
- `Write_LiveDocument_ProducesACopy` — after `create`, `client.CallOk("write", Dict("handle", handle, "out", temp, "reproducible", true))` → `path == temp`, `bytes > 0`, `File.Exists(temp)`.

- [ ] **Step 7: Run the client tests**

Run: `dotnet test .\Windows\Client\Mad.Client.Tests` (from `Windows/Client`)
Expected: all pass.

- [ ] **Step 8: Commit**

```bash
git add CLI/Source/MADCLIServe.m Windows/Client/Mad.Client.Tests/MadEngineClientTests.cs
git commit -s -m "Phase 6a: serve connection, apply-connection, live write"
```

---

### Task 3: `ConnectionSpec` model and `EngineService` wrappers

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/Models/ConnectionSpec.cs`
- Modify: `Windows/App/Mad.Designer.Windows/Engine/EngineService.cs`
- Modify: `Windows/App/Mad.Designer.Windows/Models/Schema.cs` (add `WriteResult`)
- Test: `Windows/App/Mad.Designer.Windows.Tests/ConnectionSpecTests.cs`, `Windows/App/Mad.Designer.Windows.Tests/EngineServiceTests.cs`

**Interfaces:**
- Consumes: protocol methods from Tasks 1–2.
- Produces (used by Tasks 4–9):
  - `enum ConnectionDriver { Sqlite3, MySql, SqlServer, Postgres }`
  - `static class ConnectionDriverExtensions { string Token(this ConnectionDriver); int DefaultPort(this ConnectionDriver); }` — tokens `sqlite3/mysql/sqlserver/postgres`, ports `0/3306/1433/5432`.
  - `sealed record ConnectionSpec(ConnectionDriver Driver, string? File, string? Host, int? Port, string? Database, string? ServerInstance, string? Username, string? Password)` with `static ConnectionDriver DriverFromToken(string token)` and `string? CredentialKey` (server only: `"{token}:{host}:{port}/{database}"`; null for SQLite).
  - `sealed record WriteResult(string Path, long Bytes);`
  - `EngineService`: `Task<int> TestConnectionAsync(ConnectionSpec)`, `Task<OpenResult> CreateAsync(string path, ConnectionSpec)`, `Task<ConnectionSpec> ConnectionAsync(int handle)`, `Task ApplyConnectionAsync(int handle, ConnectionSpec)`, `Task<WriteResult> WriteAsync(int handle, string outPath, bool reproducible = false)`.

- [ ] **Step 1: Write the failing tests for `ConnectionSpec`**

`ConnectionSpecTests.cs`:
- `DriverToken_And_DefaultPort_AreCorrect` — `Sqlite3.Token()=="sqlite3"` (port 0), `MySql.Token()=="mysql"` (3306), `SqlServer.Token()=="sqlserver"` (1433), `Postgres.Token()=="postgres"` (5432).
- `DriverFromToken_RoundTrips` and `DriverFromToken_UnknownThrows`.
- `CredentialKey_IsNullForSqlite_AndFormattedForServer` — SQLite → null; `MySql` with host `db.example.com`, port 3306, database `employees` → `"mysql:db.example.com:3306/employees"`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `dotnet test .\Windows\App\Mad.Designer.Windows.Tests --filter ConnectionSpecTests`
Expected: FAIL (types not defined).

- [ ] **Step 3: Implement `ConnectionSpec.cs` and `WriteResult` in `Schema.cs`**

Add the types with the exact members above. `DriverFromToken` throws `ArgumentException` on unknown tokens.

- [ ] **Step 4: Run tests to verify they pass**

Run: `dotnet test .\Windows\App\Mad.Designer.Windows.Tests --filter ConnectionSpecTests`
Expected: PASS.

- [ ] **Step 5: Add `EngineService` methods**

Add a private `static Dictionary<string, object?> ConnectionParams(ConnectionSpec spec)` (driver token + `file` for SQLite, else `host`/`port`/`database`/`server`/`credentials`). Implement the five methods via the existing `CallAsync` + JSON parsing (matching `OpenAsync`/`DescribeAsync` style): `CreateAsync` returns `OpenResult` (handle/filename/driver); `ConnectionAsync` returns a `ConnectionSpec`; `WriteAsync` returns `WriteResult`.

- [ ] **Step 6: Add `EngineServiceTests` end-to-end tests**

In `EngineServiceTests.cs`:
- `CreateFromSqlite_ThenDescribeRefresh_Completes` — `await using var service = new EngineService();` copy `chinook.sqlite3` to temp, `var open = await service.CreateAsync(tempMad, spec)`; assert `open.Driver == "Sqlite 3"`; `var describe = await service.DescribeAsync(open.Handle)` → `describe.Tables.Count == 11`; `var refresh = await service.RefreshAsync(open.Handle)` → `refresh.RowCount >= 0`.
- `TestConnection_Sqlite_ReportsTableCount` — `await service.TestConnectionAsync(sqliteSpec)` → `11`.

- [ ] **Step 7: Run the engine tests**

Run: `dotnet test .\Windows\App\Mad.Designer.Windows.Tests --filter EngineServiceTests`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/Models/ConnectionSpec.cs Windows/App/Mad.Designer.Windows/Models/Schema.cs Windows/App/Mad.Designer.Windows/Engine/EngineService.cs Windows/App/Mad.Designer.Windows.Tests/ConnectionSpecTests.cs Windows/App/Mad.Designer.Windows.Tests/EngineServiceTests.cs
git commit -s -m "Phase 6a: ConnectionSpec model and EngineService wrappers"
```

---

### Task 4: Windows Credential Manager store

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/Infrastructure/ICredentialStore.cs`
- Create: `Windows/App/Mad.Designer.Windows/Infrastructure/WindowsCredentialStore.cs`
- Test: `Windows/App/Mad.Designer.Windows.Tests/CredentialStoreTests.cs`

**Interfaces:**
- Produces: `interface ICredentialStore { void Save(string key, string username, string password); bool TryRead(string key, out string username, out string password); void Delete(string key); }` and `sealed class WindowsCredentialStore : ICredentialStore`.

- [ ] **Step 1: Write the failing tests**

`CredentialStoreTests.cs` uses an in-memory fake `ICredentialStore` (a test double) to pin the contract: `Save_ThenTryRead_RoundTrips`, `TryRead_MissingKey_ReturnsFalse`, `Delete_ThenTryRead_ReturnsFalse`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `dotnet test .\Windows\App\Mad.Designer.Windows.Tests --filter CredentialStoreTests`
Expected: FAIL.

- [ ] **Step 3: Implement `ICredentialStore` and `WindowsCredentialStore`**

`WindowsCredentialStore` P/Invokes `CredReadW`/`CredWriteW`/`CredDeleteW` from `advapi32.dll` with `CRED_TYPE_GENERIC` (1), target = `"MAD/" + key`, and `CRED_PERSIST_LOCAL_MACHINE`. `Save`/`Delete` throw on failure; `TryRead` returns false on not-found. Wrap each credential in `try/finally` to `CredFree` the blob.

- [ ] **Step 4: Run tests to verify they pass**

Run: `dotnet test .\Windows\App\Mad.Designer.Windows.Tests --filter CredentialStoreTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/Infrastructure/ICredentialStore.cs Windows/App/Mad.Designer.Windows/Infrastructure/WindowsCredentialStore.cs Windows/App/Mad.Designer.Windows.Tests/CredentialStoreTests.cs
git commit -s -m "Phase 6a: Windows Credential Manager store"
```

---

### Task 5: Recent-files service

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/Infrastructure/RecentFilesService.cs`
- Test: `Windows/App/Mad.Designer.Windows.Tests/RecentFilesServiceTests.cs`

**Interfaces:**
- Produces: `sealed class RecentFilesService { RecentFilesService(string? filePath = null); IReadOnlyList<string> Get(); void Add(string path); void Remove(string path); }` — default path `%APPDATA%\MAD\recent.json`, most-recent-first, capped at 10, persisted as a JSON array.

- [ ] **Step 1: Write the failing tests**

`RecentFilesServiceTests.cs` with a temp file path: `Add_ThenGet_ReturnsMostRecentFirst`, `Add_DeduplicatesExistingPath`, `Add_CapsAtTen`, `Remove_RemovesPath`, `Get_OnMissingFile_ReturnsEmpty`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `dotnet test .\Windows\App\Mad.Designer.Windows.Tests --filter RecentFilesServiceTests`
Expected: FAIL.

- [ ] **Step 3: Implement `RecentFilesService`**

Persist to a JSON array via `System.Text.Json`. `Add` moves to front, dedupes, trims to 10, writes atomically (temp + move). `Get` returns an empty list on missing/corrupt file.

- [ ] **Step 4: Run tests to verify they pass**

Run: `dotnet test .\Windows\App\Mad.Designer.Windows.Tests --filter RecentFilesServiceTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/Infrastructure/RecentFilesService.cs Windows/App/Mad.Designer.Windows.Tests/RecentFilesServiceTests.cs
git commit -s -m "Phase 6a: recent-files service"
```

---

### Task 6: `DocumentViewModel` — file path, save/save-as, apply connection

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows/ViewModels/DocumentViewModel.cs`
- Test: `Windows/App/Mad.Designer.Windows.Tests/DocumentViewModelTests.cs`

**Interfaces:**
- Consumes: `EngineService.WriteAsync`, `EngineService.ApplyConnectionAsync`, `EngineService.ConnectionAsync`, `ConnectionSpec`, `WriteResult` (Tasks 1–3).
- Produces (used by Tasks 8–9): `string? FilePath`, `Task OpenAsync(string path)`, `Task AdoptAsync(OpenResult open, string path)`, `Task SaveAsync()`, `Task SaveAsAsync(string path)`, `Task ApplyConnectionAsync(ConnectionSpec spec)`, `Task<ConnectionSpec?> GetConnectionAsync()`, `AsyncRelayCommand SaveCommand`, `AsyncRelayCommand SaveAsCommand`; `OpenAsync(path)` now sets `FilePath`.

- [ ] **Step 1: Write the failing tests**

In `DocumentViewModelTests.cs`:
- `SaveAs_WritesCopy_AndUpdatesFilePath` — open London; `await viewModel.SaveAsAsync(tempMad)`; assert `File.Exists(tempMad)`, `viewModel.FilePath == tempMad`.
- `Save_WithoutPath_SetsError` — open London, clear/force `FilePath = null` (add a test seam or assert `SaveAsync` reports an error when no path), assert `ErrorText` set and no file written.
- `GetConnection_ReturnsSqliteSpec` — open London; `var spec = await viewModel.GetConnectionAsync()`; assert `spec.Driver == ConnectionDriver.Sqlite3` and `spec.File` non-empty.

- [ ] **Step 2: Run tests to verify they fail**

Run: `dotnet test .\Windows\App\Mad.Designer.Windows.Tests --filter DocumentViewModelTests`
Expected: FAIL.

- [ ] **Step 3: Implement the `DocumentViewModel` changes**

Set `FilePath` in `OpenAsync`; add a private `LoadAsync(OpenResult open, string path)` (describe + query + reset rows) called by both `OpenAsync` and a new `AdoptAsync(OpenResult open, string path)`; add `SaveAsync`/`SaveAsAsync(path)` (via `WriteAsync`) and `ApplyConnectionAsync(spec)` (via `ApplyConnectionAsync` + `RefreshAsync`) and `GetConnectionAsync()` (via `ConnectionAsync`). Add `SaveCommand`/`SaveAsCommand` gated on `HasDocument`, and register them in `RaiseCanExecuteChanged`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `dotnet test .\Windows\App\Mad.Designer.Windows.Tests --filter DocumentViewModelTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/ViewModels/DocumentViewModel.cs Windows/App/Mad.Designer.Windows.Tests/DocumentViewModelTests.cs
git commit -s -m "Phase 6a: document save/save-as and apply connection"
```

---

### Task 7: `ConnectionWindowViewModel`

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/ViewModels/ConnectionWindowViewModel.cs`
- Test: `Windows/App/Mad.Designer.Windows.Tests/ConnectionWindowViewModelTests.cs`

**Interfaces:**
- Consumes: `EngineService.TestConnectionAsync`, `EngineService.CreateAsync`, `ICredentialStore`, `ConnectionSpec`, `ConnectionDriver`.
- Produces (used by Task 8): `ConnectionWindowViewModel(EngineService engine, ICredentialStore credentials, bool isEdit, ConnectionSpec? initial = null, Func<string?>? createPath = null)` with observable `Driver`, `File`, `Host`, `Port` (int), `Database`, `ServerInstance`, `Username`, `Password`, `SaveCredentials`; computed `IsSqlite`, `IsServer`, `IsSqlServer`, `StatusText`, `IsBusy`; `AsyncRelayCommand TestConnectionCommand`, `AsyncRelayCommand SubmitCommand`; `ConnectionSpec Spec { get; }`; `OpenResult? Created { get; private set; }`; `string? CreatePath { get; private set; }`; `ConnectionSpec? ResultSpec { get; private set; }`; `bool Submitted { get; private set; }`.

- [ ] **Step 1: Write the failing tests**

`ConnectionWindowViewModelTests.cs` (construct with an in-memory fake `ICredentialStore`):
- `Defaults_AreSqlite_WithVisibility` — `Driver == Sqlite3`, `IsSqlite == true`, `IsServer == false`, `IsSqlServer == false`.
- `SelectingMySql_HidesSqlite_ShowsServer_NotSqlServer` — set `Driver = MySql`, assert `IsSqlite false`, `IsServer true`, `IsSqlServer false`, and `Port == 3306` (default applied when previously 0/other-default).
- `SelectingSqlServer_ShowsServerInstance` — `Driver = SqlServer`, assert `IsSqlServer true` and `Port == 1433`.
- `ToSpec_RoundTripsFields` — set fields, assert `Spec` carries them and `Spec.CredentialKey` matches.
- `Submit_CreateMode_UsesEngineAndProducesCreated` — with a `createPath` returning a temp path and a fake engine path (skip live engine; assert `Submitted`/`Created` only after `SubmitCommand.ExecuteAsync` with a mocked engine — see note), OR assert the non-engine `TestConnection` path sets `StatusText`.

> Note: the view model's engine calls are thin; test the pure parts (visibility, default ports, `Spec`) against a real `EngineService` only where a fixture exists, and use `TestConnectionCommand` against the real SQLite chinook fixture (copy to temp) to assert `StatusText` contains `"Found 11 schema tables"`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `dotnet test .\Windows\App\Mad.Designer.Windows.Tests --filter ConnectionWindowViewModelTests`
Expected: FAIL.

- [ ] **Step 3: Implement `ConnectionWindowViewModel`**

Raise `IsSqlite`/`IsServer`/`IsSqlServer` and reset `Port` to the driver default whenever `Driver` changes (mirroring the Mac's port-default logic: only bump to the new driver default when the current port is 0 or another driver's default). `TestConnectionCommand` → `TestConnectionAsync(Spec)` → `StatusText = $"Connected! Found {n} schema tables."` or an error. `SubmitCommand` → edit mode: set `ResultSpec = Spec`, `Submitted = true`; create mode: resolve path via `createPath` (append `.mad` if missing), `CreateAsync`, save credentials when `SaveCredentials` && server && `CredentialKey != null`, set `Created`/`CreatePath`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `dotnet test .\Windows\App\Mad.Designer.Windows.Tests --filter ConnectionWindowViewModelTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/ViewModels/ConnectionWindowViewModel.cs Windows/App/Mad.Designer.Windows.Tests/ConnectionWindowViewModelTests.cs
git commit -s -m "Phase 6a: connection window view model"
```

---

### Task 8: `ConnectionWindow` view and wiring

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/Views/ConnectionWindow.xaml`, `Views/ConnectionWindow.xaml.cs`
- Modify: `Windows/App/Mad.Designer.Windows/MainWindow.xaml.cs`

**Interfaces:**
- Consumes: `ConnectionWindowViewModel` (Task 7), `DocumentViewModel.AdoptAsync`/`GetConnectionAsync`/`ApplyConnectionAsync` (Task 6).
- Produces: `ConnectionWindow` (a modal `Window`) with `DataContext` set by the caller.

- [ ] **Step 1: Build `ConnectionWindow.xaml`**

A `Window` titled "Database Connection Settings" (edit) / "Create a New Mobile Analytics Document (.mad)" (create). Driver `ComboBox` (SQLite / MySQL / Microsoft SQL Server / PostgreSQL); SQLite file `TextBox` + "Choose File…" `Button` (visibility bound to `IsSqlite`); `Host`/`Port`/`Database`/`Username`/`Password` (+ `Server Instance` for SQL Server) bound with `IsServer`/`IsSqlServer`; a "Save password in Windows Credential Manager" `CheckBox`; a status `TextBlock`; buttons "Test Connection", "Create Document…" / "Save & Refresh", "Cancel".

- [ ] **Step 2: Add code-behind for the SQLite file chooser and dialog result**

`ConnectionWindow.xaml.cs` opens an `OpenFileDialog` for SQLite (`.sqlite3;.db;.sqlite`) and a `SaveFileDialog` for the create path; `DialogResult` set on submit/cancel. The create-path delegate and file chooser delegate are wired into the view model.

- [ ] **Step 3: Wire into `MainWindow.xaml.cs`**

Add `OpenConnectionWindow(bool isEdit)`: build the `ConnectionWindowViewModel` (with `ICredentialStore`, an initial spec from `Document.GetConnectionAsync()` for edit, and a `createPath` save dialog for create); show `ConnectionWindow` as a modal; on create, `await Document.AdoptAsync(vm.Created!, vm.CreatePath!)` and add to recent files; on edit, `await Document.ApplyConnectionAsync(vm.ResultSpec!)`.

- [ ] **Step 4: Build the app to verify it compiles**

Run: `dotnet build .\Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj`
Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/Views/ConnectionWindow.xaml Windows/App/Mad.Designer.Windows/Views/ConnectionWindow.xaml.cs Windows/App/Mad.Designer.Windows/MainWindow.xaml.cs
git commit -s -m "Phase 6a: connection window view"
```

---

### Task 9: File menu, workspace gating, empty launch, command-line open

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows/ViewModels/MainWindowViewModel.cs`
- Modify: `Windows/App/Mad.Designer.Windows/MainWindow.xaml`, `MainWindow.xaml.cs`
- Modify: `Windows/App/Mad.Designer.Windows/App.xaml.cs`

**Interfaces:**
- Consumes: `DocumentViewModel` commands (Task 6), `ConnectionWindow` (Task 8), `RecentFilesService` (Task 5).

- [ ] **Step 1: Expand `MainWindowViewModel`**

Add `NewDocumentCommand`, `SaveCommand`, `SaveAsCommand`, `EditConnectionCommand`, and a `RecentFiles` observable list + `OpenRecentCommand`. Remove the London auto-open from `InitializeAsync` (leave it opening a command-line path only). Inject a `RecentFilesService` and a `Func<string?>?` open/save path provider.

- [ ] **Step 2: Add the File menu and workspace gating in `MainWindow.xaml`**

Add a `Menu` (File → New Document…, Open…, Save, Save As…, Database Connection…, Recent Files submenu; plus the existing Open…/About). Bind the Query/Designer/Viewer `TabControl.IsEnabled` to `Document.HasDocument` and each document command's `Command` to the corresponding `Document`/VM command (Refresh/Export/Save/Save As gated on `HasDocument`).

- [ ] **Step 3: Change launch behaviour in `App.xaml.cs` / `MainWindow.xaml.cs`**

Read `Environment.GetCommandLineArgs()` for a non-exe argument ending in `.mad`; on startup open it, otherwise show the empty state (no dialog, no auto-open). Keep `OnClosed` → `_engine.DisposeAsync()`.

- [ ] **Step 4: Build and run the headless tests**

Run: `dotnet build .\Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj` then `dotnet test .\Windows\App\Mad.Designer.Windows.Tests`
Expected: build succeeds, all tests pass (existing London/About/licence tests plus the new ones).

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/ViewModels/MainWindowViewModel.cs Windows/App/Mad.Designer.Windows/MainWindow.xaml Windows/App/Mad.Designer.Windows/MainWindow.xaml.cs Windows/App/Mad.Designer.Windows/App.xaml.cs
git commit -s -m "Phase 6a: file menu, workspace gating, empty launch"
```

---

### Task 10: Documentation, push, and summary

**Files:**
- Modify: `Windows/README.md`
- Modify: `docs/project/MAD_WINDOWS.md` (§6d protocol table + a short §6f Phase 6a note)
- Create: `C:\dev\mad-win-reports\phase6a-summary.md`

- [ ] **Step 1: Document the protocol extension**

In `docs/project/MAD_WINDOWS.md` §6d, add the four methods to the method table and a sentence that `write` now serializes the live document. In `Windows/README.md`, add the `create`/`test-connection`/`connection`/`apply-connection` methods to the `serve` paragraph and note the WPF launch-to-empty + connection wizard.

- [ ] **Step 2: Write the summary**

Write `C:\dev\mad-win-reports\phase6a-summary.md` covering what was built, the protocol extension, the WPF architecture, and how it was validated (create → describe → refresh → test-connection).

- [ ] **Step 3: Push**

```bash
git push origin windows-engine
```
Expected: push succeeds; DCO + Linux verification remain green; PR #32 stays draft.

- [ ] **Step 4: Confirm the branch is the only backup and no merge**

Verify `git log` shows the Phase 6a commits on `windows-engine`; do not merge to `master`.
