//
//  MTDatabaseSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 10/23/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

//#ifndef MAD_MTDatabaseSqlite3_DEBUG
//#define MAD_MTDatabaseSqlite3_DEBUG
//#endif

#import "MTDatabaseSqlite3.h"

#import <string.h>
#import <stdlib.h>
#import <stdio.h>
#import <os/log.h>

#import <dispatch/time.h>
#import <dispatch/semaphore.h>
#import <dispatch/object.h>

#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFData.h>

#import <Foundation/NSException.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNULL.h>
#import <Foundation/NSData.h>
#import <Foundation/NSCalendar.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>

#import <MADSqlite3/sqlite3.h>

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADErrorUserInfo.h>
#import <MADFoundation/MADDataTable.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseTable.h>
#import <MADAPI/MADDatabaseDataBinding.h>

#import <MADAPI/MADDatabaseConnectionsPropertiesURLProtocol.h>

#import "MTQueryCacheDeleteAllFromTable.h"
#import <MADAPI/MTQuery.h>

#import "MTQueryCacheSyncOff.h"
#import "MTQueryCacheJournalModeOverride.h"
#import "MTQueryCacheBeginTransaction.h"
#import "MTQueryCacheEndTransaction.h"
#import "MTQueryCacheSyncDefault.h"


NSString * const MTDatabaseSqlite3SafeQuote = @"\"";
NSString * const MTDatabaseSqlite3SafeFormatIdentifier = @"\"%@\"";
NSString * const MTDatabaseSqlite3SafeFormatField = @"\"%@\".\"%@\"";

BOOL Sqlite3StepResultOK(int result) {
    return (result == SQLITE_OK) || (result == SQLITE_ROW) || (result == SQLITE_DONE);
}

int compare_string_utf8_localized_asc_collation(void *data, int len1, const void *arg1, int len2, const void *arg2) {
    id str1 = [[NSString alloc] initWithBytesNoCopy:(void *)arg1 length:(NSUInteger)abs(len1) encoding:NSUTF8StringEncoding freeWhenDone:NO];
    id str2 = [[NSString alloc] initWithBytesNoCopy:(void *)arg2 length:(NSUInteger)abs(len2) encoding:NSUTF8StringEncoding freeWhenDone:NO];
    return str2 != nil ? [str1 localizedCaseInsensitiveCompare: str2] :
                         NSOrderedDescending;
}

//#ifdef MAD_MTDatabaseSqlite3_DEBUG
void sqliteLog(void *foo, const char* statement);
void sqliteLog(void *foo, const char* statement) {
    printf("=> %s\n", statement);
    //MTLogStatic(@"=> %s", statement);
}
//#endif

@interface MTDatabaseSqlite3 ()

    @property (nonatomic, strong) MADDatabaseConnection <MADDatabaseConnectionsPropertiesURL> *databaseConnection;

@end

@implementation MTDatabaseSqlite3 {
    sqlite3_stmt *_bulkStatement;
    BOOL _isOpen;
}

@dynamic databaseConnection;

//Converting native type to affinity type
// using http://www.sqlite.org/datatype3.html

+ (MADDataType)dataTypeForNativeType:(NSString *)nativeType {
    
    NSString *lowerCaseString = nativeType.lowercaseString;
    
    BOOL isInteger = [lowerCaseString rangeOfString:@"int"].location != NSNotFound;
    BOOL isText = NO;
    BOOL isNone = NO;
    BOOL isReal = NO;
    if (!isInteger) {
        isText = [lowerCaseString rangeOfString:@"char"].location != NSNotFound ||
                    [lowerCaseString rangeOfString:@"clob"].location != NSNotFound ||
                    [lowerCaseString rangeOfString:@"text"].location != NSNotFound;
        if (!isText) {
            isNone = lowerCaseString.length == 0 ||
                        [lowerCaseString rangeOfString:@"blob"].location != NSNotFound;
            
            if (!isNone) {
                isReal = [lowerCaseString rangeOfString:@"real"].location != NSNotFound ||
                    [lowerCaseString rangeOfString:@"floa"].location != NSNotFound ||
                    [lowerCaseString rangeOfString:@"doub"].location != NSNotFound;
            }

        }
    }
    
    MADDataType result;
    if (isInteger) {
        result = MADDataTypeInteger;
    } else if (isText) {
        result = MADDataTypeString;
    } else if (isNone) {
        result = MADDataTypeBlob;
    } else if (isReal) {
        result = MADDataTypeDouble;
    } else {
        result = MADDataTypeNumber;
    }
    return result;
}

+ (MADDataType)dataTypeForAffentyType:(int)affentyType {
    MADDataType result;
    switch (affentyType) {
        case SQLITE_INTEGER:
            result = MADDataTypeInteger;
            break;
        case SQLITE_FLOAT:
            result = MADDataTypeDouble;
            break;
        case SQLITE_BLOB:
            result = MADDataTypeBlob;
            break;
        case SQLITE_NULL:
        case SQLITE3_TEXT:
        default:
            result = MADDataTypeString;
            break;
    }
    return result;
}

+ (MADSqlite3SortDescription *)newSqlite3SortDescriptionForColumnType:(MADDataType)columnType
                                                            ascending:(BOOL)ascending {
    NSString *sortDescription = nil;
    NSString *nativeTypeDescription = [MADSqlite3NativeType newSqlite3NativeType:columnType];
    if ([nativeTypeDescription isEqualToString:@"TEXT"]) {
        sortDescription = ascending ? @"COLLATE LSASC ASC" : @"COLLATE LSASC DESC";
    } else {
        sortDescription = ascending ? @"ASC" : @"DESC";;
    }
    return sortDescription;
}

+ (MADDataType)dataTypeForNativeTypeNumeric:(MADDataType)dataType {
    MADDataType result;
    switch (dataType) {
        case MADDataTypeBit:
        case MADDataTypeInteger:
        case MADDataTypeShort:
        case MADDataTypeLong:
        case MADDataTypeLongLong:
        case MADDataTypeInt24:
        case MADDataTypeEnum:
            result = MADDataTypeInteger;
            break;
        case MADDataTypeSet:
        case MADDataTypeTime:
        case MADDataTypeTimeStamp:
        case MADDataTypeYear:
        case MADDataTypeDate:
        case MADDataTypeDateTime:
        case MADDataTypeString:
        case MADDataTypeVarChar:
        case MADDataTypeGeometry:
            result = MADDataTypeString;
            break;
        case MADDataTypeImage:
        case MADDataTypeBlob: {
            
            result = MADDataTypeBlob;
            break;
        }
        case MADDataTypeFloat:
            result = MADDataTypeFloat;
            break;
        case MADDataTypeDouble:
            result = MADDataTypeDouble;
            break;
        case MADDataTypeDecimal:
        case MADDataTypeNumber:
            result = MADDataTypeDecimal;
            break;
        case MADDataTypeUnknown:
        default:
            result = MADDataTypeString;
            break;
    }
    return result;
}

