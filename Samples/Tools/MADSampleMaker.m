//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADSampleMaker.m
//  Samples/Tools
//
//  Writes the curated sample reports in Samples/.  The documents are built
//  through the production store and archive writers, the same ones the app
//  saves through; nothing here is hand-written SQLite or a hand-built archive.
//
//  Usage:
//    MADSampleMaker <output-directory> <chinook.sqlite3> [postgres]
//
//  Without `postgres` it writes the three portable samples (standard, grouped,
//  composition) and verifies each one refreshes.  With `postgres` it also writes
//  PostgreSQL-Chinook.mad, taking the server details from the MAD_PG_SAMPLE_*
//  environment variables (host, port, user, password, database).  The server
//  sample deliberately stores no username or password: it exists to make the
//  app ask, not to remember a test credential.
//
//  Two companion SQLite sources are written beside the samples and deliberately
//  left in place: `chinook.sqlite3` (the data) and `chinook-payments.sqlite3`
//  (a second portable source for the join).  A .mad resolves a sibling SQLite
//  file by name, so a copied folder keeps working.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import <MAD/MAD.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADPostgres/MADDatabaseConnectionPostgres.h>
#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>

static NSString * const MADSampleFontName = @"Helvetica Neue";

#pragma mark - Shared helpers

static RptqDatabase *MADSampleDefaultDatabase(MADHeadlessDocument *document) {
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext:document.storeContext];
	return model.defaultDatabase;
}

static RptqDatabaseSchemaTable *MADSampleSchemaTable(RptqDatabase *database, NSString *tableName) {
	for (RptqDatabaseSchemaTable *table in database.hasTables) {
		if ([table.name caseInsensitiveCompare:tableName] == NSOrderedSame) return table;
	}
	return nil;
}

static RptqDatabaseSchemaField *MADSampleSchemaField(RptqDatabaseSchemaTable *table, NSString *fieldName) {
	for (RptqDatabaseSchemaField *field in table.hasFields) {
		if ([field.name caseInsensitiveCompare:fieldName] == NSOrderedSame) return field;
	}
	return nil;
}

/// Adds one query table and one query field per named schema field; answers the
/// fields keyed by the schema field name.
static NSDictionary<NSString *, RptqQueryField *> *MADSampleAddQueryTable(RptqQuery *query,
																		  RptqDatabaseSchemaTable *schemaTable,
																		  NSArray<NSString *> *fieldNames) {
	RptqStoreContext *context = query.storeContext;
	RptqQueryTable *queryTable = [RptqQueryTable newQueryTableForSchemaTable:schemaTable
																	  query:query
														forManagedObjectContext:context];
	NSMutableArray<RptqQueryField *> *queryFields = [NSMutableArray arrayWithCapacity:fieldNames.count];
	NSMutableDictionary<NSString *, RptqQueryField *> *byName = [NSMutableDictionary dictionaryWithCapacity:fieldNames.count];
	for (NSString *fieldName in fieldNames) {
		RptqDatabaseSchemaField *schemaField = MADSampleSchemaField(schemaTable, fieldName);
		if (schemaField == nil) {
			fprintf(stderr, "schema table %s has no field %s\n",
					schemaTable.name.UTF8String, fieldName.UTF8String);
			continue;
		}
		RptqQueryField *queryField = [RptqQueryField newQueryField:context];
		queryField.inQueryTable = queryTable;
		queryField.databaseSchemaField = schemaField;
		[queryFields addObject:queryField];
		byName[fieldName.lowercaseString] = queryField;
	}
	queryTable.hasQueryFields = [NSSet setWithArray:queryFields];
	return byName;
}

static void MADSampleEnsureSectionRow(RptqDocumentSection *section) {
	if (section.hasRows.count > 0) return;
	RptqDocumentSectionRows *row = (RptqDocumentSectionRows *)
		[section.storeContext insertObjectForEntity:NSStringFromClass([RptqDocumentSectionRows class])
										 identifier:0];
	row.inSection = section;
	section.hasRows = [NSOrderedSet orderedSetWithObject:row];
}

