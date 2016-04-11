//
//  MTQueryCacheSelectLimitOffset.m
//  MAD
//
//  Created by Michael Thomason on 5/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryCacheSelectLimitOffset.h"
#import <MADFoundation/MADDataColumn.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSortDescriptor.h>
#import "MTDatabaseSqlite3.h"

@interface MTQueryCacheSelectLimitOffset ()
    @property (nonatomic, strong, readwrite) NSString *sql;
@end

@implementation MTQueryCacheSelectLimitOffset

- (instancetype)initWithLimit:(NSUInteger)limit offset:(NSUInteger)offset tableName:(NSString *)tableName dropRowID:(bool)dropRowID columnKeys:(NSArray *)columnKeys
              sortDescriptors:(NSArray *)sortDescriptors columns:(NSDictionary *)columns whereClause:(NSArray *)whereClause {
    
    if (self = [super initWithObject:nil]) {
    
        NSString *sqlResult = nil;
        if (limit == NSUIntegerMax && offset == NSUIntegerMax) {
            sqlResult = [MTQueryCacheSelectLimitOffset sqlQueryWithTableName:tableName dropRowID:dropRowID columnKeys:columnKeys sortDescriptors:sortDescriptors columns:columns whereClause:whereClause];
        } else if (offset == NSUIntegerMax) {
            sqlResult = [MTQueryCacheSelectLimitOffset sqlQueryWithLimit:limit tableName:tableName dropRowID:dropRowID columnKeys:columnKeys sortDescriptors:sortDescriptors columns:columns whereClause:whereClause];
        } else {
            sqlResult = [MTQueryCacheSelectLimitOffset sqlQueryWithLimit:limit offset:offset tableName:tableName dropRowID:dropRowID columnKeys:columnKeys sortDescriptors:sortDescriptors columns:columns whereClause:whereClause];
        }
        
        NSString *sql = [[NSString alloc] initWithString:sqlResult];
        self.sql = sql;
    
    }
    return self;

}

- (instancetype)initWithObject:(id)object {

    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));

        NSNumber *limitO = object[@(MTQueryCacheSelectLimitOffsetParamatersLimit)];
        NSNumber *offsetO = object[@(MTQueryCacheSelectLimitOffsetParamatersOffset)];

        NSUInteger limit = limitO ? limitO.unsignedIntegerValue : NSNotFound;     // Careful not to fuck this up!
        NSUInteger offset = offsetO ? offsetO.unsignedIntegerValue : NSNotFound;  // Careful not to fuck this up!
        
        NSNumber *keyTableNames = @(MTQueryCacheSelectLimitOffsetParamatersTableNames);
        NSString *tableName = object[keyTableNames];

        NSArray *columnKeys = object[@(MTQueryCacheSelectLimitOffsetParamatersColumnKeys)];
        NSArray *sortDescriptors = object[@(MTQueryCacheSelectLimitOffsetParamatersSortDesc)];
        NSArray *whereClause = object[@(MTQueryCacheSelectLimitOffsetParamatersWhere)];
        
        NSDictionary *columns = object[@(MTQueryCacheSelectLimitOffsetParamatersColumns)];
        
        NSNumber *dropRowid = object[@(MTQueryCacheSelectLimitOffsetParamatersDropRowid)];
        bool dropRowID = dropRowid != false ? (dropRowid.boolValue ? YES:NO) : false;
        
        NSString *sqlResult = nil;
        if (limit == NSUIntegerMax && offset == NSUIntegerMax) {
            sqlResult = [MTQueryCacheSelectLimitOffset sqlQueryWithTableName:tableName dropRowID:dropRowID columnKeys:columnKeys sortDescriptors:sortDescriptors columns:columns whereClause:whereClause];
        } else if (offset == NSUIntegerMax) {
            sqlResult = [MTQueryCacheSelectLimitOffset sqlQueryWithLimit:limit tableName:tableName dropRowID:dropRowID columnKeys:columnKeys sortDescriptors:sortDescriptors columns:columns whereClause:whereClause];
        } else {
            sqlResult = [MTQueryCacheSelectLimitOffset sqlQueryWithLimit:limit offset:offset tableName:tableName dropRowID:dropRowID columnKeys:columnKeys sortDescriptors:sortDescriptors columns:columns whereClause:whereClause];
        }
        
        NSString *sql = [[NSString alloc] initWithString:sqlResult];
        self.sql = sql;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    return self.sql;
}

- (BOOL)returnsResults {
    return YES;
}

