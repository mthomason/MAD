//
//  RptqDatabaseSchemaTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <MADAPI/MADDatabaseTable.h>

#import "RptqDocument+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDataHelper.h"

@implementation RptqDatabaseSchemaTable (Extras)

#pragma mark - Overrides





#pragma mark - Static



+ (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(RptqStoreContext *)managedObjectContext
																name:(NSString *)name
														andQueryable:(BOOL)queryable {
	
	RptqDatabaseSchemaTable *rptqTable = [managedObjectContext insertObjectForEntity:NSStringFromClass([self class])
																		 identifier:0];
	rptqTable.name = name.copy;
	rptqTable.queryable = queryable;

	return rptqTable;
}

+ (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(RptqStoreContext *)objectContext
															andTable:(MADDatabaseTable *)table {

	RptqDatabaseSchemaTable *rptqTable = [objectContext insertObjectForEntity:NSStringFromClass([self class]) identifier:0];
	rptqTable.name = table.name.copy;
	rptqTable.queryable = table.queryable;
	return rptqTable;
}

+ (RptqDatabaseSchemaTable *)databaseSchemaTableForDatabase:(RptqDatabase *)database andTableName:(NSString *)name {
	RptqDatabaseSchemaTable *result = nil;
	for (RptqDatabaseSchemaTable *table in database.hasTables) {
		if ([table.name isEqualToString:name]) {
			result = table;
			break;
		}
	}
	return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
	return self.name;
}

- (NSString *)toString {
	return self.name;
}

- (NSString *)toStringDebug {
	return self.name;
}

- (id)debugQuickLookObject {
	NSMutableString *document = [[NSMutableString alloc] init];
	[document appendFormat:@"*********\n"];
	[document appendFormat:@"Name:              %@\n", self.name];
	[document appendFormat:@"Queryable:         %@\n", self.queryable ? @"YES" : @"NO"];
	[document appendFormat:@"Fields:            %@\n", self.hasFields];
	[document appendFormat:@"*********"];
	return document;
}

@end
