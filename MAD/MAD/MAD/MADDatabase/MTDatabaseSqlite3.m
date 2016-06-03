//
//  MTDatabaseSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 10/23/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

//#ifndef MAD_MTDatabaseSqlite3_DEBUG
//#define MAD_MTDatabaseSqlite3_DEBUG
//#endif

#import "MTDatabaseSqlite3.h"

#import <Foundation/NSException.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNULL.h>
#import <Foundation/NSData.h>
#import <Foundation/NSCalendar.h>
#import <Foundation/NSBundle.h>
#import <dispatch/time.h>
#import <dispatch/semaphore.h>
#import <string.h>
#import <stdlib.h>

#import "MTDatabaseConnectionSqlite3.h"
#import "MADErrorUserInfo.h"
#import "MTQuery.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"
#import <MADFoundation/MTDataTable.h>
#import <MADFoundation/MADDataColumn.h>
#import "MTDatabaseDataBinding.h"
#import "MTQueryCacheSyncOff.h"
#import "MTQueryCacheJournalModeOverride.h"
#import "MTQueryCacheBeginTransaction.h"
#import "MTQueryCacheEndTransaction.h"
#import "MTQueryCacheSyncDefault.h"

#import <MADSqlite3/sqlite3.h>

#import "MADDatabaseProtocol.h"

NSString * const MTDatabaseSqlite3SafeQuote = @"\"";
NSString * const MTDatabaseSqlite3SafeFormatIdentifier = @"\"%@\"";
NSString * const MTDatabaseSqlite3SafeFormatField = @"\"%@\".\"%@\"";

@interface MTDatabaseSqlite3 () {
    sqlite3_stmt *_bulkStatement;
}

    @property (nonatomic, assign, getter=isOpen) bool open;
    @property (nonatomic, strong) MTDatabaseConnectionSqlite3 *databaseConnection;

@end

@implementation MTDatabaseSqlite3

@dynamic databaseConnection;

int compare_string_utf8_localized_asc_collation(void* data, int len1, const void* arg1, int len2, const void* arg2);
int compare_string_utf8_localized_asc_collation(void* data, int len1, const void* arg1, int len2, const void* arg2) {
    NSString *string1 = [[NSString alloc] initWithBytes:arg1 length:(NSUInteger)abs(len1) encoding:NSUTF8StringEncoding];
    NSString *string2 = [[NSString alloc] initWithBytes:arg2 length:(NSUInteger)abs(len2) encoding:NSUTF8StringEncoding];
    return [string1 localizedCaseInsensitiveCompare:string2];
}

/*static inline bool Sqlite3ResultOK(int result);
static inline bool Sqlite3ResultOK(int result) {
    return result == SQLITE_OK || result == SQLITE_ROW || result == SQLITE_DONE ? true : false;
}*/

#ifdef MAD_MTDatabaseSqlite3_DEBUG
void sqliteLog(void *foo, const char* statement);
void sqliteLog(void *foo, const char* statement) {
    MTLogStatic(@"=> %s", statement);
}
#endif

- (void *)databaseHandle {
    return _database;
}