- (void *)databaseHandle {
    return _database;
}

- (instancetype)init {
    if (self = [super init]) {
        _database = NULL;
        _bulkStatement = NULL;
        _isOpen = NO;
    }
    return self;
}


- (void)openDatabase {
    [self openDatabaseWithFlags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE |
                                    SQLITE_OPEN_SHAREDCACHE | SQLITE_OPEN_FULLMUTEX];
}

- (void)openDatabaseWithFlags:(int)flags {
    //NSError *error = nil;
    //Open conneciton... closed in dealloc.
    if (!_isOpen) {
        
        //NSLog(@"Path: %@", self.databaseConnection.databaseUrl.path);
        
        const char *path = self.databaseConnection.databaseUrl.path.UTF8String;
        BOOL databaseOpen = sqlite3_open_v2(path, ((struct sqlite3 **)&_database), flags, NULL) == SQLITE_OK;
        NSAssert(databaseOpen, @"openDatabaseWithFlags failed (%s).", (char *)sqlite3_errmsg(_database));

        if (databaseOpen) {
            databaseOpen = sqlite3_extended_result_codes((struct sqlite3 *)_database, YES) == SQLITE_OK;
            NSAssert(databaseOpen, @"Error: failed to extend result codes: '%s, %s'.", __PRETTY_FUNCTION__, sqlite3_errmsg((struct sqlite3 *)_database));
            databaseOpen = sqlite3_create_collation_v2((struct sqlite3 *)_database, "LSASC",
                                        SQLITE_UTF8, (struct sqlite3 *)_database,
                                        compare_string_utf8_localized_asc_collation, NULL) == SQLITE_OK;
            NSAssert(databaseOpen, @"Error: failed to create collation: '%s, %s'.", __PRETTY_FUNCTION__, sqlite3_errmsg((struct sqlite3 *)_database));
//#ifdef MAD_MTDatabaseSqlite3_DEBUG
            //sqlite3_trace((struct sqlite3 *)_database, sqliteLog, NULL);
//#endif

        } else {
            //const char *errorMessage = sqlite3_errmsg(_database);
            //NSString *message = @(errorMessage);
            //NSString *title = NSLocalizedString(@"Connect Failed", @"Connect Failed");
            //NSString *domain = @"MTSqlite3";
            //MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle: title
            //                                                               andMessage: message];
            //error = [NSError errorWithDomain:domain code:4832 userInfo:errorUserInfo.userinfo];
        }
        _isOpen = YES;
    }
}

- (void)dealloc {
    
    if (_bulkStatement != NULL && sqlite3_clear_bindings(_bulkStatement) && sqlite3_finalize(_bulkStatement)) {
        NSAssert(0, @"Error: failed to finalize bulk statement with message: '%s, %s'.",
                    __PRETTY_FUNCTION__,
                    sqlite3_errmsg((struct sqlite3 *)_database));
    }
    
    if (_database != NULL && sqlite3_close_v2(_database) != SQLITE_OK) {
        NSAssert(0, @"Error: failed to close database with message '%s, %s'.",
                    __PRETTY_FUNCTION__,
                    sqlite3_errmsg((struct sqlite3 *)_database));
    }

}

- (id)connectWithConnection:(MADDatabaseConnection *)connection
                 credentals:(MADCredential *)credentals
            connectionError:(NSError * __autoreleasing *)error {
    [self openDatabase];
    return nil;
}

- (BOOL)tableExist:(NSString *)tablename {
    BOOL exist = NO;
    sqlite3_stmt *statement = NULL;
    const char *queryc = "SELECT count(tbl_name) FROM sqlite_master WHERE type = 'table' AND name = ?;";
	if (sqlite3_prepare_v2(_database, queryc, -1, &statement, NULL) == SQLITE_OK) {
        const char *t = tablename.UTF8String;
        int bind_result = sqlite3_bind_text(statement, 1, t, (int)strlen(t), SQLITE_STATIC);
        NSAssert(bind_result == SQLITE_OK, @"Error: '%s, %s'.", __PRETTY_FUNCTION__, sqlite3_errmsg(_database));
		if (sqlite3_step(statement) == SQLITE_ROW) {
            exist = sqlite3_column_int(statement, 0) == 1;
        }
    }
    sqlite3_clear_bindings(statement);
    sqlite3_finalize(statement);
    return exist;
}

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray <MADDatabaseTable *> *tables))completion {
    NSMutableArray <MADDatabaseTable *> *result = [[NSMutableArray alloc] init];
    BOOL success = NO;
	sqlite3_stmt *statement;
	NSString *queryStart = @"SELECT tbl_name FROM main.sqlite_master WHERE type='table';";
	char *sql = sqlite3_mprintf((char *) queryStart.UTF8String);

	if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        success = YES;
		while (sqlite3_step(statement) == SQLITE_ROW) {
            
            const unsigned char *resultString = sqlite3_column_text(statement, 0);
            NSString *tableName = @((char *)resultString);
            
            MADDatabaseTable *databaseTable;
            databaseTable = [[MADDatabaseTable alloc] initWithTableName: tableName];
            [result addObject:databaseTable];
		}
	}
	sqlite3_finalize(statement);
	sqlite3_free(sql);
    completion(success, nil, result);
}

