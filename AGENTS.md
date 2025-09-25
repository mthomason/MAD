# _MAD Designer_ Agent Overview

## Project Synopsis

_MAD Designer_ is a mobile analytic document designer.  _MAD Designer_ provides ad hoc query, reporting, and design.  It is business intelligence (BI) software.

* It is built for iOS using Objective-C
* It targets a minimum version of iOS 13
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
	* `MADFoundation`: A base framework that defines classes used by all other frameworks.  This framework does not include any other frameworks, except references to `Foundation.framework` and `UIKit.framework`.
	* `MADAPI`: This framework only has a reference to `MADFoundation` and `MADCocoaExtensions`.
	* `MADFoundation`: This framework includes important classes that can be abstracted away, such as `MADOperation` and `MADKeyChain`.
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

The core app is in a file named `Report`.  It includes a folder called `MADStack` which holds much of the source code.

The code base also includes a custom scripting language in a file called `Scrimpter`, which was going to be used for adding formula elements to the project, but it is currently not used.

The codebase also includes static library build scrips in a file called `Compressor`.  This is used to build the static libraries used by the project.  This is a very important part of the project.

## Code Style Guidance

* This project uses tabs for spacing.
* This project uses limited comments where needed
* This project is very complex, so fixes and changes should be made stratigicly to minimize side effects.

---
