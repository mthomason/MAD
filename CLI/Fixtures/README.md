# CLI fixtures

Documents the CLI's verbs are run against, beside the samples they come from
(`MAD_CLI.md` §6).

| Fixture | Source | What it pins |
|---|---|---|
| `London.portable.mad` | `MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad` | the Sqlite3 data path: 11-table schema, the London predicate, 76 rows |
| `Music.portable.mad` | `.../Reports/Music.dataset/Music.mad` | the same path on the larger sample (3503 rows) |
| `MySQL.employees.mad` | the `employees` sample database, live (MySQL 8.4) | the MySQL driver path end to end: schema import, backtick SQL, a prepared-statement fetch |
| `TDS.AdventureWorksLT2022.mad` | AdventureWorksLT2022, live (SQL Server 2022) | the TDS path end to end: schema-qualified tables, bracketed T-SQL, the freetds fetch |

## Why the samples needed converting

Both shipping samples are **legacy** documents: their definition is a Core Data
store (`StoreContent/analyitics`), and converting one needs Core Data, which the
MAD framework does not link and Linux does not have (`MAD_LINUX.md` §5.1, §9).
`London.portable.mad` and `Music.portable.mad` are the same documents written in
the portable store, so a platform without Core Data can read and refresh them —
which is what the Linux CLI and `Linux/Tests/MADHeadlessDocumentTests.m` do.

They are also the read-side counterpart of the v0 samples: `mad inspect` reports a
fixture as v1 with `StoreContent/store.sqlite` and the sample as v0 with the legacy
store, and both statements come from the same container reader.

The two live fixtures are ordinary documents the app's create chain wrote against
a real server, so their schemas are real ones (8 tables of `employees`, 12 of
AdventureWorksLT) and their queries are real SELECTs.

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

Both name the server as `mac` — this Mac's hostname, which resolves to its LAN
address here and inside the Docker containers. One name, then, for the Mac's
MySQL (published on the loopback *and* the LAN by the fixture container below) and
for the SQL Server container (published on all interfaces), so the same document
can be refreshed from the Mac and from the Linux image. `host.docker.internal`
would work only inside a container; `127.0.0.1` only on the Mac.

The MySQL fixture was created against a container that reuses the MADMySQL test
volume (the checksum-verified `employees` dataset) and publishes on every
interface, which is the one deliberate difference from
`MADMySQL/TestDatabase/mysql-test-db.sh`, whose `up` binds 127.0.0.1:

	docker run -d --name mad-mysql-fixture \
		--env MYSQL_ROOT_PASSWORD=root --env MYSQL_ROOT_HOST='%' \
		--publish 13306:3306 --volume mad-mysql-test-data:/var/lib/mysql \
		mysql:8.4@sha256:6ea90827b1100f8f2ae306a539f86d2c264a26ed435a2a9f75551dd5c3aeb242

The SQL Server container and dataset are documented in `DEVELOPER.md` and the live
`MADTdsClientLiveTests` suite:

	docker run -d --name mad-mssql -e ACCEPT_EULA=Y -e 'MSSQL_SA_PASSWORD=Root1@Root2' \
		-p 1433:1433 mcr.microsoft.com/mssql/server:2022-latest
	# then RESTORE the AdventureWorksLT2022 backup into it (see DEVELOPER.md)
