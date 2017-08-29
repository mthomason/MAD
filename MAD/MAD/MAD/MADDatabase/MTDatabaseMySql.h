//
//  MNSDatabaseMySql.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseMySql_h
#define Reports_MTDatabaseMySql_h

#import <MADAPI/MTDatabase.h>
#import <MADFoundation/MADDataType.h>

@class RptqDatabaseSchemaTable;

@interface MTDatabaseMySql : MTDatabase

    + (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    - (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    - (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName;

    - (NSString *)identifier;

@end

#endif
