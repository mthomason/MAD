//
//  MADElementMigrationPolicy.h
//  MAD Designer
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADElementMigrationPolicy_h
#define MAD_MADElementMigrationPolicy_h

#import <CoreData/CoreData.h>

@interface MADElementMigrationPolicy : NSEntityMigrationPolicy

//- (NSValue *)migrateValueFromDropPointX:(NSNumber *)dropPointX dropPointY:(NSNumber *)dropPointY;
- (NSString *)migrateValueFromMySQLDatabaseName:(NSString *)mySQLDBName
                                      tdsDBName:(NSString *)tdsDBName;
- (NSString *)migrateStringNotNullOrEmpty:(NSString *)s1
                                  string2:(NSString *)s2;

- (NSNumber *)migrateValueInt64NotZero:(NSNumber *)v1
                                value2:(NSNumber *)v2;

@end

#endif
