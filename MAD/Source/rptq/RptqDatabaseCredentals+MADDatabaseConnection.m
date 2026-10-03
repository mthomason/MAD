//
//  RptqDatabaseCredentals+MADDatabaseConnection.m
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqStoreContext.h"
#import "RptqDatabaseCredentals+MADDatabaseConnection.h"
#import <Foundation/NSString.h>
#import "MADDatabaseConnection+Constructor.h"

@implementation RptqDatabaseCredentals (MADDatabaseConnection)

- (MADDatabaseType)databaseType {

	MADDatabaseType category;
	if ([self.driverID isEqualToString: [MADDatabaseConnection Identifier:MADDatabaseTypeMySQL]]) {
		category = MADDatabaseTypeMySQL;
		
	} else if ([self.driverID isEqualToString: [MADDatabaseConnection Identifier:MADDatabaseTypeTDS]]) {
		category = MADDatabaseTypeTDS;
		
	} else if ([self.driverID isEqualToString: [MADDatabaseConnection Identifier:MADDatabaseTypeSqlite3]]) {
		category = MADDatabaseTypeSqlite3;
	
	} else {
		category = MADDatabaseTypeSqlite3;
	}
	return category;
}

@end
