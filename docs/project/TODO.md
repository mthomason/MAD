
# TODO — the wishlist

The author's product wishlist. It is not the queue: what is being worked is
tracked in `TASKS.md`, and defects are in `BUGS.md`. Entries here are picked
up when asked for.

## Product

* AI localizations
* AI-generated queries
* New export formats — JSON and more (PDF and images may be free; rich text
  is easy; HTML and text take time; Word and Excel are hard)
* New display views on the data
* Complete sample-table display, with multiple queries to display unlimited data
* Chart element
* Dashboard document type — the data model holds a report type today
* Save queries as KPIs
* Formula elements — the engine choice is open (`MAD_SCRIPTING.md` §8)
* Query visualization: fix the known problems; revisit caching and layout
* Borders implemented the same way margin and padding are
* Encrypt the document when writing it
* Edit database information
* In-App Purchase / store — revisit now that the project is open source
* Stand-alone viewer version
* YouTube demo video
* Show SQL as static text on a scroll view, for horizontal scrolling
* ORDER BY support in the query builder (suppressed in the reporting app)
* SFQL generation for Salesforce — only the join syntax differs; SFQL was
  only starting to support joins when this was written
* The reporting protocol for every other data source — the TDS driver ships;
  every other source would be useful to someone

## Viewer

* Print button
* Page numbers
* Render font style changes (size and margin are already implemented)
* Save an image of the rendered report for its thumbnail
* Cache data in the background; notify with a local notification

## UI polish

* Hover effect on the paging slider
* About popover tint — unreadable on the simulator today
* Buttons behind the cloud activity indicator — refactor to a standard
  activity indicator
* Investigate the constraint warnings when the UI is off screen
* Test multiple rows

## Functions to look at

* `- (void)setupGroupKeyIndexes`
* `- (NSArray *)groupKeys:(int64_t)rowID groupNumber:(int64_t)groupNumber`