static RptqDocumentElementLabel *MADSampleAddStaticLabel(RptqDocumentSection *section,
														  NSString *text,
														  CGFloat x, CGFloat y,
														  CGFloat width, CGFloat height,
														  double fontSize, BOOL bold) {
	MADSampleEnsureSectionRow(section);
	RptqStoreContext *context = section.storeContext;
	RptqDocumentElementLabel *label = (RptqDocumentElementLabel *)
		[context insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabel class]) identifier:0];
	label.type = MADPrintPageElementTypeLabelStatic;
	label.text = text;
	label.fontname = MADSampleFontName;
	label.fontsize = fontSize;
	label.textStyle.bold = bold;
	[section addDocumentObject:label withDropPoint:CGPointMake(x, y) managedObjectContext:context];
	[label setSizeWidth:(float)width height:(float)height];
	return label;
}

static RptqDocumentElementLabelDataField *MADSampleAddDataLabel(RptqDocumentSection *section,
																RptqQueryField *field,
																CGFloat x, CGFloat y,
																CGFloat width, CGFloat height,
																double fontSize) {
	if (field == nil) return nil;
	MADSampleEnsureSectionRow(section);
	RptqStoreContext *context = section.storeContext;
	RptqDocumentElementLabelDataField *label = (RptqDocumentElementLabelDataField *)
		[context insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier:0];
	label.type = MADPrintPageElementTypeLabelDynamic;
	label.fontname = MADSampleFontName;
	label.fontsize = fontSize;
	label.referencesQueryField = field;
	if (field.outputKey.length > 0) {
		label.fieldID = field.outputKey;
		label.tableID = field.inQueryTable.upstreamQuery.name ?: field.inQueryTable.alias;
		label.text = [NSString stringWithFormat:@"[%@]", field.outputKey];
	} else {
		label.fieldID = field.databaseSchemaField.name;
		label.tableID = [field.inQueryTable queryAlias] ?: field.inQueryTable.alias;
		label.text = [NSString stringWithFormat:@"[%@.%@]", label.tableID, label.fieldID];
	}
	[section addDocumentObject:label withDropPoint:CGPointMake(x, y) managedObjectContext:context];
	[label setSizeWidth:(float)width height:(float)height];
	return label;
}

static void MADSampleMakeGroup(RptqQuery *query, RptqQueryField *field,
							   MADSortOrder sort, int16_t weight) {
	RptqStoreContext *context = query.storeContext;
	RptqQueryGroup *group = [RptqQueryGroup newQueryGroupQueryWithSortOrder:sort
												   andManagedObjectContext:context];
	group.hasField = field;
	group.weight = weight;

	RptqDocumentSection *header = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeGroupHeader
														forManagedObjectContext:context];
	MADSampleEnsureSectionRow(header);
	[group addHasSectionObject:header];

	RptqDocumentSection *footer = [RptqDocumentSection newDocumentSectionOfType:MADDocumentSectionTypeGroupFooter
														forManagedObjectContext:context];
	MADSampleEnsureSectionRow(footer);
	[group addHasSectionObject:footer];

	[query addHasQueryGroupsObject:group];
}

static BOOL MADSampleWrite(MADHeadlessDocument *document, NSURL *url) {
	NSError *error = nil;
	[document invalidateQueryAndModelCaches];
	if (![document writeToURL:url reproducible:NO error:&error]) {
		fprintf(stderr, "write %s failed: %s\n", url.path.UTF8String,
				error.localizedDescription.UTF8String ?: "(no message)");
		return NO;
	}
	return YES;
}

#pragma mark - Verify

