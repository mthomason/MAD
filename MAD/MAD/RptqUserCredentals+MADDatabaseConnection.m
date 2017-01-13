//
//  RptqUserCredentals+MADDatabaseConnection.m
//  MAD
//
//  Created by Michael on 1/12/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqUserCredentals+MADDatabaseConnection.h"

#import <Foundation/NSString.h>

#import "RptqUserCredentals.h"

#import "MADDatabaseConnection.h"

@implementation RptqUserCredentals (MADDatabaseConnection)

- (MADDatabaseType)databaseType {

    MADDatabaseType category;
    if ([self.database_driver_type isEqualToString: [MADDatabaseConnection Identifier:MADDatabaseTypeMySQL]]) {
        category = MADDatabaseTypeMySQL;
        
    } else if ([self.database_driver_type isEqualToString: [MADDatabaseConnection Identifier:MADDatabaseTypeTDS]]) {
        category = MADDatabaseTypeTDS;
        
    } else if ([self.database_driver_type isEqualToString: [MADDatabaseConnection Identifier:MADDatabaseTypeSqlite3]]) {
        category = MADDatabaseTypeSqlite3;
    
    } else {
        category = MADDatabaseTypeSqlite3;
    }
    return category;
}

@end
