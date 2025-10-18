//
//  MADModelDatabase.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADModelDatabase.h"

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
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQuery.h"

#import "NSPredicate+Creators.h"

#import <os/log.h>

static os_log_t log_mad;

@interface MADModelDatabase ()
	- (instancetype)initWithIdentifier:(int64_t)identifier
				  managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
	- (instancetype)initWithIdentifier:(int64_t)identifier
					   queryIdentifier:(int64_t)queryIdentifier
				  managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

#pragma mark -
#pragma mark MAD Database Object ID

@implementation MADModelDatabase {
@protected
	MADDatabaseType _driverType;
	NSString *_driverName;
	NSString *_driverID;
	NSString *_driverDBName;
	NSManagedObjectContext * __weak _managedObjectContext;
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

- (NSManagedObjectContext *)managedObjectContext {
	return _managedObjectContext;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
			  managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	if (self = [super initWithIdentifier:identifier]) {
		_driverName = nil;
		_driverType = MADDatabaseTypeNotSet;
		_managedObjectContext = managedObjectContext;
	}
	return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
				   queryIdentifier:(int64_t)queryIdentifier
			  managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	
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
	
		NSArray <NSDictionary *> *results;
		
		NSFetchRequest *fetchRequest = [RptqDatabase fetchRequestDriverType: self.identifier];
		
		NSError *error = nil;
		results = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (error != nil) {
			os_log_error(log_mad, "Failed to fetch: %{public}@", error);
		}
		if (results.count > 0) {
			NSDictionary *firstResult = results[0];
			NSString *key = [RptqDatabase keyDatabaseDriverType];
			NSNumber *driverTypeWrapper = firstResult[key];
			_driverType = driverTypeWrapper.shortValue;
		}
	}
	return _driverType;
}

- (NSString *)schemaName {
	
	if (!_driverDBName) {
		NSArray <NSDictionary *> *results;
		
		NSFetchRequest *fetchRequest = [RptqDatabase fetchRequestDatabaseName:self.identifier];
		
		NSError *error = nil;
		results = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (error != nil) {
			os_log_error(log_mad, "Failed to fetch: %{public}@", error);
		}
		if (results.count > 0) {
			NSDictionary *resultSet = results[0];
			NSString *key = [RptqDatabase keyOwnedByUserDatabaseName];
			NSString *driverName = resultSet[key];
			_driverDBName = driverName.copy;
		}
	}
	return _driverDBName;
}

- (NSString *)driverID {
	
	if (!_driverID) {
		NSFetchRequest *fetchRequest = [RptqDatabase fetchRequestDatabaseDriverID:self.identifier];
		
		NSError *error = nil;
		NSArray <NSDictionary *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (error != nil) {
			os_log_error(log_mad, "Failed to fetch: %{public}@", error);
		}
		if (results.count > 0) {
			NSDictionary *resultSet = results[0];
			NSString *key = [RptqDatabase keyOwnedByUserDriverID];
			NSString *driverName = resultSet[key];
			_driverID = driverName.copy;
		}
	}
	return _driverID;
}