static BOOL MADSampleRefresh(MADHeadlessDocument *document, NSUInteger *outRows, NSError **outError) {
	MADOperationRefreshInitializeMainDataTable *initTable =
		[[MADOperationRefreshInitializeMainDataTable alloc] initWithDocument:document];
	MADOperationRefreshInitialize *initOp =
		[[MADOperationRefreshInitialize alloc] initWithDocument:document];
	[initOp addDependency:initTable];
	MADOperationRefresh *refreshOp = [[MADOperationRefresh alloc] initWithDocument:document];
	[refreshOp addDependency:initTable];
	[refreshOp addDependency:initOp];

	MADOperationQueue *queue = [[MADOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	[queue addOperation:initTable];
	[queue addOperation:initOp];
	[queue addOperation:refreshOp];

	NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:60.0];
	while (queue.operationCount > 0 && deadline.timeIntervalSinceNow > 0) {
		@autoreleasepool {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
									 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
		}
	}
	if (outRows != NULL) *outRows = document.dataTable.numberOfRows;
	if (!document.refreshed) {
		if (outError != NULL && refreshOp.errors.count > 0) {
			*outError = refreshOp.errors.firstObject;
		}
		return NO;
	}
	return YES;
}

static BOOL MADSampleVerify(NSURL *url, NSString *label, NSUInteger *outRows) {
	NSError *error = nil;
	MADHeadlessDocument *document = [MADHeadlessDocument documentWithContentsOfURL:url error:&error];
	if (document == nil) {
		fprintf(stderr, "FAIL %s: open: %s\n", label.UTF8String,
				error.localizedDescription.UTF8String ?: "(no message)");
		return NO;
	}
	NSUInteger rows = 0;
	if (!MADSampleRefresh(document, &rows, &error)) {
		fprintf(stderr, "FAIL %s: refresh: %s\n", label.UTF8String,
				error.description.UTF8String ?: "(no message)");
		return NO;
	}
	if (outRows != NULL) *outRows = rows;
	printf("verify %-28s %5lu rows\n", label.UTF8String, (unsigned long)rows);
	return YES;
}

#pragma mark - Standard sample

/// A Standard Report: one schema table (Artist), two projected fields, a
/// report header, column headers, a detail band, and a report footer.
static BOOL MADSampleWriteStandard(NSURL *url, NSURL *databaseURL) {
	NSError *error = nil;
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:databaseURL];
	MADHeadlessDocument *document = [MADHeadlessDocument createDocumentAtURL:url
													 withDatabaseConnection:connection
																credentials:nil
																	  error:&error];
	if (document == nil) {
		fprintf(stderr, "create standard sample: %s\n", error.localizedDescription.UTF8String ?: "(no message)");
		return NO;
	}

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext:document.storeContext];
	RptqDatabase *database = model.defaultDatabase;
	RptqQuery *query = database.defaultQuery;
	RptqDatabaseSchemaTable *artists = MADSampleSchemaTable(database, @"Artist");
	NSDictionary<NSString *, RptqQueryField *> *fields =
		MADSampleAddQueryTable(query, artists, @[@"ArtistId", @"Name"]);

	RptqDocumentSection *reportHeader = model.hasReportHeaderSection;
	RptqDocumentSection *pageHeader = model.hasPageHeaderSection;
	RptqDocumentSection *detail = model.hasDetailSection;
	RptqDocumentSection *pageFooter = model.hasPageFooterSection;
	RptqDocumentSection *reportFooter = model.hasReportFooterSection;

	MADSampleAddStaticLabel(reportHeader, @"Chinook Music Catalog",
							36.0, 12.0, 420.0, 28.0, 20.0, YES);
	MADSampleAddStaticLabel(reportHeader, @"Standard report · one table, no grouping",
							36.0, 40.0, 420.0, 16.0, 10.5, NO);
	[reportHeader setInterfaceHeight:64.0];

	MADSampleAddStaticLabel(pageHeader, @"Artist ID", 36.0, 4.0, 80.0, 16.0, 10.0, YES);
	MADSampleAddStaticLabel(pageHeader, @"Artist Name", 140.0, 4.0, 320.0, 16.0, 10.0, YES);
	[pageHeader setInterfaceHeight:24.0];

	MADSampleAddDataLabel(detail, fields[@"artistid"], 36.0, 3.0, 80.0, 18.0, 10.5);
	MADSampleAddDataLabel(detail, fields[@"name"], 140.0, 3.0, 380.0, 18.0, 10.5);
	[detail setInterfaceHeight:24.0];

	MADSampleAddStaticLabel(pageFooter, @"Chinook sample · Artists", 36.0, 3.0, 400.0, 14.0, 9.0, NO);
	[pageFooter setInterfaceHeight:20.0];

	MADSampleAddStaticLabel(reportFooter, @"275 artists · bundled with MAD Designer",
							36.0, 4.0, 400.0, 14.0, 9.0, NO);
	[reportFooter setInterfaceHeight:20.0];

	BOOL wrote = MADSampleWrite(document, url);
	[document.documentStore close];
	return wrote;
}

#pragma mark - Grouped sample

