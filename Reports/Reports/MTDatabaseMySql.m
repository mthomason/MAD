//
//  MNSDatabaseMySql.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

// FIXME: Add @try statements around MySQL calls.

#import "MTDatabaseMySql.h"
#import "MTQueryReportMySql.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseConnectionMySql.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import "RptqQueryCache+Extras.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryLinks+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryPredicate+Extras.h"
#import "MTKeyChain.h"

@interface MTDatabaseMySql ()

@end

@implementation MTDatabaseMySql
 
- (void)executeSql:(NSString *)sql
        completion:(void (^)(BOOL success, NSError *error, id results))completion {
    
    NSString *queryString = sql;
    MTDatabaseConnection *connectionSettings = [[self databaseConnection] retain];
    
    NSString *key = [MTKeyChain keyForServer:[connectionSettings server]
                                        port:[connectionSettings port]
                                 andDatabase:[connectionSettings database]];

    [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key
                                                 completion:^(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain) {
        if (success) {
            [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key shortCircuit:fromKeyChain completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
                
                @try {

                    NSError *connError = nil;
                    
                    MysqlServer *serv = [[MysqlServer alloc] init];
                    
                    [serv setHost:      [connectionSettings server]];
                    [serv setSchema:    [connectionSettings database]];
                    [serv setPort:      (unsigned int)[connectionSettings port]];
                    [serv setUser:      username];
                    [serv setPassword:  password];
                    
                    MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&connError];
                    if (conn && connError == nil) {
                        
                        @autoreleasepool {
                            
                            MysqlFetch *fetch = [MysqlFetch fetchWithCommand:queryString onConnection:conn extendedNames:YES];
                            id queryResults = [[fetch results] retain];
                            [[self delegateCacheData] cacheQueryResult:queryResults];
                            completion(YES, nil, queryResults);
                            [queryResults release];
                            
                        }
                        
                    } else {
                        completion(NO, connError, nil);
                    }
                    
                    [serv release];
                    
                } @catch(NSException *ex) {
                    NSError *connError = [NSError errorWithDomain:[MTDatabase identifier] code:382 userInfo:ex.userInfo];
                    completion(NO, connError, nil);
                }
            }];
        } else {
            NSError *connError = [NSError errorWithDomain:[MTDatabase identifier] code:383 userInfo:nil];
            completion(NO, connError, nil);
        }
    }];
    
    [connectionSettings release];

}

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    
    NSString *key = [MTKeyChain keyForServer:[[self databaseConnection] server] port:[[self databaseConnection] port] andDatabase:[[self databaseConnection] database]];
    [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *credentialsError, NSString *username, NSString *password, BOOL fromKeyChain) {
        
        if (success) {
            
            [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key shortCircuit:fromKeyChain completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
                
                __block MysqlServer *serv = [[MysqlServer alloc] init];
                
                [serv setUser:      username];
                [serv setPassword:  password];
                [serv setHost:      [[self databaseConnection] server]];
                [serv setPort:      (unsigned int)[[self databaseConnection] port]];
                [serv setSchema:    [[self databaseConnection] database]];
                
                NSError *errorConnection = nil;
                MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&errorConnection];
                BOOL successConnection = conn != nil;
                if (successConnection) {
                    
                    MysqlFetch *fetch = [MysqlFetch fetchWithCommand:@"SHOW TABLES;" onConnection:conn];
                    
                    NSArray *fetchResults = [fetch results], *fetchFields = [fetch fields];
                    NSInteger resultsCount = [fetchResults count], fieldsCount = [fetchFields count];
                    
                    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
                    
                    if (fetch) {
                        if (fieldsCount > 0) {
                            MysqlFetchField *resultsTableName = [fetchFields objectAtIndex:0];
                            
                            for (NSDictionary *tableName in [fetch results]) {
                                
                                NSString *tableKey = [resultsTableName name];
                                NSString *tn = [tableName objectForKey:tableKey];
                                
                                MTDatabaseTable *databaseTable = [[MTDatabaseTable alloc] initWithTableName: tn];
                                [results addObject: databaseTable];
                                [databaseTable release];
                            }
                        }
                    }
                    completion(successConnection, errorConnection, [results autorelease]);
                } else {
                    [[MTKeyChain sharedObject] deleteKey:key];
                    completion(NO, errorConnection, nil);
                }
                
                [serv release];
            }];
            
        } else {
            completion(success, credentialsError, nil);
        }
    }];
}


