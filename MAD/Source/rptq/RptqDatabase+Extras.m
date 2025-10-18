//
//  RptqDatabase+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDatabase+Extras.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseCredentals.h"
#import "RptqDataHelper.h"
#import "NSPredicate+Creators.h"
#import <MADFoundation/MADStringUtilities.h>

#import <CoreFoundation/CFNumber.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <Foundation/NSExpression.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSExpressionDescription.h>
#import <os/log.h>

static os_log_t rptq_log;

@implementation RptqDatabase (Extras)

#pragma mark -
#pragma mark Static

+ (void)load {
	if (self == [RptqDatabase class]) {
		NSString *c = NSStringFromClass([RptqDatabase class]);
		rptq_log = os_log_create("com.mad", c.UTF8String);
	}
}

+ (NSString *)keyDriverID { return NSStringFromSelector(@selector(driverID)); }
+ (NSString *)keyOwnedByUser { return NSStringFromSelector(@selector(ownedByUser)); }
+ (NSString *)keyDatabaseDriverType { return NSStringFromSelector(@selector(databaseDriverTypeEnum)); }

+ (NSString *)keyOwnedByUserDriverID {
	return [[MADStringUtilities stringByAppendingPeriod:[self keyOwnedByUser]] stringByAppendingString:[self keyDriverID]];
}

+ (NSString *)keyOwnedByUserDatabaseName {
	return [[MADStringUtilities stringByAppendingPeriod:[self keyOwnedByUser]] stringByAppendingString:NSStringFromSelector(@selector(dbname))];
}

+ (NSFetchRequest *)fetchRequestDatabaseDriverID:(int64_t)identifier {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithIdentifier:identifier];
	NSString *keyOwndByUserDriverID = [self keyOwnedByUserDriverID];
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqDatabase class])];
	
	NSExpression *expressionForDatabaseDriverType = [NSExpression expressionForKeyPath:keyOwndByUserDriverID];
	
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	expressionDescription.name = [keyOwndByUserDriverID copy];
	expressionDescription.expression = expressionForDatabaseDriverType;
	expressionDescription.expressionResultType = NSStringAttributeType;
	
	NSArray *propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription, nil];
	fetchRequest.propertiesToFetch = propertiesToFetch;
	fetchRequest.resultType = NSDictionaryResultType;
	fetchRequest.predicate = predicate;

	return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestDatabaseName:(int64_t)identifier {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithIdentifier:identifier];
	NSString *keyOwndByUserDBName = [self keyOwnedByUserDatabaseName];
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqDatabase class])];
	
	NSExpression *expressionForDatabaseDriverType = [NSExpression expressionForKeyPath:keyOwndByUserDBName];
	
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	expressionDescription.name = [keyOwndByUserDBName copy];
	expressionDescription.expression = expressionForDatabaseDriverType;
	expressionDescription.expressionResultType = NSStringAttributeType;
	
	fetchRequest.propertiesToFetch = @[expressionDescription];
	fetchRequest.resultType = NSDictionaryResultType;
	fetchRequest.predicate = predicate;
	
	return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestDriverName:(int64_t)identifier {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithIdentifier:identifier];

	NSString *key = [self keyOwnedByUserDatabaseName];
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqDatabase class])];
	NSExpression *expressionForDatabaseDriverType = [NSExpression expressionForKeyPath:key];
	
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	expressionDescription.name = [key copy];
	expressionDescription.expression = expressionForDatabaseDriverType;
	expressionDescription.expressionResultType = NSStringAttributeType;
	
	fetchRequest.propertiesToFetch = @[expressionDescription];
	fetchRequest.resultType = NSDictionaryResultType;
	fetchRequest.predicate = predicate;

	return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestDriverType:(int64_t)identifier {
	NSPredicate *predicate = [NSPredicate newPredicateObjectWithIdentifier:identifier];

	NSString *keyDatabaseDriverTypeEnum = [self keyDatabaseDriverType];
	
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqDatabase class])];
	NSExpression *expressionForDatabaseDriverType = [NSExpression expressionForKeyPath:keyDatabaseDriverTypeEnum];

	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	expressionDescription.name = [keyDatabaseDriverTypeEnum copy];
	expressionDescription.expression = expressionForDatabaseDriverType;
	expressionDescription.expressionResultType = NSInteger16AttributeType;
	
	fetchRequest.propertiesToFetch = @[expressionDescription];
	fetchRequest.resultType = NSDictionaryResultType;
	fetchRequest.predicate = predicate;
	return fetchRequest;
}

+ (RptqDatabase *)databaseForDocument:(RptqDocument *)document
					  andConnecitonId:(int64_t)connectionId {
	
	RptqDatabase *currentDatabase = nil;
	for (RptqDatabase *db in document.hasDatabaseSchemas) {
		if (db.identifier == connectionId) {
			currentDatabase = db;
			break;
		}
	}

	return currentDatabase;
}

+ (instancetype)newDatabaseFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
											   driverType:(NSString *)driverIdentifier
											 connectionId:(int64_t)identifier NS_RETURNS_RETAINED {
	NSEntityDescription *databaseEntity = [NSEntityDescription entityForName: NSStringFromClass([self class])
													  inManagedObjectContext: objectContext];
	RptqDatabase *database = [[self alloc] initWithEntity: databaseEntity
						   insertIntoManagedObjectContext: objectContext];
	database.databaseDriverType = [driverIdentifier copy];
	database.identifier = identifier;
	return database;
}

#pragma mark -
#pragma mark Overrides

- (void)awakeFromInsert {
	[super awakeFromInsert];
	if (self.managedObjectContext.parentContext && self.identifier <= 0) {
		self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
											managedObjectContext:self.managedObjectContext];
	}
}

- (RptqQuery *)defaultQuery { return self.hasQueries.anyObject; }

- (RptqDatabaseSchemaTable *)getTableWithName:(NSString *)name {
	RptqDatabaseSchemaTable *result = nil;
	for (RptqDatabaseSchemaTable *table in self.hasTables) {
		if ([table.name isEqualToString:name]) {
			result = table;
			break;
		}
	}
	return result;
}

- (MADDatabaseType)databaseType {
	return self.databaseDriverTypeEnum;
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"*********\n"];
	[description appendFormat:@"Driver type:        %@\n", self.databaseDriverType];
	[description appendFormat:@"Driver type id:     %hd\n", self.databaseDriverTypeEnum];
	[description appendFormat:@"Identifier:         %lld\n", self.identifier];
	[description appendFormat:@"Tables:             %@\n", self.hasTables];
	[description appendFormat:@"Queries:            %@\n", self.hasQueries];
	[description appendFormat:@"Owned by query:     %@\n", self.ownedByQueryAsStaticResource];
	[description appendFormat:@"Owned by user:      %@\n", self.ownedByUser];
	[description appendFormat:@"*********"];
	return description;
}

@end