- (BOOL)bindStatement:(void ** /* sqlite3_stmt ** */)statement
         withBindings:(MADDatabaseDataBinding *)databinding {

    int success = 0;
    if ([databinding.value isEqual:[NSNull null]]) {
        success = sqlite3_bind_null(*statement, databinding.columnNumber);
    } else {
        switch (databinding.datatype) {
                
            case MADDataTypeBlob: {

                if ([databinding.value isKindOfClass:[NSString class]]) {
                    success = sqlite3_bind_text(*statement, databinding.columnNumber,
                                                ((NSString *)databinding.value).UTF8String,
                                                (int)strlen(((NSString *)databinding.value).UTF8String),
                                                SQLITE_TRANSIENT);
                } else if ([databinding.value isKindOfClass:[NSData class]]) {
                    success = sqlite3_bind_blob(*statement,
                                                databinding.columnNumber,
                                                ((NSData *)databinding.value).bytes,
                                                (int)((NSData *)databinding.value).length,
                                                SQLITE_TRANSIENT);
                }
                
                break;
            }
                
            case MADDataTypeInteger: {
                success = sqlite3_bind_int64(*statement, databinding.columnNumber,
                                             ((NSNumber *)databinding.value).longLongValue);
                break;
            }
                
            case MADDataTypeString: {
                
                if ([databinding.value isKindOfClass:[NSString class]]) {

                    success = sqlite3_bind_text(*statement, databinding.columnNumber,
                                                ((NSString *)databinding.value).UTF8String,
                                                (int)[((NSString *)databinding.value) lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
                                                SQLITE_TRANSIENT);
                    
                } else if ([databinding.value isKindOfClass:[NSDateComponents class]]) {
                    
                    NSDate *date = ((NSDateComponents *)databinding.value).date != nil ?
                                        ((NSDateComponents *)databinding.value).date :
                                        [[NSCalendar currentCalendar] dateFromComponents:databinding.value];
                    success = sqlite3_bind_double(*statement, databinding.columnNumber, date.timeIntervalSince1970);
                    
                } else {
                    //NSAssert(NO, @"What else is there? %s", __PRETTY_FUNCTION__);
                }
                break;
                
            }
            case MADDataTypeFloat:
            case MADDataTypeDouble: {
                NSNumber * __weak n = (NSNumber *)databinding.value;
                success = sqlite3_bind_double(*statement, databinding.columnNumber, n.doubleValue);
                break;
            }
                
            case MADDataTypeNull:
                success = sqlite3_bind_null(*statement, databinding.columnNumber);
                break;
                
            default:
                NSAssert(NO, @"This is going to end badly.  Only binding blobs right now.");
                break;
                
        }
    }
    NSAssert(success == SQLITE_OK, @"Error: '%s, %s'.", __PRETTY_FUNCTION__,
                                   sqlite3_errmsg(_database));
    return (success == SQLITE_OK);
}

- (void)handleFailureInMethod:(SEL)selector
                       object:(id)object
                         file:(NSString *)fileName
                   lineNumber:(NSInteger)line
                  description:(NSString *)format {
    //NSLog(@"Assert: (%@:%ld)", fileName, (long)line);
}

- (void)executeQueryWithSql:(NSString *)queryString
        queryBinaryBindings:(NSArray *)queryBinaryBindings
             queryFieldKeys:(NSArray *)queryFieldKeys
             transactionSet:(BOOL)queryPartOfTransactionSet {

    //NSLog(@"SQL: %@", queryString);
    BOOL success = YES;

    if (queryString.length > 0) {
        
        sqlite3_stmt *statement = NULL;
        char *sql = sqlite3_mprintf(queryString.UTF8String);
        
        if (statement == NULL) {
            int prepare_result = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
            NSAssert(prepare_result == SQLITE_OK, @"ExecuteQueryWithSql failed (%s).", (char *)sqlite3_errmsg(_database));
            success = prepare_result == SQLITE_OK;
            
            if (queryBinaryBindings.count > 0) {
                for (MADDatabaseDataBinding *databinding in queryBinaryBindings) {
                    [self bindStatement:(void **)&statement withBindings:databinding];
                }
            }
        } else if (queryPartOfTransactionSet) {
            if (queryBinaryBindings.count > 0) {
                for (MADDatabaseDataBinding *databinding in queryBinaryBindings) {
                    [self bindStatement:(void **)&statement withBindings:databinding];
                }
            }
        }
        NSAssert(success, @"ExecuteQueryWithSql failed (%s).", (char *)sqlite3_errmsg(_database));
        
        int step_result = sqlite3_step(statement);
        NSAssert(Sqlite3StepResultOK(step_result), @"sqlite3_step failed (%s).", (char *)sqlite3_errmsg(_database));
        sqlite3_clear_bindings(statement);
        step_result = sqlite3_finalize(statement);
        NSAssert(step_result == SQLITE_OK, @"sqlite3_finalize failed (%s).", (char *)sqlite3_errmsg(_database));
        statement = NULL;
        sqlite3_free(sql);
        sql = NULL;
    }
}

- (BOOL)executeSQL:(NSString *)sql
         fieldKeys:(NSArray *)fieldKeys
      onConnection:(id)dbconn
   intoResultTable:(MADDataTable *)dataTable
         withError:(NSError * __autoreleasing *)error {
    BOOL result = [self executeSQL: sql
                         fieldKeys: fieldKeys
                      onConnection: dbconn
                   intoResultTable: dataTable
                    transactionSet: NO
                    returnsResults: YES
                    binaryBindings: nil
                         withError: error];
    return result;
}

- (BOOL)executeSQL: (NSString *)sql
         fieldKeys: (NSArray *)fieldKeys
      onConnection: (id)dbconn
   intoResultTable: (MADDataTable *)dataTable
    transactionSet: (BOOL)partOfTransactionSet
    returnsResults: (BOOL)returnsResults
    binaryBindings: (NSArray *)binaryBindings
         withError: (NSError * __autoreleasing *)resultError {
   
    sqlite3_stmt *statement = NULL;
    statement = partOfTransactionSet ? _bulkStatement : statement;

    BOOL success = NO;
    char *errorMessage = NULL;
    char *csql = sqlite3_mprintf(sql.UTF8String);
    
    
    if (statement == NULL) {
        if (sqlite3_prepare_v2(_database, csql, -1, &statement, NULL) != SQLITE_OK) {
            os_log_debug(OS_LOG_DEFAULT, "%s at %s", sqlite3_errmsg(_database),
                     __PRETTY_FUNCTION__);
            success = NO;
        } else {
            success = YES;
        }
        if (binaryBindings.count > 0) {
            for (MADDatabaseDataBinding *databinding in binaryBindings) {
                [self bindStatement:(void **)&statement withBindings:databinding];
            }
        }
    } else if (partOfTransactionSet) {
        if (binaryBindings.count > 0) {
            for (MADDatabaseDataBinding *databinding in binaryBindings) {
                [self bindStatement:(void **)&statement withBindings:databinding];
            }
        }
    }
    
    if (returnsResults && success) {
        
        
        int numberOfColumns = sqlite3_column_count(statement);
        numberOfColumns = numberOfColumns >= 0 ? numberOfColumns : 0;
        [dataTable removeAllObjects];
        
        NSUInteger rowCounter = 0;
        int sqlite3_step_result;
        while (SQLITE_ROW == (sqlite3_step_result = sqlite3_step(statement))) {
            
            if (rowCounter == 0) {  //If first time around, calculate column information.
                for (int columnCounter = 0; columnCounter < numberOfColumns; columnCounter++) {
                    
                    //@autoreleasepool {
                    
                    NSString *fieldName = fieldKeys[(NSUInteger)columnCounter];
                    
                    MADDataColumn *dataColumn;
                    dataColumn = [[MADDataColumn alloc] initWithIdentifier:fieldName];
                    
                    int affentyType = sqlite3_column_type(statement, (int)columnCounter);
                    
                    const char *columnName = sqlite3_column_name(statement, (int)columnCounter);
                    NSAssert(columnName != NULL, @"%s at %s", sqlite3_errmsg(_database), __PRETTY_FUNCTION__);
                    
                    const char *tableName = sqlite3_column_table_name(statement, (int)columnCounter);
                    const char *databaseName = sqlite3_column_database_name(statement, (int)columnCounter);
                    
                    char const *pzDataType = NULL;
                    char const *pzCollSeq = NULL;
                    int pNotNull = 0;
                    int pPrimaryKey = 0;
                    int pAutoinc = 0;
                    
                    if (tableName != NULL) {
                        
                        /*
                         
                         int sqlite3_table_column_metadata(
                         sqlite3 *db,                // Connection handle
                         const char *zDbName,        // Database name or NULL
                         const char *zTableName,     // Table name
                         const char *zColumnName,    // Column name
                         char const **pzDataType,    // OUTPUT: Declared data type
                         char const **pzCollSeq,      OUTPUT: Collation sequence name
                         int *pNotNull,               OUTPUT: True if NOT NULL constraint exists
                         int *pPrimaryKey,            OUTPUT: True if column part of PK
                         int *pAutoinc                OUTPUT: True if column is auto-increment
                         );
                         */
                        
                        int metadata_result;
                        metadata_result = sqlite3_table_column_metadata(_database,
                                                                        databaseName,
                                                                        tableName,
                                                                        columnName,
                                                                        &pzDataType,
                                                                        &pzCollSeq,
                                                                        &pNotNull,
                                                                        &pPrimaryKey,
                                                                        &pAutoinc);
                        //NSAssert(metadata_result == SQLITE_OK, @"%s at %s",
                        //         sqlite3_errmsg(_database), __PRETTY_FUNCTION__);
                    }
                    
                    dataColumn.fieldName = fieldName;
                    dataColumn.nativeType = (int16_t)affentyType;
                    MADDataType columnType = [MTDatabaseSqlite3 dataTypeForAffentyType:affentyType];
                    dataColumn.type = columnType;
                    
                    dataColumn.primaryKey = pPrimaryKey ? NO : pPrimaryKey;
                    dataColumn.autoIncrement = pAutoinc ? NO : pAutoinc;
                    dataColumn.notNull = pNotNull ? NO : pNotNull;
                    [dataTable addColumn:dataColumn];
                    //}
                }
                
                [dataTable beginBulkInsert];
            }
            [self readRow:rowCounter];
            
            NSMutableDictionary *resultsForRow = [[NSMutableDictionary alloc] initWithCapacity:(NSUInteger)numberOfColumns];
            
            for (int colCtr = 0; colCtr < numberOfColumns; colCtr++) {
                
                resultsForRow[fieldKeys[(NSUInteger)colCtr]] = [MADDatabaseResultValue newDatabaseResultValue:statement
                                                                                                 columnNumber:colCtr];
                
            }
            
            [dataTable addRowWithDataForFieldKeys:resultsForRow];
            //resultsForRow = nil;
            rowCounter++;
        }
        
        [dataTable endBulkInsert];
    }
    
    if (!returnsResults) {
        if (!Sqlite3StepResultOK(sqlite3_step(statement))) {
            os_log_debug(OS_LOG_DEFAULT, "%s",
                         (char *)sqlite3_errmsg(_database));
        }
    }
    
    if (!partOfTransactionSet) {
        if (statement != NULL) {
            sqlite3_clear_bindings(statement);
            success = sqlite3_finalize(statement) == SQLITE_OK;
            NSAssert(success, @"%s at %s", sqlite3_errmsg(_database), __PRETTY_FUNCTION__);
        }
    } else {
        success = sqlite3_reset(statement) == SQLITE_OK;
        NSAssert(success, @"%s at %s", sqlite3_errmsg(_database), __PRETTY_FUNCTION__);
        _bulkStatement = statement;
    }
    
    if (!success) {
        errorMessage = (char *)sqlite3_errmsg(_database);
        NSLog(@"%s.", errorMessage);
    }
    
    NSString *message = nil;
    if (errorMessage != NULL) {
        success = NO;
        message = [[NSString alloc] initWithUTF8String:errorMessage];
    } else if (success == NO) {
        message = NSLocalizedString(@"Unknown database failure.", @"Unknown database failure.");
    }

    NSError *error = nil;
    if (!success) {
        NSString *title = NSLocalizedString(@"Error", @"Error");
        NSString *domain = @"MTSqlite3";
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
        error = [errorUserInfo errorWithDomain:domain code:4784];
        //NSLog(@"%@", error);
    }
    if (resultError != NULL) *resultError = error;

    sqlite3_free(csql);
    return success;
}

- (BOOL)executeQuery:(MTQuery <MADQueryDataBindingProtocol> *)query
       withDataTable:(__kindof MADDataTable *)dataTable
            andError:(NSError * __autoreleasing *)error {

    BOOL status = NO;
    NSError * __autoreleasing sqlError = NULL;
    NSString *sqlResult = [query getSql:self error:&sqlError];
    NSString *queryString = [[NSString alloc] initWithString: sqlResult];
    
    NSAssert(sqlError == NULL, @"Error %@", @"Could not create query string.");

    if (queryString.length > 0) {

        //NSAssert(dataTable != nil, @"Need a datatable");
        
        NSError * __autoreleasing *executeError = NULL;
        status = [self executeSQL: queryString
                        fieldKeys: [query conformsToProtocol:@protocol(MADQueryFieldKeysProtocol)] ?
                                    ((MTQuery <MADQueryFieldKeysProtocol> *)query).fieldKeys : nil
                     onConnection: nil
                  intoResultTable: dataTable
                   transactionSet: query.partOfTransactionSet
                   returnsResults: query.returnsResults
                   binaryBindings: [query conformsToProtocol:@protocol(MADQueryDataBindingProtocol)] ? query.binaryBindings : nil
                        withError: executeError];
        
        NSAssert(executeError == NULL, @"Error: %@", (*executeError).localizedDescription);
        

    }
    
    return status;

}

- (BOOL)executeQuery:(MTQuery *)query withError:(NSError * __autoreleasing *)error {

    MADDataTable *dataTable;
    if ([query conformsToProtocol:@protocol(MADQueryDataTableProtocol)] &&
        ((MTQuery <MADQueryDataTableProtocol> *)query).dataTable != nil) {
        dataTable = ((MTQuery <MADQueryDataTableProtocol> *)query).dataTable;
    } else {
        dataTable = [self.delegate dataTableForQuery:query];
    }

    return [self executeQuery:query withDataTable:dataTable andError:error];
}

+ (id <NSCopying>)object: (void * /* sqlite3_stmt * */)statement
         forColumnNumber:(int)columnCounter
                withType: (MADDataType)type {

    id <NSCopying> columnValue;
    switch (type) {

        case MADDataTypeLong:
            columnValue = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, columnCounter)];
            break;

        case MADDataTypeLongLong:
            columnValue = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, columnCounter)];
            break;

        case MADDataTypeInt24:
        case MADDataTypeInteger:
            columnValue = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, columnCounter)];
            break;

        case MADDataTypeShort:
            columnValue = [[NSNumber alloc] initWithInt:sqlite3_column_int(statement, columnCounter)];
            break;

        case MADDataTypeImage:
        case MADDataTypeBlob: {
            const void *blob = sqlite3_column_blob(statement, columnCounter);
            columnValue = [[NSData alloc] initWithBytes: blob
                                                 length: (NSUInteger)sqlite3_column_bytes(statement, columnCounter)];
            break;
        }

        case MADDataTypeFloat:
            columnValue = [[NSNumber alloc] initWithDouble: sqlite3_column_double(statement, columnCounter)];
            break;

        case MADDataTypeNumber:
        case MADDataTypeDouble:
        case MADDataTypeDecimal:
            columnValue = [[NSNumber alloc] initWithDouble: sqlite3_column_double(statement, columnCounter)];
            break;

        case MADDataTypeBit:
        case MADDataTypeVarChar:
        case MADDataTypeString:
        case MADDataTypeEnum:
        case MADDataTypeYear:
        case MADDataTypeSet: {
            const unsigned char *text = sqlite3_column_text(statement, columnCounter);
            if (text == NULL) {
                columnValue = [NSNull null];
            } else {
                columnValue = [[NSString alloc] initWithCString: (const char *) text
                                                       encoding: NSUTF8StringEncoding];
            }
            break;
        }

        case MADDataTypeUnknown:
        case MADDataTypeNull: {
            columnValue = [NSNull null];
            break;
        }

        case MADDataTypeTimeStamp:
        case MADDataTypeTime:
        case MADDataTypeDate:
        case MADDataTypeDateTime:
        case MADDataTypeGeometry:
        default: {
            //NSAssert(NO, @"Type is not expected...  Should really be encapsulated in MTDatabaseSqlite3: %lu", (unsigned long)type);
            if (sqlite3_column_type(statement, columnCounter) == SQLITE3_TEXT) {
                const unsigned char *text = sqlite3_column_text(statement, columnCounter);
                if (text == NULL) {
                    columnValue = [NSNull null];
                } else {
                    columnValue = [[NSString alloc] initWithCString: (const char *) text
                                                           encoding: NSUTF8StringEncoding];
                }
            }
            break;
        }
    }
    return columnValue;
}

