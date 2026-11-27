# Sample reports

Self-contained `.mad` reports for MAD Designer.  They are small, portable (the
portable SQLite store, no legacy Core Data), and built through the app's own
store and archive writers.

Open them with **File > Open…** in MAD Designer for macOS, or copy the whole
`Reports` folder and open a sample from the copy.  Keep `chinook.sqlite3` beside
the `.mad` files: a SQLite sample resolves its database by name next to the
document, so the folder is portable as a unit.

| File | Type | Data | What it demonstrates | Verified |
|---|---|---|---|---|
| `Reports/Chinook-Standard.mad` | Standard Report | bundled Chinook SQLite | one table, column headers, a detail band, a multi-page report | 275 rows, 8 pages |
| `Reports/Chinook-Grouped.mad` | Standard Report | bundled Chinook SQLite | a query grouping with group header and footer bands, 59 customer groups, many pages | 412 rows, 15 pages |
| `Reports/Chinook-Composition.mad` | Composition Report | bundled Chinook SQLite | two sources: an **Albums** source with its own layout and an **Artists** source with no layout (Viewer row grid), joined into a Result | Result 347 rows / 10 pages; Albums 347 rows / 10 pages; Artists 275-row, 2-column grid |
| `Reports/Composition-MySQL-PostgreSQL-SQLServer.mad` | Composition Report | MySQL `employees`, PostgreSQL `chinook`, SQL Server `AdventureWorksLT2022` | three live sources joined on `demo_id`; MySQL has its own layout, PostgreSQL and SQL Server are layout-less (Viewer row grids); each source asks for its own password on first refresh | Result 5 rows / 1 page; MySQL 5 rows / 1 page; PostgreSQL 5-row, 3-column grid; SQL Server 5-row, 3-column grid |
| `Reports/PostgreSQL-Chinook.mad` | Standard Report | PostgreSQL `chinook` | a server connection with **no stored username or password**; refresh asks for the password | 347 rows, 10 pages after the prompt |

If one of the three servers is not reachable when the cross-database sample is
generated, the builder drops that driver and writes the best two-source variant
(`Composition-MySQL-PostgreSQL.mad` or `Composition-PostgreSQL-SQLServer.mad`)
and says which one it dropped.  A sample needs two reachable sources.

`Reports/chinook.sqlite3` is the data the three SQLite samples read.  It is the
same Chinook database the app already ships as a sample.

## First run: SQLite samples

SQLite needs no credentials.  Open a sample, switch to **Viewer**, and press
**Refresh**.  The app reads `chinook.sqlite3` from beside the `.mad` file (a copy
outside the repository works the same way) and renders the report.

## First run: the PostgreSQL sample

The PostgreSQL sample stores the host (`127.0.0.1`), port (`5432`), database
(`chinook`) and a non-secret username hint (`mad`).  It deliberately stores no
password.  On the first refresh:

1. The refresh fails with *Credentials required*.
2. The app presents **Database Connection Settings** with the host, database,
   username and port already filled in and the password field empty.
3. Type the test password and choose **Save & Refresh**.  The sheet validates
   the connection and the Viewer renders the report.

The test password is **not** in this folder, in the `.mad` files, or in this
README.  It is the PostgreSQL test credential in
`docs/zh/project/TEST-DB-INFO.md`; supply it at the prompt.  If the test server
is not running, the sample reports a connection error rather than silently
showing old rows.

## First run: the cross-database composition sample

`Reports/Composition-MySQL-PostgreSQL-SQLServer.mad` joins one small table from
each of the three live test servers: MySQL `employees`, PostgreSQL `chinook` and
SQL Server `AdventureWorksLT2022`.  The three databases share no key of their
own, so the sample uses a purpose-built `composition_demo` table with the same
`demo_id` values in each.  Create it once:

```sql
-- MySQL, database employees
CREATE TABLE composition_demo (
	demo_id INT NOT NULL PRIMARY KEY,
	label   VARCHAR(64) NOT NULL,
	amount  DECIMAL(10,2) NOT NULL
);
INSERT INTO composition_demo (demo_id, label, amount) VALUES
	(1, 'MySQL / North',   101.50),
	(2, 'MySQL / South',   102.50),
	(3, 'MySQL / East',    103.50),
	(4, 'MySQL / West',    104.50),
	(5, 'MySQL / Central', 105.50);

-- PostgreSQL, database chinook
CREATE TABLE public.composition_demo (
	demo_id INT NOT NULL PRIMARY KEY,
	label   VARCHAR(64) NOT NULL,
	amount  NUMERIC(10,2) NOT NULL
);
INSERT INTO public.composition_demo (demo_id, label, amount) VALUES
	(1, 'Postgres / North',   201.00),
	(2, 'Postgres / South',   202.00),
	(3, 'Postgres / East',    203.00),
	(4, 'Postgres / West',    204.00),
	(5, 'Postgres / Central', 205.00);

-- SQL Server, database AdventureWorksLT2022
CREATE TABLE dbo.composition_demo (
	demo_id INT NOT NULL PRIMARY KEY,
	label   VARCHAR(64) NOT NULL,
	amount  DECIMAL(10,2) NOT NULL
);
INSERT INTO dbo.composition_demo (demo_id, label, amount) VALUES
	(1, 'SQL Server / North',   301.75),
	(2, 'SQL Server / South',   302.75),
	(3, 'SQL Server / East',    303.75),
	(4, 'SQL Server / West',    304.75),
	(5, 'SQL Server / Central', 305.75);
```

The sample stores the host, port, database and a non-secret username hint for
each source (`root`, `mad`, `sa`); it stores **no password** — the portable
store has no password column.  The test logins and passwords are in
`docs/zh/project/TEST-DB-INFO.md`.  The MySQL test login happens to use the same
string for its username and password; the sample carries only the username.

To open and run it, with no credentials previously saved for those three
connections:

1. In MAD Designer for macOS, choose **File > Open…** and open
   `Reports/Composition-MySQL-PostgreSQL-SQLServer.mad`.  The toolbar reads
   **Composition Report** and the node picker lists **Result**, **MySQL**,
   **PostgreSQL** and **SQL Server**.
2. Switch to **Viewer** and press **Refresh**.  The refresh asks for each source
   in turn: **Database Connection Settings** opens with the driver, host, port,
   database and username already filled in and the password blank.
3. Type that source's password and choose **Save & Refresh**.  The sheet
   validates the connection, then asks for the next source.  After the third
   source the Result renders **5 rows** joined on `demo_id`, with
   `mysql_label` / `mysql_amount`, `postgres_label` / `postgres_amount` and
   `sqlserver_label` / `sqlserver_amount`.
4. Pick **MySQL** in the node picker: the Designer shows its three fields and
   its own page layout; the Viewer renders that layout.  Pick **PostgreSQL** or
   **SQL Server**: the Designer's bands are empty and the Viewer shows the cached
   rows as a **3-column row grid** (layout-less sources are reports of rows, not
   pages).
5. Save a copy elsewhere and reopen it.  The composition (Result + three
   sources, one layout and two layout-less) survives, and refreshing the copy
   asks for the three passwords again.
6. **Export…** writes the joined Result as a PDF.

The sample asks for the passwords; it never carries them.  If a server is not
running, its source fails with a connection error rather than silently showing
old rows.

## Checks

`./Samples/check.sh` builds a small AppKit tool from the same sources as the
app and drives the documents through `MADMacDocument`, the three workspaces and
`MADMacConnectionWindowController`.  It:

* opens each sample with no stored credentials and refreshes it;
* checks the standard sample renders 275 rows / 8 pages;
* checks the grouped sample renders 412 rows / 15 pages with group bands;
* checks the composition Result (347 rows), the **Albums** source's own layout
  (10 pages), and the **Artists** source's row grid (2 columns, 275 rows);
* copies the reports outside the repository, refreshes the copy, saves and
  reopens it;
* deletes the PostgreSQL connection's Keychain entries, confirms the connection
  sheet asks for the password with `127.0.0.1` / `chinook` / `mad` prefilled,
  enters the test password, and confirms the refresh returns 347 rows;
* for the cross-database sample, deletes the Keychain entry for each of the three
  source connections, opens the sample, presses Refresh, and answers the real
  per-source connection sheets in turn — checking that each names its source,
  prefills host/port/database/username and leaves the password blank, then
  entering that source's password.  It confirms the Result joins to 5 rows, the
  MySQL source renders its own page, PostgreSQL and SQL Server each show a
  3-column row grid, the node picker lists all four nodes, and the exported PDF
  is written; then it saves a copy, reopens it, and refreshes it through the same
  three prompts.

