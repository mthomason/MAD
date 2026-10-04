# _MAD Designer_ Agent Overview

## Project Synopsis

_MAD Designer_ is a mobile analytic document designer.  _MAD Designer_ provides ad hoc query, reporting, and design.  It is business intelligence (BI) software.

* It is built for iOS using Objective-C
* It targets a minimum version of iOS 15
* It is built for iPhone, iPad, and My Mac (Designed for iPad)

## Project Overview

_MAD Designer_ is a Core Data application that defines a `.mad` file type, which is a `UIManagedDocument` type.

It is BI software, and currently support access to MySQL and SQL Server databases.  It also uses Sqlite3 for example reports and internal data tables.

The software is designed to be extensible.  Developers should be able to do the following:

* Create frameworks which support new database types
* Create new document element types (e.g. static labels, data labels, aggregate types, and barcode labels)
* Create new document export formats (e.g. export to PDF and JSON)

## User Workflow

When a user launches the application, they are presented with a file explorer.  This can be local files, or iCloud files.

When they open a file, they are presented with a screen that has three core components on the tab bar:

* MAD Query: This is the tool for designing ad hoc queries
* MAD Designer: This is the tool for laying out the visual elements that will be shown on the report
* MAD Viewer: This is the document viewer where a user can view and refresh the report that they have designed

A user, when creating a new document, will start by pressing the plus button in the file explorer.  This with present them with options to choose a database type.  Once they choose a database type, then can enter the information to connect to the database.  Once they do this, the software attempts to connect to the database, and if it's successful, it reads the database scheme information, and creates a `.mad` document based on database schema.

A user can then open report.

Once they open the report, will only have the database schema.  In the query tab, MAD Query, they can add tables that they want to query to access.  They can add the links between the tables (e.g. left outer join or full join).  They can also add filters, groupings, and more to the query.  The software auto generates the SQL query for the database.  The user is required to understand their data, but not really know how to write SQL.

Once they are done with that, they can move to the designer tab.  In the designer tab, they can add the reporting elements.  The designer tab lays out the report with different groupings, and they choose which grouping to add the elements to.  The groups follow:

* Report Header
* Page Header
* Any query groupings
* Report Detail
* Any query grouping footers
* Page Footer
* Report Footer

The designer view is a scroll view that allows zooming.  Each of the groupings is represented as a collection view, which is on the designer scroll view.  The groupings also contain their own scroll view.  The document elements can be moved between these using touch.

Once this is complete, the user can go to the MAD Viewer screen and use the refresh button to load the report data.  The data is all read back at once, and stored in a Sqlite3 cache; this is needed to allow aggregate functions.

## Project Structure

* This is a large and complex project that currently includes a main project and thirteen (13x) frameworks
	* `MADFoundation`: A base framework that defines classes used by all other frameworks.  This framework does not include any other frameworks, except references to `Foundation.framework` and `UIKit.framework`.  It includes important classes that can be abstracted away, such as `MADOperation` and `MADKeyChain`.
	* `MADAPI`: This framework only has a reference to `MADFoundation` and `MADCocoaExtensions`.
	* `MAD`: This framework defines `MADDatabase`, which is subclassed by custom database types (e.g. MySQL or SQL Server).  It also defines other core types.
	* `MADCocoaExtensions`: These are some core helper classes that are used all over the project.  It's useful classes, categories, and functions that are abstracted into this framework.
	* `MADDataStructures`: This defines core data structures and algorithms. The data structures include a graph, tree, stack, and linked list.
	* `MADFileManager`: This framework includes core file management classes for file coordination, file meta data, and storage state.
	* `MADExplorer`: This framework holds some of the file explorer code.  Other code for the file explorer is in the main project.
	* `MADMySQL`: The MySQL implementation of the `MADDatabase`.
	* `MADTdsClient`: Implements `MADDatabaseSQLServer`, the SQL Server subclass of `MADDatabase`
	* `MADSqlite3`: A wrapper around Sqlite3.
	* `MADTds`: A base wrapper around the freetds project.
	* `MADBarcodes`: This is used for the barcode element.  `MADBarcodes` is currently unused and unmaintained.
	* `MADFeedback`: This is a framework to allow user feedback.  `MADFeedback` is currently unused and unmaintained.

The core app is in `MADDesigner`.  Its source is in `MADDesigner/Source`, and its targets -- the app itself, the stand-alone viewer, and the unit and UI test bundles -- are in `MADDesigner/Targets`.

The code base also includes a custom scripting language in a file called `Scrimpter`, which was going to be used for adding formula elements to the project, but it is currently not used.

The codebase also includes static library build scrips in a file called `Compressor`.  This is used to build the static libraries used by the project.  This is a very important part of the project.