- (NSString *)identifier {
    return self.databaseConnection.identifier;
}

+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    id result = [[NSString alloc] initWithFormat:MTDatabaseSqlite3SafeFormatField, tableName, fieldName];
    return result;
}
- (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    MADSafeQueryField * result = [MTDatabaseSqlite3 newSafeQueryField:fieldName andTable:tableName];
    return result;
}

+ (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName {
    id result = [[NSString alloc] initWithFormat:MTDatabaseSqlite3SafeFormatIdentifier, fieldOrTableName];
    return result;
}

- (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName {
    id result = [[NSString alloc] initWithFormat:MTDatabaseSqlite3SafeFormatIdentifier, fieldOrTableName];
    return result;
}

- (NSString *)tableAliasConnector {
    return @" ";
}

- (void)beginBulkInsert {
    int size_of_wal_log;
    int number_of_checkpointed_frames;
    int	wal = sqlite3_wal_checkpoint_v2(_database, NULL, SQLITE_CHECKPOINT_RESTART,
                                   &size_of_wal_log, &number_of_checkpointed_frames);
    NSAssert(wal == SQLITE_OK, @"sqlite3_wal_checkpoint_v2 returned %d at %s.", wal, __PRETTY_FUNCTION__);
    //dispatch_semaphore_t s0 = dispatch_semaphore_create(0);
    
    [self getTables:^(BOOL success, NSError *error, NSArray *tables) {
        
        MTQuery *dropTable;
        BOOL successQuery = NO;
        for (MADDatabaseTable *table in tables) {
            dropTable = [[MTQueryCacheDeleteAllFromTable alloc] initWithTableName:table.name];
            successQuery = [self executeQuery:dropTable withError:nil];
            NSAssert(successQuery, @"%s at %s", sqlite3_errmsg((sqlite3 *)self->_database),
                     __PRETTY_FUNCTION__);

        }
        
    //    dispatch_semaphore_signal(s0);
    }];
    //dispatch_semaphore_wait(s0, DISPATCH_TIME_FOREVER);
    //dispatch_release(s0);
    
    BOOL success = NO;
    NSError * __autoreleasing errorQuerySyncMode = NULL;
    MTQuery *querySyncMode = [[MTQueryCacheSyncOff alloc] init];
    success = [self executeQuery:querySyncMode withError:&errorQuerySyncMode];
    NSAssert(success, @"%s at %s", sqlite3_errmsg((sqlite3 *)self->_database),
             __PRETTY_FUNCTION__);

    NSError * __autoreleasing errorQueryJournalMode = NULL;
    MTQuery *queryJournalMode = [[MTQueryCacheJournalModeOverride alloc] init];
    success = [self executeQuery:queryJournalMode withError:&errorQueryJournalMode];
    NSAssert(success, @"%s at %s", sqlite3_errmsg((sqlite3 *)self->_database),
             __PRETTY_FUNCTION__);

    //char *err = 0;
    //sqlite3_exec((sqlite3 *)self->_database, "PRAGMA journal_mode = MEMORY", NULL, NULL, &err);

    NSError * __autoreleasing errorQueryCacheBeginTransaction = NULL;
    MTQuery *query = [[MTQueryCacheBeginTransaction alloc] init];
    success = [self executeQuery:query withError:&errorQueryCacheBeginTransaction];
    NSAssert(success, @"%s at %s", sqlite3_errmsg((sqlite3 *)self->_database),
             __PRETTY_FUNCTION__);

}

- (void)endBulkInsert {

    BOOL success = NO;

    NSError * __autoreleasing errorCacheEndTransaction = NULL;
    MTQuery *query = [[MTQueryCacheEndTransaction alloc] init];
    success = [self executeQuery:query withError:&errorCacheEndTransaction];
    NSAssert(success, @"%s at %s", sqlite3_errmsg((sqlite3 *)self->_database),
             __PRETTY_FUNCTION__);

    NSError * __autoreleasing errorQuerySyncMode = NULL;
    MTQuery *querySyncMode = [[MTQueryCacheSyncDefault alloc] init];
    success = [self executeQuery:querySyncMode withError:&errorQuerySyncMode];
    NSAssert(success, @"%s at %s", sqlite3_errmsg((sqlite3 *)self->_database),
             __PRETTY_FUNCTION__);

    /*
     NSError * __autoreleasing errorJournalMode = NULL;
     MTQuery *queryJournalMode = [[MTQuery alloc] initWithQueryType:MADQueryTypeCacheJournalModeDefault object:@{}];
     [queryJournalMode performQueryWithDatabase:self withError:&errorJournalMode];
    */
    
    sqlite3_finalize(_bulkStatement);
    _bulkStatement = NULL;
    sqlite3_close_v2(_database);
    _database = NULL;
    
}

#pragma mark -
#pragma mark Reading Tables

- (void)enumerateTablesFromConnection:(id)process
                           usingBlock:(void (^)(MADDatabaseTable *obj, NSUInteger index, BOOL *stop))block
                           completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL success = NO;
    sqlite3_stmt *statement;
    NSString *queryStart = @"SELECT tbl_name FROM main.sqlite_master WHERE type='table';";
    const char *queryStartChar = queryStart.UTF8String;
    char *sql = sqlite3_mprintf((char *) queryStartChar);
    //NSLog(@"SQL3: %s", sql);

    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        success = YES;
        BOOL stop = NO;
        NSUInteger counter = 0;
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            const char *resultString = (char *)sqlite3_column_text(statement, 0);
            NSString *readName = [[NSString alloc] initWithCString: resultString
                                                          encoding: NSUTF8StringEncoding];
            
            
            MADDatabaseTable *databaseTable;
            databaseTable = [[MADDatabaseTable alloc] initWithTableName: readName];
            [result addObject:databaseTable];
            block(databaseTable, counter, &stop);
            if (stop) break;
            counter++;
        }
    }
    sqlite3_finalize(statement);
    sqlite3_clear_bindings(statement);
    sqlite3_free(sql);
    completion(success, nil, result);
    
}

