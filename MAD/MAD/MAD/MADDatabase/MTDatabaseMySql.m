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
#import <MADFoundation/MADDataColumn.h>
#import "MADCredential.h"

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

#import <MADMySQL/mysql.h>

@interface MTDatabaseMySql ()
    <MysqlFetchDelegate>

    @property (nonatomic, strong) MTDatabaseConnectionMySql *databaseConnection;

@end

@implementation MTDatabaseMySql

@dynamic databaseConnection;

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return [self.delegate dataTableForQuery:query];
}

- (void)didFetchRow:(NSUInteger)row {
    [self readRow:row];
}

// FIXME: Return error.
- (id)connectWithConnection:(MTDatabaseConnectionMySql *)connection credentals:(MADCredential *)credentals {

    if (credentals == nil) {
        credentals = [self getCredentalsWithConnection:connection];
    }

    bool success = false;
    MysqlConnection *conn = nil;
    
    if (connection && credentals) {
        NSError *connError = nil;
        
        MysqlServer *serv = [[MysqlServer alloc] init];
        
        NSString *server = [connection server];
        serv.host = server.copy;
        
        NSString *database = [connection database];
        serv.schema = database.copy;
        
        serv.port = (unsigned int)connection.port;
        serv.user = credentals.username.copy;
        serv.password = credentals.password.copy;
        
        conn = [MysqlConnection connectToServer: serv error:&connError];
        
        success = (conn && connError == nil);
    }
    return success ? conn : nil;
}

- (BOOL)executeQuery:(MTQuery *)query withError:(NSError * __autoreleasing *)error {
    bool result = false;
    MTDatabaseConnection *connectionSettings = [self databaseConnection];
    MysqlConnection *dbconn = [self connectWithConnection:connectionSettings credentals:nil];
    if (dbconn) {
        MysqlFetch *myFetch = [[MysqlFetch alloc] init];
        myFetch.delegate = self;
        
        NSError *sqlError = nil;
        NSString *queryString = [query getSqlWithError:&sqlError];
        if (queryString.length > 0 && sqlError == nil) {
            MTDataTable *dataTable;
            if (query.dataTable) {
                dataTable = query.dataTable;
            } else {
                dataTable = [self dataTableForQuery:query];
            }
            [myFetch fetchWithCommand: queryString
                            dataTable: &dataTable
                         onConnection: dbconn
                                error: &sqlError];
        }
        if (sqlError) {
            MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:sqlError.localizedDescription andMessage:sqlError.localizedFailureReason];
            if (error != NULL) {
                *error = [errorUserInfo errorWithDomain:sqlError.domain code:sqlError.code];
            }
        } else {
            result = true;
        }
    }
    return result ? YES : NO;
}

- (BOOL)executeSql:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn intoResultTable:(MTDataTable *)dataTable withError:(NSError * __autoreleasing *)error {
    MysqlFetch *myFetch = [[MysqlFetch alloc] init];
    myFetch.delegate = self;
    NSError *fetchError = nil;
    [myFetch fetchWithCommand: sql dataTable: &dataTable onConnection:dbconn extendedNames:YES error: &fetchError];
    return fetchError == nil;
}

+ (NSError *)errorCouldNotGetCredientals {
    NSString *title = NSLocalizedString(@"Notice", @"Notice");
    NSString *failureReason = NSLocalizedString(@"Could not get credentials.", @"Could not get credentials.");
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title, NSLocalizedFailureReasonErrorKey : failureReason};
    NSError *error = [NSError errorWithDomain:@"MTDatabase" code:43421 userInfo:errorInfo];
    return error;
}

- (NSString *)domain {
    return NSStringFromClass([self class]);
}

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    
    MTDatabaseConnection *connectionSettings = [self databaseConnection];
    MysqlConnection *conn = [self connectWithConnection:connectionSettings credentals:nil];
    if (conn) {
        
        NSError *fetchError = nil;
        MysqlFetch *myFetch = [[MysqlFetch alloc] init];
        MTDataTable *dataTableVirtual = [MTDataTable newDataTableForIdentifier:@"v999"];
        MTDataTable *dataTable = [myFetch fetchWithCommand:@"SHOW TABLES;" dataTable:&dataTableVirtual
                                              onConnection: conn error: &fetchError];
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
        completion(YES, fetchError, results);
    } else {
        completion(NO, nil, nil);
    }
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
    NSString * __autoreleasing safeIdentifier = [NSString stringWithFormat:@"`%@`.`%@`", tableName, fieldName];
    return safeIdentifier;
}

- (NSString *)safeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    NSString * __autoreleasing safeIdentifier = [MTDatabaseMySql safeQueryField:fieldName andTable:tableName];
    return safeIdentifier;
}

