# MAD Windows Phase 5 — WPF Shell Proof Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (native) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A `net10.0-windows` WPF shell that proves the `mad serve` process boundary in a real UI — the three-workspace frame (MAD Query / Designer / Viewer), open `CLI/Fixtures/London.portable.mad`, refresh 76 rows into a `DataGrid`, export CSV/JSON, and an About window wired to the Windows dependency register — with a headless `dotnet test` acceptance path so no human interaction is needed to verify it.

**Architecture:** Reuse the Phase 4 `Mad.Client.MadEngineClient` unchanged; wrap it in an `EngineService` async facade serialized by a `SemaphoreSlim(1,1)`. Hand-rolled MVVM (no external package): `DocumentViewModel` holds shared open/describe/query/refresh/export state, three `UserControl` views bind to it, and an `AboutViewModel` renders the Windows licence register. The app auto-opens the London fixture on startup (repo-root discovery) so it demos with zero clicks.

**Tech Stack:** WPF / XAML, .NET 10 LTS (`net10.0-windows`, `UseWPF`, pinned by `Windows/global.json`), `System.Text.Json`, `System.Data.DataTable` for the grid, xunit for the headless acceptance. No third-party NuGet packages.

**Spec:** `C:\dev\MAD-Windows-DevEnv\WINDOWS_POC_PLAN.md` §4 "Phase 5" (acceptance), `docs/project/MAD_WINDOWS.md` §6d (the `serve` protocol) and §8 (the Windows dependency register), `Windows/README.md`, `ThirdParty/Licenses/Windows/README.md`.

## Global Constraints

- **Do not change** the Objective-C engine, the `serve` protocol, the toolchain, or the Phase 4 `Mad.Client` code. Reuse `Mad.Client` as a `ProjectReference` only.
- **TFM is exactly `net10.0-windows`**, pinned by `Windows/global.json` (SDK `10.0.404`); the app lives under `Windows/App/` so the pin applies. Run all `dotnet` commands from `Windows/App` or `Windows/Client`.
- **Async only:** engine calls run via `await Task.Run(...)` behind the semaphore; no engine call may run on the UI thread.
- **Engine paths:** `mad.exe` at `Windows/Engine/build/mad.exe`, GNUstep bin at `C:\GNUstep\x64\Release\bin` (env overrides `MAD_EXE` / `GNUSTEP_BIN` / `MAD_DOCUMENT` / `MAD_REPO_ROOT`).
- **Licence surface is the Windows set only** (never the Apple set): GNUstep Base, libiconv, gnustep-corebase (LGPL-2.1); libobjc2, libffi (MIT); libdispatch (Apache-2.0 + Swift exception); SQLite, zlib, bzip2, libarchive, OpenSSL, FreeTDS, MariaDB Connector/C, libpq. Texts from `ThirdParty/Licenses/Windows/` and `ThirdParty/Licenses/`, plus `NOTICE`, root `LICENSE`, and the Windows relink offer.
- **PDF and barcodes stay deferred.** Leave Apple/Linux builds and the one-shot CLI verbs alone. Public five-language docs are Phase 6 (English-only strings here).
- **Commits:** `git commit -s` to `windows-engine`; keep DCO and Linux verification green; PR #32 stays a draft.
- **Acceptance values:** describe → 21 columns / 11 tables / driver `"Sqlite 3"`; refresh → `rowCount` 76; export json → 76 rows in `mad.report/1`; export csv → 78 lines (header + 76 rows + trailing empty element).

## Review Focus

