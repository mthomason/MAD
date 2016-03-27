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
#import "MADCredential.h"

#import "MTDatabaseConnection.h"
#import "MTDatabaseConnectionMySql.h"

#import <MADMySQL/MysqlConnection.h>
#import <MADMySQL/MysqlServer.h>
#import <MADMySQL/MysqlFetch.h>
#import <MADMySQL/MysqlFetchField.h>
//#import <MADMySQL/MysqlException.h>
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

@end

@implementation MTDatabaseMySql

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return [self.delegate dataTableForQuery:query];
}

- (void)didFetchRow:(NSUInteger)row {
    [self readRow:row];
}

// FIXME: Return error.
- (id)connectWithConnection:(MTDatabaseConnection *)connection credentals:(MADCredential *)credentals {

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
                *error = [NSError errorWithDomain:sqlError.domain code:sqlError.code userInfo:errorUserInfo.userinfo];
            }
        } else {
            result = true;
        }
    }
    return result ? YES : NO;
}

+ (NSError *)errorCouldNotGetCredientals {
    NSString *title = NSLocalizedString(@"Notice", @"Notice");
    NSString *failureReason = NSLocalizedString(@"Could not get credentials.", @"Could not get credentials.");
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : title,
                                NSLocalizedFailureReasonErrorKey : failureReason};
    NSError * __autoreleasing error = [NSError errorWithDomain:@"MTDatabase" code:43421 userInfo:errorInfo];
    return error;
}

- (NSString *)domain {
    return NSStringFromClass([self class]);
}