- (NSString *)driverName {

	if (!_driverName) {
		NSFetchRequest *fetchRequest = [RptqDatabase fetchRequestDriverName:self.identifier];
		NSError *error = nil;
		NSArray <NSDictionary *> *results = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (error != nil) {
			os_log_error(log_mad, "Failed to fetch: %{public}@", error);
		}
		if (results.count > 0) {
			NSDictionary *resultSet = results[0];
			NSString *driverName = [resultSet objectForKey:[RptqDatabase keyOwnedByUserDatabaseName]];
			_driverName = driverName.copy;
		}
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
 @brief Fetches RptqQueryField <Name, Identifier> for all query tables.
 @param None
 @returns
 @abstract
*/

- (void)updateTables {

	NSManagedObjectContext *managedObjectContext = _managedObjectContext;
	
	void (^setupExpressionWithType)(NSExpressionDescription *, NSString *, NSExpression *, NSAttributeType) = ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression, NSAttributeType type) {
		expressionDescription.name = name.copy;
		expressionDescription.expression = expression;
		expressionDescription.expressionResultType = type;
	};
	
	NSUInteger expressionCount = 3;
	NSMutableArray <NSExpressionDescription *> *expressionDescriptionArray = [[NSMutableArray alloc] initWithCapacity:expressionCount];
	
	NSString *inDbKey = [[MADStringUtilities stringByAppendingPeriod:NSStringFromSelector(@selector(inDatabase))] stringByAppendingString:NSStringFromSelector(@selector(identifier))];
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithIdentifier:self.identifier atKeyPath:inDbKey];
	
	for (NSUInteger i=0; i<expressionCount; i++) {
		NSExpressionDescription *ed = [[NSExpressionDescription alloc] init];
		[expressionDescriptionArray addObject:ed];
	}
	
	NSFetchRequest *fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqDatabaseSchemaTable class])];
	
	NSExpression *expressionForSelf = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(identifier))];
	NSExpression *expresssionForQueryable = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(queryable))];
	NSExpression *expressionForName = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(name))];
	
	setupExpressionWithType(expressionDescriptionArray[0], NSStringFromSelector(@selector(identifier)), expressionForSelf, NSInteger64AttributeType);
	setupExpressionWithType(expressionDescriptionArray[1], NSStringFromSelector(@selector(queryable)), expresssionForQueryable, NSBooleanAttributeType);
	setupExpressionWithType(expressionDescriptionArray[2], NSStringFromSelector(@selector(name)), expressionForName, NSStringAttributeType);
	
	fetchQueryTable.propertiesToFetch = expressionDescriptionArray;
	fetchQueryTable.resultType = NSDictionaryResultType;
	fetchQueryTable.predicate = predicate;
	
	NSSortDescriptor *sortByTableName = [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector(@selector(name)) ascending:YES];
	fetchQueryTable.sortDescriptors = @[sortByTableName];
	
	NSError *fetchError = nil;
	NSArray <NSDictionary *> *results = [managedObjectContext executeFetchRequest:fetchQueryTable error:&fetchError];
	if (fetchError != nil) {
		os_log_error(log_mad, "Failed to fetch right field: %{public}@", fetchError);
	}

	NSMutableOrderedSet <NSNumber *> *tables = [[NSMutableOrderedSet alloc] init];
	NSMutableDictionary <NSNumber *, MADModelTable *> *tableDictionary = [[NSMutableDictionary alloc] init];
	
	for (NSDictionary *tableData in results) {
		
		NSNumber *schemaTableIdentifier = tableData[NSStringFromSelector(@selector(identifier))];
		NSString *schemaTableName = tableData[NSStringFromSelector(@selector(name))];
		NSNumber *schemaTableQuerable = tableData[NSStringFromSelector(@selector(queryable))];
		
		MADModelTable *table = [[MADModelTable alloc] initWithIdentifier: schemaTableIdentifier.longLongValue
													managedObjectContext: managedObjectContext
																	name: schemaTableName
															   queryable: schemaTableQuerable.boolValue];
		[tables addObject:schemaTableIdentifier];
		[tableDictionary setObject:table forKey:schemaTableIdentifier];
	}

	_tableDictionary = tableDictionary;
	_tables = tables;
}

- (void)updateQueries {
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	expressionDescription.name = NSStringFromSelector(@selector(identifier));
	expressionDescription.expression = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(identifier))];
	expressionDescription.expressionResultType = NSInteger64AttributeType;

	NSString *keyPath = [[MADStringUtilities stringByAppendingPeriod:NSStringFromSelector(@selector(inDatabase))] stringByAppendingString:NSStringFromSelector(@selector(identifier))];

	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQuery class])];
	
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithIdentifier:self.identifier atKeyPath:keyPath];
	request.predicate = predicate;
	request.resultType = NSDictionaryResultType;
	request.includesSubentities = NO;
	request.includesPropertyValues = NO;
	
	NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = _managedObjectContext;
	NSArray <NSDictionary <NSString *, NSNumber *> *> *result = [managedObjectContext executeFetchRequest:request error:&error];
	if (error != nil) {
		os_log_error(log_mad, "Failed to fetch: %{public}@", error);
	}

	NSMutableOrderedSet <MADModelQuery *> *queries = [[NSMutableOrderedSet <MADModelQuery *> alloc] init];
	NSUInteger i = 0;
	for (NSDictionary <NSString *, NSNumber *> *objid in result) {
		NSNumber *identifer = objid[NSStringFromSelector(@selector(identifier))];
		MADModelQuery *queryObjectID = [[MADModelQuery alloc] initWithIdentifier: identifer.longLongValue
															managedObjectContext: managedObjectContext];
		[queries addObject: queryObjectID];
		queryObjectID = nil;
		i++;
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