- (void)getTablesFromConnection:(id)process
                     completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    [self getTables:^(BOOL success, NSError *error, NSArray *tables) {
        if (error) {
            //NSLog(@"Error: %@", error);
        }
        completion(success, error, tables);
    }];
}

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn
                                                   error:(NSError *__autoreleasing *)error {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    NSString *queryStart = @"SELECT tbl_name FROM main.sqlite_master WHERE type='table';";
    char *sql = sqlite3_mprintf((char *) queryStart.UTF8String);
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            const char *resultString = (const char *)sqlite3_column_text(statement, 0);
            NSString *readName = [[NSString alloc] initWithCString: resultString
                                                          encoding: NSUTF8StringEncoding];
            
            MADDatabaseTable *databaseTable = [[MADDatabaseTable alloc] initWithTableName: readName];
            [result addObject:databaseTable];
        }
    }
    sqlite3_finalize(statement);
    sqlite3_free(sql);
    return result;
}

#pragma mark -
#pragma mark Reading Fields

- (NSArray <MADDatabaseField *> *)fieldsForTable: (NSString *)tableName
                                      connection: (id)process
                                           error: (NSError * __autoreleasing *)error {
    NSMutableArray * __autoreleasing result = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    NSString *queryStart = @"SELECT tbl_name FROM main.sqlite_master WHERE type='table';";
    char *sql = sqlite3_mprintf((char *) queryStart.UTF8String);
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            const char *resultString = (const char *)sqlite3_column_text(statement, 0);
            NSString *readName = [[NSString alloc] initWithCString: resultString
                                                           encoding: NSUTF8StringEncoding];
            
            MADDatabaseTable *databaseTable = [[MADDatabaseTable alloc] initWithTableName: readName];
            [result addObject:databaseTable];
        }
    } else {
        //NSLog(@"Error: %@", queryStart);
    }
    sqlite3_finalize(statement);
    sqlite3_free(sql);
    return result;
}

