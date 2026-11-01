# Agent Prompt: Missing/Unreachable Data Source Control Flow, Server Refresh Credentials, and Connection UI Overhaul

> **Instructions for the Coding Agent:**
> You are working on the `fix/datasource-and-connection-ux` branch of `/Users/michael/Desktop/Reports`.
> Read this entire document carefully, inspect the referenced source files, present a concise implementation plan to the user if any design question needs confirmation (per `AGENTS.md`), implement all four parts below, run all verification gates, and prepare the updated macOS release build.
>
> **Important Product Constraint:**
> Do **not** bundle sample reports (`London.mad`, `Music.mad`) or `chinook.sqlite3` inside `MAD Designer.app` on macOS, and do **not** add sample-downloading UI. The native macOS app uses `NSDocument` (not the iOS file explorer), and `London.mad` / `Music.mad` have already been removed from the GitHub Release download area and READMEs. Focus strictly on making the application's data-source error handling, reconnection flow, credential plumbing, and connection dialog rock-solid across all four database drivers (**SQLite**, **MySQL**, **Microsoft SQL Server**, and **PostgreSQL**).

---

## 1. Root-Cause Bugs You Must Fix

An audit of `MADSqlite3`, `MAD`, `Mac/`, and `MADDesigner/` uncovered five concrete defects that break the user workflow when refreshing reports or connecting to databases:

