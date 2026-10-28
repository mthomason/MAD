---
layout: default
---

# Writing a MAD driver in an afternoon

Every file:line reference below is current as of 2026-10-25.

## What a driver is

A driver is two small classes and one registration call:

1. a subclass of `MADDatabase` (`MADAPI/Source/MADDatabase.h` — the header
   says it plainly: "This class is built for subclassing") that knows how
   to browse a source's schema and execute a query against it;
2. a connection class — a `MADDatabaseConnection` subclass that conforms
   to the `MADDatabaseDriver` protocol
   (`MADAPI/Source/MADDatabaseDriverRegistry.h`) and registers itself in
   `+load`.

Everything else — the query designer's graph, SQL generation, the row
cache, the render pipeline, the seven export formats, the CLI, the Docker
image — is shared machinery the driver plugs into. The contract a driver
satisfies is *"return a schema and rows in table form"*
(`docs/project/MAD_STRATEGY.md` §3.7), which is why a driver can front
anything that can be made to look like a table: a SQL database, a Web
service, a file.

The three server examples to crib from are `MADPostgres` (6 files,
`MADPostgres/Source/`, subclass `MADDatabasePostgres` over `libpq`),
`MADMySQL` (18 files, `MADMySQL/Source/`, subclass `MADDatabaseMySQL`) and
`MADTdsClient` (SQL Server over FreeTDS). Sqlite3 is the fourth shipped
driver (`MADSqlite3`), and the file-backed case
(`+newDatabaseConnectionWithURL:`) shows in its connection class.

## Step 1 — the type constant

Pick the next free `MADDatabaseType` value (`MADAPI/Source/MADDatabaseType.h`;
shipped types are 1–12) or extend the enum. This is what the document
stores, so it is a format constant: once documents exist with your type,
the number is permanent.

## Step 2 — subclass `MADDatabase`

The abstract seams live in `MADAPI/Source/MADDatabaseProtocol.h`
(`MADDatabaseDataSource`). The required surface:

```objc
- (void)getTables:(void (^)(BOOL success, NSError *error,
                            NSArray <MADDatabaseTable *> *tables))completion;

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn
                                                    error:(NSError **)error;
- (NSArray <MADDatabaseField *> *)fieldsForTable:(NSString *)tableName
                                     connection:(id)dbconn
                                          error:(NSError **)error;

- (id)connectWithConnection:(MADDatabaseConnection *)connection
                 credentals:(MADCredential *)credentals
            connectionError:(NSError **)error;

// The execution seam: the driver fills the table it is handed.  The
// destination is any <MADDataTableWriting>, which is what keeps the
// promise to "anything that returns a table" (MADDataTable.h).
- (BOOL)executeSQL:(NSString *)sql
         fieldKeys:(NSArray *)fieldKeys
      onConnection:(id)dbconn
  intoResultTable:(id <MADDataTableWriting>)dataTable
         withError:(NSError **)error;

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError **)error;
- (BOOL)executeQuery:(MADQuery *)query
       withDataTable:(id <MADDataTableWriting>)dataTable
            andError:(NSError **)error;

// Optional: only file-backed drivers have nothing to dial.
- (void)closeConnection:(id)process;
```

Schema browsing (`getTables…`, `fieldsForTable:…`) is what the app's
create-document flow calls when it imports a database's schema into a new
`.mad`; the execution seam is what `mad refresh` and the viewer call.
`MADOperationRefresh.m:134` shows the exact call the refresh chain makes.

## Step 3 — the connection class and registration

```objc
@interface MyDriverConnection : MADDatabaseConnection <MADDatabaseDriver>
@end

@implementation MyDriverConnection
+ (void)load {
	[MADDatabaseDriverRegistry registerDriverClass: self];
}
+ (MADDatabaseType)databaseType { return MADDatabaseTypeMyDriver; }
+ (NSString *)Identifier { return @"MyDriver"; } // stored in documents
+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentials { … }
+ (Class)databaseClass { return [MyDatabase class]; }
+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host
										 database:(NSString *)database
											 port:(NSInteger)port { … }
@end
```

`+Identifier` is what `RptqDatabaseCredentals.driverID` holds, so it is a
document-format constant — pick a stable spelling ("MySQL", "TDS",
"PostgreSQL", "Sqlite 3" are the shipped ones). A second class claiming a
taken type is a programming error; the registry asserts it.

## Step 4 — link it so the registration runs

Registration is per-process and **by link**: a process that does not link
your driver cannot build its databases (the constructor asserts with a
clear message rather than failing later with nil).