- (instancetype)init {
    if (self = [super init]) {
        _database = NULL;
        _bulkStatement = NULL;
        _open = false;
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
    if (!self.isOpen) {
       const char *path = self.databaseConnection.databaseUrl.path.UTF8String;
        if (sqlite3_open_v2(path, ((struct sqlite3 **)&_database), flags, NULL) == SQLITE_OK) {
            sqlite3_extended_result_codes((struct sqlite3 *)_database, true);
            sqlite3_create_collation((struct sqlite3 *)_database, "LSASC",
                                        SQLITE_UTF8, (struct sqlite3 *)_database,
                                        compare_string_utf8_localized_asc_collation);
#ifdef MAD_MTDatabaseSqlite3_DEBUG
            sqlite3_trace((struct sqlite3 *)_database, sqliteLog, NULL);
#endif

        } else {
            //const char *errorMessage = sqlite3_errmsg(_database);
            //NSString *message = @(errorMessage);
            //NSString *title = NSLocalizedString(@"Connect Failed", @"Connect Failed");
            //NSString *domain = @"MTSqlite3";
            //MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle: title
            //                                                               andMessage: message];
            //error = [NSError errorWithDomain:domain code:4832 userInfo:errorUserInfo.userinfo];
        }
        self.open = true;
    }
}

- (void)dealloc {
    
    if (_bulkStatement != NULL && sqlite3_finalize(_bulkStatement)) {
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

- (id)connectWithConnection:(MTDatabaseConnection *)connection
                 credentals:(MADCredential *)credentals {
    [self openDatabase];
    return nil;
}

- (BOOL)tableExist:(NSString *)tablename {
    BOOL exist = NO;
	NSString *query;
    query = @"SELECT count(tbl_name) FROM sqlite_master WHERE type = 'table' AND name = ?;";
    sqlite3_stmt *statement = NULL;
    const char *queryc = query.UTF8String;
	if (sqlite3_prepare_v2(_database, queryc, -1, &statement, NULL) == SQLITE_OK) {
        const char *t = tablename.UTF8String;
        sqlite3_bind_text(statement, 1, t, (int)strlen(t), SQLITE_STATIC);
		if (sqlite3_step(statement) == SQLITE_ROW) {
            exist = sqlite3_column_int(statement, 0) == 1;
        }
    }
    sqlite3_finalize(statement);
    return exist;
}

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL success = NO;
	sqlite3_stmt *statement;
	NSString *queryStart = @"SELECT tbl_name FROM main.sqlite_master WHERE type='table';";
	char *sql = sqlite3_mprintf((char *) queryStart.UTF8String);

	if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        success = YES;
		while (sqlite3_step(statement) == SQLITE_ROW) {
            
            const unsigned char *resultString = sqlite3_column_text(statement, 0);
            NSString *tableName = @((char *)resultString);
            
            MTDatabaseTable *databaseTable;
            databaseTable = [[MTDatabaseTable alloc] initWithTableName: tableName];
            [result addObject:databaseTable];
		}
	}
	sqlite3_finalize(statement);
	sqlite3_free(sql);
    completion(success, nil, result);
}

//Converting native type to affinity type
// using http://www.sqlite.org/datatype3.html

+ (MADDataType)dataTypeForNativeType:(NSString *)nativeType {
    
    NSString *lowerCaseString = nativeType.lowercaseString;
    
    bool isInteger = [lowerCaseString rangeOfString:@"int"].location != NSNotFound;
    bool isText = false;
    bool isNone = false;
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
    NSString *nativeTypeDescription = [MTDatabaseSqlite3 newNativeTypeForDataType:columnType];
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

+ (NSString *)newNativeTypeForDataType:(MADDataType)dataType {
    NSString *columnAffinity;
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


- (NSString *)newNativeTypeForDataType:(MADDataType)dataType {
    return [MTDatabaseSqlite3 newNativeTypeForDataType:dataType];
}

- (sqlite3_stmt *)statementForQueryInTransactionSet:(bool)partOfTransactionSet andStatement:(sqlite3_stmt *)statement {
    return partOfTransactionSet ? _bulkStatement : statement;
}

+ (void)bindStatement:(void ** /* sqlite3_stmt ** */)statement withBindings:(MTDatabaseDataBinding *)databinding {

    int success = 0;
    if ([databinding.value isEqual:[NSNull null]]) {
        success = sqlite3_bind_null(*statement, databinding.columnNumber);
    } else {
        switch (databinding.datatype) {
                
            case MADDataTypeBlob: {

                if ([databinding.value isKindOfClass:[NSString class]]) {
                    success = sqlite3_bind_text(*statement, databinding.columnNumber, ((NSString *)databinding.value).UTF8String, (int)strlen(((NSString *)databinding.value).UTF8String), SQLITE_TRANSIENT);
                } else if ([databinding.value isKindOfClass:[NSData class]]) {
                    success = sqlite3_bind_blob(*statement, databinding.columnNumber, ((NSData *)databinding.value).bytes, (int)((NSData *)databinding.value).length, SQLITE_TRANSIENT);
                }
                
                break;
            }
                
            case MADDataTypeInteger: {
                success = sqlite3_bind_int64(*statement, databinding.columnNumber, ((NSNumber *)databinding.value).longLongValue);
                break;
            }
                
            case MADDataTypeString: {
                
                if ([databinding.value isKindOfClass:[NSString class]]) {

                    success = sqlite3_bind_text(*statement, databinding.columnNumber, ((NSString *)databinding.value).UTF8String, (int)[((NSString *)databinding.value) lengthOfBytesUsingEncoding:NSUTF8StringEncoding], SQLITE_TRANSIENT);
                    
                } else if ([databinding.value isKindOfClass:[NSDateComponents class]]) {
                    
                    NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:databinding.value];
                    success = sqlite3_bind_double(*statement, databinding.columnNumber, date.timeIntervalSince1970);
                    
                } else {
                    NSAssert(false, @"What else is there? %s", __PRETTY_FUNCTION__);
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
                NSAssert(false, @"This is going to end badly.  Only binding blobs right now.");
                break;
                
        }
    }
}

- (void)handleFailureInMethod:(SEL)selector
                       object:(id)object
                         file:(NSString *)fileName
                   lineNumber:(NSInteger)line
                  description:(NSString *)format {
    NSLog(@"Assert: (%@:%ld)", fileName, (long)line);
}

+ (void)executeQueryWithSql:(NSString *)queryString
                   database:(void * /* sqlite3 * */)_database
        queryBinaryBindings:(NSArray *)queryBinaryBindings
             queryFieldKeys:(NSArray *)queryFieldKeys
  queryPartOfTransactionSet:(bool)queryPartOfTransactionSet {

    //NSLog(@"SQL: %@", queryString);
    BOOL success = YES;

    if (queryString.length > 0) {
        
        sqlite3_stmt *statement = NULL;
        char *sql = sqlite3_mprintf(queryString.UTF8String);
        
        if (statement == NULL) {
            int prepare_result = sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
            success = SQLITE_OK == prepare_result;
            if (queryBinaryBindings.count > 0) {
                for (MTDatabaseDataBinding *databinding in queryBinaryBindings) {
                    [MTDatabaseSqlite3 bindStatement:(void **)&statement withBindings:databinding];
                }
            }
        } else if (queryPartOfTransactionSet) {
            if (queryBinaryBindings.count > 0) {
                for (MTDatabaseDataBinding *databinding in queryBinaryBindings) {
                    [MTDatabaseSqlite3 bindStatement:(void **)&statement withBindings:databinding];
                }
            }
        }
        NSAssert(success, @"ExecuteQueryWithSql failed (%s).", (char *)sqlite3_errmsg(_database));
        
        sqlite3_step(statement);

        sqlite3_finalize(statement);
        statement = NULL;
        sqlite3_free(sql);
        sql = NULL;
    }
}

- (BOOL)executeSql:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn
   intoResultTable:(MTDataTable *)dataTable withError:(NSError * __autoreleasing *)error {
    
    return [self executeSql:sql fieldKeys:fieldKeys onConnection:dbconn intoResultTable:dataTable
       partOfTransactionSet:NO returnsResults:YES binaryBindings:nil withError:error];
}

- (BOOL)executeSql: (NSString *)queryString
         fieldKeys: (NSArray *)fieldKeys onConnection: (id)dbconn
   intoResultTable: (MTDataTable *)dataTable partOfTransactionSet: (BOOL)partOfTransactionSet
    returnsResults: (BOOL)returnsResults
    binaryBindings: (NSArray *)binaryBindings
         withError: (NSError * __autoreleasing *)resultError {
   
    sqlite3_stmt *statement = NULL;
    statement = [self statementForQueryInTransactionSet:partOfTransactionSet andStatement:statement];

    BOOL success = NO;
    char *errorMessage = NULL;
    char *sql = sqlite3_mprintf(queryString.UTF8String);
    
    
    if (statement == NULL) {
        success = SQLITE_OK == sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
        if (binaryBindings.count > 0) {
            for (MTDatabaseDataBinding *databinding in binaryBindings) {
                [MTDatabaseSqlite3 bindStatement:&statement withBindings:databinding];
            }
        }
    } else if (partOfTransactionSet) {
        if (binaryBindings.count > 0) {
            for (MTDatabaseDataBinding *databinding in binaryBindings) {
                [MTDatabaseSqlite3 bindStatement:&statement withBindings:databinding];
            }
        }
    }
    
    if (returnsResults) {
        
        if (success) {
            
            int numberOfColumns = sqlite3_column_count(statement);
            numberOfColumns = numberOfColumns >= 0 ? numberOfColumns : 0;
            [dataTable removeAllObjects];
            
            NSUInteger rowCounter = 0;
            
            //NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
            int sqlite3_step_result;
            while (SQLITE_ROW == (sqlite3_step_result = sqlite3_step(statement))) {
                
                if (rowCounter == 0) {  //If first time around, calculate column information.
                    for (int columnCounter = 0; columnCounter < numberOfColumns; columnCounter++) {
                        
                        @autoreleasepool {

                            NSString *fieldName = fieldKeys[(NSUInteger)columnCounter];
                            
                            MADDataColumn *dataColumn;
                            dataColumn = [[MADDataColumn alloc] initWithIdentifier:fieldName];
                            
                            int affentyType = sqlite3_column_type(statement, (int)columnCounter);

                            const char *columnName = sqlite3_column_name(statement, (int)columnCounter);
                            const char *tableName = sqlite3_column_table_name(statement, (int)columnCounter);
                            const char *databaseName = sqlite3_column_database_name(statement, (int)columnCounter);
                            
                            char const **pzDataType = NULL;
                            char const **pzCollSeq = NULL;
                            int *pNotNull = 0;
                            int *pPrimaryKey = 0;
                            int *pAutoinc = 0;
                            
                            if (tableName != NULL) {
                                sqlite3_table_column_metadata(_database, databaseName, tableName,
                                                              columnName, pzDataType, pzCollSeq,
                                                              pNotNull, pPrimaryKey, pAutoinc);
                            }
                            
                            dataColumn.fieldName = fieldName;
                            dataColumn.nativeType = affentyType;
                            MADDataType columnType = [MTDatabaseSqlite3 dataTypeForAffentyType:affentyType];
                            dataColumn.type = columnType;
                            
                            dataColumn.primaryKey = (pPrimaryKey == NULL) ? false : *pPrimaryKey;
                            dataColumn.autoIncrement = (pAutoinc == NULL) ? false : *pAutoinc;
                            dataColumn.notNull = (pNotNull == NULL) ? false : *pNotNull;
                            [dataTable addColumn:dataColumn];
                            dataColumn = nil;
                        }
                    }
                    
                    [dataTable beginBulkInsert];
                }
                [self readRow:rowCounter];
                
                NSMutableDictionary *resultsForRow = [[NSMutableDictionary alloc] initWithCapacity:(NSUInteger)numberOfColumns];
                
                for (int colCtr = 0; colCtr < numberOfColumns; colCtr++) {
                    
                    NSString *fieldName = fieldKeys[(NSUInteger)colCtr];
                    id value = [MTDatabaseSqlite3 newValueForStatement:statement
                                                          columnNumber:colCtr];
                    resultsForRow[fieldName] = value;
                    
                }
                
                [dataTable addRowWithDataForFieldKeys:resultsForRow];
                resultsForRow = nil;
                rowCounter++;
            }
            //NSLog(@"%@", queryString);
            //NSLog(@"%d-%d: %s", sqlite3_errcode(_database), sqlite3_step_result, sqlite3_errmsg(_database));

            [dataTable endBulkInsert];
            
        }
    } else {
        //NSLog(@"%d-%d: %s", sqlite3_errcode(_database), sqlite3_step_result, sqlite3_errmsg(_database));
        // FIXME: Handle failures.
        sqlite3_step(statement);
    }
    if (partOfTransactionSet == NO) {
        success = SQLITE_OK == sqlite3_finalize(statement);
    } else {
        sqlite3_reset(statement);
        _bulkStatement = statement;
    }
    
    if (success == NO) {
        errorMessage = (char *)sqlite3_errmsg(_database);
    }
    
    NSString *message = nil;
    if (errorMessage != NO) {
        success = NO;
        message = [[NSString alloc] initWithUTF8String:errorMessage];
    } else if (success == NO) {
        message = NSLocalizedString(@"Unknown database failure.", @"Unknown database failure.");
    }

    NSError *error = nil;
    if (success == NO) {
        NSString *title = NSLocalizedString(@"Error", @"Error");
        NSString *domain = @"MTSqlite3";
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
        error = [errorUserInfo errorWithDomain:domain code:4784];
    }
    if (resultError != NULL) *resultError = error;

    sqlite3_free(sql);
    return success;
}


- (BOOL)executeQuery:(MTQuery *)query withError:(NSError * __autoreleasing *)resultError {

    NSError *error = nil;
    NSString *queryString = [NSString stringWithString: [query getSqlWithError:&error]];
    //NSLog(@"SQL2: %@", queryString);

    MTDataTable * dataTable;
    if (query.dataTable) {
        dataTable = query.dataTable;
    } else {
        dataTable = [self.delegate dataTableForQuery:query];
    }

    return [self executeSql: queryString fieldKeys: query.fieldKeys onConnection: nil
            intoResultTable: dataTable partOfTransactionSet: query.partOfTransactionSet
            returnsResults: query.returnsResults binaryBindings: query.binaryBindings withError: resultError];
}

+ (id)newValueForStatement:(void * /* sqlite3_stmt * */)statement columnNumber:(int)columnNumber {
    id value = nil;
    int affentyType = sqlite3_column_type(statement, columnNumber);   //http://www.sqlite.org/c3ref/c_blob.html
    switch (affentyType) {
        case SQLITE_INTEGER: {
            value = [[NSNumber alloc] initWithInteger: sqlite3_column_int64(statement, columnNumber)];
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
            NSAssert(false, @"Unhandled case");
            break;
    }
    
    if (value == nil) {
        value = [NSNull null];
    }
    return value;
}

+ (id)newObject: (void * /* sqlite3_stmt * */)statement forColumnNumber:(int)columnCounter
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
            //NSAssert(false, @"Type is not expected...  Should really be encapsulated in MTDatabaseSqlite3: %lu", (unsigned long)type);
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
    return MADIdentifierDatabaseSqlite3;
}

+ (NSString *)identifier {
    return MADIdentifierDatabaseSqlite3;
}

+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    return [NSString stringWithFormat:MTDatabaseSqlite3SafeFormatField, tableName, fieldName];
}
- (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    return [MTDatabaseSqlite3 newSafeQueryField:fieldName andTable:tableName];
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
    dispatch_semaphore_t s0 = dispatch_semaphore_create(0);
    [self getTables:^(BOOL success, NSError *error, NSArray *tables) {
        
        for (MTDatabaseTable *table in tables) {
            NSDictionary *queryDefination = [MTQuery newQueryDefinitionCacheDeleteAllFromTable:table.name];
            MTQuery *dropTable = [[MTQuery alloc] initWithQueryType:MADQueryTypeCacheDeleteAllFromTable object:queryDefination];
            NSError * __autoreleasing error = NULL;
            bool success = false;
            success = [self executeQuery:dropTable withError:&error];
        }
        
        dispatch_semaphore_signal(s0);
    }];
    dispatch_semaphore_wait(s0, DISPATCH_TIME_FOREVER);

    bool success = false;
    NSError * __autoreleasing errorQuerySyncMode = NULL;
    MTQuery * __autoreleasing querySyncMode = [[MTQueryCacheSyncOff alloc] init];
    success = [self executeQuery:querySyncMode withError:&errorQuerySyncMode];


    NSError * __autoreleasing errorQueryJournalMode = NULL;
    MTQuery * __autoreleasing queryJournalMode = [[MTQueryCacheJournalModeOverride alloc] init];
    success = [self executeQuery:queryJournalMode withError:&errorQueryJournalMode];


    NSError * __autoreleasing errorQueryCacheBeginTransaction = NULL;
    MTQuery * __autoreleasing query = [[MTQueryCacheBeginTransaction alloc] init];
    success = [self executeQuery:query withError:&errorQueryCacheBeginTransaction];

}

- (void)endBulkInsert {

    bool success = false;

    NSError * __autoreleasing errorCacheEndTransaction = NULL;
    MTQuery * __autoreleasing query = [[MTQueryCacheEndTransaction alloc] init];
    success = [self executeQuery:query withError:&errorCacheEndTransaction];
    
    NSError * __autoreleasing errorQuerySyncMode = NULL;
    MTQuery * __autoreleasing querySyncMode = [[MTQueryCacheSyncDefault alloc] init];
    success = [self executeQuery:querySyncMode withError:&errorQuerySyncMode];

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

#pragma mark - Reading Tables

- (void)enumerateTablesFromConnection:(id)process
                           usingBlock:(void (^)(MTDatabaseTable *obj, NSUInteger index, BOOL *stop))block
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
            
            
            MTDatabaseTable *databaseTable = [[MTDatabaseTable alloc] initWithTableName: readName];
            [result addObject:databaseTable];
            block(databaseTable, counter, &stop);
            if (stop) break;
            counter++;
        }
    }
    sqlite3_finalize(statement);
    sqlite3_free(sql);
    completion(success, nil, result);
    
}

- (void)getTablesFromConnection:(id)process completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    [self getTables:^(BOOL success, NSError *error, NSArray *tables) {
        completion(success, error, tables);
    }];
}

