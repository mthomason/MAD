//
//  MADModelDocument.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADModelDocument.h"
#import <MAD/RptqStoreContext.h>
#import "MADModelDatabase.h"
#import "MADModelQuery.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "RptqQueryLinks.h"
#import "RptqQueryTable.h"
#import "madlog.h"

#import <MADFoundation/MADStringUtilities.h>

#import <Foundation/NSExpression.h>
#import <Foundation/NSOperation.h>
#import <CoreFoundation/CFNumber.h>

static NSString *keyIDDatabase = @"ID";
static NSString *keyIDQuery = @"IQ";
static NSString *keyIDDocument = @"IO";

@interface MADModelDocument ()
	- (instancetype)initWithContext:(RptqStoreContext *)managedObjectContext;
	@property (nonatomic, readwrite, strong) NSMutableOrderedSet <MADModelDatabase *> *databases;
@end

#pragma mark -
#pragma mark MAD Document Object ID

@implementation MADModelDocument {
@protected
	NSOperationQueue *_objectContextQueue;
	RptqStoreContext * __weak _managedObjectContext;
	id <NSObject> _observeChangeNotification;
	id <NSObject> _observeWillSaveNotification;
	id <NSObject> _observeDidSaveNotification;
}
@synthesize managedObjectContext = _managedObjectContext;

- (void)dealloc {
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:_observeChangeNotification];
	[notificationCenter removeObserver:_observeWillSaveNotification];
	[notificationCenter removeObserver:_observeDidSaveNotification];
	_managedObjectContext = nil;
}

- (instancetype)init {
	if (self = [self initWithIdentifier: -1 managedObjectContext: nil]) {
		
	}
	return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier {
	if (self = [self initWithIdentifier:identifier managedObjectContext:nil]) {
		
	}
	return self;
}

- (instancetype)initWithContext:(RptqStoreContext *)managedObjectContext {
	if (self = [self initWithIdentifier: -1 managedObjectContext:managedObjectContext]) {
		
	}
	return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
			  managedObjectContext:(RptqStoreContext *)managedObjectContext {
	if (self = [super initWithIdentifier:identifier]) {
		_managedObjectContext = managedObjectContext;
		
		NSOperationQueue *objectContextQueue;
		objectContextQueue = [[NSOperationQueue alloc] init];
		objectContextQueue.qualityOfService = NSOperationQualityOfServiceUserInitiated;
		
		__weak MADModelDocument *wself = self;
		void (^blockChange)(NSNotification *) = ^(NSNotification *note) {
			//id keys = note.userInfo.keyEnumerator;
			//id objects = note.userInfo.objectEnumerator;
			
			NSSet *deletedObjects, *updatedObjects, *insertedObjects;

			insertedObjects = [note.userInfo objectForKey:RptqStoreContextInsertedObjectsKey];
			[insertedObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull __unused stop) {
				
				if ([obj isKindOfClass:[RptqQueryLinks class]]) {
					__strong MADModelDocument *sself = wself;
					if (sself) {
						MADModelQuery *query = sself.firstQuery;
						[query insertQueryLink:obj];
					}
				}
				
				if ([obj isKindOfClass:[RptqQueryTable class]]) {
					__strong MADModelDocument *sself = wself;
					if (sself) {
						MADModelQuery *query = sself.firstQuery;
						[query insertQueryTable: obj];
					}
				}
				
			}];

			
			updatedObjects = [note.userInfo objectForKey:RptqStoreContextUpdatedObjectsKey];
			[updatedObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull __unused stop) {
				
				if ([obj isKindOfClass:[RptqQueryLinks class]]) {
					//typeof(self) sself = wself;
					//MADModelQuery *query = sself.firstQuery;
				}
				
				if ([obj isKindOfClass:[RptqQueryTable class]]) {
					//typeof(self) sself = wself;
					//MADModelQuery *query = sself.firstQuery;
				}
				
			}];
			
			deletedObjects = [note.userInfo objectForKey:RptqStoreContextDeletedObjectsKey];
			[deletedObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull __unused stop) {
				
				if ([obj isKindOfClass:[RptqQueryLinks class]]) {
					__strong MADModelDocument *sself = wself;
					if (sself) {
						MADModelQuery *query = sself.firstQuery;
						NSNumber *idn = @(((RptqQueryLinks *)obj).identifier);
						[query deleteQueryLinkID:idn];
					}
				}
				
				if ([obj isKindOfClass:[RptqQueryTable class]]) {
					__strong MADModelDocument *sself = wself;
					if (sself) {
						MADModelQuery *query = sself.firstQuery;
						NSNumber *idn = @(((RptqQueryTable *)obj).identifier);
						[query deleteQueryTableID:idn];
					}
				}
				
			}];

		};
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		_observeChangeNotification = [notificationCenter addObserverForName:RptqStoreContextObjectsDidChangeNotification
																	 object:managedObjectContext
																	  queue:_objectContextQueue
																 usingBlock:blockChange];
		
		_observeWillSaveNotification = [notificationCenter addObserverForName:RptqStoreContextWillSaveNotification
																	   object:managedObjectContext
																		queue:_objectContextQueue
																   usingBlock:^(NSNotification * _Nonnull note) {
			os_log_debug(OS_LOG_DEFAULT, "%@: %@", NSStringFromClass(note.class), note);
		}];
		_observeDidSaveNotification = [notificationCenter addObserverForName:RptqStoreContextDidSaveNotification
																	  object:managedObjectContext
																	   queue:_objectContextQueue
																  usingBlock:^(NSNotification * _Nonnull note) {
			os_log_debug(OS_LOG_DEFAULT, "%@: %@", NSStringFromClass(note.class), note);
		}];

		[self updateDocumentDatabaseQuery];

		_objectContextQueue = objectContextQueue;
		_managedObjectContext = managedObjectContext;
	}
	return self;
}

