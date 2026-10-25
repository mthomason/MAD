//
//  MADQuerySelectExpressionAllFields.m
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADQuerySelectExpressionAllFields.h"
#import <MAD/RptqStoreContext.h>
#import "MADQueryActiveQueryFields.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"

#import <MADAPI/MADDatabase.h>
#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>

#import <MADFoundation/MADStringUtilities.h>

#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSException.h>

// A table's fields are a set, so its enumeration order is hash order -- not stable
// across runs or platforms.  Same reasoning and same order as the active-fields list
// (MADQuerySelectExpressionActiveFields.m): the field name decides, the identifier
// breaks a tie between two query fields naming one schema field.
static NSArray <RptqQueryField *> *MADAllFieldsInOrder(MADDatabase *database, NSSet <RptqQueryField *> *queryFields) {
	return [queryFields.allObjects sortedArrayUsingComparator: ^NSComparisonResult(RptqQueryField *a, RptqQueryField *b) {
		NSString *left = [database newSafeIdentifier: a.databaseSchemaField.name];
		NSString *right = [database newSafeIdentifier: b.databaseSchemaField.name];
		NSComparisonResult ordered = [left compare: right];
		return ordered != NSOrderedSame ? ordered : [@(a.identifier) compare: @(b.identifier)];
	}];
}

@implementation MADQuerySelectExpressionAllFields

- (instancetype)initWithDatabase:(MADDatabase *)database
						  tables:(NSArray <MTPair *> *)tables
		 forManagedObjectContext:(RptqStoreContext *)context {
	
	if (self = [super init]) {
		
		NSMutableString *result = [[NSMutableString alloc] init];
		
		NSUInteger tableCounter = 0;
		for (MTPair *pair in tables) {
			MTVertex *queryTable = pair.former;
			int64_t objectID = [queryTable.object longLongValue];

			RptqQueryTable *table = (RptqQueryTable *)[context objectForEntity:NSStringFromClass([RptqQueryTable class]) identifier:objectID];
			NSAssert(table != nil, @"Expect a table.");
			if (table != nil) {
				if (tableCounter != 0) [result appendString:@",\n"];
				
				NSString *tableName = [table queryAlias];
				MADSafeQueryField *safeTableName = [database newSafeIdentifier:tableName];
				NSString *tableAlias = [MADStringUtilities stringByAppendingPeriod:safeTableName];

				NSUInteger fieldCounter = 0;
				NSArray <RptqQueryField *> *hasQueryFields = MADAllFieldsInOrder(database, table.hasQueryFields);
				for (RptqQueryField *queryField in hasQueryFields) {
					if (fieldCounter != 0)  [result appendString:@",\n"];
					MADSafeQueryField *safeFieldName = [database newSafeIdentifier:queryField.databaseSchemaField.name];
					NSString *fieldAlias = [tableAlias stringByAppendingString:safeFieldName];
					[result appendString: @"\t"];
					[result appendString: fieldAlias];
					fieldCounter++;
				}
				tableCounter++;
			}
		}
		self.sql = result;
	}
	return self;
}

@end
