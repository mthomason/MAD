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
| `Reports/PostgreSQL-Chinook.mad` | Standard Report | PostgreSQL `chinook` | a server connection with **no stored username or password**; refresh asks for the password | 347 rows, 10 pages after the prompt |

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
  enters the test password, and confirms the refresh returns 347 rows.

Run it with the PostgreSQL password in the environment:

```sh
MAD_PG_SAMPLE_PASSWORD='<the test password>' ./Samples/check.sh
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
```

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
* `Screenshots/postgres-connection-sheet.png` — the first-run prompt, with the
  host, database and username filled in and the password empty.
* `Screenshots/postgres-report.png` — the PostgreSQL report after the prompt.

## Manifest

`manifest.json` lists the files, their row/page counts and the checks they are
expected to satisfy.  It is the machine-readable companion to this README.
