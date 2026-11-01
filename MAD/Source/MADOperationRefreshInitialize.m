//
//  MADOperationRefreshInitialize.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADOperationRefreshInitialize.h"
#import "MADOperationRefreshInitalizeMainDataTable.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseConnectionsPropertiesURLProtocol.h>
#import <MADAPI/MADDatabase.h>

#import <MADFoundation/MADDataTable.h>

#import <MAD/MADDocumentDataProtocol.h>
#import <MAD/MADHeadlessDocument.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADQueryFull.h>
#import <MAD/MADDatabase+Constructor.h>
#import <MAD/MADDatabaseConnection+Constructor.h>

#if TARGET_OS_IPHONE
// The rendering side of a document, which only a MADocument has: the report
// formatter that draws the report and the section layout managers that measure it.
// MADReportFormatter, MADSectionLayoutManager and MADocument are all excluded from
// the Linux build (docs/project/MAD_LINUX.md §9 Phase D), so this is the one branch of the
// refresh chain that does not compile there -- and a headless document has nothing
// to render, so the branch is skipped rather than stubbed.
#import <MAD/MADocument.h>
#import <MAD/MADReportFormatter.h>
#endif

#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSectionEnumerator.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>


@interface MADOperationRefreshInitialize ()

	@property (nonatomic, weak) id <MADDocumentDataProtocol> document;
	@property (nonatomic, assign) BOOL success;

@end

// The portable store context is main-queue-owned.  Marshal store reads onto
// the main queue (inline when already there) rather than taking a lock in
// every accessor.  See docs/project/BUGS.md "The refresh path reads the shared store
// context from operation-queue threads".
static void MADOperationRefreshInitializeRunOnMain(dispatch_block_t block) {
	if ([NSThread isMainThread]) block();
	else dispatch_sync(dispatch_get_main_queue(), block);
}

@implementation MADOperationRefreshInitialize

- (void)dealloc {}

- (instancetype)initWithDocument:(id <MADDocumentDataProtocol>)document {
	if (self = [super init]) {
		_document = document;
		_success = NO;
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	if (self.cancelled) {
		return [self finish];
	}
	
	id <MADDocumentDataProtocol> doc = _document;
	for (NSOperation *dependency in self.dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationRefreshInitializeMainDataTableProtocol)]) {
			doc = ((id <MADOperationRefreshInitializeMainDataTableProtocol>)dependency).document;
			break;
		}
	}
	id <MADDocumentDataProtocol> document = doc;
	
	// The document-graph reads and the sort (which reads the query's sort
	// descriptors) run on main; only the resolved query crosses back to this
	// operation thread.
	__block RptqQuery *rptqQuery = nil;
	MADOperationRefreshInitializeRunOnMain(^{
		RptqStoreContext *private = doc.storeContext;
		RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: private];
		if (rptqDocument == nil) {
			rptqDocument = [RptqDocument newDocumentForManagedObjectContext: private];
		}

		RptqDatabase *rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
		rptqQuery = rptqDatabase.hasQueries.anyObject;

		if (document.database == nil) {
			RptqDatabaseCredentals *rptqUser = rptqQuery.inDatabase.ownedByUser;
			NSURL *docURL = [document respondsToSelector:@selector(fileURL)] ? [(id)document fileURL] : nil;
			MADDatabaseConnection *databaseConnection = [MADDatabaseConnection newDatabaseConnection:rptqUser documentURL:docURL];
			[document updateDatabaseWithConnection:databaseConnection];
		} else if (document.database.databaseConnection.databaseType == MADDatabaseTypeSqlite3 &&
				   [document.database.databaseConnection conformsToProtocol:@protocol(MADDatabaseConnectionsPropertiesURL)]) {
			NSURL *curUrl = ((id <MADDatabaseConnectionsPropertiesURL>)document.database.databaseConnection).databaseUrl;
			NSString *curPath = curUrl.path;
			NSFileManager *fm = [NSFileManager defaultManager];
			BOOL existsNonEmpty = (curPath.length > 0 && [fm fileExistsAtPath:curPath] && [[fm attributesOfItemAtPath:curPath error:nil] fileSize] > 0);
			if (!existsNonEmpty) {
				RptqDatabaseCredentals *rptqUser = rptqQuery.inDatabase.ownedByUser;
				NSURL *docURL = [document respondsToSelector:@selector(fileURL)] ? [(id)document fileURL] : nil;
				if (rptqUser != nil) {
					MADDatabaseConnection *resolved = [MADDatabaseConnection newDatabaseConnection:rptqUser documentURL:docURL];
					if (resolved != nil) {
						[document updateDatabaseWithConnection:resolved];
					}
				}
			}
		}

		if (rptqDatabase == nil || rptqQuery == nil) {
			rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
			rptqQuery = rptqDatabase.hasQueries.anyObject;
		}
		[document dataTableSort:rptqQuery];
	});

	document.database.delegate = (id <MADDatabaseResultsProtocol>)doc;

#if TARGET_OS_IPHONE
	// A document that renders gets its formatter here, before the refresh runs:
	// MADOperationRefresh sets -refreshed on the way out and MADocument keeps that
	// flag on the formatter.  A headless document keeps its own.
	if ([doc isKindOfClass: [MADocument class]]) {
		MADocument *layout = (MADocument *)doc;
		[layout resetSectionLayoutManagers];
		layout.reportFormatter = [MADReportFormatter newReportFormatterWithLayout: layout
																		 options: MADReportFormatterOptionsNone];
	}
#endif

	[self finish];

}

@end
