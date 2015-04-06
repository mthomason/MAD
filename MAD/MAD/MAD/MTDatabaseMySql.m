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

#import "MysqlConnection.h"
#import "MysqlServer.h"
#import "MysqlFetch.h"
#import "MysqlFetchField.h"

#import "MTQuery.h"

#import "MTDatabaseField.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "MTKeyChain.h"

#import "MTDataTable.h"
#import "MTDataColumn.h"
#import "MTDatabaseTable.h"


@interface MTDatabaseMySql ()
    <MysqlFetchDelegate>

@end

@implementation MTDatabaseMySql

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return [self.delegate dataTableForQuery:query];
}

- (void)didFetchRow:(NSUInteger)row {
    [self readRow:row];
}

- (void)connectWithCredentals:(MTDatabaseConnection *)connection completion:(void (^)(id, BOOL, NSError *))completion {
    
    [self getCredentalsWithConnection:connection completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {

        if (success) {
            NSError *connError = nil;
            
            MysqlServer *serv = [[MysqlServer alloc] init];
            
            [serv setHost:      [connection server]];
            [serv setSchema:    [connection database]];
            [serv setPort:      (unsigned int)[connection port]];
            [serv setUser:      username];
            [serv setPassword:  password];
            
            MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&connError];
            
            success = (conn && connError == nil);
            completion(conn, success, connError);
        } else if (error !=  nil) {
            completion(nil, NO, error);
        } else {
            NSError *error = [MTDatabaseMySql errorCouldNotGetCredientals];
            completion(nil, NO, error);
        }
        
    }];
}

- (void)executeQuery:(MTQuery *)query completion:(void (^)(BOOL, NSError *))completion {
    MTDatabaseConnection *connectionSettings = [self databaseConnection];
    [self connectWithCredentals:connectionSettings completion:^(id dbconn, BOOL success, NSError *error) {
        MysqlConnection *conn = dbconn;
        if (conn && error == nil) {
            @autoreleasepool {
                MysqlFetch *myFetch = [[MysqlFetch alloc] init];
                myFetch.delegate = self;
                [myFetch performQuery: query
                         onConnection: conn];
                completion(YES, nil);
            }
            
        } else {
            if (error.code != MTKeyErrorUserCanceled) {
                [self performSelectorOnMainThread: @selector(removeCredentalsBecauseOfError:)
                                       withObject: error waitUntilDone: NO];
            }
            completion(NO, error);
            
        }
    }];
    
    /*
    
    [self getCredentalsWithConnection:connectionSettings completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
        if (success) {
            
            [self connectWithCredentals:connectionSettings completion:^(id dbconn, BOOL success, NSError *error) {
                MysqlConnection *conn = dbconn;
                if (conn && error == nil) {
                    @autoreleasepool {
                        MysqlFetch *myFetch = [[MysqlFetch alloc] init];
                        myFetch.delegate = self;
                        [myFetch performQuery: query
                                 onConnection: conn];
                        completion(YES, nil);
                    }
                    
                } else {

                    [self performSelectorOnMainThread: @selector(removeCredentalsBecauseOfError:)
                                           withObject: error waitUntilDone: NO];
                    completion(NO, error);
                    
                }
            }];

        } else {
            NSString *title = NSLocalizedString(@"Notice", @"Notice");
            NSString *failureReason = NSLocalizedString(@"Could not get credentials.", @"Could not get credentials.");
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title,
                                        NSLocalizedFailureReasonErrorKey : failureReason};
            NSError *error = [NSError errorWithDomain:@"MTDatabase" code:43421 userInfo:errorInfo];
            completion(NO, error);
            
        }
    }];*/
}

+ (NSError *)errorCouldNotGetCredientals {
    NSString *title = NSLocalizedString(@"Notice", @"Notice");
    NSString *failureReason = NSLocalizedString(@"Could not get credentials.", @"Could not get credentials.");
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title,
                                NSLocalizedFailureReasonErrorKey : failureReason};
    NSError *error = [NSError errorWithDomain:@"MTDatabase" code:43421 userInfo:errorInfo];
    return error;
}