1. **NULL cells in rows** — SQLite returns NULLs; the grid must show a blank cell, not throw. → Task 4 test `NullCells_BecomeDBNull`.
2. **Duplicate column `name` across tables** — `DataTable` columns must key on the unique `key`, not `name`, or `Add` throws. → Task 4 test `DuplicateNames_KeyOnKey`.
3. **Missing `mad.exe` / engine startup failure** — a clear `ErrorText`, not a crash or white screen. → Task 5 test `Open_BadDocument_SetsErrorAndStaysUsable`.
4. **Missing licence files (dev vs packaged)** — the About window renders what it can with placeholders, never throws. → Task 7 test `MissingLicenseFile_ReturnsNull_AboutHandlesIt`.
5. **Engine orphan on close** — window close and `Dispose` must `Shutdown` + `Kill(entireProcessTree)`; no lingering `mad.exe`. → Task 3 test `EngineService_Dispose_StopsProcess` (asserts `Pid` is gone after `DisposeAsync`).

---

## Task 1: Scaffold the WPF solution and app project

**Files:**
- Create: `Windows/App/Mad.Designer.Windows.slnx`
- Create: `Windows/App/Mad.Designer.Windows/Mad.Designer.Windows.csproj`
- Create: `Windows/App/Mad.Designer.Windows/App.xaml`, `App.xaml.cs`
- Create: `Windows/App/Mad.Designer.Windows/MainWindow.xaml`, `MainWindow.xaml.cs`

**Interfaces:**
- Produces: a buildable `net10.0-windows` WPF project `Mad.Designer.Windows` whose assembly later tasks extend; the `.slnx` lists `Mad.Designer.Windows` and `Mad.Designer.Windows.Tests`.

- [ ] **Step 1: Write `Mad.Designer.Windows.csproj`**

`Microsoft.NET.Sdk`, `TargetFramework=net10.0-windows`, `UseWPF=true`, `OutputType=WinExe`, `Nullable=enable`, `ImplicitUsings=enable`, `RootNamespace=Mad.Designer.Windows`, `AssemblyName=Mad.Designer.Windows`, and a `ProjectReference` to `..\..\Client\Mad.Client\Mad.Client.csproj`. No `PackageReference`.

- [ ] **Step 2: Write a minimal `App.xaml`/`App.xaml.cs` and `MainWindow.xaml`/`MainWindow.xaml.cs`**

`App.xaml` declares `<Application ... StartupUri="MainWindow.xaml"/>`; `App.xaml.cs` is an empty `partial class App`. `MainWindow.xaml` is a `Window` (`Title="MAD Designer"`, `Height=780`, `Width=1240`, `MinHeight=620`, `MinWidth=960`) with a single placeholder `TextBlock`. `MainWindow.xaml.cs` is `InitializeComponent()` only.

- [ ] **Step 3: Write `Mad.Designer.Windows.slnx`**

Two `<Project Path=.../>` entries: `Mad.Designer.Windows/Mad.Designer.Windows.csproj` and `Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj` (the tests project is created in Task 2).

- [ ] **Step 4: Build the app and verify it compiles**

Run: `cd Windows/App && dotnet build Mad.Designer.Windows/Mad.Designer.Windows.csproj`
Expected: build succeeds, exit 0, `Mad.Designer.Windows.dll` produced.

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows.slnx Windows/App/Mad.Designer.Windows
git commit -s -m "Windows Phase 5: scaffold the WPF shell project"
```

## Task 2: MVVM infrastructure and the path resolver

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/Infrastructure/Mvvm.cs`
- Create: `Windows/App/Mad.Designer.Windows/Infrastructure/MadPathResolver.cs`
- Create: `Windows/App/Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj`
- Test: `Windows/App/Mad.Designer.Windows.Tests/MadPathResolverTests.cs`

**Interfaces:**
- Consumes: the app project from Task 1.
- Produces:
  - `ObservableObject` — `INotifyPropertyChanged`, `protected void OnPropertyChanged(string name)`, `protected bool Set<T>(ref T field, T value, [CallerMemberName] string name = "")`.
  - `RelayCommand : ICommand` — `RelayCommand(Action execute, Func<bool>? canExecute = null)`.
  - `AsyncRelayCommand : ICommand` — `AsyncRelayCommand(Func<Task> execute, Func<bool>? canExecute = null)`, exposes `bool IsRunning` and `Task ExecuteAsync()`; `CanExecute` is false while `IsRunning`.
  - `MadPathResolver` — `static string RepoRoot()`, `DefaultDocument()`, `MadExe()`, `GnustepBin()`, `LicensesRoot()` (all parameterless; they read `AppContext.BaseDirectory` and the `MAD_DOCUMENT`/`MAD_EXE`/`GNUSTEP_BIN`/`MAD_REPO_ROOT` env vars).