### Bug 1 (CRITICAL): macOS Refresh Chain Never Supplies Credentials to `MADOperationRefresh`
* **Where:**
  * [`Mac/Source/MADMacDocument.m:203-257`](../../Mac/Source/MADMacDocument.m#L203-L257) (`-refreshDataWithPassword:completion:`)
  * [`MAD/Source/MADOperationRefresh.m:79-102`](../../MAD/Source/MADOperationRefresh.m#L79-L102) (`-execute`)
* **What happens:**
  In `MADMacDocument -refreshDataWithPassword:completion:`, `refreshOp` (`MADOperationRefresh`) is added to `_refreshQueue` with only two dependencies: `initTable` (`MADOperationRefreshInitializeMainDataTable`) and `initOp` (`MADOperationRefreshInitialize`). Neither conforms to `MADOperationHoldsCredentialsProtocol`.
  Whenever `[document.database.databaseConnection requiresCredentials]` is `YES` (which is true for **MySQL, SQL Server, and PostgreSQL**), `MADOperationRefresh -execute` (`MADOperationRefresh.m:81-100`) scans `self.dependencies` for an operation conforming to `MADOperationHoldsCredentialsProtocol`. Finding none, it **unconditionally aborts with `errMissingCredentials` (code 3, `"Credentials required"`)**.
* **Consequence:** Refreshing **any** MySQL, SQL Server, or PostgreSQL report in `MAD Viewer` on macOS currently fails 100% of the time, even when the server is online and credentials are in the Keychain.
* **Reference implementations of `MADOperationHoldsCredentialsProtocol`:**
  * [`CLI/Source/MADCLIDocument.m:46-55,127-132`](../../CLI/Source/MADCLIDocument.m#L46-L55) (`MADCLICredentialsOperation`)
  * [`MADDesigner/Source/MADOperationRefreshReload.m:75-90`](../../MADDesigner/Source/MADOperationRefreshReload.m#L75-L90) (`MADOperationGetCredentials`)

### Bug 2 (CRITICAL): macOS `MADMacDocument` Discards the Real Driver Error on Refresh Failure
* **Where:** [`Mac/Source/MADMacDocument.m:239-245`](../../Mac/Source/MADMacDocument.m#L239-L245)
* **What happens:**
  When `refreshOp` finishes with `doc.refreshed == NO`, `MADMacDocument` ignores `refreshOp.errors.firstObject` and substitutes a hardcoded generic error:
  `"Could not refresh report data. Check the query and database connection settings."`
* **Consequence:** Neither the user nor `MADMacViewerViewController` can distinguish *why* the refresh failed (missing SQLite file vs. missing credentials vs. authentication failure vs. unreachable host/port vs. SQL error).

### Bug 3 (CRITICAL): Keychain Key Mismatch Between Document Creation, Storage, and Refresh
* **Where:**
  * [`Mac/Source/MADMacConnectionWindowController.m:368-370`](../../Mac/Source/MADMacConnectionWindowController.m#L368-L370)
  * [`Mac/Source/MADMacDocument.m:218-221`](../../Mac/Source/MADMacDocument.m#L218-L221)
  * [`MAD/Source/rptq/RptqDocument+Extras.m:366-437`](../../MAD/Source/rptq/RptqDocument+Extras.m#L366-L437) (`-storeDatabaseConnectionDefination:forManagedObjectContext:`)
  * [`MADDesigner/Source/MADOperationGetCredentials.m:86-88`](../../MADDesigner/Source/MADOperationGetCredentials.m#L86-L88)
* **What happens:**
  * `MADMacConnectionWindowController.m:369` saves credentials under `conn.identifier` (which is the static driver string `@"MySQL"`, `@"TDS"`, or `@"PostgreSQL"`, colliding across all servers of the same type).
  * `MADMacDocument.m:219` tries to save `passwordOverride` under `credRow.key`, which is `nil` because `-storeDatabaseConnectionDefination:forManagedObjectContext:` never sets `credentals.key`.
  * `MADOperationGetCredentials.m:86-88` (on iOS) derives the Keychain keys from `databaseConnection.connectionString` via `[MADKeyChain newKeyForUsernameWithMainKey:key]` and `[MADKeyChain newKeyForPasswordWithMainKey:key]` (or `[MADKeyChain saveUsername:andPassword:forKey:databaseConnection.connectionString]`).

### Bug 4 (CRITICAL): `MADDatabaseSqlite3` Opens Missing Source Databases with `SQLITE_OPEN_CREATE`
* **Where:**
  * [`MADSqlite3/Source/MADDatabaseSqlite3.m:234-274,292-300`](../../MADSqlite3/Source/MADDatabaseSqlite3.m#L234-L300)
  * [`MADSqlite3/Source/MADDatabaseConnectionSqlite3.m:63-91`](../../MADSqlite3/Source/MADDatabaseConnectionSqlite3.m#L63-L91)
* **What happens:**
  1. When a SQLite `.mad` document is opened and its `.sqlite3` file is missing or moved, `MADDatabaseConnectionSqlite3 +newDatabaseConnection:` falls back to returning `dbUrl` pointing to a non-existent path in `Application Support`.
  2. When the user clicks **Refresh**, `MADDatabaseSqlite3 -connectWithConnection:credentals:connectionError:` (`:292-300`) calls `[self openDatabase]`, which calls `sqlite3_open_v2` with `SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE` (`:235`).
  3. **Because `SQLITE_OPEN_CREATE` is passed, SQLite silently creates an empty, 0-byte `.sqlite3` file on disk!**
  4. `-connectWithConnection:credentals:connectionError:` never writes to `connectionError` and returns `self` as if the connection succeeded.
  5. Next, `-executeSQL:` runs `SELECT ...` against the empty 0-byte database, which fails with `SQLITE_ERROR: no such table: <TableName>`.
  6. Worse: because the 0-byte `.sqlite3` file now exists on disk in `Application Support`, every subsequent `fileExistsAtPath:` check believes the database file exists!
  7. Furthermore, if the parent directory does not exist, `NSAssert(databaseOpen, ...)` at `MADDatabaseSqlite3.m:249` crashes in Debug builds instead of populating `connectionError` and returning `nil`.

### Bug 5: "New Report from Database Connection" UI (`MADMacConnectionWindowController`) & Lack of Reconnect UI
* **Where:** [`Mac/Source/MADMacConnectionWindowController.m`](../../Mac/Source/MADMacConnectionWindowController.m)
* **Problems:**
  1. **Layout & Visual Design:** Uses manual `NSMakeRect` coordinates in a static `540×420` window where **all controls for every database type are stacked on screen at the same time** (SQLite file path + Browse button, Host, Port, SQL Server Instance, Database Name, Username, Password), merely toggling `.enabled = YES/NO`. When SQLite is selected, 6 server text fields sit disabled below it; when PostgreSQL or MySQL is selected, the SQLite file row and SQL Server instance row sit disabled on screen.
  2. **Create-only:** It can only create a *new* document (`File -> New Document…`). There is no way to open Connection Settings for an *existing* `.mad` document to point it at a relocated `.sqlite3` file or update a database server's host, port, instance, database name, or credentials.
  3. **Copies SQLite files into Application Support unconditionally (`:243-253`):** When creating a SQLite report, `MADMacConnectionWindowController` copies the user's `.sqlite3` file into `Application Support` rather than referencing the user's chosen file path directly.

---

## 2. Required Implementation Plan (Parts A–D)

### Part A: Safe SQLite Source Opening & Smart Path Resolution (`MADSqlite3` + `MAD`)
1. **Never create a 0-byte file when connecting to a source SQLite database:**
   * In [`MADSqlite3/Source/MADDatabaseSqlite3.m`](../../MADSqlite3/Source/MADDatabaseSqlite3.m#L234-L300), `-connectWithConnection:credentals:connectionError:` must verify that the target SQLite file at `self.databaseConnection.databaseUrl.path` exists and is non-empty (file size `> 0`) before opening, and open without creating a blank file if missing.
   * If a 0-byte file exists at that path (left over from the old `SQLITE_OPEN_CREATE` bug), remove the 0-byte file and treat it as missing.
   * When the file is missing or cannot be opened, do **not** trip `NSAssert` in `-connectWithConnection:credentals:connectionError:`; populate `*error` with a clear, structured `NSError` (e.g., domain `MADDatabaseSqlite3ErrorDomain` / `NSStringFromClass([self class])`, distinct code for missing file, with a clear `NSLocalizedDescriptionKey` naming the missing file and `NSLocalizedFailureReasonErrorKey` naming the path) and return `nil`.
   * *(Note: Make sure internal cache databases in `MADDataTableFast` / `MADArrayCaching` that legitimately create new cache files still work as before.)*
2. **Smart SQLite Path Resolution:**
   * In [`MADSqlite3/Source/MADDatabaseConnectionSqlite3.m`](../../MADSqlite3/Source/MADDatabaseConnectionSqlite3.m#L63-L91) (and in `MADOperationRefreshInitialize` / `MADHeadlessDocument` / `MADocument` where `document.fileURL` is known):
   * Resolve a SQLite connection's file URL by checking these locations in order for an **existing, non-empty (`size > 0`)** file:
     1. Exact path in `credentals.host` or `credentals.database` (if absolute and non-empty).
     2. **Sibling file in the same directory as the `.mad` document** (`[document.fileURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:credentals.database.lastPathComponent]`).
     3. Local Application Support directory (`~/Library/Application Support/com.thomason.report.mac/<filename>` and the group identifier directory).
     4. App bundle resource (`[[NSBundle mainBundle] URLForResource:withExtension:]`, used on iOS).
   * Add a helper method on `MADMacDocument` / `MADHeadlessDocument` to update a document's database connection (`RptqDatabaseCredentals` + `document.database`) when the user selects a new `.sqlite3` file or updates server connection parameters.

### Part B: Fix Server Credentials & Error Propagation on Refresh (`MADMacDocument`)
1. **Supply Credentials to `MADOperationRefresh`:**
   * In [`Mac/Source/MADMacDocument.m:203-257`](../../Mac/Source/MADMacDocument.m#L203-L257) (`-refreshDataWithPassword:completion:`), ensure `doc.database` is initialized from `RptqDatabaseCredentals` if `nil`, and if `[doc.database.databaseConnection requiresCredentials]` is `YES`:
     * Look up saved username/password from `MADKeyChain` using a consistent key derived from `doc.database.databaseConnection.connectionString` (with fallback to `credRow.key` or `conn.identifier` so previously saved credentials still resolve).
     * If `passwordOverride` (or a credential override) is provided, use it and optionally save it to `MADKeyChain`.
     * Attach a `MADOperation <MADOperationHoldsCredentialsProtocol>` dependency (like `MADCLICredentialsOperation` in `CLI/Source/MADCLIDocument.m:46-55`) to `refreshOp` when credentials are available.
2. **Propagate Real Errors:**
   * In `refreshOp.completionBlock` (`MADMacDocument.m:235-252`), extract `refreshOp.errors.firstObject` and pass that real `NSError *` to `completion(ok, err)` instead of overwriting it with the generic string.

### Part C: Interactive Control Flow When Data Source Is Missing, Unreachable, or Needs Credentials (`MADMacViewerViewController` & `MADDesigner` iOS)
When a user clicks **Refresh** (or **Export** / **Print** when unrefreshed) in [`Mac/Source/MADMacViewerViewController.m`](../../Mac/Source/MADMacViewerViewController.m#L411-L435) and refresh fails, provide a clear, native recovery workflow instead of leaving them at a dead end:
1. **Case 1 — SQLite Database File Not Found (`MADDatabaseTypeSqlite3`):**
   * Present a document-modal sheet (`NSAlert` or `NSOpenPanel`):
     * **Title:** `Database File “<filename>” Could Not Be Found`
     * **Informative Text:** Shows the expected path and asks the user to locate the SQLite database file on their Mac.
     * **Buttons:** **`Locate File…`** (default) and **`Cancel`**.
   * Clicking **`Locate File…`** opens an `NSOpenPanel` (allowing `.sqlite3`, `.sqlite`, `.db`, or any SQLite file). When the user picks a file:
     * Update the document's `RptqDatabaseCredentals` (`host` = selected path, `dbname` = selected filename) and `headlessDocument.database`, mark the document dirty (`updateChangeCount:NSChangeDone`), and **immediately re-run the refresh**!
2. **Case 2 — Server Database Needs Credentials or Authentication Failed (`MADDatabaseTypeMySQL`, `TDS`, `Postgres`):**
   * If credentials are missing (`errMissingCredentials`) or authentication fails, present the Connection / Credentials sheet pre-filled with the document's driver, host, port, database name, and username so the user can enter their password (with a "Save password in Keychain" checkbox) or adjust the connection details and click **Connect & Refresh**.
3. **Case 3 — Server Database Unreachable / Network Error / SQL Error:**
   * Present a document-modal `NSAlert` showing the **actual error description and failure reason** from the driver (e.g. connection refused, host unreachable, unknown database, or SQL error), with action buttons:
     * **`Connection Settings…`** — opens the Connection Settings sheet (Part D) pre-populated with the document's current connection so the user can point it to the right host/port/database, test the connection, and refresh.
     * **`Retry`** — retries the refresh.
     * **`Cancel`** — dismisses the alert and keeps the error summary visible in the bottom status bar.
4. **Menu Bar & Toolbar Access at Any Time:**
   * Add a **`Database Connection…`** menu item under the `File` menu in [`Mac/Source/MADMacAppDelegate.m`](../../Mac/Source/MADMacAppDelegate.m#L80-L95) (and/or a button in the `MAD Query` workspace toolbar) that opens the Connection Settings sheet for the active `MADMacDocument` at any time.
5. **iOS Audit (`MADDesigner`):**
   * Check [`MADDesigner/Source/MADViewerController.m:747-776`](../../MADDesigner/Source/MADViewerController.m#L747-L776):
     * Ensure the error alert displays both `error.localizedDescription` and `error.localizedFailureReason` (when non-empty and distinct) so SQLite missing-file errors and SQL Server / MySQL / PostgreSQL connection errors show the specific reason rather than just `"Connect Failed"` or `"Error"`.

### Part D: Overhaul `MADMacConnectionWindowController` ("New Report from Database Connection" & "Edit Connection Settings")
Redesign [`Mac/Source/MADMacConnectionWindowController.m`](../../Mac/Source/MADMacConnectionWindowController.m) so it looks and feels like a polished, modern native macOS dialog and supports both creating a new document and editing an existing document's connection:
1. **Dynamic, Driver-Specific Form Layout (Hide Irrelevant Controls!):**
   * Do **not** show SQLite controls when a server driver is selected, do **not** show server controls when SQLite is selected, and do **not** show "Server Instance" unless Microsoft SQL Server is selected.
   * Dynamically swap or collapse the form rows (and smoothly resize the window/sheet height to fit) based on the selected driver:
     * **SQLite:**
       * Clean file selection card/row showing the selected `.sqlite3` / `.db` file path (or a placeholder), a **`Choose File…`** button, and file status indicator (exists / file size).
       * Do **not** copy the user's `.sqlite3` file into `Application Support` on creation (`MADMacConnectionWindowController.m:243-253`); store the actual selected `NSURL` in `MADDatabaseConnectionSqlite3` (`RptqDocument+Extras.m:391-399` already stores `sqliteURL.path` in `credentals.host` and `sqliteURL.path.lastPathComponent` in `credentals.dbname`).
     * **MySQL / PostgreSQL:**
       * Host / Address (`127.0.0.1` placeholder/default) and Port (`3306` for MySQL, `5432` for PostgreSQL) on a clean two-column row.
       * Database Name.
       * Username and Password, plus a **"Save password in Keychain"** checkbox (`NSButton` with `NSButtonTypeSwitch`).
     * **Microsoft SQL Server:**
       * Same as MySQL/PostgreSQL (Port `1433`), plus the optional **Server Instance** field.
2. **Visual Polish:**
   * Add a clean header banner with the selected database driver's icon/badge and title, a framed form group (`NSBox` or clean macOS form grid with right-aligned labels and proper vertical rhythm), a proper `nextKeyView` tab ring across all visible text fields, and a clear status row with spinner and status icon.
3. **Support Both Modes:**
   * **Mode 1: New Document (`File -> New Document…`):**
     * Buttons: `Cancel`, `Test Connection`, `Create Document…` (default `\r`).
   * **Mode 2: Edit / Reconnect Document (`File -> Database Connection…` or triggered from a failed Refresh):**
     * Runs as a window or document-modal sheet pre-populated with the open `MADMacDocument`'s current connection settings (`RptqDatabaseCredentals`).
     * Buttons: `Cancel`, `Test Connection`, `Save & Refresh` (default `\r`).
     * Updates the open document's `RptqDatabaseCredentals` and `headlessDocument.database`, saves credentials to `MADKeyChain` if checked, marks the document dirty, closes the sheet, and triggers a refresh.

---

## 3. Key Files Reference

| Component | File Path | Notes |
|---|---|---|
| SQLite URL Resolution | [`MADSqlite3/Source/MADDatabaseConnectionSqlite3.m`](../../MADSqlite3/Source/MADDatabaseConnectionSqlite3.m#L63-L91) | `+newDatabaseConnection:` path resolution order. |
| SQLite Open & Error Handling | [`MADSqlite3/Source/MADDatabaseSqlite3.m`](../../MADSqlite3/Source/MADDatabaseSqlite3.m#L234-L300) | Fix `SQLITE_OPEN_CREATE` on missing source DB (`:235`), remove `NSAssert` on open failure (`:249`), and populate `connectionError` in `-connectWithConnection:credentals:connectionError:` (`:292-300`). |
| Shared Refresh Operation | [`MAD/Source/MADOperationRefresh.m`](../../MAD/Source/MADOperationRefresh.m#L60-L173) | Reads `MADOperationHoldsCredentialsProtocol` from `self.dependencies` (`:79-102`) and calls `connectWithConnection:credentals:connectionError:` (`:106-114`). |
| Shared Refresh Initializer | [`MAD/Source/MADOperationRefreshInitialize.m`](../../MAD/Source/MADOperationRefreshInitialize.m#L72-L129) | Lazy `document.database` initialization from `RptqDatabaseCredentals` (`:100-104`). |
| Stored Connection Model | [`MAD/Source/rptq/RptqDocument+Extras.m`](../../MAD/Source/rptq/RptqDocument+Extras.m#L366-L437) | `-storeDatabaseConnectionDefination:forManagedObjectContext:`. |
| macOS Document & Refresh | [`Mac/Source/MADMacDocument.h`](../../Mac/Source/MADMacDocument.h), [`Mac/Source/MADMacDocument.m`](../../Mac/Source/MADMacDocument.m#L203-L257) | Add credential operation dependency, unify Keychain lookup, propagate `refreshOp.errors.firstObject`, and add method to update connection settings. |
| macOS Viewer UI | [`Mac/Source/MADMacViewerViewController.m`](../../Mac/Source/MADMacViewerViewController.m#L411-L474) | Add interactive error recovery flow in `-refreshReportAction:` (Locate SQLite file / Enter Credentials / Edit Connection Settings). |
| macOS Connection Controller | [`Mac/Source/MADMacConnectionWindowController.h`](../../Mac/Source/MADMacConnectionWindowController.h), [`Mac/Source/MADMacConnectionWindowController.m`](../../Mac/Source/MADMacConnectionWindowController.m) | Overhaul UI to dynamically show only driver-relevant fields, fix Keychain key, stop copying SQLite files to App Support, and add Edit/Reconnect mode. |
| macOS App Delegate | [`Mac/Source/MADMacAppDelegate.m`](../../Mac/Source/MADMacAppDelegate.m#L80-L95) | Add `Database Connection…` menu item under `File`. |
| macOS Smoke Test | [`Mac/Tests/MADMacSmokeTest.m`](../../Mac/Tests/MADMacSmokeTest.m#L68-L142) | Add tests for: (1) missing SQLite file returns error and does NOT create 0-byte file; (2) sibling `.sqlite3` resolution next to `.mad` file; (3) server credential dependency in `MADMacDocument`; (4) connection controller dynamic field visibility and edit mode. |
| iOS Viewer Alert | [`MADDesigner/Source/MADViewerController.m`](../../MADDesigner/Source/MADViewerController.m#L747-L776) | Include `error.localizedFailureReason` in the error alert message when present. |

---

## 4. Verification & Release Checklist

Before finishing, you **must** run and pass all of the following verification gates:

1. **macOS Build, Smoke Test, and Packaging:**
   ```sh
   ./Mac/build.sh --smoke-test --package
   ```
2. **iOS Simulator Unit Test Suites (`MADSqlite3`, `MAD`, `MADDesignerUnitTests`):**
   ```sh
   xcodebuild test -workspace Reports.xcworkspace -scheme MADSqlite3 \
     -destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
     -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci

   xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
     -destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
     -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
   ```
3. **Linux Headless Build & Test Suite (required whenever `MADSqlite3` or `MAD` files change):**
   ```sh
   ./Linux/build.sh
   ```
4. **Update `docs/project/BUGS.md` / `docs/project/BUGS_FIXED.md`:**
   Record the fixed defects (`MADDatabaseSqlite3` `SQLITE_OPEN_CREATE` on missing source DB, `MADMacDocument` missing `MADOperationHoldsCredentialsProtocol` dependency) per `AGENTS.md`.
5. **Follow the `AGENTS.md` PR & Approval Gate Flow:**
   * Commit all work with `git commit -s` (DCO sign-off).
   * Present a summary of the changes to the user and get approval before pushing the branch, merging the PR, and uploading the rebuilt `MAD-Designer-macOS.dmg` / `MAD-Designer-macOS.zip` to the `v9.1.0-macos` GitHub Release (and updating the SHA-256 in `mthomason/homebrew-tap`).
