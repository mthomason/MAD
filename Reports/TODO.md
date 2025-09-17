
# TODO

## Primary

* ~~Add images back~~
* ~~Got rid of warning images~~
* Test iCloud stuff and make sure intro screen activity is synced correctly
* ~~Test TDS~~
* ~~See if something can be done about slow load of SQL screen~~
* ~~Infoscreen in dark mode is unreadable... can't be dismissed~~
* Recreate sample reports (in new format)
* Fix minor UI issues
* AI localizations
* That's it...

Test passwords are (it's a never on test server):
root, root, employees
test, test, AdventureWorks2022

* ~~Update designer UI so state doesn't get out of sync when user clicks away~~
* ~~Update toolbox UI for dark mode~~
* Setup test databases for ~~MySQL~~ and ~~MS SQL Server~~.

## Secondary

* Add new export formats (.json, ect.)
* Add new display views on the data
* Make the sample table display complete, with multiple queries to display unlimited data
* Add way to use AI generated queries
* Add store / monetization pathway
* Fix problems with query visualization view

## Tertiary

* See if something can be done about constraint warnings when the UI is off screen (it's not an issue yet, lol), or perhaps these are real issues, or something to do with animations
* Test multiple rows

---

Icon generation, copy, and removal
Query visualization caching
Query visualization layout

--

Need the ability to edit database informaiton.
Use hover effect on paging slider

About popover should not have transparent background… or it should have a tint… currently unreadable on simulator.

Can press buttons behind cloud activity indicator.
    This needs to be refactored, use standard activity indicator, etc.

How To
    Display YouTube Demo Video
    In App Purchase
    Report Viewer Stand Alone Version

Report Designer
    Implement "border" in the same way that margin and padding are implemented.
    On iPad version, make sure tool box close button works.  Right now, only touch away works.
    Formula type will use a sub set of JavaScript, since JavaScript is widely known, and there is a processor for it  built into Safari which is always running on iOS.
    COMPLETE - Expand the abstract report elements to include images, labels, and formula types.  It already includes a data-field type that links to a spot in the query.

Report Viewer
    Provide print button.
    Save image of rendered report for thumbnail.
    Render font style changes in rendering of report (size and margin are already implemented).
    Show page numbers.
    Cache data in the background, use NSLocalNotification to notify when data is cached.

Data Model
    COMPLETE - Abstract table schema so that the same table may be included multiple times.

Database Access
    SalesForce needs the sql generator to create SFQL as it is now creating SQL.  Only difference is join syntax, but the join grouping is the same.  SFQL was only starting to support joins when I started on this project.
    Implement the reporting protocol for the already compiled TDS driver.  This will provide support for MS SQL Server and Sybase.
    Prioritize and then implement the same protocol for every other datasource known, becasue each one would be useful to someone.

Show SQL
    This should display static text on scroll view, to allow for horizontal scrolling.

Query Builder
    Add support for ORDER BY, but suppress it in reporting app.

File Type
    Add encryption while writing to the file.

Export
    Add the ability to export to many file types.  I believe exporting to PDF, and image types may be free.  Exporting to rich text may be easy.  Word or Excel may be hard.  HTML, test, and other types maybe time consuming.

Future
    Expand report elements to add a chart type.
    Expand data model to hold a dashboad type as it now holds a report type.
    Add the ability to save queries for KPI's.
