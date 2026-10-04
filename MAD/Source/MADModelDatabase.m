//
//  MADModelDatabase.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADModelDatabase.h"
#import <MAD/RptqStoreContext.h>

#import <Foundation/NSException.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSortDescriptor.h>

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSExpressionDescription.h>

#import <MADFoundation/MADStringUtilities.h>

#import "MADModel.h"
#import "MADModelTable.h"
#import "MADModelQuery.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"
#import "RptqDatabaseCredentals.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQuery.h"

#import "NSPredicate+Creators.h"

#import <os/log.h>

static os_log_t log_mad;

@interface MADModelDatabase ()
	- (instancetype)initWithIdentifier:(int64_t)identifier
				  managedObjectContext:(RptqStoreContext *)managedObjectContext;
	- (instancetype)initWithIdentifier:(int64_t)identifier
					   queryIdentifier:(int64_t)queryIdentifier
				  managedObjectContext:(RptqStoreContext *)managedObjectContext;
@end

#pragma mark -
#pragma mark MAD Database Object ID

@implementation MADModelDatabase {
@protected
	MADDatabaseType _driverType;
	NSString *_driverName;
	NSString *_driverID;
	NSString *_driverDBName;
	RptqStoreContext * __weak _managedObjectContext;
	NSMutableOrderedSet <NSNumber *> *_tables;
	NSMutableDictionary <NSNumber *, MADModelTable *> *_tableDictionary;
	NSOrderedSet <MADModelQuery *> *_queries;
}

@dynamic managedObjectContext;
@dynamic tableDictionary;
@dynamic tables;

@synthesize queries = _queries;

+ (void)load {
	if (self == [MADModelDatabase class]) {
		NSString *c = NSStringFromClass([MADModelDatabase class]);
		log_mad = os_log_create("com.mad", c.UTF8String);
	}
}

- (void)dealloc {
	[_tables removeAllObjects];
	[_tableDictionary removeAllObjects];
	_queries = nil;
	_managedObjectContext = nil;
}

