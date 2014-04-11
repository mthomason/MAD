//
//  MNSDatabaseMySql.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseMySql.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseConnectionMySql.h"

#import "MTQuery.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import "RptqQueryCache.h"
#import "RptqQueryCache+Extras.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqQueryPredicate.h"
#import "RptqQueryPredicate+Extras.h"

#import "MTKeyChain.h"
#import "NSError+UserInterface.h"
#import "NSError+Constructors.h"

#import "MTDataTable.h"
#import "MTDataColumn.h"

@interface MTDatabaseMySql ()

@end

@implementation MTDatabaseMySql

- (void)connectWithCredentals:(MTDatabaseConnection *)connection completion:(void (^)(id, BOOL, NSError *))completion {
    
    [self getCredentalsWithConnection:connection completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {

        NSError *connError = nil;
        
        MysqlServer *serv = [[MysqlServer alloc] init];
        
        [serv setHost:      [connection server]];
        [serv setSchema:    [connection database]];
        [serv setPort:      (unsigned int)[connection port]];
        [serv setUser:      username];
        [serv setPassword:  password];
        
        MysqlConnection *conn = [[MysqlConnection connectToServer: serv error:&connError] retain];

        success = (conn && connError == nil);
        completion(conn, success, connError);
        
        [conn release];
        [serv release];
        

    }];
}

- (void)executeQuery:(MTQuery *)query completion:(void (^)(BOOL, NSError *, MTDataTable *))completion {
    MTDatabaseConnection *connectionSettings = [[self databaseConnection] retain];
    [self getCredentalsWithConnection:connectionSettings completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
        [self connectWithCredentals:connectionSettings completion:^(id dbconn, BOOL success, NSError *error) {
            MysqlConnection *conn = [dbconn retain];
            if (conn && error == nil) {
                
                @autoreleasepool {
                    NSError *error = nil;
                    NSString *sql = [query getSqlWithError:&error];
                    if (error == nil) {
                        MTDataTable *fetch = [[MysqlFetch fetchWithCommand:sql onConnection:conn extendedNames:YES] retain];
                        //These native types are not set by the mysql lib.
                        for (MTDataColumn *column in [[fetch columns] objectEnumerator]) {
                            NSNumber *cType = @([MTDatabaseMySql dataTypeForNativeType:column.columnType.integerValue]);
                            [column setNativeColumnType:cType];
                            
                        }
                        //Fixme set native column types
                        [[self delegateCacheData] cacheQueryResult:fetch];
                        completion(YES, nil, fetch);
                        [fetch release];
                    } else {
                        completion(NO, error, nil);
                    }
                    
                }
                
            } else {
                SEL removeCredentalsBecauseOfError = @selector(removeCredentalsBecauseOfError:);
                [self performSelectorOnMainThread:removeCredentalsBecauseOfError withObject:error waitUntilDone:NO];
                completion(NO, error, nil);
            }
            [conn release];
        }];
    }];
    [connectionSettings release];
}

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    
    MTDatabaseConnection *connectionSettings = [[self databaseConnection] retain];
    [self getCredentalsWithConnection:connectionSettings completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
        [self connectWithCredentals:connectionSettings completion:^(id dbconn, BOOL success, NSError *error) {
            
            MysqlConnection *conn = [dbconn retain];
            BOOL successConnection = conn != nil;
            if (successConnection) {
                
                MTDataTable *fetch = [MysqlFetch fetchWithCommand:@"SHOW TABLES;" onConnection:conn];
                
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
                completion(successConnection, error, [results autorelease]);
            } else {
                SEL removeCredentalsBecauseOfError = @selector(removeCredentalsBecauseOfError:);
                [self performSelectorOnMainThread:removeCredentalsBecauseOfError withObject:error waitUntilDone:NO];
                completion(NO, error, nil);
            }
            [conn release];
        }];
    }];
    [connectionSettings release];
    
}


- (void)getFieldsForTableName: (NSString *)tableName
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    
    
    MTDatabaseConnection *connectionSettings = [[self databaseConnection] retain];
    [self getCredentalsWithConnection:connectionSettings completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
        [self connectWithCredentals:connectionSettings completion:^(id dbconn, BOOL success, NSError *error) {
            MysqlConnection *conn = [dbconn retain];
            BOOL successConnection = conn != nil;
            NSMutableArray *results = nil;
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
                        
                        [results release];
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
                SEL removeCredentalsBecauseOfError = @selector(removeCredentalsBecauseOfError:);
                [self performSelectorOnMainThread:removeCredentalsBecauseOfError withObject:error waitUntilDone:NO];
            }

            NSArray *resultsArray = [[resultsDictionary allValues] retain];
            [resultsDictionary release];
            
            completion(successConnection, error, [resultsArray autorelease]);
            
        }];
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
