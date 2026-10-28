# CLI fixtures

Documents the CLI's verbs are run against, beside the samples they come from
(`docs/project/MAD_CLI.md` §6).

| Fixture | Source | What it pins |
|---|---|---|
| `London.portable.mad` | `MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad` | the Sqlite3 data path: 11-table schema, the London predicate, 76 rows |
| `Music.portable.mad` | `.../Reports/Music.dataset/Music.mad` | the same path on the larger sample (3503 rows) |
| `MySQL.employees.mad` | the `employees` sample database, live (MySQL 8.4) | the MySQL driver path end to end: schema import, backtick SQL, a prepared-statement fetch |
| `TDS.AdventureWorksLT2022.mad` | AdventureWorksLT2022, live (SQL Server 2022) | the TDS path end to end: schema-qualified tables, bracketed T-SQL, the freetds fetch |
| `Postgres.chinook.mad` | Chinook, live (PostgreSQL 17) | the PostgreSQL path end to end: schema import, double-quoted SQL, the libpq fetch |

## Why the samples needed converting

Both shipping samples are **legacy** documents: their definition is a Core Data
store (`StoreContent/analyitics`), and converting one needs Core Data, which the
MAD framework does not link and Linux does not have (`docs/project/MAD_LINUX.md` §5.1, §9).
`London.portable.mad` and `Music.portable.mad` are the same documents written in
the portable store, so a platform without Core Data can read and refresh them —
which is what the Linux CLI and `Linux/Tests/MADHeadlessDocumentTests.m` do.

They are also the read-side counterpart of the v0 samples: `mad inspect` reports a
fixture as v1 with `StoreContent/store.sqlite` and the sample as v0 with the legacy
store, and both statements come from the same container reader.

The three live fixtures are ordinary documents the app's create chain wrote against
a real server, so their schemas are real ones (8 tables of `employees`, 12 of
AdventureWorksLT, 11 of Chinook) and their queries are real SELECTs.

## How they were made

On the Mac, with the app's own code paths — nothing here is hand-written:

	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad" \
		"$PWD/CLI/Fixtures/London.portable.mad"
	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad" \
		"$PWD/CLI/Fixtures/Music.portable.mad"

	CLI/build.sh --make-fixture create mysql mac 13306 root root employees "$PWD/CLI/Fixtures/MySQL.employees.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/MySQL.employees.mad" titles "title,from_date,to_date"

	CLI/build.sh --make-fixture create tds mac 1433 sa 'Root1@Root2' AdventureWorksLT2022 "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad" "SalesLT.Product" "Name,ListPrice,Color"

	CLI/build.sh --make-fixture create postgres mac 5432 mad mad_test_pw chinook "$PWD/CLI/Fixtures/Postgres.chinook.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/Postgres.chinook.mad" track "name,composer,unit_price"

`--make-fixture` compiles `MADFixtureMaker.m` (the same flags as the tool, plus the
legacy converter and the value transformers) and runs it in the simulator:

* `portable` copies the document, opens it with `MADocument` — which converts the
  legacy store on the way in — marks it changed and closes it, which is the save
  path.
* `create` runs the app's create-document chain against a live server: create the
  document, first-time setup, add the connection, import the schema, close (which
  saves).
* `select` does what the designer does when a table and its fields are ticked: adds
  the query table, a query field per schema field, and one data label per query
  field — the labels are what make the fields *active*, since the SELECT list is
  the fields the report's elements reference (`MADQueryActiveQueryFields`).

The result is not byte-stable across runs (the store is SQLite and the archive
carries timestamps), so the fixtures are regenerated only when a sample or the
store format changes, and a diff in them is a real one to look at.

## The host name in the live fixtures

All three name the server as `mac` — this Mac's hostname, which resolves to its LAN
address here and inside the Docker containers. One name, then, for the Mac's
MySQL (published on the loopback *and* the LAN by the fixture container below) and
for the SQL Server and PostgreSQL containers (published on all interfaces), so the same document
can be refreshed from the Mac and from the Linux image. `host.docker.internal`
would work only inside a container; `127.0.0.1` only on the Mac.

All three live fixtures were created against the canonical test containers, which
`docs/project/DEVELOPER.md` documents and whose scripts create them from pinned images and
checksum-verified datasets:

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on 13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on 1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on 5432

All three publish on every interface, so the documents' `mac` host name resolves
from the Mac and from inside the Linux image. The MySQL container is on 13306,
not 3306, because the Oracle MySQL installer's launchd service may own 3306.
`down` stops a server (the volumes keep the data); `reset` removes it and the
next `up` rebuilds it.

The CLI's `--host`, `--port` and `--database` override the stored connection
for one run (`docs/project/MAD_CLI.md` §3), which is how a CI job points one of
these documents at a service container whose host and port differ from the
Mac's. The document itself is not rewritten.