- (void)getTablesFromConnection:(id)dbconn completion:(void (^)(BOOL, NSError *, NSArray *))completion {

    NSError *error = nil;
    MysqlConnection *conn = dbconn;
    MysqlFetch *myFetch = [[MysqlFetch alloc] init];
    MTDataTable *dataTableVirtual = [MTDataTable newDataTableForIdentifier:@"v999"];
    MTDataTable *dataTable = [myFetch fetchWithCommand: @"SHOW TABLES;"
                                             dataTable: &dataTableVirtual
                                          onConnection: conn
                                                 error: &error];
    NSMutableArray *results = nil;
    if (error == nil) {
        NSInteger resultsCount = [dataTable count];
        results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
        for (NSInteger i=0; i<[dataTable count]; i++) {
            @autoreleasepool {
                NSString *tableName = [dataTable objectAtRow:i column:0];
                MTDatabaseTable *table = [[MTDatabaseTable alloc] initWithTableName:tableName];
                [results addObject:table];
            }
        }
    }
    completion(error == nil, error, results);
}

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    
    MTDatabaseConnection *connectionSettings = [self databaseConnection];
    
    [self connectWithCredentals:connectionSettings completion:^(id dbconn, BOOL success, NSError *error) {
        
        MysqlConnection *conn = dbconn;
        BOOL successConnection = conn != nil;
        if (successConnection) {
            
            NSError *fetchError = nil;
            MysqlFetch *myFetch = [[MysqlFetch alloc] init];
            MTDataTable *dataTableVirtual = [MTDataTable newDataTableForIdentifier:@"v999"];
            MTDataTable *dataTable = [myFetch fetchWithCommand:@"SHOW TABLES;"
                                                     dataTable:&dataTableVirtual
                                                  onConnection: conn
                                                         error: &fetchError];
            NSMutableArray *results = nil;
            if (fetchError == nil) {
                NSInteger resultsCount = [dataTable count];
                results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
                for (NSInteger i=0; i<[dataTable count]; i++) {
                    @autoreleasepool {
                        NSString *tableName = [dataTable objectAtRow:i column:0];
                        MTDatabaseTable *table = [[MTDatabaseTable alloc] initWithTableName:tableName];
                        [results addObject:table];
                    }
                }
            }
            completion(successConnection, fetchError, results);
        } else {
            SEL removeCredentalsBecauseOfError = @selector(removeCredentalsBecauseOfError:);
            [self performSelectorOnMainThread:removeCredentalsBecauseOfError withObject:error waitUntilDone:NO];
            completion(NO, error, nil);
        }
    }];
}

- (void)getFieldsForTableName: (NSString *)tableName connection:(id)dbconn
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    
    MysqlConnection *conn = dbconn;
    BOOL successConnection = conn != nil;
    NSMutableDictionary *resultsDictionary = nil;
    
    NSString *command = [NSString stringWithFormat:@"SHOW COLUMNS FROM %@;", [self safeIdentifier:tableName]];
    MysqlFetch *myFetch = [[MysqlFetch alloc] init];
    MTDataTable *dataTableVirtual = [MTDataTable newDataTableForIdentifier:@"v9998"];
    NSError *errorShowColumns = nil;
    NSError *errorColumnMetaData = nil;

    MTDataTable *dataTable = [myFetch fetchWithCommand:command dataTable:&dataTableVirtual onConnection:conn error:&errorShowColumns];
    if (errorShowColumns == nil) {
        NSInteger resultsCount = [dataTable count];
        resultsDictionary = [[NSMutableDictionary alloc] initWithCapacity:resultsCount];
        
        for (NSInteger i=0; i<[dataTable numberOfRows]; i++) {
            NSString *name = [dataTable objectAtRow:i column:0];
            NSString *safeId = [self safeIdentifierForTable:tableName andField:name];
            MTDatabaseField *field = [[MTDatabaseField alloc] initWithName:name];
            resultsDictionary[safeId] = field;
        }
        
        MTDataTable *dataTableVirtual2 = [MTDataTable newDataTableForIdentifier:@"v9997"];
        NSString *command2 = [NSString stringWithFormat:@"SELECT * FROM %@ LIMIT 0;", [self safeIdentifier:tableName]];
        MysqlFetch *myFetch2 = [[MysqlFetch alloc] init];
        MTDataTable *dataTable2 = [myFetch2 fetchWithCommand:command2 dataTable:&dataTableVirtual2 onConnection:conn error:&errorColumnMetaData];
        if (errorColumnMetaData == nil) {
            for (MTDataColumn *dataColumn in [dataTable2 columnsEnumerator]) {
                MTDatabaseField *databaseField = resultsDictionary[[dataColumn fieldName]];
                NSInteger nativeColumnType = [[dataColumn nativeColumnType] integerValue];
                [databaseField setFieldTypeNative:nativeColumnType];
                MTDataType fieldType = [MTDatabaseMySql dataTypeForNativeType: nativeColumnType];
                [databaseField setFieldType:fieldType];
                [databaseField setWidth:[[dataColumn dataLength] integerValue]];
                [databaseField setDecimals:[[dataColumn dataPercision] integerValue]];
                [databaseField setPrimaryKey:[dataColumn isPrimaryKey]];
            }
        }
    }
    NSError *errorResult = errorShowColumns == nil ? errorColumnMetaData : errorShowColumns;
    completion(successConnection, errorResult, [resultsDictionary allValues]);
}