- (NSMutableOrderedSet <MADModelDatabase *> *)databases {
	if (!_databases) {
		[self update];
	}
	return _databases;
}

- (MADModelDatabase *)firstDatabase {
	return self.databases.firstObject;
}

- (MADModelQuery *)firstQuery {
	return self.firstDatabase.firstQuery;
}

- (void)update {
	@autoreleasepool {
		[self updateDocumentDatabaseQuery];
	}
}

//Load all the databases and queries for this document.  This is because current versions
// of the software only use one database and query.

- (void)updateDocumentDatabaseQuery {

	RptqStoreContext *managedObjectContext = _managedObjectContext;
	NSArray *queries = [managedObjectContext objectsForEntity:NSStringFromClass([RptqQuery class])];

	NSMutableArray *results = [NSMutableArray arrayWithCapacity:queries.count];
	for (RptqQuery *query in queries) {
		[results addObject:@{
			keyIDQuery: @(query.identifier),
			keyIDDatabase: @(query.inDatabase.identifier),
			keyIDDocument: @(query.inDatabase.ownedByQueryAsStaticResource.identifier),
		}];
	}

	if (results.count == 0) return;
	
	NSMutableOrderedSet <MADModelDatabase *> *databases = [[NSMutableOrderedSet <MADModelDatabase *> alloc] initWithCapacity:results.count];
	for (NSDictionary <NSString *, __kindof NSObject *> *resultWrapper in results) {
		int64_t docID = 0, dbID = 0, qID = 0;
		CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)resultWrapper[keyIDQuery], kCFNumberSInt64Type, &qID);
		CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)resultWrapper[keyIDDatabase], kCFNumberSInt64Type, &dbID);
		CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)resultWrapper[keyIDDocument], kCFNumberSInt64Type, &docID);
		MADModelDatabase *database = [[MADModelDatabase alloc] initWithIdentifier: dbID
																  queryIdentifier: qID
															 managedObjectContext: managedObjectContext];
		[databases addObject: database];
		database = nil;
	}
	
	_databases = databases;
}

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	[debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
	[debug appendFormat:@"ID:\t%lld\n", self.identifier];
	if (_databases.count > 0) {
		[debug appendFormat:@"Databases:\t%@", _databases];
	}
	return debug;
}

@end