Run it with the three passwords in the environment (only the PostgreSQL one is
needed for the single-source sample; the cross-database check is skipped unless
all three are set):

```sh
MAD_MYSQL_SAMPLE_PASSWORD='<mysql>' \
MAD_PG_SAMPLE_PASSWORD='<postgres>' \
MAD_TDS_SAMPLE_PASSWORD='<sql server>' \
	./Samples/check.sh
```

The run writes every intermediate PNG/PDF under `Samples/build/Screenshots`;
the curated images in `Samples/Screenshots` are copies of the useful ones.

## Regenerating

Build the Mac app first (the maker links the frameworks the app built):

```sh
./Mac/build.sh
./Samples/build.sh --run
MAD_PG_SAMPLE_PASSWORD='<the test password>' \
	./Samples/build.sh --run Samples/Reports \
	MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset/chinook.sqlite3 postgres

# Cross-database composition: needs the three demo tables and the three passwords.
MAD_MYSQL_SAMPLE_PASSWORD='<mysql>' \
MAD_PG_SAMPLE_PASSWORD='<postgres>' \
MAD_TDS_SAMPLE_PASSWORD='<sql server>' \
	./Samples/build.sh --run Samples/Reports \
	MADDesigner/Resources/Assets/Samples.xcassets/Data/chinook.dataset/chinook.sqlite3 \
	crossdatabase
```

The `crossdatabase` mode reads `MAD_MYSQL_SAMPLE_*`, `MAD_PG_SAMPLE_*` and
`MAD_TDS_SAMPLE_*` (`HOST`, `PORT`, `USER`, `PASSWORD`, `DATABASE`; the defaults
match the test servers).  A source with no password is skipped.  The mode tries
all three drivers, builds the best two-source variant if one cannot connect, and
refreshes the composition through `MADOperationRefreshComposed` with the three
credentials before it exits.

`Samples/Tools/MADSampleMaker.m` creates the documents from the source database
and the production store/archive writers; it verifies each one refreshes before
it exits.  `Samples/build.sh` is the compile-and-run wrapper.

## Screenshots

* `Screenshots/standard-report.png` — the Standard Report's first page.
* `Screenshots/standard-designer.png` — its Designer bands and query fields.
* `Screenshots/grouped-report.png` — the grouped report's first page.
* `Screenshots/grouped-designer.png` — its group header/footer bands.
* `Screenshots/composition-result-report.png` — the composition Result.
* `Screenshots/composition-result-designer.png` — the Result's Designer.
* `Screenshots/composition-albums-designer.png` — selecting the Albums source in
  the Designer shows that source's own bands and field list.
* `Screenshots/composition-albums-report.png` — the Albums source's own layout.
* `Screenshots/composition-artists-designer.png` — the layout-less Artists
  source in the Designer: empty bands, ready to author.
* `Screenshots/composition-artists-grid-view.png` — the same source in the
  Viewer: its row grid, not a report page.
* `Screenshots/composition-cross-result-report.png` — the cross-database
  composition's Result: five rows joined on `demo_id` from MySQL, PostgreSQL and
  SQL Server.
* `Screenshots/composition-cross-result-designer.png` — the Result's Designer:
  title, the seven joined columns, and the report-columns list.
* `Screenshots/composition-cross-connection-sheet.png` — the first-run prompt
  for one source: driver, host, port, database and username prefilled, password
  blank, and the status line naming the source.
* `Screenshots/composition-cross-mysql-designer.png` — the MySQL source's own
  Designer bands.
* `Screenshots/composition-cross-mysql-viewer.png` — the MySQL source's own
  page layout in the Viewer.
* `Screenshots/composition-cross-postgres-designer.png` /
  `composition-cross-postgres-grid.png` — the layout-less PostgreSQL source:
  empty bands in the Designer, then its 3-column row grid in the Viewer.
* `Screenshots/composition-cross-sqlserver-designer.png` /
  `composition-cross-sqlserver-grid.png` — the layout-less SQL Server source,
  the same two states.
* `Screenshots/postgres-connection-sheet.png` — the first-run prompt, with the
  host, database and username filled in and the password empty.
* `Screenshots/postgres-report.png` — the PostgreSQL report after the prompt.

## Manifest

`manifest.json` lists the files, their row/page counts and the checks they are
expected to satisfy.  It is the machine-readable companion to this README.
