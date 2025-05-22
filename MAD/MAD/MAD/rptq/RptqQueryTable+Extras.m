//
//  RptqQueryTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqQueryTable+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSExpressionDescription.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <Foundation/NSExpression.h>

#import <stdio.h>

#import <MADFoundation/MADStringUtilities.h>

#import <MADFoundation/madlib.h>

#import "RptqDocument+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDataHelper.h"

@implementation RptqQueryTable (Extras)

+ (NSString *)keyPathAlias {
	NSString *result = NSStringFromSelector(@selector(alias));
	return result;
}

+ (NSString *)keyPathDropIndex {
	NSString *result = NSStringFromSelector(@selector(dropIndex));
	return result;
}

#pragma mark - Overrides

- (void)awakeFromInsert {
	[super awakeFromInsert];
	if (self.managedObjectContext.parentContext && self.identifier <= 0) {
		[[NSNotificationCenter defaultCenter] willChangeValueForKey:NSStringFromSelector(@selector(identifier))];
		self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
											managedObjectContext:self.managedObjectContext];
		[[NSNotificationCenter defaultCenter] didChangeValueForKey:NSStringFromSelector(@selector(identifier))];
	}
}

+ (instancetype)queryTableWithObjectID:(NSManagedObjectID *)objectID
				  managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	return (RptqQueryTable *)[managedObjectContext objectWithID:objectID];
}

+ (NSFetchRequest *)fetchRequestQueryTables:(NSPredicate *)predicate {
	
	NSFetchRequest *fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqQueryTable class])];
	NSString *keyPathTableName = [[MADStringUtilities stringByAppendingPeriod:NSStringFromSelector(@selector(inQueryTable))] stringByAppendingString: NSStringFromSelector(@selector(databaseSchemaTable))];
	keyPathTableName = [MADStringUtilities stringByAppendingPeriod:keyPathTableName];
	keyPathTableName = [keyPathTableName stringByAppendingString: NSStringFromSelector(@selector(name))];
	
	NSArray<NSString *> *keys = @[
		@"QTI",
		@"STI",
	];
	
	NSArray<NSExpression *> *expressions = @[
		[NSExpression expressionForKeyPath: NSStringFromSelector(@selector(identifier))],
		[NSExpression expressionForKeyPath: NSStringFromSelector(@selector(databaseSchemaTable))],
	];
	
	NSArray<NSNumber *> *types = @[
		@(NSInteger64AttributeType),
		@(NSInteger64AttributeType),
	];
	
	NSMutableArray<NSExpressionDescription *> *descriptions = [NSMutableArray arrayWithCapacity:keys.count];
	for (NSUInteger i=0; i<keys.count; i++) {
		NSExpressionDescription *desc = [[NSExpressionDescription alloc] init];
		desc.name = keys[i];
		desc.expression = expressions[i];
		desc.expressionResultType = types[i].unsignedIntegerValue;
		[descriptions addObject:desc];
	}
	
	fetchQueryTable.propertiesToFetch = descriptions;
	fetchQueryTable.resultType = NSDictionaryResultType;
	fetchQueryTable.predicate = predicate;
	
	return fetchQueryTable;
}

+ (RptqQueryTable *)newQueryTableForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
									   database:(RptqDatabase *)database
						forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {


	RptqQuery *query = database.defaultQuery;
	NSSet <RptqQueryTable *> *queryTables = database.defaultQuery.hasQueryTables;
	int64_t dupeCtr = 0;
	for (RptqQueryTable *table in queryTables) {
		if ([table.databaseSchemaTable.objectID isEqual:databaseSchemaTable.objectID]) {
			dupeCtr++;
		}
	}
	
	NSEntityDescription *tableEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryTable class]) inManagedObjectContext: managedObjectContext];
	RptqQueryTable *queryTable = [[RptqQueryTable alloc] initWithEntity: tableEntity insertIntoManagedObjectContext: managedObjectContext];
	queryTable.databaseSchemaTable = databaseSchemaTable;
	queryTable.inQuery = query;
	queryTable.dropIndex = dupeCtr;
	queryTable.alias = [queryTable.tableAlias copy];
	
	return queryTable;
}

- (NSString *)tableAlias {
	return self.dropIndex == 0 ? self.databaseSchemaTable.name : [self queryAlias];
}

- (NSString *)queryAlias {
	return [RptqQueryTable queryAliasForSchemaTableName:self.databaseSchemaTable.name
											  dropIndex:self.dropIndex];
}

+ (NSString *)queryAliasForSchemaTableName:(NSString *)schemaTableName
								 dropIndex:(int64_t)dropIndex {
	char buf[22]; char *ptr;
	ltoa(dropIndex, buf);
	ptr = buf;
	NSString *indexString = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
	return [schemaTableName stringByAppendingString:indexString];
}

- (BOOL)isEqualTo:(RptqQueryTable *)sender {
	
	if ([sender isEqual:sender])
		return YES;

	if ([sender isKindOfClass:self.class]) {
		NSNumber *i1;
		NSNumber *i2;
		return [i1 isEqualToNumber:i2];
	}
	
	return NO;
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"***********   RptqQueryTable  ***********\n"];
	[description appendFormat:@"Identifier:             %lld\n", self.identifier];
	[description appendFormat:@"Alias:                  %@\n", self.alias];
	[description appendFormat:@"***********   RptqQueryTable  ***********"];
	return description;
}

@end