- (void)getFieldsForTableName: (NSString *)tableName
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    
    
    __block MysqlServer *serv = [[MysqlServer alloc] init];
    
    [serv setHost:      [[self databaseConnection] server]];
    [serv setSchema:    [[self databaseConnection] database]];
    [serv setPort:      (unsigned int)[[self databaseConnection] port]];
    
    NSString *key = [MTKeyChain keyForServer:[[self databaseConnection] server] port:[[self databaseConnection] port] andDatabase:[[self databaseConnection] database]];
    
    [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *credentialsError, NSString *username, NSString *password, BOOL fromKeyChain) {
        
        if (success) {
            
            [serv setUser:      username];
            [serv setPassword:  password];
            
            [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key shortCircuit:fromKeyChain completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
                
                NSError *errorConnection = nil;
                MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&errorConnection];
                
                NSMutableArray *results = nil;
                BOOL successConnection = conn != nil;
                
                NSMutableDictionary *resultsDictionary = nil;
                
                if (successConnection) {
                    NSString *command = [NSString stringWithFormat:@"SHOW COLUMNS FROM %@;", tableName];
                    MysqlFetch *fetch = [MysqlFetch fetchWithCommand:command onConnection:conn];
                    if (fetch) {
                        if ([[fetch fields] count] > 0) {
                            
                            MysqlFetchField *fieldMetaData = [[fetch fields] objectAtIndex:0];
                            results = [[NSMutableArray alloc] initWithCapacity: [[fetch results] count]];
                            resultsDictionary = [[NSMutableDictionary alloc] initWithCapacity:[[fetch results] count]];
                            
                            for (NSDictionary *field in [fetch results]) {
                                NSString *fieldName = [field objectForKey:[fieldMetaData name]];
                                
                                MTDatabaseField *databaseField = [[MTDatabaseField alloc] initWithName: fieldName];
                                //[databaseField setDatatype:[field objectForKey:@"Type"]];
                                [results addObject: databaseField];
                                [resultsDictionary setObject:databaseField forKey:fieldName];
                                [databaseField release];
                            }
                        }
                    }
                    
                    NSString *command2 = [NSString stringWithFormat:@"SELECT * FROM %@ LIMIT 0;", tableName];
                    MysqlFetch *fetch2 = [MysqlFetch fetchWithCommand:command2 onConnection:conn];
                    if (fetch) {
                        
                        if ([[fetch2 fields] count] > 0) {
                            
                            for (MysqlFetchField *field in [fetch2 fields]) {
                                
                                MTDataType dataType = [MTDatabaseMySql dataTypeForNativeType:[field fieldType]];
                                NSString *fieldNameKey = [field name];
                                NSArray *fieldNameParts = [fieldNameKey componentsSeparatedByString:@"."];
                                NSString *fieldNameKeyLastPart = [fieldNameParts lastObject];
                                NSString *fieldName = [fieldNameKeyLastPart stringByReplacingOccurrencesOfString:@"`" withString:@""];
                                MTDatabaseField *databaseField = [[resultsDictionary objectForKey:fieldName] retain];
                                [databaseField setFieldTypeNative:[field fieldType]];
                                [databaseField setFieldType:dataType];
                                [databaseField setWidth:[field width]];
                                [databaseField setDecimals:[field decimals]];
                                [databaseField setPrimaryKey:[field primaryKey]];
                                [databaseField release];
                            }
                        }
                    }
                } else {
                    [[MTKeyChain sharedObject] deleteKey:key];
                    [error presentErrorToUser];
                }
                [serv release];
                
                [results release];
                NSArray *resultsArray = [[resultsDictionary allValues] retain];
                [resultsDictionary release];
                
                completion(successConnection, errorConnection, [resultsArray autorelease]);
                
            }];
            
        } else {
            completion(success, credentialsError, nil);
        }
    }];
}

