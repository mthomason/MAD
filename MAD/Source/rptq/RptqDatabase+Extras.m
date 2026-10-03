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

#import "RptqStoreContext.h"
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

+ (instancetype)newDatabaseFactoryForManagedObjectContext:(RptqStoreContext *)objectContext
											   driverType:(NSString *)driverIdentifier
											 connectionId:(int64_t)identifier NS_RETURNS_RETAINED {
	RptqDatabase *database = [objectContext insertObjectForEntity:NSStringFromClass([self class]) identifier:identifier];
	database.databaseDriverType = [driverIdentifier copy];
	return database;
}

#pragma mark -
#pragma mark Overrides

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
