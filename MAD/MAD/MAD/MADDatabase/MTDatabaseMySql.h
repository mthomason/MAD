//
//  MNSDatabaseMySql.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseMySql_h
#define Reports_MTDatabaseMySql_h

#import "MTDatabase.h"
#import <MADFoundation/MADDataType.h>

@class RptqDatabaseSchemaTable;

@interface MTDatabaseMySql : MTDatabase

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
- (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
- (NSString *)safeIdentifier:(NSString *)fieldOrTableName;

- (NSString *)identifier;
+ (NSString *)identifier;

@end

#endif
