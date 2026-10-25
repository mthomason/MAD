//
//  RptqQueryTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqQueryTable+Extras.h"

#import <CoreFoundation/CFNumber.h>

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

+ (instancetype)queryTableWithObjectID:(int64_t)objectID
				  managedObjectContext:(RptqStoreContext *)managedObjectContext {
	return (RptqQueryTable *)[managedObjectContext objectForEntity:NSStringFromClass([RptqQueryTable class])
													   identifier:objectID];
}

+ (RptqQueryTable *)newQueryTableForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
									   database:(RptqDatabase *)database
						forManagedObjectContext:(RptqStoreContext *)managedObjectContext {


	RptqQuery *query = database.defaultQuery;
	NSSet <RptqQueryTable *> *queryTables = database.defaultQuery.hasQueryTables;
	int64_t dupeCtr = 0;
	for (RptqQueryTable *table in queryTables) {
		if (table.databaseSchemaTable.identifier == databaseSchemaTable.identifier) {
			dupeCtr++;
		}
	}

	RptqQueryTable *queryTable = (RptqQueryTable *)[managedObjectContext insertObjectForEntity:NSStringFromClass([RptqQueryTable class])
																 identifier:0];
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
	return [[schemaTableName stringByAppendingString:indexString] stringByReplacingOccurrencesOfString:@"." withString:@""];
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
