//
//  MADDatabaseSQLProtocol.h
//  MADAPI
//
//  Created by Michael on 9/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDatabaseSQLProtocol_h
#define MADDatabaseSQLProtocol_h

#import <Foundation/NSObject.h>

@protocol MADDatabaseSQLProtocol <NSObject>

    + (NSString *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    - (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName;
    - (NSString *)newSafeIdentifier:(NSString *)fieldOrTableName;
    - (NSString *)tableAliasForTable:(NSString *)tableName;

    - (NSString *)selectPart;
    - (NSString *)selectPartWithLimitedResults:(NSUInteger)limit;
    - (NSString *)sqlLimitClause;
    - (NSString *)sqlLimitClause:(NSUInteger)limit;
    - (NSString *)fieldAliasForField:(NSString *)field withSafeTableName:(NSString *)safeTableName;
    - (NSString *)fieldAliasForField:(NSString *)fieldName andTableName:(NSString *)tableName;
    - (NSString *)tableAliasConnector;

    - (NSString *)sqlAggregateFunctionLength;
    - (NSString *)sqlAggregateFunctionMax;

    - (NSString *)sqlSampleDataForField:(NSString *)fieldName
                               andTable:(NSString *)tableName;

@end

#endif /* MADDatabaseSQLProtocol_h */