/// A grouped, multi-page Standard Report: Invoice rows grouped by CustomerId,
/// with a group header carrying the customer number and a group footer.
static BOOL MADSampleWriteGrouped(NSURL *url, NSURL *databaseURL) {
	NSError *error = nil;
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:databaseURL];
	MADHeadlessDocument *document = [MADHeadlessDocument createDocumentAtURL:url
													 withDatabaseConnection:connection
																credentials:nil
																	  error:&error];
	if (document == nil) {
		fprintf(stderr, "create grouped sample: %s\n", error.localizedDescription.UTF8String ?: "(no message)");
		return NO;
	}

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext:document.storeContext];
	RptqQuery *query = [MADSampleDefaultDatabase(document) defaultQuery];
	RptqDatabaseSchemaTable *invoices = MADSampleSchemaTable(model.defaultDatabase, @"Invoice");
	NSDictionary<NSString *, RptqQueryField *> *fields =
		MADSampleAddQueryTable(query, invoices, @[@"CustomerId", @"InvoiceId", @"InvoiceDate", @"Total"]);

	MADSampleMakeGroup(query, fields[@"customerid"], MADSortOrderAccending, 0);

	RptqDocumentSection *reportHeader = model.hasReportHeaderSection;
	RptqDocumentSection *pageHeader = model.hasPageHeaderSection;
	RptqDocumentSection *detail = model.hasDetailSection;
	RptqDocumentSection *pageFooter = model.hasPageFooterSection;
	RptqDocumentSection *reportFooter = model.hasReportFooterSection;

	MADSampleAddStaticLabel(reportHeader, @"Invoices by Customer",
							36.0, 12.0, 420.0, 28.0, 20.0, YES);
	MADSampleAddStaticLabel(reportHeader, @"Grouped report · 412 invoices in 59 customer groups",
							36.0, 40.0, 420.0, 16.0, 10.5, NO);
	[reportHeader setInterfaceHeight:64.0];

	MADSampleAddStaticLabel(pageHeader, @"Customer", 36.0, 4.0, 90.0, 16.0, 10.0, YES);
	MADSampleAddStaticLabel(pageHeader, @"Invoice #", 140.0, 4.0, 90.0, 16.0, 10.0, YES);
	MADSampleAddStaticLabel(pageHeader, @"Date", 240.0, 4.0, 110.0, 16.0, 10.0, YES);
	MADSampleAddStaticLabel(pageHeader, @"Total", 360.0, 4.0, 90.0, 16.0, 10.0, YES);
	[pageHeader setInterfaceHeight:24.0];

	RptqQueryGroup *group = [query sortedQueryGroups].firstObject;
	RptqDocumentSection *groupHeader = [RptqDocumentSection headerSectionInSections:group.hasSection];
	RptqDocumentSection *groupFooter = [RptqDocumentSection footerSectionInSections:group.hasSection];
	MADSampleAddStaticLabel(groupHeader, @"Customer", 36.0, 4.0, 60.0, 16.0, 10.0, YES);
	MADSampleAddDataLabel(groupHeader, fields[@"customerid"], 100.0, 4.0, 30.0, 16.0, 11.0);
	[groupHeader setInterfaceHeight:24.0];
	MADSampleAddStaticLabel(groupFooter, @"End of customer", 36.0, 2.0, 160.0, 14.0, 9.0, NO);
	[groupFooter setInterfaceHeight:18.0];

	MADSampleAddDataLabel(detail, fields[@"invoiceid"], 140.0, 3.0, 90.0, 18.0, 10.5);
	MADSampleAddDataLabel(detail, fields[@"invoicedate"], 240.0, 3.0, 110.0, 18.0, 10.5);
	MADSampleAddDataLabel(detail, fields[@"total"], 360.0, 3.0, 90.0, 18.0, 10.5);
	[detail setInterfaceHeight:24.0];

	MADSampleAddStaticLabel(pageFooter, @"Chinook sample · grouped report", 36.0, 3.0, 400.0, 14.0, 9.0, NO);
	[pageFooter setInterfaceHeight:20.0];

	MADSampleAddStaticLabel(reportFooter, @"412 invoices · grouped by CustomerId",
							36.0, 4.0, 400.0, 14.0, 9.0, NO);
	[reportFooter setInterfaceHeight:20.0];

	BOOL wrote = MADSampleWrite(document, url);
	[document.documentStore close];
	return wrote;
}