- (RptqStoreContext *)managedObjectContext {
	return _managedObjectContext;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
			  managedObjectContext:(RptqStoreContext *)managedObjectContext {
	if (self = [super initWithIdentifier:identifier]) {
		_driverName = nil;
		_driverType = MADDatabaseTypeNotSet;
		_managedObjectContext = managedObjectContext;
	}
	return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
				   queryIdentifier:(int64_t)queryIdentifier
			  managedObjectContext:(RptqStoreContext *)managedObjectContext {
	
	if (self = [super initWithIdentifier:identifier]) {
		_driverName = nil;
		_driverType = MADDatabaseTypeNotSet;
		_managedObjectContext = managedObjectContext;
		MADModelQuery *queryObjectID;
		
		NSMutableOrderedSet <MADModelQuery *> *queries;
		queries = [[NSMutableOrderedSet <MADModelQuery *> alloc] init];
		
		queryObjectID = [[MADModelQuery alloc] initWithIdentifier: queryIdentifier
														 database: self];
		[queries addObject: queryObjectID];
		_queries = queries;
	}
	return self;
}

- (NSDictionary <NSNumber *, MADModelTable *> *)tableDictionary {
	if (!_tableDictionary) {
		@autoreleasepool {
			[self updateTables];
		}
	}
	return _tableDictionary;
}

- (NSOrderedSet <NSNumber *> *)tables {
	if (!_tables) {
		@autoreleasepool {
			[self updateTables];
		}
	}
	return _tables;
}

- (NSOrderedSet <MADModelQuery *> *)queries {
	if (!_queries) {
		@autoreleasepool {
			[self updateQueries];
		}
	}
	return _queries;
}

- (MADModelQuery *)firstQuery {
	return self.queries.firstObject;
}

- (void)update {
	@autoreleasepool {
		[self updateTables];
	}
	@autoreleasepool {
		[self updateQueries];
	}
}

- (MADDatabaseType)driverType {
	
	if (_driverType == MADDatabaseTypeNotSet) {
		RptqDatabase *database = (RptqDatabase *)[self.managedObjectContext objectForEntity:NSStringFromClass([RptqDatabase class]) identifier:self.identifier];
		if (database) _driverType = (MADDatabaseType)database.databaseDriverTypeEnum;
	}
	return _driverType;
}

- (NSString *)schemaName {

	if (!_driverDBName) {
		RptqDatabase *database = (RptqDatabase *)[self.managedObjectContext objectForEntity:NSStringFromClass([RptqDatabase class]) identifier:self.identifier];
		_driverDBName = database.ownedByUser.dbname.copy;
	}
	return _driverDBName;
}

- (NSString *)driverID {

	if (!_driverID) {
		RptqDatabase *database = (RptqDatabase *)[self.managedObjectContext objectForEntity:NSStringFromClass([RptqDatabase class]) identifier:self.identifier];
		_driverID = database.ownedByUser.driverID.copy;
	}
	return _driverID;
}

- (NSString *)driverName {

	if (!_driverName) {
		RptqDatabase *database = (RptqDatabase *)[self.managedObjectContext objectForEntity:NSStringFromClass([RptqDatabase class]) identifier:self.identifier];
		_driverName = database.ownedByUser.dbname.copy;
	}
	return _driverName;
 /*

	NSString *databaseType = database.ownedByUser.driverID.copy;
	RptqDatabaseCredentals *user = database.ownedByUser;
	NSString * schemaName = [user databaseSchemaName].copy;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString *TextFormatConnection = @"You are connecting to %1$@"
		@" datasource named %2$@.";
		NSString *localizedMessageFormat;
		NSString *localizedMessage;
		NSAttributedString *message;
		localizedMessageFormat = NSLocalizedString(TextFormatConnection, TextFormatConnection);
		localizedMessage = [[NSString alloc] initWithFormat:localizedMessageFormat, databaseType, schemaName];
		message = [MADAttributedStringQueryController newAttributedStringQuerySectionDatasourceForMessage: localizedMessage
																							 databaseType: databaseType
																							   schemaName: schemaName];
		dispatch_sync(dispatch_get_main_queue(), ^{
			cell.textLabel.attributedText = message;
			cell.textLabel.text = localizedMessage;
		});
	});
*/
	return @"";
}

/**
 @brief Rebuilds the model's table list from the store's schema tables, sorted by name.
*/

- (void)updateTables {

	RptqStoreContext *managedObjectContext = _managedObjectContext;
	// The pre-migration fetch sorted by name; the store keeps insertion order,
	// so the sort is restored here.  See BUGS.md "The milestone-(a) model
	// rewrites dropped the schema sort orders".
	NSSortDescriptor *sortByTableName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	NSArray *schemaTables = [[managedObjectContext objectsForEntity:NSStringFromClass([RptqDatabaseSchemaTable class])]
							 sortedArrayUsingDescriptors:@[ sortByTableName ]];

	NSMutableOrderedSet <NSNumber *> *tables = [[NSMutableOrderedSet alloc] init];
	NSMutableDictionary <NSNumber *, MADModelTable *> *tableDictionary = [[NSMutableDictionary alloc] init];

	for (RptqDatabaseSchemaTable *schemaTable in schemaTables) {
		if (schemaTable.inDatabase.identifier != self.identifier) continue;
		NSNumber *schemaTableIdentifier = @(schemaTable.identifier);
		MADModelTable *table = [[MADModelTable alloc] initWithIdentifier: schemaTable.identifier
													managedObjectContext: managedObjectContext
																	name: schemaTable.name
															   queryable: schemaTable.queryable];
		[tables addObject:schemaTableIdentifier];
		[tableDictionary setObject:table forKey:schemaTableIdentifier];
	}

	_tableDictionary = tableDictionary;
	_tables = tables;
}

- (void)updateQueries {
	RptqStoreContext *managedObjectContext = _managedObjectContext;
	NSArray *queriesForDatabase = [managedObjectContext objectsForEntity:NSStringFromClass([RptqQuery class])];

	NSMutableOrderedSet <MADModelQuery *> *queries = [[NSMutableOrderedSet <MADModelQuery *> alloc] init];
	for (RptqQuery *query in queriesForDatabase) {
		if (query.inDatabase.identifier != self.identifier) continue;
		MADModelQuery *queryObjectID = [[MADModelQuery alloc] initWithIdentifier: query.identifier
															managedObjectContext: managedObjectContext];
		[queries addObject: queryObjectID];
	}
	_queries = queries;
}

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	[debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
	[debug appendFormat:@"ID:\t%@\n", self.objectID];
	if (_tables) {
		[debug appendFormat:@"Tables:\t%@", _tables];
	}
	if (_queries) {
		[debug appendFormat:@"Queries:\t%@", self.queries];
	}
	return debug;
}

@end