- [ ] **Step 1: Write the failing test `MadPathResolverTests`**

`DefaultDocument_ResolvesLondonFixture` asserts `MadPathResolver.DefaultDocument()` ends with `CLI/Fixtures/London.portable.mad` and the file exists. `MadExe_ResolvesBuiltEngine` asserts `MadPathResolver.MadExe()` ends with `Windows/Engine/build/mad.exe` and the file exists. `GnustepBin_ResolvesGnuStepDir` asserts `MadPathResolver.GnustepBin()` equals `C:\GNUstep\x64\Release\bin` (or the `GNUSTEP_BIN` override). `LicensesRoot_ResolvesThirdPartyLicenses` asserts `MadPathResolver.LicensesRoot()` ends with `ThirdParty/Licenses` and the directory exists.

- [ ] **Step 2: Run it to see it fail**

Run: `cd Windows/App && dotnet test Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj`
Expected: compilation failure — `MadPathResolver` does not exist.

- [ ] **Step 3: Implement `Mvvm.cs` and `MadPathResolver.cs`**

`RepoRoot()` walks `new DirectoryInfo(AppContext.BaseDirectory)` upward until `CLI/Fixtures/London.portable.mad` exists, else throws `DirectoryNotFoundException`. `DefaultDocument()` returns `MAD_DOCUMENT` if set, else `Path.Combine(RepoRoot(), "CLI", "Fixtures", "London.portable.mad")`. `MadExe()` returns `MAD_EXE` if set, else `Path.Combine(RepoRoot(), "Windows", "Engine", "build", "mad.exe")`. `GnustepBin()` returns `GNUSTEP_BIN` if set, else `C:\GNUstep\x64\Release\bin`. `LicensesRoot()` returns `MAD_REPO_ROOT`-based `ThirdParty/Licenses` if `MAD_REPO_ROOT` is set, else `Path.Combine(RepoRoot(), "ThirdParty", "Licenses")`.

- [ ] **Step 4: Run the test to see it pass**

Run: `cd Windows/App && dotnet test Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/Infrastructure Windows/App/Mad.Designer.Windows.Tests
git commit -s -m "Windows Phase 5: MVVM infrastructure and path resolver"
```