#pragma mark - Composition sources

/// A source report over Album with a small layout: header title and the three
/// album fields in the detail band.  Used as the composition's first source.
static BOOL MADSampleWriteAlbumSource(NSURL *url, NSURL *databaseURL) {
	NSError *error = nil;
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:databaseURL];
	MADHeadlessDocument *document = [MADHeadlessDocument createDocumentAtURL:url
													 withDatabaseConnection:connection
																credentials:nil
																	  error:&error];
	if (document == nil) return NO;

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext:document.storeContext];
	RptqQuery *query = [MADSampleDefaultDatabase(document) defaultQuery];
	RptqDatabaseSchemaTable *albums = MADSampleSchemaTable(model.defaultDatabase, @"Album");
	NSDictionary<NSString *, RptqQueryField *> *fields =
		MADSampleAddQueryTable(query, albums, @[@"AlbumId", @"Title", @"ArtistId"]);

	MADSampleAddStaticLabel(model.hasReportHeaderSection, @"Albums",
							36.0, 10.0, 420.0, 24.0, 17.0, YES);
	[model.hasReportHeaderSection setInterfaceHeight:48.0];
	MADSampleAddStaticLabel(model.hasPageHeaderSection, @"Album ID · Title · Artist ID",
							36.0, 4.0, 420.0, 16.0, 10.0, YES);
	[model.hasPageHeaderSection setInterfaceHeight:24.0];
	MADSampleAddDataLabel(model.hasDetailSection, fields[@"albumid"], 36.0, 3.0, 60.0, 18.0, 10.5);
	MADSampleAddDataLabel(model.hasDetailSection, fields[@"title"], 110.0, 3.0, 250.0, 18.0, 10.5);
	MADSampleAddDataLabel(model.hasDetailSection, fields[@"artistid"], 370.0, 3.0, 60.0, 18.0, 10.5);
	[model.hasDetailSection setInterfaceHeight:24.0];

	BOOL wrote = MADSampleWrite(document, url);
	[document.documentStore close];
	return wrote;
}

/// A source report over Artist with no layout elements.  It still projects
/// ArtistId and Name from labels that are deliberately not attached to a band,
/// so the imported source is a valid report of rows and the Viewer shows the
/// row grid instead of a page.
static BOOL MADSampleWriteArtistGridSource(NSURL *url, NSURL *databaseURL) {
	NSError *error = nil;
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:databaseURL];
	MADHeadlessDocument *document = [MADHeadlessDocument createDocumentAtURL:url
													 withDatabaseConnection:connection
																credentials:nil
																	  error:&error];
	if (document == nil) return NO;

	RptqDatabase *database = MADSampleDefaultDatabase(document);
	RptqQuery *query = database.defaultQuery;
	RptqDatabaseSchemaTable *artists = MADSampleSchemaTable(database, @"Artist");
	NSDictionary<NSString *, RptqQueryField *> *fields =
		MADSampleAddQueryTable(query, artists, @[@"ArtistId", @"Name"]);

	// A label is what makes a query field active.  These two are intentionally
	// not attached to any section: the source is a report of rows, not pages.
	for (RptqQueryField *field in fields.allValues) {
		RptqDocumentElementLabelDataField *label = (RptqDocumentElementLabelDataField *)
			[document.storeContext insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabelDataField class])
											  identifier:0];
		label.type = MADPrintPageElementTypeLabelDynamic;
		label.referencesQueryField = field;
		label.text = field.databaseSchemaField.name;
	}

	BOOL wrote = MADSampleWrite(document, url);
	[document.documentStore close];
	return wrote;
}

#pragma mark - Composition

static RptqQueryField *MADSampleRootField(RptqQuery *root, NSString *sourceName, NSString *fieldName) {
	for (RptqQueryTable *table in root.hasQueryTables) {
		if (![table.upstreamQuery.name isEqualToString:sourceName]) continue;
		for (RptqQueryField *field in table.hasQueryFields) {
			if ([field.databaseSchemaField.name caseInsensitiveCompare:fieldName] == NSOrderedSame) return field;
		}
	}
	return nil;
}

