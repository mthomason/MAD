//
//  RptqDatabaseCredentals+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqDatabaseCredentals+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqDataHelper.h"
#import "MADDatabaseConnection+Constructor.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADDatabaseType.h>
#import <MADAPI/MADDatabaseConnection.h>

#import <CoreFoundation/CFNumber.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <Foundation/NSPathUtilities.h>
@implementation RptqDatabaseCredentals (Extras)



#pragma mark - Overrides

- (NSString *)database {
	return self.dbname;
}

- (NSString *)databaseSchemaName {
	NSString *result = @"";
	MADDatabaseType databaseType = [self.inDatabase databaseType];
	switch (databaseType) {
		
		case MADDatabaseTypeMySQL:
		case MADDatabaseTypeSqlite3:
			result = [self.dbname copy];
			break;
		
		case MADDatabaseTypeTDS:
			result = [self.dbname copy];
			break;

		case MADDatabaseTypeUnknown: {
			
			if ([self.driverID isEqualToString: [RptqDatabaseCredentals driverIDMySQL]]) {
				result = [self.dbname copy];
				self.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeMySQL;
				
			} else if ([self.driverID isEqualToString:[RptqDatabaseCredentals driverIDTDS]]) {
				result = [self.dbname copy];
				self.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeTDS;
				
			} else if ([self.driverID isEqualToString:[RptqDatabaseCredentals driverIDSqlite3]]) {
				result = [self.dbname copy];
				self.inDatabase.databaseDriverTypeEnum = MADDatabaseTypeSqlite3;
				
			}
			
			break;
		}
		default:
			result = @"unknown";
			break;
	}
	return result.stringByDeletingPathExtension.capitalizedString;
}

#pragma mark - Static

+ (instancetype)newDatabaseCredental:(RptqStoreContext *)objectContext {
	return (RptqDatabaseCredentals *)[objectContext insertObjectForEntity:NSStringFromClass([self class])
															  identifier:0];
}

+ (NSArray <RptqDatabaseCredentals *> *)newDatabaseCredentals:(RptqStoreContext *)context {
	NSArray *credentals = [context objectsForEntity:NSStringFromClass([RptqDatabaseCredentals class])];
	return [credentals sortedArrayUsingComparator:^NSComparisonResult(RptqDatabaseCredentals *a, RptqDatabaseCredentals *b) {
		return [(a.driverID ?: @"") compare:(b.driverID ?: @"")];
	}];
}

+ (NSString *)driverIDMySQL {
	return [MADDatabaseConnection Identifier:MADDatabaseTypeMySQL];
}

+ (NSString *)driverIDTDS {
	return [MADDatabaseConnection Identifier:MADDatabaseTypeTDS];
}

+ (NSString *)driverIDSqlite3 {
	return [MADDatabaseConnection Identifier:MADDatabaseTypeSqlite3];
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"*********   RptqDatabaseCredentals  *********\n"];
	[description appendFormat:@"Identifier:             %lld\n",    self.identifier];
	[description appendFormat:@"Type:                   %@\n",      self.driverID];
	[description appendFormat:@"Host:                   %@\n",      self.host];
	[description appendFormat:@"Database:               %@\n",      self.dbname];
	[description appendFormat:@"*********   RptqDatabaseCredentals  *********"];
	return description;
}

@end
