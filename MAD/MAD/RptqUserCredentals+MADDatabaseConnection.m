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

- (MADDatabaseCategory)databaseType {

    MADDatabaseCategory category;
    if ([self.database_driver_type isEqualToString: [MADDatabaseConnection Identifier:MADDatabaseCategoryMySQL]]) {
        category = MADDatabaseCategoryMySQL;
        
    } else if ([self.database_driver_type isEqualToString: [MADDatabaseConnection Identifier:MADDatabaseCategoryTDS]]) {
        category = MADDatabaseCategoryTDS;
        
    } else if ([self.database_driver_type isEqualToString: [MADDatabaseConnection Identifier:MADDatabaseCategorySqlite3]]) {
        category = MADDatabaseCategorySqlite3;
    
    } else {
        category = MADDatabaseCategorySqlite3;
    }
    return category;
}

@end