/// A Composition Report joining the Album source to the row-grid Artist source.
/// The Result's four projected columns are album_id, album_title, artist_id and
/// artist_name; the two ArtistId copies stay in the query as join keys.
static BOOL MADSampleWriteComposition(NSURL *url, NSURL *albumSourceURL, NSURL *artistSourceURL) {
	NSError *error = nil;
	MADHeadlessDocument *albumSource = [MADHeadlessDocument documentWithContentsOfURL:albumSourceURL error:&error];
	if (albumSource == nil) return NO;
	MADHeadlessDocument *artistSource = [MADHeadlessDocument documentWithContentsOfURL:artistSourceURL error:&error];
	if (artistSource == nil) return NO;

	MADHeadlessDocument *document = [MADHeadlessDocument createEmptyDocumentAtURL:url error:&error];
	if (document == nil) {
		fprintf(stderr, "create composition sample: %s\n", error.localizedDescription.UTF8String ?: "(no message)");
		return NO;
	}

	RptqStoreContext *context = document.storeContext;
	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext:context];
	RptqQuery *root = (RptqQuery *)[context insertObjectForEntity:NSStringFromClass([RptqQuery class]) identifier:0];
	root.name = @"Result";
	model.rootQuery = root;

	RptqQuery *albums = [context importQueryGraphFromContext:albumSource.storeContext
									   relativePathBaseURL:albumSourceURL
													  error:&error];
	if (albums == nil) return NO;
	albums.name = @"Albums";
	root.inDatabase = albums.inDatabase;
	[model addChildQuery:albums error:&error];

	RptqQuery *artists = [context importQueryGraphFromContext:artistSource.storeContext
										relativePathBaseURL:artistSourceURL
													   error:&error];
	if (artists == nil) return NO;
	artists.name = @"Artists";
	[model addChildQuery:artists error:&error];

	// Shape the Result's projection: friendly output keys, and the two join
	// keys out of the projection (they remain in the query for the link).
	RptqQueryField *albumId = MADSampleRootField(root, @"Albums", @"AlbumId");
	RptqQueryField *albumTitle = MADSampleRootField(root, @"Albums", @"Title");
	RptqQueryField *albumArtistId = MADSampleRootField(root, @"Albums", @"ArtistId");
	RptqQueryField *artistId = MADSampleRootField(root, @"Artists", @"ArtistId");
	RptqQueryField *artistName = MADSampleRootField(root, @"Artists", @"Name");
	albumId.outputKey = @"album_id"; albumId.outputIndex = 0;
	albumTitle.outputKey = @"album_title"; albumTitle.outputIndex = 1;
	artistId.outputKey = @"artist_id"; artistId.outputIndex = 2;
	artistName.outputKey = @"artist_name"; artistName.outputIndex = 3;
	albumArtistId.outputKey = nil;
	albumArtistId.outputIndex = 0;

	RptqQueryLinks *join = [RptqQueryLinks newQueryLinksWithLeftField:albumArtistId
														   rightField:artistId
															 joinType:MADLinkTypeInnerJoin
												 managedObjectContext:context];
	join.inQuery = root;

	// Result layout.
	MADSampleAddStaticLabel(model.hasReportHeaderSection, @"Albums & Artists",
							36.0, 12.0, 420.0, 28.0, 20.0, YES);
	MADSampleAddStaticLabel(model.hasReportHeaderSection, @"Composition report · two sources joined on ArtistId",
							36.0, 40.0, 420.0, 16.0, 10.5, NO);
	[model.hasReportHeaderSection setInterfaceHeight:64.0];

	MADSampleAddStaticLabel(model.hasPageHeaderSection, @"Album ID", 36.0, 4.0, 80.0, 16.0, 10.0, YES);
	MADSampleAddStaticLabel(model.hasPageHeaderSection, @"Album Title", 140.0, 4.0, 240.0, 16.0, 10.0, YES);
	MADSampleAddStaticLabel(model.hasPageHeaderSection, @"Artist", 410.0, 4.0, 160.0, 16.0, 10.0, YES);
	[model.hasPageHeaderSection setInterfaceHeight:24.0];

	MADSampleAddDataLabel(model.hasDetailSection, albumId, 36.0, 3.0, 80.0, 18.0, 10.5);
	MADSampleAddDataLabel(model.hasDetailSection, albumTitle, 140.0, 3.0, 240.0, 18.0, 10.5);
	MADSampleAddDataLabel(model.hasDetailSection, artistName, 410.0, 3.0, 160.0, 18.0, 10.5);
	[model.hasDetailSection setInterfaceHeight:24.0];

	MADSampleAddStaticLabel(model.hasPageFooterSection,
							@"Chinook sample · Albums source (layout) + Artists source (row grid)",
							36.0, 3.0, 460.0, 14.0, 9.0, NO);
	[model.hasPageFooterSection setInterfaceHeight:20.0];

	if (![model validateCompositionGraphWithError:&error]) {
		fprintf(stderr, "composition validation: %s\n", error.localizedDescription.UTF8String ?: "(no message)");
		return NO;
	}

	BOOL wrote = MADSampleWrite(document, url);
	[document.documentStore close];
	[albumSource.documentStore close];
	[artistSource.documentStore close];
	return wrote;
}