## Code Style Guidance

* This project uses tabs for spacing.
* This project uses limited comments where needed
* This project is very complex, so fixes and changes should be made stratigicly to minimize side effects.
* **Mark deliberately-unused code as unused with a clang attribute, at the declaration.**  Do
  not silence the warning away from it, and do not leave the declaration bare.
	* A file-static function nothing calls yet: `__attribute__((unused))`, as
	  `MADFeedback/MADFeedback/MADFeedbackUncaughtExceptionHandler.m:91` does.
	* An unused local: `__unused`, as `MADSqlite3/Source/MADDataTableFast.m:606` does.
	* A non-functional initializer on a class that must not be built that way: `NS_UNAVAILABLE`
	  in the header, as `MADFoundation/Source/MADCredential.h:20` does.
	* An unused parameter: `__unused` on the parameter itself, so the signature stays honest
	  to its caller.

  Every framework target sets `GCC_WARN_UNUSED_FUNCTION` and `GCC_WARN_UNUSED_VARIABLE` to
  `YES`.  The point of the attribute is that what the compiler still reports is genuinely
  dead code rather than something parked on purpose -- an unmarked warning means delete it.

## Testing

Each framework has one test target, exposed by a shared scheme of the same name. Run a
suite against an iOS Simulator:

	xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
		-destination 'platform=iOS Simulator,name=iPhone 17 Pro'

`MADMySQL` and `MADTdsClient` each carry a second file -- `MADMySQLLiveTests.m` and
`MADTdsClientLiveTests.m` -- that talks to a real database server and **skips** when one is
not reachable, so the suite still passes on a machine without a server. The credentials
they expect are in `DEVELOPER.md`, and each can be overridden with a `MAD_MYSQL_TEST_*` or
`MAD_TDS_TEST_*` environment variable.

`MADBarcodes`, `MADFeedback`, `MADTds`, `Scrimpter`, and `Compressor` expose no shared test
scheme, so the command above does not reach them.

## Related Documents

* `BUGS.md` -- known defects, grouped by framework, with `file:line` references and the
  tests that pin each one.
* `TASKS.md` -- the engineering task queue: what is being worked, in order, with the
  context needed to start cold.
* `ROADMAP.md` -- the plan: which register, queue and design document gets picked up next,
  and in what order.
* `MADDataTable_Architecture_Report.md` -- the `MADDataTable` class cluster across
  `MADFoundation`, `MAD`, `MADSqlite3`, `MADMySQL`, and `MADTdsClient`.
* `MAD_FORMAT.md` -- what a `.mad` document is, and what it should be.
* `MAD_FUTURE.md` -- the vision: the `.mad` as a data object, the hidden file types as
  products, the web clone, AI, and the money.
* `MAD_LINUX.md` -- the technical assessment of compiling the headless engine on
  Linux: the dependency audit, GNUstep coverage, and the compile-and-call plan.
* `MAD_CLI.md` -- the `mad` command-line tool: what it does, and the phasing to build it.
* `LIBRARIES.md` -- the vendored libraries on disk, how Xcode reaches them, and the build plan.
* `THIRD_PARTY_LICENSES.md` -- every third-party component in the app, how it is linked, its
  licence, and what shipping it obliges us to do. Read before adding or removing a library.
* `LICENSE_COMPLIANCE_PLAN.md` -- the remediation plan for those findings, including the
  MySQL-to-MariaDB replacement and the LGPL relink obligation.
* `MAD_STORE_MIGRATION.md` -- the plan to move the `.mad` store off Core Data to a portable
  SQLite schema of our own.
* `DEVELOPER.md` -- test database credentials and common build commands.
* `TODO.md` -- the product wishlist: features and ideas.
* `README.md` -- build notes and the export-compliance statement.
* `APPSTORE.md` -- the App Store promotional text and description currently in use.

## Tracking Files Are Maintained, Not Acted On

`BUGS.md` and `TASKS.md` are **records, not instructions**. An agent may -- and should --
keep them accurate: add an entry when new evidence appears, record a fix, and re-status a
task. What an agent must **not** do is start work because a file lists it. Entries there
are picked up when the user asks for that task by name or number, never on the agent's own
initiative.

`BUGS.md` uses two conventions for a fixed defect, and both are in use today: most
sections mark it **Status: Fixed** in place with a `Now:` line saying what changed,
while the oldest entries sit under *Already fixed (for reference)* with their commit
hash. Match whatever the section you are editing already does rather than converting it.

`TODO.md` is the user's own wishlist and is not for agents to edit.

Every directory with an `AGENTS.md` also has a `CLAUDE.md` symlink to it, so the two names
always name the same file.

---
