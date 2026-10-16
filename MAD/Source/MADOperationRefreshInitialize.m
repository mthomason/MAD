//
//  MADOperationRefreshInitialize.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/2/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationRefreshInitialize.h"
#import "MADOperationRefreshInitalizeMainDataTable.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>

#import <MADFoundation/MADDataTable.h>

#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADReportFormatter.h>
#import <MAD/MADSectionLayoutManager.h>
#import <MAD/MADQueryFull.h>
#import <MAD/MADDatabase+Constructor.h>

#import <MAD/RptqDocument+extras.h>
#import <MAD/RptqDatabase+extras.h>
#import <MAD/RptqQuery+extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSectionEnumerator.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>


@interface MADOperationRefreshInitialize ()

	@property (nonatomic, weak) MADocument *document;
	@property (nonatomic, assign) BOOL success;

@end

// The portable store context is main-queue-owned.  Marshal store reads onto
// the main queue (inline when already there) rather than taking a lock in
// every accessor.  See BUGS.md "The refresh path reads the shared store
// context from operation-queue threads".
static void MADOperationRefreshInitializeRunOnMain(dispatch_block_t block) {
	if ([NSThread isMainThread]) block();
	else dispatch_sync(dispatch_get_main_queue(), block);
}

@implementation MADOperationRefreshInitialize

- (void)dealloc {}

- (instancetype)initWithDocument:(MADocument *)document {
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
	
	MADocument *doc = _document;
	for (NSOperation *dependency in self.dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationRefreshInitializeMainDataTableProtocol)]) {
			doc = ((id <MADOperationRefreshInitializeMainDataTableProtocol>)dependency).document;
			break;
		}
	}
	MADocument *document = doc;
	
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
			MADDatabaseConnection *databaseConnection = [MADDatabaseConnection newDatabaseConnection:rptqUser];
			[document updateDatabaseWithConnection:databaseConnection];
		}

		if (rptqDatabase == nil || rptqQuery == nil) {
			rptqDatabase = rptqDocument.hasDatabaseSchemas.anyObject;
			rptqQuery = rptqDatabase.hasQueries.anyObject;
		}
		[document dataTableSort:rptqQuery];
	});

	document.database.delegate = (id <MADDatabaseResultsProtocol>)doc;
	[document resetSectionLayoutManagers];
	MADReportFormatter *formatter = [MADReportFormatter newReportFormatterWithLayout: document
																			 options: MADReportFormatterOptionsNone];

	document.reportFormatter = formatter;

	[self finish];

}

@end
