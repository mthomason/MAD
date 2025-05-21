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

static NSString *keyDatabase = @"DA", *keyQuery = @"QU", *keyDocument = @"DO",
				*keyIDDatabase = @"ID", *keyIDQuery = @"IQ", *keyIDDocument = @"IO";

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
		void (^blockChange)(NSNotification *);
		blockChange = ^(NSNotification *note) {
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
	NSFetchRequest *request;
	request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([RptqDocument class])];
	request.fetchLimit = 1;
	request.resultType = NSManagedObjectIDResultType;
	request.includesSubentities = NO;
	request.includesPropertyValues = NO;
	return request;
}

// MARK: Fetch request <RptqDocument::ObjectID, RptqDatabase::ObjectID, RptqQuery::ObjectID>.

+ (NSFetchRequest <NSDictionary <NSString *, __kindof NSObject *> *> *)fetchRequestDocDBQueryIDs {
	NSFetchRequest *request;
	
	void (^initExpression)(NSExpressionDescription *, NSString *,
							NSExpression *, NSAttributeType) =
	^void(NSExpressionDescription *expressionDescription, NSString *name,
		  NSExpression *expression, NSAttributeType type) {
		expressionDescription.name = name.copy;
		expressionDescription.expression = expression;
		expressionDescription.expressionResultType = type;
	};
	
	NSUInteger expressionCount = 6;
	NSExpressionDescription *description[expressionCount];
	
	for (NSUInteger i=0; i<expressionCount; i++) {
		description[i] = [[NSExpressionDescription alloc] init];
	}
	
	request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQuery class])];
	
	NSString *identifier = NSStringFromSelector(@selector(identifier));
	NSString *inDatabase = NSStringFromSelector(@selector(inDatabase));
	NSString *inDocument;
	NSString *keyOwnedByQuery = NSStringFromSelector(@selector(ownedByQueryAsStaticResource));
	inDocument = [MADStringUtilities stringByAppendingPeriodToString:inDatabase];
	inDocument = [inDocument stringByAppendingString: keyOwnedByQuery];
	
	NSString *inDBID = [MADStringUtilities stringByAppendingPeriodToString:inDatabase];
	inDBID = [inDBID stringByAppendingString:identifier];
	
	NSString *inDocID = [MADStringUtilities stringByAppendingPeriodToString:inDocument];
	inDocID = [inDocID stringByAppendingString:identifier];
	
	NSExpression *dbExpression = [NSExpression expressionForKeyPath:inDatabase];
	NSExpression *dbInDocExpression = [NSExpression expressionForKeyPath:inDocument];
	NSExpression *selfExpresssion = [NSExpression expressionForEvaluatedObject];
	NSExpression *dbIDExpression = [NSExpression expressionForKeyPath:inDBID];
	NSExpression *queryIDExpression = [NSExpression expressionForKeyPath:identifier];
	NSExpression *docIDExpression = [NSExpression expressionForKeyPath:inDocID];

	initExpression(description[0], keyDatabase, dbExpression, NSObjectIDAttributeType);
	initExpression(description[1], keyDocument, dbInDocExpression, NSObjectIDAttributeType);
	initExpression(description[2], keyQuery, selfExpresssion, NSObjectIDAttributeType);
	initExpression(description[3], keyIDDatabase, dbIDExpression, NSInteger64AttributeType);
	initExpression(description[4], keyIDQuery, queryIDExpression, NSInteger64AttributeType);
	initExpression(description[5], keyIDDocument, docIDExpression, NSInteger64AttributeType);
	
	request.resultType = NSDictionaryResultType;
	
	NSArray *propertiesToFetch;
	propertiesToFetch = [[NSArray alloc] initWithObjects:description
												   count:expressionCount];
	request.propertiesToFetch = propertiesToFetch;
	
	for (NSUInteger i=0; i<expressionCount; i++) {
		description[i] = nil;
	}
	
	inDatabase = nil;
	inDocument = nil;
	
	return request;
}

//Load all the databases and queries for this document.  This is because current versions
// of the software only use one database and query.

- (void)updateDocumentDatabaseQuery {
	
	NSArray <NSDictionary *> *results;

	NSManagedObjectContext *managedObjectContext;
	managedObjectContext = _managedObjectContext;
	
	NSFetchRequest *request = [MADModelDocument fetchRequestDocDBQueryIDs];
	
	NSError *error = nil;
	results = [managedObjectContext executeFetchRequest:request error:&error];
	if (error != nil) {
		os_log_error(GetMadLog(), "%s Error fetching: %@", __PRETTY_FUNCTION__, error);
	}
	
	NSAssert(results.count > 0, @"We expect results.");
	if (results.count == 0) return;
	
	NSMutableOrderedSet <MADModelDatabase *> *databases;
	databases = [[NSMutableOrderedSet <MADModelDatabase *> alloc] initWithCapacity:results.count];
	
	MADModelDatabase *database;

	NSDictionary <NSString *, __kindof NSObject *> *resultWrapper;
	
	//_objectID = [[results.firstObject objectForKey: keyDocument] copy];

	int64_t docID, dbID, qID;
	for (resultWrapper in results) {

		CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)resultWrapper[keyIDQuery],
						 kCFNumberSInt64Type, &qID);
		CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)resultWrapper[keyIDDatabase],
						 kCFNumberSInt64Type, &dbID);
		CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)resultWrapper[keyIDDocument],
						 kCFNumberSInt64Type, &docID);
		database = [[MADModelDatabase alloc] initWithIdentifier: dbID
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