+ (NSString *)sqlQueryWithTableName:(NSString *)tableName dropRowID:(bool)dropRowID columnKeys:(NSArray *)columnKeys
                    sortDescriptors:(NSArray *)sortDescriptors columns:(NSDictionary *)columns whereClause:(NSArray *)whereClause {
    
    NSString *sqlSelect = [MTQueryCacheSelectLimitOffset SelectClauseForTableName:tableName dropRowID:dropRowID columnKeys:columnKeys];
    NSMutableString *sql = [[NSMutableString alloc] initWithString:sqlSelect];
    
    NSString *sortClause = [MTQueryCacheSelectLimitOffset SortDescriptionFoSortDescriptionDefination:sortDescriptors columns:columns];
    [sql appendString:sortClause];
    
    NSString *whereClauseDef = [MTQueryCacheSelectLimitOffset WhereClauseForWhereClauseDefination:whereClause];
    [sql appendString:whereClauseDef];
    
    return sql;
    
}

+ (NSString *)sqlQueryWithLimit:(NSUInteger)limit tableName:(NSString *)tableName dropRowID:(bool)dropRowID columnKeys:(NSArray *)columnKeys
                sortDescriptors:(NSArray *)sortDescriptors columns:(NSDictionary *)columns whereClause:(NSArray *)whereClause {
    NSString *sqlQuery = [MTQueryCacheSelectLimitOffset sqlQueryWithTableName:tableName dropRowID:dropRowID columnKeys:columnKeys sortDescriptors:sortDescriptors columns:columns whereClause:whereClause];
    return [sqlQuery stringByAppendingFormat:@" LIMIT %ld ", (unsigned long)limit];
}

+ (NSString *)sqlQueryWithLimit:(NSUInteger)limit offset:(NSUInteger)offset tableName:(NSString *)tableName dropRowID:(bool)dropRowID columnKeys:(NSArray *)columnKeys
                sortDescriptors:(NSArray *)sortDescriptors columns:(NSDictionary *)columns whereClause:(NSArray *)whereClause {
    NSString *sqlQuery = [MTQueryCacheSelectLimitOffset sqlQueryWithLimit:limit tableName:tableName dropRowID:dropRowID columnKeys:columnKeys sortDescriptors:sortDescriptors columns:columns whereClause:whereClause];
    return [sqlQuery stringByAppendingFormat:@" OFFSET %ld ", (unsigned long)offset];
}

+ (NSString *)SelectClauseForTableName:(NSString *)tableName dropRowID:(bool)droprowid columnKeys:(NSArray *)columnKeys {
    if (columnKeys.count == 0) {
        return [NSString stringWithFormat:@" rowid FROM %@", tableName];
    } else {
        NSMutableString *sql = [[NSMutableString alloc] init];
        NSUInteger columnCounter = 0;
        for (NSString *key in columnKeys) {
            if (columnCounter != 0) {
                [sql appendString:@", "];
            }
            [sql appendFormat:@"\"%@\"", key];
            columnCounter++;
        }
        if (droprowid) {
            [sql appendFormat:@" FROM %@", tableName];
        } else {
            [sql appendFormat:@", rowid FROM %@", tableName];
        }
        return sql;
    }
    
}

+ (NSString *)SortDescriptionFoSortDescriptionDefination:(NSArray <__kindof NSSortDescriptor *> *)sortDescription columns:(NSDictionary <__kindof NSString *, __kindof MADDataColumn *> *)columns {
    if (sortDescription.count > 0) {
        NSUInteger sortCounter = 0;
        NSMutableString *sql = [[NSMutableString alloc] initWithString:@" ORDER BY "];
        for (NSSortDescriptor *sortDescriptor in sortDescription) {
            if (sortCounter != 0) [sql appendString:@", "];
            
            MADDataColumn *dataColumn = nil;
            if (columns) {
                dataColumn = columns[sortDescriptor.key];
            }
            NSString *sortDescription = [MTDatabaseSqlite3 sortDescForColumnType: dataColumn.columnType ascending: sortDescriptor.ascending];
            
            [sql appendFormat:@"%@ %@", sortDescriptor.key, sortDescription];
            sortCounter++;
        }
        return sql;
    } else {
        return @"";
    }
}

+ (NSString *)WhereClauseForWhereClauseDefination:(NSArray <__kindof NSDictionary *> *)whereClause {
    // FIXME: Right now only handles equal case.
    if ([whereClause count] > 0) {
        NSMutableString *sql = [[NSMutableString alloc] initWithString:@" WHERE "];
        NSUInteger counter = 0;
        for (NSDictionary *condition in whereClause) {
            if (counter > 0) [sql appendString:@" AND "];
            NSString *columnHandle = condition[MTQueryKeyPredicateColumn];
            NSString *columnValue = condition[MTQueryKeyPredicateValue];
            [sql appendFormat:@"%@ = %@", columnHandle, columnValue];
            counter++;
        }
        return sql;
    } else {
        return @"";
    }
}

@end