#pragma mark - PostgreSQL server sample

static BOOL MADSampleWritePostgres(NSURL *url) {
	NSDictionary<NSString *, NSString *> *env = NSProcessInfo.processInfo.environment;
	NSString *host = env[@"MAD_PG_SAMPLE_HOST"] ?: @"127.0.0.1";
	NSString *portString = env[@"MAD_PG_SAMPLE_PORT"] ?: @"5432";
	NSString *user = env[@"MAD_PG_SAMPLE_USER"] ?: @"mad";
	NSString *password = env[@"MAD_PG_SAMPLE_PASSWORD"] ?: @"";
	NSString *database = env[@"MAD_PG_SAMPLE_DATABASE"] ?: @"chinook";
	if (password.length == 0) {
		fprintf(stderr, "skip PostgreSQL sample: MAD_PG_SAMPLE_PASSWORD is not set\n");
		return NO;
	}

	NSError *error = nil;
	MADDatabaseConnectionPostgres *connection =
		[[MADDatabaseConnectionPostgres alloc] initWithHost:host
												   database:database
													andPort:portString.integerValue];
	MADCredential *credential = [[MADCredential alloc] initWithUsername:user andPassword:password];
	MADHeadlessDocument *document = [MADHeadlessDocument createDocumentAtURL:url
													 withDatabaseConnection:connection
																credentials:credential
																	  error:&error];
	if (document == nil) {
		fprintf(stderr, "create PostgreSQL sample: %s\n", error.localizedDescription.UTF8String ?: "(no message)");
		return NO;
	}

	RptqDocument *model = [RptqDocument newDocumentReadFromManagedObjectContext:document.storeContext];
	RptqQuery *query = [MADSampleDefaultDatabase(document) defaultQuery];
	RptqDatabaseSchemaTable *albums = MADSampleSchemaTable(model.defaultDatabase, @"album");
	if (albums == nil) albums = MADSampleSchemaTable(model.defaultDatabase, @"Album");
	NSDictionary<NSString *, RptqQueryField *> *fields =
		MADSampleAddQueryTable(query, albums, @[@"album_id", @"title", @"artist_id"]);

	// The username is a hint for the connection sheet, never a credential: the
	// test password is deliberately absent from the document.  `domain` is the
	// unused column on a PostgreSQL credential row (MAD uses it only for TDS).
	RptqDatabaseCredentals *credentials = model.defaultDatabase.ownedByUser;
	if (credentials != nil) credentials.domain = user;

	MADSampleAddStaticLabel(model.hasReportHeaderSection, @"Chinook Music Catalog",
							36.0, 12.0, 420.0, 28.0, 20.0, YES);
	MADSampleAddStaticLabel(model.hasReportHeaderSection, @"PostgreSQL sample · password is asked at refresh",
							36.0, 40.0, 420.0, 16.0, 10.5, NO);
	[model.hasReportHeaderSection setInterfaceHeight:64.0];

	MADSampleAddStaticLabel(model.hasPageHeaderSection, @"Album ID", 36.0, 4.0, 80.0, 16.0, 10.0, YES);
	MADSampleAddStaticLabel(model.hasPageHeaderSection, @"Title", 140.0, 4.0, 340.0, 16.0, 10.0, YES);
	[model.hasPageHeaderSection setInterfaceHeight:24.0];
	MADSampleAddDataLabel(model.hasDetailSection, fields[@"album_id"], 36.0, 3.0, 80.0, 18.0, 10.5);
	MADSampleAddDataLabel(model.hasDetailSection, fields[@"title"], 140.0, 3.0, 380.0, 18.0, 10.5);
	[model.hasDetailSection setInterfaceHeight:24.0];

	MADSampleAddStaticLabel(model.hasPageFooterSection, @"PostgreSQL · Chinook",
							36.0, 3.0, 400.0, 14.0, 9.0, NO);
	[model.hasPageFooterSection setInterfaceHeight:20.0];

	BOOL wrote = MADSampleWrite(document, url);
	[document.documentStore close];
	return wrote;
}