- (void)getFieldsForTableName: (NSString *)tableName
                   completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    
    
    MTDatabaseConnection *connectionSettings = [self databaseConnection];
    [self getCredentalsWithConnection:connectionSettings completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
        [self connectWithCredentals:connectionSettings completion:^(id dbconn, BOOL success, NSError *error) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                
                NSError *errorShowColumns = nil;
                NSError *errorColumnMetaData = nil;
                MysqlConnection *conn = dbconn;
                BOOL successConnection = conn != nil;
                NSMutableDictionary *resultsDictionary = nil;
                if (successConnection) {
                    
                    
                    NSString *command = [NSString stringWithFormat:@"SHOW COLUMNS FROM %@;", [self safeIdentifier:tableName]];
                    MysqlFetch *myFetch = [[MysqlFetch alloc] init];
                    MTDataTable *dataTableVirtual = [MTDataTable newDataTableForIdentifier:@"v9998"];
                    MTDataTable *dataTable = [myFetch fetchWithCommand: command
                                                             dataTable: &dataTableVirtual
                                                          onConnection: conn
                                                                 error: &errorShowColumns];
                    if (errorShowColumns == nil) {
                        NSInteger resultsCount = [dataTable count];
                        resultsDictionary = [[NSMutableDictionary alloc] initWithCapacity:resultsCount];
                        
                        for (NSInteger i=0; i<[dataTable numberOfRows]; i++) {
                            NSString *name = [dataTable objectAtRow:i column:0];
                            NSString *safeId = [self safeIdentifierForTable:tableName andField:name];
                            MTDatabaseField *field = [[MTDatabaseField alloc] initWithName:name];
                            resultsDictionary[safeId] = field;
                        }
                        
                        MTDataTable *dataTableVirtual2 = [MTDataTable newDataTableForIdentifier:@"v9997"];
                        NSString *command2 = [NSString stringWithFormat:@"SELECT * FROM %@ LIMIT 0;", [self safeIdentifier:tableName]];
                        MysqlFetch *myFetch2 = [[MysqlFetch alloc] init];
                        MTDataTable *dataTable2 = [myFetch2 fetchWithCommand: command2
                                                                   dataTable: &dataTableVirtual2
                                                                onConnection: conn
                                                                       error: &errorColumnMetaData];
                        if (errorColumnMetaData == nil) {
                            for (MTDataColumn *dataColumn in [dataTable2 columnsEnumerator]) {
                                MTDatabaseField *databaseField = resultsDictionary[[dataColumn fieldName]];
                                NSInteger nativeColumnType = [[dataColumn nativeColumnType] integerValue];
                                [databaseField setFieldTypeNative:nativeColumnType];
                                MTDataType fieldType = [MTDatabaseMySql dataTypeForNativeType: nativeColumnType];
                                [databaseField setFieldType:fieldType];
                                [databaseField setWidth:[[dataColumn dataLength] integerValue]];
                                [databaseField setDecimals:[[dataColumn dataPercision] integerValue]];
                                [databaseField setPrimaryKey:[dataColumn isPrimaryKey]];
                            }
                        }
                    }
                } else {
                    SEL removeCredentalsBecauseOfError = @selector(removeCredentalsBecauseOfError:);
                    NSError *resultError = nil;
                    if (error == nil) {
                        resultError = errorShowColumns == nil ? errorColumnMetaData : errorShowColumns;
                    } else {
                        resultError = error;
                    }
                    [self performSelectorOnMainThread:removeCredentalsBecauseOfError withObject:resultError waitUntilDone:NO];
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    completion(successConnection, error, [resultsDictionary allValues]);
                });
            });
            
        }];
    }];
}

- (void)closeProcess:(id)process {
    mysql_close(((MysqlConnection *)process).connection);
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

+ (NSString *)safeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    return [NSString stringWithFormat:@"`%@`.`%@`", tableName, fieldName];
}

- (NSString *)safeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    return [MTDatabaseMySql safeQueryField:fieldName andTable:tableName];
}

- (NSString *)safeIdentifierForTable:(NSString *)tableName andField:(NSString *)fieldName {
    return [NSString stringWithFormat:@"`%@`.`%@`", tableName, fieldName];
}

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName {
    return [NSString stringWithFormat:@"`%@`", fieldOrTableName];
}

@end