## Task 3: Schema models and the async engine service

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/Models/Schema.cs`
- Create: `Windows/App/Mad.Designer.Windows/Engine/EngineService.cs`
- Test: `Windows/App/Mad.Designer.Windows.Tests/EngineServiceTests.cs`

**Interfaces:**
- Consumes: `Mad.Client.MadEngineClient` (Start/CallOk/Shutdown/Dispose), `MadPathResolver`.
- Produces:
  - `record ReportColumn(string Key, string Name, string? Table, string? Type)`
  - `record SchemaField(string Name, string Type, bool PrimaryKey)`
  - `record SchemaTable(string Name, IReadOnlyList<SchemaField> Fields)`
  - `record OpenResult(int Handle, string Filename, string Driver)`
  - `record DescribeResult(string Driver, IReadOnlyList<ReportColumn> Columns, IReadOnlyList<SchemaTable> Tables)`
  - `record RefreshResult(int RowCount, double Elapsed)`
  - `sealed class EngineService : IAsyncDisposable` with `EngineService(string? madExe = null, string? gnustepBin = null)`, `bool IsRunning`, `int Pid`, and methods `Task<OpenResult> OpenAsync(string path, string? host = null, int? port = null, string? database = null)`, `Task<DescribeResult> DescribeAsync(int handle)`, `Task<string> QueryAsync(int handle)`, `Task<RefreshResult> RefreshAsync(int handle, int? rows = null, string? credentials = null)`, `Task<string> ExportAsync(int handle, string format)`, `Task ShutdownAsync()`, `ValueTask DisposeAsync()`.

- [ ] **Step 1: Write the failing test `EngineServiceTests`**

`LondonFlow_OpenDescribeQueryRefreshExport_Completes`: start `new EngineService()`, `OpenAsync(MadPathResolver.DefaultDocument())` → `Handle >= 0`, `Driver == "Sqlite 3"`; `DescribeAsync` → `Columns.Count == 21`, `Tables.Count == 11`, first column `Key == "\"Album0\".\"AlbumId\""`; `QueryAsync` → contains `"FROM"`; `RefreshAsync` → `RowCount == 76`; `ExportAsync(handle, "json")` → parses to `mad.report/1` with `76` rows; `ExportAsync(handle, "csv")` → splits to `78` lines. `DisposeAsync` then asserts the engine `Pid` no longer exists (poll `Process.GetProcessById` up to 5 s).

- [ ] **Step 2: Run it to see it fail**

Run: `cd Windows/App && dotnet test Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj --filter EngineServiceTests`
Expected: compilation failure — `EngineService`/`Schema` do not exist.

- [ ] **Step 3: Implement `Schema.cs` and `EngineService.cs`**

`EngineService` holds a lazily-started `MadEngineClient` and a `SemaphoreSlim _gate = new(1,1)`. Each method does `await _gate.WaitAsync(); try { await EnsureStartedAsync(); var result = await Task.Run(() => _client.CallOk(method, parameters)); return Parse(result); } finally { _gate.Release(); }`. `EnsureStartedAsync` calls `_client.Start()` once. Parsing reads `JsonElement` members into the records; `DescribeAsync` maps `columns` → `ReportColumn` and `tables[].fields[]` → `SchemaTable`/`SchemaField`; `ExportAsync` returns `result.GetProperty("data").GetString()`. `DisposeAsync` calls `ShutdownAsync()` then `_client.Dispose()`. Wrap `MadEngineException` from `Start` with a clear message naming the missing `mad.exe`.

- [ ] **Step 4: Run the test to see it pass**

Run: `cd Windows/App && dotnet test Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj --filter EngineServiceTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/Models/Schema.cs Windows/App/Mad.Designer.Windows/Engine/EngineService.cs Windows/App/Mad.Designer.Windows.Tests/EngineServiceTests.cs
git commit -s -m "Windows Phase 5: async engine service over mad serve"
```

## Task 4: `mad.report/1` parsing and the grid data table

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/Models/MadReport.cs`
- Test: `Windows/App/Mad.Designer.Windows.Tests/MadReportTests.cs`

**Interfaces:**
- Consumes: `ReportColumn` from Task 3.
- Produces:
  - `sealed class MadReport` with `string Format`, `string Driver`, `string Sql`, `int RowCount`, `IReadOnlyList<ReportColumn> Columns`, `IReadOnlyList<IReadOnlyDictionary<string, object?>> Rows`, `static MadReport Parse(string json)`, and `System.Data.DataTable ToDataTable()`.

- [ ] **Step 1: Write the failing tests `MadReportTests`**

`Parse_ExtractsColumnsAndRows` parses a small hand-written `mad.report/1` string (2 columns, 3 rows, one NULL, one number) and asserts `Columns.Count == 2`, `Rows.Count == 3`, a `null` value survives as `null`. `NullCells_BecomeDBNull` asserts `ToDataTable().Rows[0][key] == DBNull.Value` for a NULL cell. `DuplicateNames_KeyOnKey` parses columns `{"key":"\"A\".\"Id\"","name":"Id"}` and `{"key":"\"B\".\"Id\"","name":"Id"}` and asserts `ToDataTable()` builds 2 columns without throwing, captioned `Id`/`Id`, keyed `"A"."Id"`/`"B"."Id"`. `Parse_LondonExport_Has76Rows` uses a captured real export string (run `mad serve` export once and paste the `data` value) and asserts `Rows.Count == 76` and `Columns.Count == 21`.