/*
 const char *errorName = NULL, *errorMessage = NULL;
 mad_sqlite3Err(SQLITE_OK, &errorName, &errorMessage);
 NSString *fullMessage = [[NSString alloc] initWithFormat:@"%s: %s", errorName, errorMessage];
 //NSLog(@"%@", fullMessage);
 */
void mad_sqlite3Err(int rc, const char **errName, const char **errMsg) {
    *errName = 0;
    *errMsg = "unknown error";
    int i;
    for(i=0; i<2 && *errName==0; i++, rc &= 0xff){
        switch( rc ){
            case SQLITE_OK:
                *errName = "SQLITE_OK";
                *errMsg = "not an error";
                break;
            case SQLITE_ERROR:
                *errName = "SQLITE_ERROR";
                *errMsg = "SQL logic error or missing database";
                break;
            case SQLITE_INTERNAL:
                *errName = "SQLITE_INTERNAL";
                break;
            case SQLITE_PERM:
                *errName = "SQLITE_PERM";
                *errMsg = "access permission denied";
                break;
            case SQLITE_ABORT:
                *errName = "SQLITE_ABORT";
                *errMsg = "callback requested query abort";
                break;
            case SQLITE_ABORT_ROLLBACK:
                *errName = "SQLITE_ABORT_ROLLBACK";
                *errMsg = "abort due to ROLLBACK";
                break;
            case SQLITE_BUSY:
                *errName = "SQLITE_BUSY";
                *errMsg = "database is locked";
                break;
            case SQLITE_BUSY_RECOVERY:
                *errName = "SQLITE_BUSY_RECOVERY";
                break;
            case SQLITE_BUSY_SNAPSHOT:
                *errName = "SQLITE_BUSY_SNAPSHOT";
                break;
            case SQLITE_LOCKED:
                *errName = "SQLITE_LOCKED";
                *errMsg = "database table is locked";
                break;
            case SQLITE_LOCKED_SHAREDCACHE:
                *errName = "SQLITE_LOCKED_SHAREDCACHE";
                break;
            case SQLITE_NOMEM:
                *errName = "SQLITE_NOMEM";
                *errMsg = "out of memory";
                break;
            case SQLITE_READONLY:
                *errName = "SQLITE_READONLY";
                *errMsg = "attempt to write a readonly database";
                break;
            case SQLITE_READONLY_RECOVERY:
                *errName = "SQLITE_READONLY_RECOVERY";
                break;
            case SQLITE_READONLY_CANTLOCK:
                *errName = "SQLITE_READONLY_CANTLOCK";
                break;
            case SQLITE_READONLY_ROLLBACK:
                *errName = "SQLITE_READONLY_ROLLBACK";
                break;
            case SQLITE_READONLY_DBMOVED:
                *errName = "SQLITE_READONLY_DBMOVED";
                break;
            case SQLITE_INTERRUPT:
                *errName = "SQLITE_INTERRUPT";
                *errMsg = "interrupted";
                break;
            case SQLITE_IOERR:
                *errName = "SQLITE_IOERR";
                *errMsg = "disk I/O error";
                break;
            case SQLITE_IOERR_READ:
                *errName = "SQLITE_IOERR_READ";
                break;
            case SQLITE_IOERR_SHORT_READ:
                *errName = "SQLITE_IOERR_SHORT_READ";
                break;
            case SQLITE_IOERR_WRITE:
                *errName = "SQLITE_IOERR_WRITE";
                break;
            case SQLITE_IOERR_FSYNC:
                *errName = "SQLITE_IOERR_FSYNC";
                break;
            case SQLITE_IOERR_DIR_FSYNC:
                *errName = "SQLITE_IOERR_DIR_FSYNC";
                break;
            case SQLITE_IOERR_TRUNCATE:
                *errName = "SQLITE_IOERR_TRUNCATE";
                break;
            case SQLITE_IOERR_FSTAT:
                *errName = "SQLITE_IOERR_FSTAT";
                break;
            case SQLITE_IOERR_UNLOCK:
                *errName = "SQLITE_IOERR_UNLOCK";
                break;
            case SQLITE_IOERR_RDLOCK:
                *errName = "SQLITE_IOERR_RDLOCK";
                break;
            case SQLITE_IOERR_DELETE:
                *errName = "SQLITE_IOERR_DELETE";
                break;
            case SQLITE_IOERR_NOMEM:
                *errName = "SQLITE_IOERR_NOMEM";
                break;
            case SQLITE_IOERR_ACCESS:
                *errName = "SQLITE_IOERR_ACCESS";
                break;
            case SQLITE_IOERR_CHECKRESERVEDLOCK:
                *errName = "SQLITE_IOERR_CHECKRESERVEDLOCK";
                break;
            case SQLITE_IOERR_LOCK:
                *errName = "SQLITE_IOERR_LOCK";
                break;
            case SQLITE_IOERR_CLOSE:
                *errName = "SQLITE_IOERR_CLOSE";
                break;
            case SQLITE_IOERR_DIR_CLOSE:
                *errName = "SQLITE_IOERR_DIR_CLOSE";
                break;
            case SQLITE_IOERR_SHMOPEN:
                *errName = "SQLITE_IOERR_SHMOPEN";
                break;
            case SQLITE_IOERR_SHMSIZE:
                *errName = "SQLITE_IOERR_SHMSIZE";
                break;
            case SQLITE_IOERR_SHMLOCK:
                *errName = "SQLITE_IOERR_SHMLOCK";
                break;
            case SQLITE_IOERR_SHMMAP:
                *errName = "SQLITE_IOERR_SHMMAP";
                break;
            case SQLITE_IOERR_SEEK:
                *errName = "SQLITE_IOERR_SEEK";
                break;
            case SQLITE_IOERR_DELETE_NOENT:
                *errName = "SQLITE_IOERR_DELETE_NOENT";
                break;
            case SQLITE_IOERR_MMAP:
                *errName = "SQLITE_IOERR_MMAP";
                break;
            case SQLITE_IOERR_GETTEMPPATH:
                *errName = "SQLITE_IOERR_GETTEMPPATH";
                break;
            case SQLITE_IOERR_CONVPATH:
                *errName = "SQLITE_IOERR_CONVPATH";
                break;
            case SQLITE_CORRUPT:
                *errName = "SQLITE_CORRUPT";
                *errMsg = "database disk image is malformed";
                break;
            case SQLITE_CORRUPT_VTAB:
                *errName = "SQLITE_CORRUPT_VTAB";
                break;
            case SQLITE_NOTFOUND:
                *errName = "SQLITE_NOTFOUND";
                *errMsg = "unknown operation";
                break;
            case SQLITE_FULL:
                *errName = "SQLITE_FULL";
                *errMsg = "database or disk is full";
                break;
            case SQLITE_CANTOPEN:
                *errName = "SQLITE_CANTOPEN";
                *errMsg = "unable to open database file";
                break;
            case SQLITE_CANTOPEN_NOTEMPDIR:
                *errName = "SQLITE_CANTOPEN_NOTEMPDIR";
                break;
            case SQLITE_CANTOPEN_ISDIR:
                *errName = "SQLITE_CANTOPEN_ISDIR";
                break;
            case SQLITE_CANTOPEN_FULLPATH:
                *errName = "SQLITE_CANTOPEN_FULLPATH";
                break;
            case SQLITE_CANTOPEN_CONVPATH:
                *errName = "SQLITE_CANTOPEN_CONVPATH";
                break;
            case SQLITE_PROTOCOL:
                *errName = "SQLITE_PROTOCOL";
                *errMsg = "locking protocol";
                break;
            case SQLITE_EMPTY:
                *errName = "SQLITE_EMPTY";
                *errMsg = "table contains no data";
                break;
            case SQLITE_SCHEMA:
                *errName = "SQLITE_SCHEMA";
                *errMsg = "database schema has changed";
                break;
            case SQLITE_TOOBIG:
                *errName = "SQLITE_TOOBIG";
                *errMsg = "string or blob too big";
                break;
            case SQLITE_CONSTRAINT:
                *errName = "SQLITE_CONSTRAINT";
                *errMsg = "constraint failed";
                break;
            case SQLITE_CONSTRAINT_UNIQUE:
                *errName = "SQLITE_CONSTRAINT_UNIQUE";
                break;
            case SQLITE_CONSTRAINT_TRIGGER:
                *errName = "SQLITE_CONSTRAINT_TRIGGER";
                break;
            case SQLITE_CONSTRAINT_FOREIGNKEY:
                *errName = "SQLITE_CONSTRAINT_FOREIGNKEY";
                break;
            case SQLITE_CONSTRAINT_CHECK:
                *errName = "SQLITE_CONSTRAINT_CHECK";
                break;
            case SQLITE_CONSTRAINT_PRIMARYKEY:
                *errName = "SQLITE_CONSTRAINT_PRIMARYKEY";
                break;
            case SQLITE_CONSTRAINT_NOTNULL:
                *errName = "SQLITE_CONSTRAINT_NOTNULL";
                break;
            case SQLITE_CONSTRAINT_COMMITHOOK:
                *errName = "SQLITE_CONSTRAINT_COMMITHOOK";
                break;
            case SQLITE_CONSTRAINT_VTAB:
                *errName = "SQLITE_CONSTRAINT_VTAB";
                break;
            case SQLITE_CONSTRAINT_FUNCTION:
                *errName = "SQLITE_CONSTRAINT_FUNCTION";
                break;
            case SQLITE_CONSTRAINT_ROWID:
                *errName = "SQLITE_CONSTRAINT_ROWID";
                break;
            case SQLITE_MISMATCH:
                *errName = "SQLITE_MISMATCH";
                *errMsg = "datatype mismatch";
                break;
            case SQLITE_MISUSE:
                *errName = "SQLITE_MISUSE";
                *errMsg = "library routine called out of sequence";
                break;
            case SQLITE_NOLFS:
                *errName = "SQLITE_NOLFS";
                *errMsg = "large file support is disabled";
                break;
            case SQLITE_AUTH:
                *errName = "SQLITE_AUTH";
                *errMsg = "authorization denied";
                break;
            case SQLITE_FORMAT:
                *errName = "SQLITE_FORMAT";
                *errMsg = "auxiliary database format error";
                break;
            case SQLITE_RANGE:
                *errName = "SQLITE_RANGE";
                *errMsg = "bind or column index out of range";
                break;
            case SQLITE_NOTADB:
                *errName = "SQLITE_NOTADB";
                *errMsg = "file is encrypted or is not a database";
                break;
            case SQLITE_ROW:
                *errName = "SQLITE_ROW";
                break;
            case SQLITE_NOTICE:
                *errName = "SQLITE_NOTICE";
                break;
            case SQLITE_NOTICE_RECOVER_WAL:
                *errName = "SQLITE_NOTICE_RECOVER_WAL";
                break;
            case SQLITE_NOTICE_RECOVER_ROLLBACK:
                *errName = "SQLITE_NOTICE_RECOVER_ROLLBACK";
                break;
            case SQLITE_WARNING:
                *errName = "SQLITE_WARNING";
                break;
            case SQLITE_WARNING_AUTOINDEX:
                *errName = "SQLITE_WARNING_AUTOINDEX";
                break;
            case SQLITE_DONE:
                *errName = "SQLITE_DONE";
                break;
            default:
                *errName = "SQLITE_UNKNOWN(%d)";
                break;
        }
    }
    
}