- (NSArray <MTDatabaseTable *> *)getTablesFromConnection:(id)dbconn error:(NSError *__autoreleasing *)error {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL success = NO;
    sqlite3_stmt *statement;
    NSString *queryStart = @"SELECT tbl_name FROM main.sqlite_master WHERE type='table';";
    char *sql = sqlite3_mprintf((char *) queryStart.UTF8String);
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        success = YES;
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            const char *resultString = (const char *)sqlite3_column_text(statement, 0);
            NSString *readName = [[NSString alloc] initWithCString: resultString
                                                          encoding: NSUTF8StringEncoding];
            
            MTDatabaseTable *databaseTable = [[MTDatabaseTable alloc] initWithTableName: readName];
            [result addObject:databaseTable];
        }
    }
    sqlite3_finalize(statement);
    sqlite3_free(sql);
    return result;
}

#pragma mark - Reading Fields

- (NSArray *)fieldsForTable: (NSString *)tableName connection:(id)process error:(NSError * __autoreleasing *)error {
    NSMutableArray * __autoreleasing result = [[NSMutableArray alloc] init];
    BOOL success = NO;
    sqlite3_stmt *statement;
    NSString *queryStart = @"SELECT tbl_name FROM main.sqlite_master WHERE type='table';";
    char *sql = sqlite3_mprintf((char *) queryStart.UTF8String);
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        success = YES;
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            const char *resultString = (const char *)sqlite3_column_text(statement, 0);
            NSString *readName = [[NSString alloc] initWithCString: resultString
                                                           encoding: NSUTF8StringEncoding];
            
            MTDatabaseTable *databaseTable = [[MTDatabaseTable alloc] initWithTableName: readName];
            [result addObject:databaseTable];
        }
    }
    sqlite3_finalize(statement);
    sqlite3_free(sql);
    return result;
}

@end