- (void)enumerateTablesFromConnection:(id)dbconn
                           usingBlock:(void (^)(id obj, NSUInteger index, BOOL *stop))block
                           completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    NSError *error = nil;
    MysqlConnection *connection = dbconn;
    MysqlFetch *myFetch = [[MysqlFetch alloc] init];
    MTDataTable *dataTableVirtual = [MTDataTable newDataTableForIdentifier:@"v999"];
    MTDataTable *dataTable = [myFetch fetchWithCommand: @"SHOW TABLES;"
                                             dataTable: &dataTableVirtual
                                          onConnection: connection
                                                 error: &error];
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /*
    
    
    MysqlFetch *mf = [[MysqlFetch alloc] init];
    NSError *errorFetch = nil;
    
    if (!connection) {
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : @"Connection is empty.",
                                    NSLocalizedFailureReasonErrorKey : @"Connection Error"};
        errorFetch = [NSError errorWithDomain:[self domain] code:3492 userInfo:errorInfo];
    }
    
    if (errorFetch == nil) {
        MYSQL_STMT *myStatement = mysql_stmt_init(connection.connection);
        const char *cCommand = "SHOW TABLES;";
        int prepareResult = mysql_stmt_prepare(myStatement, cCommand, strlen(cCommand));
        if (prepareResult) {
            const char *err = mysql_stmt_error(myStatement);
            unsigned int code = mysql_stmt_errno(myStatement);
            NSString *errorString = [[NSString alloc] initWithFormat:@"MySQL says %d! %s.", code, err];
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : errorString,
                                        NSLocalizedFailureReasonErrorKey : @"Error"};
            errorFetch = [NSError errorWithDomain:[self domain] code:(NSInteger)code userInfo:errorInfo];
            error = errorFetch;
            
        } else {
            
            // build out and connect the bindings
            
            MYSQL_BIND *bindings = calloc(myStatement->field_count,sizeof(MYSQL_BIND));
            
            // Notes on how MySQL numeric datatypes are handled in the code following:
            //
            // INTEGER datatype handled by MYSQL_TYPE_LONG
            // INT datatype handled by MYSQL_TYPE_LONG
            // BIGINT datatype handled by MYSQL_TYPE_LONGLONG
            // TINYINT datatype handled by MYSQL_TYPE_TINY
            // REAL datatype handled by MYSQL_TYPE_DOUBLE
            // DOUBLE datatype handled by MYSQL_TYPE_DOUBLE
            // FLOAT datatype handled by MYSQL_TYPE_FLOAT
            // DECIMAL datatype handled by MYSQL_TYPE_NEWDECIMAL
            // NUMERIC datatype handled by MYSQL_TYPE_NEWDECIMAL (note: NUMERIC is implemented as DECIMAL by MySQL)
            //
            // SMALLINT datatype not handled currently - exception will occur if used
            // MEDIUMINT datatype not handled currently - exception will occur if used
            // BIT datatype not handled currently - exception will occur if used
            // Note: CHAR datatype isn't considered numeric and is handled by MYSQL_TYPE_STRING
            
            NSMutableArray *fieldNameCollector = [[NSMutableArray alloc] initWithCapacity:myStatement->field_count];
            NSMutableArray *fieldCollector = [[NSMutableArray alloc] initWithCapacity:myStatement->field_count];
            NSMutableSet *sourceTables = [[NSMutableSet alloc] initWithCapacity:myStatement->field_count];
            
            [dataTableVirtual removeAllObjects];
            
            for (NSUInteger x=0; x < myStatement->field_count;x++) {
                NSString *table=[[NSString alloc]  initWithBytes:myStatement->fields[x].table
                                                          length:myStatement->fields[x].table_length
                                                        encoding:NSUTF8StringEncoding];
                [sourceTables addObject:table];
                
                NSString *fieldName;
                if (sourceTables.count > 1){
                    NSString *fieldKeyName=[[NSString alloc]  initWithBytes:myStatement->fields[x].name
                                                                     length:myStatement->fields[x].name_length
                                                                   encoding:NSUTF8StringEncoding];
                    if (table.length > 0) {
                        fieldName = table.length > 0 ? [[NSString alloc] initWithFormat:@"`%@`.`%@`", table, fieldKeyName] :
                                                       [[NSString alloc] initWithFormat:@"`%@`", fieldKeyName];
                    }
                } else {
                    fieldName = [[NSString alloc]  initWithBytes: myStatement->fields[x].name
                                                          length: myStatement->fields[x].name_length
                                                        encoding: NSUTF8StringEncoding];
                }
                [fieldNameCollector addObject:fieldName];
                
                MTDataColumn *dataColumn = [[MTDataColumn alloc] initWithIdentifier:fieldName];
                MysqlFetchField *field = [[MysqlFetchField alloc] init];
                
                
                [fieldCollector addObject:field];
                field.name=fieldName;
                field.width=myStatement->fields[x].length;
                field.decimals=myStatement->fields[x].decimals;
                field.fieldType=myStatement->fields[x].type;
                if (IS_PRI_KEY(myStatement->fields[x].flags)) field.primaryKey=YES;
                
                bindings[x] = [MysqlFetch bindDataForStatement: myStatement andField: x];
                
                NSInteger ftype = myStatement->fields[x].type;
                NSNumber *fieldType = @(ftype);
                NSNumber *fieldLength = @(myStatement->fields[x].length);
                NSNumber *fieldPercision = @(myStatement->fields[x].decimals);
                NSNumber *fieldTypeMad = @(0);
                
                [dataColumn setFieldName:field.name];
                [dataColumn setNativeColumnType:fieldType];
                [dataColumn setDataLength:fieldLength];
                [dataColumn setDataPercision:fieldPercision];
                [dataColumn setColumnType:fieldTypeMad];
                [dataColumn setPrimaryKey:field.primaryKey];
                
                NSNumber *cType = @([MTDataTypeMySQL dataTypeForNativeType:ftype]);
                [dataColumn setColumnType:cType];
                
                [dataTableVirtual addColumn:dataColumn];
                
            }
            
            //[*dataTable beginBulkInsert];
            
            [mf setFieldNames:fieldNameCollector];
            [mf setFields:fieldCollector];
            
            if (mysql_stmt_bind_result(myStatement,(MYSQL_BIND *)bindings)) {
                errorFetch = [MysqlException errorWithConnection:connection domain:[self domain] andCode:3534];
            } else {
                
                if (mysql_stmt_execute(myStatement)) {
                    errorFetch = [MysqlException errorWithConnection:connection domain:[self domain] andCode:4534];
                } else {
                    
                    [self fetchResultsFromConnection:connection
                                       intoDataTable:dataTable
                                       withStatement:myStatement
                                               fetch:mf
                                         andBindings:bindings];
                    
                    for (NSUInteger x=0; x < myStatement->field_count;x++) {
                        free(bindings[x].buffer);
                        free(bindings[x].length);
                        free(bindings[x].error);
                        free(bindings[x].is_null);
                    }
                    free(bindings);
                    mysql_stmt_close(myStatement);
                }
            }
        }
    }
    
//    return *dataTable;
    
    
    
    
    
    
    
    
    
    */
    
    
    
    
    
    
    
    
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
    MysqlConnection *conn = [self connectWithConnection:connectionSettings credentals:nil];
    if (conn) {
        
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
        completion(YES, fetchError, results);
    } else {
        completion(NO, nil, nil);
    }
}

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
            for (MTDataColumn *dataColumn in columnsEnumerator) {
                MTDatabaseField *databaseField = resultsDictionary[[dataColumn fieldName]];
                
                NSInteger nativeColumnType = dataColumn.nativeColumnType.integerValue;
                databaseField.fieldTypeNative = nativeColumnType;
                
                MTDataType fieldType = [MTDataTypeMySQL dataTypeForNativeType: nativeColumnType];
                databaseField.fieldType = fieldType;
                databaseField.width = dataColumn.dataLength.unsignedIntegerValue;
                databaseField.decimals = dataColumn.dataPercision.unsignedIntegerValue;
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

@end