- [ ] **Step 2: Run them to see them fail**

Run: `cd Windows/App && dotnet test Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj --filter MadReportTests`
Expected: compilation failure — `MadReport` does not exist.

- [ ] **Step 3: Implement `MadReport.cs`**

`Parse` uses `JsonDocument.Parse`; reads `format`, `document.driver`, `query.sql`, `query.rowCount`, `columns[]` (key/name/table/type), and `rows[]` (each an object keyed by column key; a value maps `String`→string, `Number`→`decimal`, `True`/`False`→bool, `Null`→null, else `GetRawText()`). `ToDataTable` adds one `typeof(object)` column per `Columns[i]` with `ColumnName = Key` and `Caption = Name`, then one row per `Rows[i]` where a missing/null cell becomes `DBNull.Value`.

- [ ] **Step 4: Run the tests to see them pass**

Run: `cd Windows/App && dotnet test Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj --filter MadReportTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/Models/MadReport.cs Windows/App/Mad.Designer.Windows.Tests/MadReportTests.cs
git commit -s -m "Windows Phase 5: parse mad.report/1 into the grid data table"
```

## Task 5: The document view model (open / refresh / export)

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/ViewModels/DocumentViewModel.cs`
- Test: `Windows/App/Mad.Designer.Windows.Tests/DocumentViewModelTests.cs`

**Interfaces:**
- Consumes: `EngineService`, `MadReport`, `ReportColumn`, `SchemaTable`, `ObservableObject`, `AsyncRelayCommand`.
- Produces:
  - `sealed class DocumentViewModel : ObservableObject` with `DocumentViewModel(EngineService engine)`, `bool IsBusy`, `string StatusText`, `string? ErrorText`, `string Driver`, `string FileName`, `string Sql`, `IReadOnlyList<ReportColumn> Columns`, `IReadOnlyList<SchemaTable> Tables`, `int RowCount`, `System.Data.DataView? DataView`, `bool HasDocument`, `AsyncRelayCommand RefreshCommand`, `AsyncRelayCommand ExportCsvCommand`, `AsyncRelayCommand ExportJsonCommand`, and methods `Task OpenAsync(string path)`, `Task RefreshAsync()`, `Task ExportAsync(string format, string outPath)`.

- [ ] **Step 1: Write the failing tests `DocumentViewModelTests`**

`OpenRefreshExport_London_Completes`: `OpenAsync(London)` → `HasDocument` true, `Columns.Count == 21`, `Tables.Count == 11`, `Sql` contains `"FROM"`; `RefreshAsync()` → `RowCount == 76`, `DataView!.Count == 76`; `ExportAsync("csv", temp)` → file exists with `78` lines; `ExportAsync("json", temp)` → parses to `mad.report/1` with `76` rows. `Open_BadDocument_SetsErrorAndStaysUsable`: `OpenAsync("no-such.mad")` → `HasDocument` false, `ErrorText` non-null and non-empty, `IsBusy` false, and the VM does not throw.

- [ ] **Step 2: Run them to see them fail**

Run: `cd Windows/App && dotnet test Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj --filter DocumentViewModelTests`
Expected: compilation failure — `DocumentViewModel` does not exist.

- [ ] **Step 3: Implement `DocumentViewModel.cs`**

`OpenAsync` sets `IsBusy`, calls `engine.OpenAsync` then `DescribeAsync` then `QueryAsync`, populates state, and sets `StatusText = "Opened <filename>"`. `RefreshAsync` sets `IsBusy`, calls `engine.RefreshAsync`, then `engine.ExportAsync(handle, "json")` → `MadReport.Parse` → `DataView = report.ToDataTable().DefaultView`, sets `RowCount`, `StatusText = "Rendered N cached rows"`. `ExportAsync(format, outPath)` calls `engine.ExportAsync(handle, format)` and `File.WriteAllText(outPath, data)`. Every method wraps the engine call in `try/catch (MadEngineException e)` → sets `ErrorText = e.Message` (no rethrow), clears `ErrorText` on success, and resets `IsBusy = false` in `finally`. `RefreshCommand`/`ExportCsvCommand`/`ExportJsonCommand` are `AsyncRelayCommand`s delegating to `RefreshAsync`/`ExportAsync("csv", ...)`/`ExportAsync("json", ...)`; the two export commands write to a temp path by default (the View supplies a save dialog later). Guard `ExportAsync`/`RefreshAsync` with `HasDocument`.

- [ ] **Step 4: Run the tests to see them pass**

Run: `cd Windows/App && dotnet test Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj --filter DocumentViewModelTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/ViewModels/DocumentViewModel.cs Windows/App/Mad.Designer.Windows.Tests/DocumentViewModelTests.cs
git commit -s -m "Windows Phase 5: document view model (open/refresh/export)"
```

## Task 6: The main window and the three workspaces

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/ViewModels/MainWindowViewModel.cs`
- Create: `Windows/App/Mad.Designer.Windows/Views/QueryView.xaml` (+`.cs`), `DesignerView.xaml` (+`.cs`), `ViewerView.xaml` (+`.cs`)
- Modify: `Windows/App/Mad.Designer.Windows/MainWindow.xaml` (+`.cs`), `App.xaml.cs`