@end

@implementation MADDatabaseResultValue

- (id)copyWithZone:(NSZone *)zone {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: @""
                                 userInfo: nil];
}

+ (instancetype)newDatabaseResultValue:(void *)statement columnNumber:(int)columnNumber {
    id value = nil;
    switch (sqlite3_column_type(statement, columnNumber)) { //http://www.sqlite.org/c3ref/c_blob.html
        case SQLITE_INTEGER: {
            value = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, columnNumber)];
            break;
        }
        case SQLITE_FLOAT: {
            value = [[NSNumber alloc] initWithDouble: sqlite3_column_double(statement, columnNumber)];
            break;
        }
        case SQLITE_BLOB: {
            const void *blob = sqlite3_column_blob(statement, columnNumber);
            value = [[NSData alloc] initWithBytes: blob
                                           length: (NSUInteger)sqlite3_column_bytes16(statement, columnNumber)];
            break;
        }
        case SQLITE_NULL: {
            value = [NSNull null];
            break;
        }
        case SQLITE3_TEXT: {
            const char *resultString = (char *)sqlite3_column_text(statement, columnNumber);
            value = [[NSString alloc] initWithCString: resultString
                                             encoding: NSUTF8StringEncoding];
            break;
        }
        default:
            NSAssert(NO, @"Unhandled case");
            break;
    }
    
    if (value == nil) {
        value = [NSNull null];
    }
    return value;
}