#pragma mark - main

int main(int argc, const char *argv[]) {
	@autoreleasepool {
		if (argc < 3) {
			fprintf(stderr, "usage: MADSampleMaker <output-directory> <chinook.sqlite3> [postgres]\n");
			return 1;
		}
		NSURL *directory = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]] isDirectory:YES];
		NSURL *chinook = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[2]] isDirectory:NO];
		BOOL makePostgres = (argc >= 4 && strcmp(argv[3], "postgres") == 0);

		NSError *error = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtURL:directory
									 withIntermediateDirectories:YES
													  attributes:nil
														   error:&error]) {
			fprintf(stderr, "cannot create %s: %s\n", directory.path.UTF8String,
					error.localizedDescription.UTF8String ?: "(no message)");
			return 1;
		}

		NSURL *dbCopy = [directory URLByAppendingPathComponent:@"chinook.sqlite3" isDirectory:NO];
		if (![dbCopy.path isEqualToString:chinook.path]) {
			[[NSFileManager defaultManager] removeItemAtURL:dbCopy error:NULL];
			if (![[NSFileManager defaultManager] copyItemAtURL:chinook toURL:dbCopy error:&error]) {
				fprintf(stderr, "cannot copy chinook: %s\n", error.localizedDescription.UTF8String ?: "(no message)");
				return 1;
			}
		}

		NSURL *standardURL = [directory URLByAppendingPathComponent:@"Chinook-Standard.mad" isDirectory:NO];
		NSURL *groupedURL = [directory URLByAppendingPathComponent:@"Chinook-Grouped.mad" isDirectory:NO];
		NSURL *compositionURL = [directory URLByAppendingPathComponent:@"Chinook-Composition.mad" isDirectory:NO];
		NSURL *albumSourceURL = [directory URLByAppendingPathComponent:@".Album-Source.mad" isDirectory:NO];
		NSURL *artistSourceURL = [directory URLByAppendingPathComponent:@".Artist-Grid-Source.mad" isDirectory:NO];
		NSURL *postgresURL = [directory URLByAppendingPathComponent:@"PostgreSQL-Chinook.mad" isDirectory:NO];

		BOOL ok = YES;
		ok = MADSampleWriteStandard(standardURL, dbCopy) && ok;
		ok = MADSampleWriteGrouped(groupedURL, dbCopy) && ok;
		ok = MADSampleWriteAlbumSource(albumSourceURL, dbCopy) && ok;
		ok = MADSampleWriteArtistGridSource(artistSourceURL, dbCopy) && ok;
		ok = MADSampleWriteComposition(compositionURL, albumSourceURL, artistSourceURL) && ok;
		[[NSFileManager defaultManager] removeItemAtURL:albumSourceURL error:NULL];
		[[NSFileManager defaultManager] removeItemAtURL:artistSourceURL error:NULL];

		if (makePostgres) {
			BOOL wrote = MADSampleWritePostgres(postgresURL);
			ok = wrote && ok;
		}

		if (!ok) return 1;

		NSUInteger standardRows = 0, groupedRows = 0, compositionRows = 0;
		if (!MADSampleVerify(standardURL, @"Chinook-Standard.mad", &standardRows)) return 1;
		if (!MADSampleVerify(groupedURL, @"Chinook-Grouped.mad", &groupedRows)) return 1;
		if (!MADSampleVerify(compositionURL, @"Chinook-Composition.mad", &compositionRows)) return 1;

		if (standardRows == 0 || groupedRows == 0 || compositionRows == 0) {
			fprintf(stderr, "a sample refreshed to zero rows\n");
			return 1;
		}
		printf("wrote samples in %s\n", directory.path.UTF8String);
		return 0;
	}
}