- (NSString *)safeIdentifierForTable:(NSString *)tableName andField:(NSString *)fieldName {
    NSString * __autoreleasing safeIdentifier = [NSString stringWithFormat:@"`%@`.`%@`", tableName, fieldName];
    return safeIdentifier;
}

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName {
    NSString * __autoreleasing safeIdentifier = [NSString stringWithFormat:@"`%@`", fieldOrTableName];
    return safeIdentifier;
}

#pragma mark - Reading Tables

- (void)enumerateTablesFromConnection:(id)dbconn
                           usingBlock:(void (^)(MTDatabaseTable *obj, NSUInteger index, BOOL *stop))block
                           completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    NSError *error = nil;
    MysqlConnection *connection = dbconn;
    MysqlFetch *myFetch = [[MysqlFetch alloc] init];
    MTDataTable *dataTableVirtual = [MTDataTable newDataTableForIdentifier:@"v999"];
    MTDataTable *dataTable = [myFetch fetchWithCommand: @"SHOW TABLES;"
                                             dataTable: &dataTableVirtual
                                          onConnection: connection
                                                 error: &error];
    
    
    NSMutableArray *results = nil;
    if (error == nil) {

        NSUInteger resultsCount = [dataTable count];
        results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
        NSUInteger counter = 0;

        BOOL stop = NO;
        for (NSUInteger i=0; i<[dataTable count]; i++) {
            @autoreleasepool {

                NSString *tableName = [dataTable objectAtRow:i column:0];
                MTDatabaseTable *table = [[MTDatabaseTable alloc] initWithTableName:tableName];

                [results addObject:table];

                block(table, counter, &stop);
                if (stop) break;
                counter++;

            }
        }
    }
    completion(error == nil, error, results);
}

- (void)getTablesFromConnection:(id)dbconn completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    
    NSError *error = nil;
    MysqlConnection *conn = dbconn;
    MysqlFetch *myFetch = [[MysqlFetch alloc] init];
    MTDataTable *dataTableVirtual = [MTDataTable newDataTableForIdentifier:@"v999"];
    MTDataTable *dataTable = [myFetch fetchWithCommand: @"SHOW TABLES;"
                                             dataTable: &dataTableVirtual
                                          onConnection: conn
                                         extendedNames: YES
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


- (NSArray <MTDatabaseTable *> *)getTablesFromConnection:(id)dbconn error:(NSError * __autoreleasing *)outError {
    
    NSError *errorFetch = nil;
    MysqlConnection *conn = dbconn;
    MysqlFetch *myFetch = [[MysqlFetch alloc] init];
    MTDataTable *dataTableVirtual = [MTDataTable newDataTableForIdentifier:@"v999"];
    MTDataTable *dataTable = [myFetch fetchWithCommand: @"SHOW TABLES;"
                                             dataTable: &dataTableVirtual
                                          onConnection: conn
                                         extendedNames: YES
                                                 error: &errorFetch];
    if (outError == nil && errorFetch != nil) {
        NSDictionary *userInfo = @{NSUnderlyingErrorKey: errorFetch};
        NSString *domain = NSStringFromClass(self.class);
        *outError = [NSError errorWithDomain:domain code:934 userInfo:userInfo];
    }
    NSMutableArray *results = nil;
    if (errorFetch == nil) {
        NSUInteger resultsCount = [dataTable count];
        results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
        for (NSUInteger i=0; i<resultsCount; i++) {
            @autoreleasepool {
                NSString *tableName = [dataTable objectAtRow:i column:0];
                MTDatabaseTable *table = [[MTDatabaseTable alloc] initWithTableName:tableName];
                [results addObject:table];
            }
        }
    }
    return results;
}

#pragma mark - Reading Fields

- (NSArray *)fieldsForTable: (NSString *)tableName connection:(id)dbconn error:(NSError * __autoreleasing *)error {
    
    MysqlConnection *conn = dbconn;
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
            NSEnumerator *columnsEnumerator = [dataTable2 columnsEnumerator];
            for (MADDataColumn *dataColumn in columnsEnumerator) {
                MTDatabaseField *databaseField = resultsDictionary[[dataColumn fieldName]];
                
                databaseField.fieldTypeNative = dataColumn.nativeType;
                
                MTDataType fieldType = [MTDataTypeMySQL dataTypeForNativeType: dataColumn.nativeType];
                databaseField.fieldType = fieldType;
                databaseField.width = dataColumn.dataLength;
                databaseField.decimals = dataColumn.dataPercision;
                databaseField.primaryKey = dataColumn.isPrimaryKey ? YES : NO;
            }
        }
    }
    NSError *errorResult = errorShowColumns == nil ? errorColumnMetaData : errorShowColumns;
    if (error == NULL && errorResult != nil) {
        *error = errorResult;
    }
    
    NSArray * __autoreleasing resultValues = resultsDictionary.allValues;
    return resultValues;
}

@end
