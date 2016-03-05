//
//  MNSDatabaseMySql.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseMySql.h"

#import "MADErrorUserInfo.h"
#import <MADFoundation/MTDataTable.h>
#import <MADFoundation/MTDataColumn.h>

#import "MTDatabaseConnection.h"
#import "MTDatabaseConnectionMySql.h"

#import <MADMySQL/MysqlConnection.h>
#import <MADMySQL/MysqlServer.h>
#import <MADMySQL/MysqlFetch.h>
#import <MADMySQL/MysqlFetchField.h>
#import <MADMySQL/MTDataTypeMySQL.h>

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

#import "MTDataTable+Factory.h"
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
    [self connectWithCredentals:connectionSettings completion:^(MysqlConnection *dbconn, BOOL success, NSError *error) {
        if (dbconn && error == nil) {
            @autoreleasepool {
                
                MysqlFetch *myFetch = [[MysqlFetch alloc] init];
                myFetch.delegate = self;
                
                NSString *queryString = [query getSqlWithError:&error];
                if (queryString.length > 0 && error == nil) {
                    MTDataTable *dataTable = [self dataTableForQuery:query];
                    [myFetch fetchWithCommand:queryString dataTable:&dataTable onConnection:dbconn error:&error];
                }
                MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:error.localizedDescription andMessage:error.localizedFailureReason];
                error = error ? [NSError errorWithDomain:error.domain code:error.code userInfo:errorUserInfo.userinfo] : nil;
                completion(error == nil, error);
                
            }
            
        } else {
            completion(NO, error);
            
        }
    }];
    
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
        NSUInteger resultsCount = [dataTable count];
        results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
        for (NSUInteger i=0; i<[dataTable count]; i++) {
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
                NSUInteger resultsCount = [dataTable count];
                results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
                for (NSUInteger i=0; i<[dataTable count]; i++) {
                    @autoreleasepool {
                        NSString *tableName = [dataTable objectAtRow:i column:0];
                        MTDatabaseTable *table = [[MTDatabaseTable alloc] initWithTableName:tableName];
                        [results addObject:table];
                    }
                }
            }
            completion(successConnection, fetchError, results);
        } else {
            completion(NO, error, nil);
        }
    }];
}

- (void)getFieldsForTableName: (NSString *)tableName connection:(id)dbconn
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    
    MysqlConnection *conn = dbconn;
    BOOL successConnection = conn != nil;
    NSMutableDictionary *resultsDictionary = nil;
    
    NSString *command = [[NSString alloc] initWithFormat:@"SHOW COLUMNS FROM %@;", [self safeIdentifier:tableName]];
    MysqlFetch *myFetch = [[MysqlFetch alloc] init];
    MTDataTable *dataTableVirtual = [MTDataTable newDataTableForIdentifier:@"v9998"];
    NSError *errorShowColumns = nil;
    NSError *errorColumnMetaData = nil;

    MTDataTable *dataTable = [myFetch fetchWithCommand:command dataTable:&dataTableVirtual onConnection:conn error:&errorShowColumns];
    if (errorShowColumns == nil) {
        NSUInteger resultsCount = [dataTable count];
        resultsDictionary = [[NSMutableDictionary alloc] initWithCapacity:resultsCount];
        
        for (NSUInteger i=0; i<[dataTable numberOfRows]; i++) {
            NSString *name = [dataTable objectAtRow:i column:0];
            NSString *safeId = [self safeIdentifierForTable:tableName andField:name];
            MTDatabaseField *field = [[MTDatabaseField alloc] initWithName:name];
            resultsDictionary[safeId] = field;
        }
        
        MTDataTable *dataTableVirtual2 = [MTDataTable newDataTableForIdentifier:@"v9997"];
        NSString *command2 = [[NSString alloc] initWithFormat:@"SELECT * FROM %@ LIMIT 0;", [self safeIdentifier:tableName]];
        MysqlFetch *myFetch2 = [[MysqlFetch alloc] init];
        MTDataTable *dataTable2 = [myFetch2 fetchWithCommand:command2 dataTable:&dataTableVirtual2 onConnection:conn error:&errorColumnMetaData];
        if (errorColumnMetaData == nil) {
            for (MTDataColumn *dataColumn in [dataTable2 columnsEnumerator]) {
                MTDatabaseField *databaseField = resultsDictionary[[dataColumn fieldName]];
                NSInteger nativeColumnType = [[dataColumn nativeColumnType] integerValue];
                [databaseField setFieldTypeNative:nativeColumnType];
                MTDataType fieldType = [MTDataTypeMySQL dataTypeForNativeType: nativeColumnType];
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
                NSError *resultError = nil;
                if (successConnection) {
                    
                    
                    NSString *command = [[NSString alloc] initWithFormat:@"SHOW COLUMNS FROM %@;", [self safeIdentifier:tableName]];
                    MysqlFetch *myFetch = [[MysqlFetch alloc] init];
                    MTDataTable *dataTableVirtual = [MTDataTable newDataTableForIdentifier:@"v9998"];
                    MTDataTable *dataTable = [myFetch fetchWithCommand: command
                                                             dataTable: &dataTableVirtual
                                                          onConnection: conn
                                                                 error: &errorShowColumns];
                    if (errorShowColumns == nil) {
                        NSUInteger resultsCount = [dataTable count];
                        resultsDictionary = [[NSMutableDictionary alloc] initWithCapacity:resultsCount];
                        
                        for (NSUInteger i=0; i<[dataTable numberOfRows]; i++) {
                            NSString *name = [dataTable objectAtRow:i column:0];
                            NSString *safeId = [self safeIdentifierForTable:tableName andField:name];
                            MTDatabaseField *field = [[MTDatabaseField alloc] initWithName:name];
                            resultsDictionary[safeId] = field;
                        }
                        
                        MTDataTable *dataTableVirtual2 = [MTDataTable newDataTableForIdentifier:@"v9997"];
                        NSString *command2 = [[NSString alloc] initWithFormat:@"SELECT * FROM %@ LIMIT 0;", [self safeIdentifier:tableName]];
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
                                MTDataType fieldType = [MTDataTypeMySQL dataTypeForNativeType: nativeColumnType];
                                [databaseField setFieldType:fieldType];
                                [databaseField setWidth:[[dataColumn dataLength] unsignedIntegerValue]];
                                [databaseField setDecimals:[[dataColumn dataPercision] unsignedIntegerValue]];
                                [databaseField setPrimaryKey:[dataColumn isPrimaryKey]];
                            }
                        }
                    }
                } else {
                    if (error == nil) {
                        resultError = errorShowColumns == nil ? errorColumnMetaData : errorShowColumns;
                    } else {
                        resultError = error;
                    }
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    completion(successConnection, resultError, [resultsDictionary allValues]);
                });
            });
            
        }];
    }];
}

- (void)closeProcess:(id)process {
    mysql_close(((MysqlConnection *)process).connection);
}

- (NSString *)identifier {
    return MADIdentifierDatabaseMySQL;
}

+ (NSString *)identifier {
    return MADIdentifierDatabaseMySQL;
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