+ (instancetype)newDatabaseResultValueCast: (void * /* sqlite3_stmt * */)statement
                           forColumnNumber: (int)columnCounter
                                  withType: (MADDataType)type {
    
    id columnValue;
    switch (type) {
            
        case MADDataTypeLong:
            columnValue = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, columnCounter)];
            break;
            
        case MADDataTypeLongLong:
            columnValue = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, columnCounter)];
            break;
            
        case MADDataTypeInt24:
        case MADDataTypeInteger:
            columnValue = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, columnCounter)];
            break;
            
        case MADDataTypeShort:
            columnValue = [[NSNumber alloc] initWithInt:sqlite3_column_int(statement, columnCounter)];
            break;
            
        case MADDataTypeImage:
        case MADDataTypeBlob: {
            const void *blob = sqlite3_column_blob(statement, columnCounter);
            columnValue = [[NSData alloc] initWithBytes: blob
                                                 length: (NSUInteger)sqlite3_column_bytes(statement, columnCounter)];
            break;
        }
            
        case MADDataTypeFloat:
            columnValue = [[NSNumber alloc] initWithDouble: sqlite3_column_double(statement, columnCounter)];
            break;
            
        case MADDataTypeNumber:
        case MADDataTypeDouble:
        case MADDataTypeDecimal:
            columnValue = [[NSNumber alloc] initWithDouble: sqlite3_column_double(statement, columnCounter)];
            break;
            
        case MADDataTypeBit:
        case MADDataTypeVarChar:
        case MADDataTypeString:
        case MADDataTypeEnum:
        case MADDataTypeYear:
        case MADDataTypeSet: {
            const unsigned char *text = sqlite3_column_text(statement, columnCounter);
            if (text == NULL) {
                columnValue = [NSNull null];
            } else {
                columnValue = [[NSString alloc] initWithCString: (const char *) text
                                                       encoding: NSUTF8StringEncoding];
            }
            break;
        }
            
        case MADDataTypeUnknown:
        case MADDataTypeNull: {
            columnValue = [NSNull null];
            break;
        }
            
        case MADDataTypeTimeStamp:
        case MADDataTypeTime:
        case MADDataTypeDate:
        case MADDataTypeDateTime:
        case MADDataTypeGeometry:
        default: {
            //NSAssert(NO, @"Type is not expected...  Should really be encapsulated in MTDatabaseSqlite3: %lu", (unsigned long)type);
            if (sqlite3_column_type(statement, columnCounter) == SQLITE3_TEXT) {
                const unsigned char *text = sqlite3_column_text(statement, columnCounter);
                if (text == NULL) {
                    columnValue = [NSNull null];
                } else {
                    columnValue = [[NSString alloc] initWithCString: (const char *) text
                                                           encoding: NSUTF8StringEncoding];
                }
            }
            break;
        }
    }
    return columnValue;
}

@end

@implementation MADSqlite3NativeType

+ (instancetype)newSqlite3NativeType:(MADDataType)dataType {
    id columnAffinity;
    switch (dataType) {
        case MADDataTypeBit:
        case MADDataTypeInteger:
        case MADDataTypeShort:
        case MADDataTypeLong:
        case MADDataTypeLongLong:
        case MADDataTypeInt24:
        case MADDataTypeEnum:
            columnAffinity = @"INTEGER";
            break;
        case MADDataTypeSet:
        case MADDataTypeTime:
        case MADDataTypeTimeStamp:
        case MADDataTypeYear:
        case MADDataTypeDate:
        case MADDataTypeDateTime:
        case MADDataTypeString:
        case MADDataTypeVarChar:
        case MADDataTypeGeometry:
            columnAffinity = @"TEXT";
            break;
        case MADDataTypeImage:
        case MADDataTypeBlob:
            columnAffinity = @"NONE";
            break;
        case MADDataTypeFloat:
        case MADDataTypeDouble:
            columnAffinity = @"REAL";
            break;
        case MADDataTypeDecimal:
        case MADDataTypeNumber:
            columnAffinity = @"NUMERIC";
            break;
        case MADDataTypeUnknown:
        default:
            columnAffinity = @"TEXT";
            break;
    }
    return columnAffinity;
}

@end