+ (MTDataType)dataTypeForNativeType:(NSInteger)nativeType {
    MTDataType result;
    switch (nativeType) {
        //case MAX_NO_FIELD_TYPES:
        //    result = MTDataTypeString;
        //    break;
        case MYSQL_TYPE_BIT:
            result = MTDataTypeBit;
            break;
        case MYSQL_TYPE_BLOB:
            result = MTDataTypeBlob;
            break;
        case MYSQL_TYPE_DATE:
            result = MTDataTypeDate;
            break;
        case MYSQL_TYPE_DATETIME:
            result = MTDataTypeDateTime;
            break;
        case MYSQL_TYPE_DECIMAL:
            result = MTDataTypeDecimal;
            break;
        case MYSQL_TYPE_DOUBLE:
            result = MTDataTypeDouble;
            break;
        case MYSQL_TYPE_ENUM:
            result = MTDataTypeEnum;
            break;
        case MYSQL_TYPE_FLOAT:
            result = MTDataTypeFloat;
            break;
        case MYSQL_TYPE_GEOMETRY:
            result = MTDataTypeGeometry;
            break;
        case MYSQL_TYPE_INT24:
            result = MTDataTypeInteger;
            break;
        case MYSQL_TYPE_LONG:
            result = MTDataTypeLong;
            break;
        case MYSQL_TYPE_LONG_BLOB:
            result = MTDataTypeBlob;
            break;
        case MYSQL_TYPE_LONGLONG:
            result = MTDataTypeLongLong;
            break;
        case MYSQL_TYPE_MEDIUM_BLOB:
            result = MTDataTypeBlob;
            break;
        case MYSQL_TYPE_NEWDATE:
            result = MTDataTypeDate;
            break;
        case MYSQL_TYPE_NEWDECIMAL:
            result = MTDataTypeDecimal;
            break;
        case MYSQL_TYPE_NULL:
            result = MTDataTypeNumber;
            break;
        case MYSQL_TYPE_SET:
            result = MTDataTypeSet;
            break;
        case MYSQL_TYPE_SHORT:
            result = MTDataTypeShort;
            break;
        case MYSQL_TYPE_STRING:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_TIME:
            result = MTDataTypeDateTime;
            break;
        case MYSQL_TYPE_TIMESTAMP:
            result = MTDataTypeTimeStamp;
            break;
        case MYSQL_TYPE_TINY:
            result = MTDataTypeShort;
            break;
        case MYSQL_TYPE_TINY_BLOB:
            result = MTDataTypeBlob;
            break;
        case MYSQL_TYPE_VAR_STRING:
            result = MTDataTypeVarChar;
            break;
        case MYSQL_TYPE_VARCHAR:
             result = MTDataTypeVarChar;
            break;
        case MYSQL_TYPE_YEAR:
            result = MTDataTypeYear;
            break;
        default:
            result = MTDataTypeString;
            break;
    }
    return result;
}

- (NSString *)identifier {
    return [MTDatabaseConnectionMySql identifier];
}

+ (NSString *)identifier {
    return [MTDatabaseConnectionMySql identifier];
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    return [MTDatabaseMySql safeQueryField:queryField];
}

+ (NSString *)safeQueryField:(RptqQueryField *)queryField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[queryField inQueryTable] queryAlias];
    NSString *fieldName = [[queryField databaseSchemaField] name];
    return [NSString stringWithFormat:@"`%@`.`%@`", queryTable, fieldName];
}

- (NSString *)safeQuerySchemaField:(RptqDatabaseSchemaField *)schemaField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[schemaField inTable] name];
    NSString *fieldName = [schemaField name];
    return [NSString stringWithFormat:@"`%@`.`%@`", queryTable, fieldName];
}

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName {
    // FIXME: Use backticks `` to make more robust.
    return [NSString stringWithFormat:@"`%@`", fieldOrTableName];
}

@end