**Interfaces:**
- Consumes: `DocumentViewModel`, `ObservableObject`, `RelayCommand`.
- Produces:
  - `sealed class MainWindowViewModel : ObservableObject` with `DocumentViewModel Document`, `Workspace SelectedWorkspace` (`enum Workspace { Query, Designer, Viewer }`), `ICommand OpenAboutCommand`, `ICommand OpenDocumentCommand`, `Task InitializeAsync()` (auto-opens `MadPathResolver.DefaultDocument()`).

- [ ] **Step 1: Implement `MainWindowViewModel`**

`InitializeAsync` awaits `Document.OpenAsync(MadPathResolver.DefaultDocument())`, swallowing `MadEngineException` (leaving `ErrorText` set). `OpenDocumentCommand` uses a `Microsoft.Win32.OpenFileDialog` (filter `.mad`) and calls `Document.OpenAsync(path)`; it is a `RelayCommand` whose `Execute` fire-and-forgets the async open. `OpenAboutCommand` is a `RelayCommand` whose handler is wired in `MainWindow.xaml.cs` (opens `new AboutWindow { DataContext = new AboutViewModel() }`).

- [ ] **Step 2: Build the three workspace views**

`QueryView.xaml`: a two-column `Grid` — left a `TreeView` bound to `Tables` (table name → fields), right a read-only monospace `TextBox` bound to `Sql`. `DesignerView.xaml`: a centered placeholder `TextBlock` ("The report designer canvas arrives in Phase 6.") plus a `ListBox` of `Columns` names. `ViewerView.xaml`: a top `StackPanel` with `Refresh` (bound `RefreshCommand`), `Export CSV` (`ExportCsvCommand`), `Export JSON` (`ExportJsonCommand`), and a `DataGrid` (`ItemsSource="{Binding DataView}"`, `AutoGenerateColumns="True"`) with a status `TextBlock` bound to `StatusText` and a `ProgressBar` bound to `IsBusy`.

- [ ] **Step 3: Wire `MainWindow.xaml`**

A `TabControl` (`SelectedIndex` bound to `SelectedWorkspace`) with three `TabItem`s — "MAD Query" (`QueryView`), "MAD Designer" (`DesignerView`), "MAD Viewer" (`ViewerView`) — a bottom status bar (busy + status), and a menu/toolbar with `Open…` and `About`. `MainWindow.xaml.cs` sets `DataContext = new MainWindowViewModel(...)` and, in `Loaded`, awaits `vm.InitializeAsync()`.