* **Apple:** link your framework into the host (the CLI names its drivers
  in `CLI/build.sh`'s `FRAMEWORKS` list), or use `-ObjC` when linking a
  static archive — categories and `+load` methods are otherwise dropped
  silently.
* **Linux:** add your archive **whole-archived** to the `mad` target in
  `Linux/CMakeLists.txt`, the way `madsqlite3`, `madmysql`, `madtdsclient`
  and `madpostgres` are:

  ```cmake
  target_link_libraries(mad PUBLIC
      "$<LINK_LIBRARY:WHOLE_ARCHIVE,my_driver>" …)
  ```

  This is not a nicety — a driver's work is reached through categories
  (message sends, no symbols), and a non-whole static link drops them: the
  failure is a crash at the first message send, not a linker warning
  (`Linux/README.md`, "The compat shims" / "The drivers are registered").
  A per-driver source list in `cmake/MyDriverSources.cmake` follows the
  `MADFoundationSources.cmake` shape, with every excluded file named and
  the reason.

## Step 5 — the test conventions (this is the house style; match it)

Two suites, in the framework's test target:

1. **Offline tests** — schema structures, field metadata, identifier
   quoting, the connection's property round trip. These always run.
2. **Live tests** — talk to a real source and **skip, never fail**, when
   one is not reachable. `MADMySQL/MADMySQLTests/MADMySQLLiveTests.m` is
   the template: credentials default to a documented local server and
   every one is overridable by an environment variable
   (`MAD_MYSQL_TEST_HOST`, `MAD_MYSQL_TEST_PORT`, `MAD_MYSQL_TEST_USER`,
   `MAD_MYSQL_TEST_PASSWORD`, `MAD_MYSQL_TEST_SCHEMA`), and each live test
   begins with `XCTSkipIf(![self serverIsAvailable], …)`. A machine
   without your source still gets a green suite. Note the MySQL file's
   comment: use `127.0.0.1`, not `localhost`, inside the iOS Simulator.
3. **Registry tests** — `MADDatabaseDriverRegistryTests` shows the shape:
   register a test driver, assert the lookup, assert the duplicate-type
   throw. Your driver gets one of these for free by construction.
4. Port the suites to `Linux/Tests/` if the driver belongs in the
   headless build (see `cmake/` and `Linux/README.md` "Adding the next
   framework"); otherwise say in the PR why it is Apple-only.

## Step 6 — the honest caveat: what a non-SQL driver can and cannot do today

This is the one part of the pitch that is not finished, and it is written
down deliberately (`docs/project/MAD_STRATEGY.md` §4.7): the **execution**
layer is driver-shaped — `executeSQL:…intoResultTable:…` and the
`MADDataTableWriting` destination are honest about "anything that returns a
table" — but the **compilation** layer is shared: `MADQueryFull` compiles
the query graph to one SQL text per driver. Your driver receives **SQL
text**, not the graph (tables, fields, predicates, groups).

So a REST/Web-service driver today:

* **can** browse its schema (`getTables…`, `fieldsForTable:…`), take the
  connection form the app already has, receive the generated SQL and
  translate it to API calls, deliver rows into any writable table, and
  ride the whole refresh/render/export path — a fully working driver;
* **cannot** receive the query graph natively: to know *what* the engine
  is asking it must parse the SQL text back out of the string it was
  handed. The practical route: the engine's own SQL parser (built for the
  SQL-entry feature, `docs/project/MAD_SQL_ENTRY.md`) already parses the
  supported subset — the generated SQL is that subset by construction — so
  a driver can reuse it to recover the graph;
* the **proper fix** is a per-driver compilation hook — the same shape the
  project sketched for Salesforce SFQL back in 2012 — so "install a
  driver" means "install a driver for anything", not "for SQL dialects we
  happen to match". It is sequenced as engine-contract work (Stage 1) and
  is a genuinely welcome first PR if you want a bigger bite than a driver.

One more honest note, for server deployments rather than drivers: a
user-installed driver is **arbitrary code in the server process**. The
registry works for trusted, first-party drivers today; a driver
marketplace needs signing, sandboxing or worker-process isolation before
it can exist, and that is designed into the server's API, not bolted on
later.

## Step 7 — land it

Propose the driver through the driver-proposal issue template, follow the
test-first rule in [CONTRIBUTING.md](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING.md) (failing
test, then code toward green; snapshot fixtures rather than generating
them with the new code), and if the driver links a new third-party
library, extend
[docs/project/THIRD_PARTY_LICENSES.md](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md)
and the licence obligations with it — the repo takes that file seriously.
