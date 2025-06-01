//
//  MADModelDocument.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADModelDocument.h"
#import "madlog.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSExpression.h>
#import <Foundation/NSOperation.h>

#import <CoreData/CoreData.h>
#import <MADFoundation/MADStringUtilities.h>

#import "MADModelDatabase.h"
#import "MADModelQuery.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "RptqQueryLinks.h"
#import "RptqQueryTable.h"

static NSString *keyDatabase = @"DA";
static NSString *keyQuery = @"QU";
static NSString *keyDocument = @"DO";
static NSString *keyIDDatabase = @"ID";
static NSString *keyIDQuery = @"IQ";
static NSString *keyIDDocument = @"IO";

@interface MADModelDocument ()
	- (instancetype)initWithContext:(NSManagedObjectContext *)managedObjectContext;
	@property (nonatomic, readwrite, strong) NSMutableOrderedSet <MADModelDatabase *> *databases;
@end

#pragma mark -
#pragma mark MAD Document Object ID

@implementation MADModelDocument {
@protected
	NSOperationQueue *_objectContextQueue;
	NSManagedObjectContext * __weak _managedObjectContext;
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

- (instancetype)initWithContext:(NSManagedObjectContext *)managedObjectContext {
	if (self = [self initWithIdentifier: -1 managedObjectContext:managedObjectContext]) {
		
	}
	return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
			  managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	if (self = [super initWithIdentifier:identifier]) {
		_managedObjectContext = managedObjectContext;
		
		NSOperationQueue *objectContextQueue;
		objectContextQueue = [[NSOperationQueue alloc] init];
		objectContextQueue.qualityOfService = NSOperationQualityOfServiceUserInitiated;
		
		__typeof(self) __weak wself = self;
		void (^blockChange)(NSNotification *) = ^(NSNotification *note) {
			//NSLog(@"%@: %@", NSStringFromClass(note.class), note);
			//id keys = note.userInfo.keyEnumerator;
			//id objects = note.userInfo.objectEnumerator;
			
			NSSet *deletedObjects, *updatedObjects, *insertedObjects, *invalidatedObjects;

			NSString *keyManagedObjectContext;
			NSManagedObjectContext *objectContext;
			
			keyManagedObjectContext = NSStringFromSelector(@selector(managedObjectContext));
			objectContext = [note.userInfo objectForKey:keyManagedObjectContext];
			insertedObjects = [note.userInfo objectForKey:NSInsertedObjectsKey];
			[insertedObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
				
				if ([obj isKindOfClass:[RptqQueryLinks class]]) {
					typeof(self) sself = wself;
					MADModelQuery *query = sself.firstQuery;
					[query insertQueryLink:obj];
				}
				
				if ([obj isKindOfClass:[RptqQueryTable class]]) {
					typeof(self) sself = wself;
					MADModelQuery *query = sself.firstQuery;
					[query insertQueryTable: obj];
				}
				
			}];

			
			updatedObjects = [note.userInfo objectForKey:NSUpdatedObjectsKey];
			[updatedObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
				
				if ([obj isKindOfClass:[RptqQueryLinks class]]) {
					//typeof(self) sself = wself;
					//MADModelQuery *query = sself.firstQuery;
					//[query deleteQueryLinkID:((NSManagedObject *)obj).objectID];
				}
				
				if ([obj isKindOfClass:[RptqQueryTable class]]) {
					//typeof(self) sself = wself;
					//MADModelQuery *query = sself.firstQuery;
					//[query deleteQueryTableID:((NSManagedObject *)obj).objectID];
				}
				
			}];
			
			deletedObjects = [note.userInfo objectForKey:NSDeletedObjectsKey];
			[deletedObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
				
				if ([obj isKindOfClass:[RptqQueryLinks class]]) {
					typeof(self) sself = wself;
					MADModelQuery *query = sself.firstQuery;
					NSNumber *idn = @(((RptqQueryLinks *)obj).identifier);
					[query deleteQueryLinkID:idn];
				}
				
				if ([obj isKindOfClass:[RptqQueryTable class]]) {
					typeof(self) sself = wself;
					MADModelQuery *query = sself.firstQuery;
					NSNumber *idn = @(((RptqQueryTable *)obj).identifier);
					[query deleteQueryTableID:idn];
				}
				
			}];
			
			invalidatedObjects = [note.userInfo objectForKey:NSInvalidatedObjectsKey];
			
		};
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		_observeChangeNotification = [notificationCenter addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
																	 object:managedObjectContext
																	  queue:_objectContextQueue
																 usingBlock:blockChange];
		
		_observeWillSaveNotification = [notificationCenter addObserverForName:NSManagedObjectContextWillSaveNotification
																	   object:managedObjectContext
																		queue:_objectContextQueue
																   usingBlock:^(NSNotification * _Nonnull note) {
																	   NSLog(@"%@: %@", NSStringFromClass(note.class), note);
																   }];
		_observeDidSaveNotification = [notificationCenter addObserverForName:NSManagedObjectContextDidSaveNotification
																	  object:managedObjectContext
																	   queue:_objectContextQueue
																  usingBlock:^(NSNotification * _Nonnull note) {
																	  NSLog(@"%@: %@", NSStringFromClass(note.class), note);
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

// MARK: Fetch request <RptqDocument::ObjectID>.

+ (NSFetchRequest <NSManagedObjectID *> *)fetchRequestObjectID {
	NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([RptqDocument class])];
	request.fetchLimit = 1;
	request.resultType = NSManagedObjectIDResultType;
	request.includesSubentities = NO;
	request.includesPropertyValues = NO;
	return request;
}

// MARK: Fetch request <RptqDocument::ObjectID, RptqDatabase::ObjectID, RptqQuery::ObjectID>.

+ (NSFetchRequest <NSDictionary <NSString *, __kindof NSObject *> *> *)fetchRequestDocDBQueryIDs {
	void (^initExpression)(NSExpressionDescription *, NSString *, NSExpression *, NSAttributeType) = ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression, NSAttributeType type) {
		expressionDescription.name = [name copy];
		expressionDescription.expression = [expression copy];
		expressionDescription.expressionResultType = type;
	};
	
	NSUInteger expressionCount = 6;
	NSMutableArray <NSExpressionDescription *> *expressionDescriptions = [[NSMutableArray alloc] initWithCapacity:expressionCount];
	
	for (NSUInteger i=0; i<expressionCount; i++) {
		NSExpressionDescription *description = [[NSExpressionDescription alloc] init];
		[expressionDescriptions addObject: description];
	}
	
	
	NSString *inDocument = [[MADStringUtilities stringByAppendingPeriod:NSStringFromSelector(@selector(inDatabase))] stringByAppendingString: NSStringFromSelector(@selector(ownedByQueryAsStaticResource))];
	NSString *inDBID = [[MADStringUtilities stringByAppendingPeriod:NSStringFromSelector(@selector(inDatabase))] stringByAppendingString:NSStringFromSelector(@selector(identifier))];
	NSString *inDocID = [[MADStringUtilities stringByAppendingPeriod:inDocument] stringByAppendingString:NSStringFromSelector(@selector(identifier))];
	
	initExpression(expressionDescriptions[0], keyDatabase, [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(inDatabase))], NSObjectIDAttributeType);
	initExpression(expressionDescriptions[1], keyDocument, [NSExpression expressionForKeyPath:inDocument], NSObjectIDAttributeType);
	initExpression(expressionDescriptions[2], keyQuery, [NSExpression expressionForEvaluatedObject], NSObjectIDAttributeType);
	initExpression(expressionDescriptions[3], keyIDDatabase, [NSExpression expressionForKeyPath:inDBID], NSInteger64AttributeType);
	initExpression(expressionDescriptions[4], keyIDQuery, [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(identifier))], NSInteger64AttributeType);
	initExpression(expressionDescriptions[5], keyIDDocument, [NSExpression expressionForKeyPath:inDocID], NSInteger64AttributeType);
	
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQuery class])];
	request.resultType = NSDictionaryResultType;
	request.propertiesToFetch = expressionDescriptions;
	return request;
}

//Load all the databases and queries for this document.  This is because current versions
// of the software only use one database and query.

- (void)updateDocumentDatabaseQuery {
	
	NSManagedObjectContext *managedObjectContext = _managedObjectContext;
	NSFetchRequest *request = [MADModelDocument fetchRequestDocDBQueryIDs];
	
	NSError *error = nil;
	NSArray <NSDictionary *> *results = [managedObjectContext executeFetchRequest:request error:&error];
	if (error != nil) {
		os_log_error(GetMadLog(), "%s Error fetching: %@", __PRETTY_FUNCTION__, error);
	}
	
	//NSAssert(results.count > 0, @"We expect results.");
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