- [ ] **Step 4: Build and verify**

Run: `cd Windows/App && dotnet build Mad.Designer.Windows/Mad.Designer.Windows.csproj`
Expected: XAML compiles, build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/ViewModels/MainWindowViewModel.cs Windows/App/Mad.Designer.Windows/Views Windows/App/Mad.Designer.Windows/MainWindow.xaml Windows/App/Mad.Designer.Windows/MainWindow.xaml.cs Windows/App/Mad.Designer.Windows/App.xaml.cs
git commit -s -m "Windows Phase 5: main window and three-workspace frame"
```

## Task 7: The About window and the Windows licence register

**Files:**
- Create: `Windows/App/Mad.Designer.Windows/Models/WindowsLicenseRegistry.cs`
- Create: `Windows/App/Mad.Designer.Windows/ViewModels/AboutViewModel.cs`
- Create: `Windows/App/Mad.Designer.Windows/Views/AboutWindow.xaml` (+`.cs`)
- Test: `Windows/App/Mad.Designer.Windows.Tests/WindowsLicenseRegistryTests.cs`

**Interfaces:**
- Consumes: `MadPathResolver.LicensesRoot`, `ObservableObject`.
- Produces:
  - `record WindowsComponent(string Name, string License, string Details, string LicenseTitle, string LicensePath)` (LicensePath relative to `ThirdParty/Licenses`).
  - `static class WindowsLicenseRegistry` with `IReadOnlyList<WindowsComponent> Components`, `string RelinkOffer`, `string OverviewText`, `string BrandNotice`, `string? ReadLicenseText(WindowsComponent c)`.
  - `sealed class AboutViewModel : ObservableObject` with `string Version`, `string Overview`, `string LicenseNotice`, `IReadOnlyList<WindowsComponent> Components`, `WindowsComponent? SelectedComponent`, `string SelectedAcknowledgement`.

- [ ] **Step 1: Write the failing tests `WindowsLicenseRegistryTests`**

`Components_AreTheWindowsSet_NotApple`: `Components.Count == 14`, contains `GNUstep Base` (license `LGPL-2.1-or-later`) and `MariaDB Connector/C`, and does **not** contain `zint`, `libpng`, or `Font Awesome`. `EveryComponent_LicenseFileExists`: for each component, `ReadLicenseText(c)` is non-null/non-empty. `MissingLicenseFile_ReturnsNull_AboutHandlesIt`: a fabricated `WindowsComponent` with a bogus `LicensePath` yields `ReadLicenseText` == null. `RelinkOffer_MentionsWindowsEngine`: `RelinkOffer` is non-empty and contains `"Windows engine"` and `"relink"`.

- [ ] **Step 2: Run them to see them fail**

Run: `cd Windows/App && dotnet test Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj --filter WindowsLicenseRegistryTests`
Expected: compilation failure — `WindowsLicenseRegistry` does not exist.

- [ ] **Step 3: Implement `WindowsLicenseRegistry.cs`**

`Components` hardcodes the 14 Windows components with `LicensePath` values: `Windows/LGPL-2.1.txt` (GNUstep Base, libiconv, gnustep-corebase), `Windows/libobjc2-MIT.txt`, `Windows/libdispatch-Apache-2.0-with-Swift-exception.txt`, `Windows/libffi-MIT.txt`, and the shared `sqlite3-LICENSE.md`, `zlib-LICENSE.txt`, `bzip2-LICENSE.txt`, `libarchive-BSD-2-Clause.txt`, `openssl-Apache-2.0.txt`, `LGPL-3.0.txt` (FreeTDS, MariaDB Connector/C), `postgres-LICENSE.txt`. `ReadLicenseText` resolves `Path.Combine(LicensesRoot(), c.LicensePath)` and reads UTF-8 (null if missing). `RelinkOffer` extracts the `## The relink offer (the native Windows engine)` section from `ThirdParty/Licenses/README.md` (heading through the next `## ` heading); falls back to a hardcoded copy of that paragraph if the file is unreadable. `OverviewText` and `BrandNotice` are English constants mirroring the Mac About content, Windows-correct (PDF deferred on Windows).

