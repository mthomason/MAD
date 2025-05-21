//
//  MADQuerySelectExpressionAllFields.m
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQuerySelectExpressionAllFields.h"
#import "MADQueryActiveQueryFields.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"

#import <MADAPI/MADDatabase.h>
#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>

#import <MADFoundation/MADStringUtilities.h>

#import <CoreData/NSManagedObjectContext.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSException.h>

@implementation MADQuerySelectExpressionAllFields

- (instancetype)initWithDatabase:(MADDatabase *)database
						  tables:(NSArray <MTPair *> *)tables
		 forManagedObjectContext:(NSManagedObjectContext *)context {
	
	if (self = [super init]) {
		
		NSMutableString *result = [[NSMutableString alloc] init];
		
		NSUInteger tableCounter = 0;
		for (MTPair *pair in tables) {
			MTVertex *queryTable = pair.former;
			NSManagedObjectID *objectID = queryTable.object;
			
			RptqQueryTable *table = [context objectWithID:objectID];
			NSAssert(table != nil, @"Expect a table.");
			if (table != nil) {
				if (tableCounter != 0) [result appendString:@",\n"];
				
				NSString *tableName = [table queryAlias];
				MADSafeQueryField *safeTableName = [database newSafeIdentifier:tableName];
				NSString *tableAlias = [MADStringUtilities stringByAppendingPeriod:safeTableName];

				NSUInteger fieldCounter = 0;
				NSEnumerator <RptqQueryField *> *hasQueryFields = table.hasQueryFields.objectEnumerator;
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