- [ ] **Step 4: Implement `AboutViewModel.cs` and `AboutWindow.xaml`**

`AboutViewModel` composes `Overview = OverviewText`, `LicenseNotice = BrandNotice + NOTICE + RelinkOffer + MIT + LGPL-2.1 + LGPL-3.0` texts (each read via `ReadLicenseText`/`NOTICE`/root `LICENSE`), and `Components`; `SelectedAcknowledgement` updates on `SelectedComponent` change to that component's `Details` + licence text (with a `"(license text not found)"` placeholder). `AboutWindow.xaml`: a header (title, `Version`, copyright) and a `TabControl` — Overview (read-only `TextBox`), License & Notice (read-only `TextBox`), Acknowledgements (`ListBox` of components bound to `Components` + a `TextBox` bound to `SelectedAcknowledgement`). `MainWindow` opens it via the `OpenAboutCommand` seam from Task 6.

- [ ] **Step 5: Run the tests and build to see them pass**

Run: `cd Windows/App && dotnet test Mad.Designer.Windows.Tests/Mad.Designer.Windows.Tests.csproj --filter WindowsLicenseRegistryTests && dotnet build Mad.Designer.Windows/Mad.Designer.Windows.csproj`
Expected: PASS, build succeeds.

- [ ] **Step 6: Commit**

```bash
git add Windows/App/Mad.Designer.Windows/Models/WindowsLicenseRegistry.cs Windows/App/Mad.Designer.Windows/ViewModels/AboutViewModel.cs Windows/App/Mad.Designer.Windows/Views/AboutWindow.xaml Windows/App/Mad.Designer.Windows/Views/AboutWindow.xaml.cs Windows/App/Mad.Designer.Windows.Tests/WindowsLicenseRegistryTests.cs
git commit -s -m "Windows Phase 5: About window and Windows licence register"
```

## Task 8: Docs and final verification

**Files:**
- Modify: `Windows/README.md`, `Windows/AGENTS.md`, `docs/project/MAD_WINDOWS.md`

**Interfaces:**
- Consumes: the complete app from Tasks 1–7.

- [ ] **Step 1: Document the app**

Add a `## The WPF shell (Windows/App)` section to `Windows/README.md` (build/run/test commands, the auto-open behavior, the About window). Update `Windows/AGENTS.md` `App/` bullet to describe the app tree and its test project. Add a `## 6e. Phase 5 — the WPF shell proof` section to `docs/project/MAD_WINDOWS.md` recording the architecture decisions (reuse of `Mad.Client`, `EngineService` semaphore, hand-rolled MVVM, `DataTable` grid, headless acceptance, auto-open London).

- [ ] **Step 2: Run the full verification**

Run: `cd Windows/Client && dotnet test Mad.Client.Tests` (Phase 4 regression) and `cd Windows/App && dotnet test Mad.Designer.Windows.Tests` (Phase 5 acceptance) and `cd Windows/App && dotnet build Mad.Designer.Windows/Mad.Designer.Windows.csproj`.
Expected: all green; the app tests print the London flow (21/11, 76 rows, 78 CSV lines).

- [ ] **Step 3: Commit**

```bash
git add Windows/README.md Windows/AGENTS.md docs/project/MAD_WINDOWS.md
git commit -s -m "Windows Phase 5: document the WPF shell"
```

- [ ] **Step 4: Write the phase summary**

Write `C:\dev\mad-win-reports\phase5-summary.md` (what was built, the architecture calls, the verification output, and the merge-hold note that PR #32 stays draft).
