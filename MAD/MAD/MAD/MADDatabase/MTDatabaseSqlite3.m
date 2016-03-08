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
#import "MTDatabaseConnectionSqlite3.h"
#import "MADErrorUserInfo.h"
#import "MTQuery.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"
#import <MADFoundation/MTDataTable.h>
#import <MADFoundation/MTDataColumn.h>
#import "MTDatabaseDataBinding.h"

NSString * const MTDatabaseSqlite3SafeQuote = @"\"";
NSString * const MTDatabaseSqlite3SafeFormatIdentifier = @"\"%@\"";
NSString * const MTDatabaseSqlite3SafeFormatField = @"\"%@\".\"%@\"";

@interface MTDatabaseSqlite3 ()

@property (nonatomic, readwrite, assign) sqlite3 *database;
@property (atomic, assign) sqlite3_stmt *bulkStatement;

@property (nonatomic, assign, getter=isOpen) bool open;
@property (nonatomic, strong) NSCalendar *currentCalandar;

@end

@implementation MTDatabaseSqlite3

- (void *)databaseHandle {
    return _database;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _database = NULL;
        _bulkStatement = NULL;
        _open = false;
        NSCalendar *currentCalandar = [NSCalendar currentCalendar];
        [self setCurrentCalandar:currentCalandar];
    }
    return self;
}

- (void)openDatabase {
    [self openDatabaseWithFlags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_SHAREDCACHE | SQLITE_OPEN_FULLMUTEX];
}

- (void)openDatabaseWithFlags:(int)flags {
    NSError *error = nil;
    //Open conneciton... closed in dealloc.
    if (!self.isOpen) {
       const char *path = self.databaseConnection.databaseUrl.path.UTF8String;
        BOOL isOpen = sqlite3_open_v2(path, &_database, flags, NULL) == SQLITE_OK;
        if (isOpen) {
            sqlite3_extended_result_codes(_database, true);
            sqlite3_create_collation(_database, "LSASC",
                                        SQLITE_UTF8, _database,
                                        compare_string_utf8_localized_asc_collation);
#ifdef MAD_MTDatabaseSqlite3_DEBUG
            sqlite3_trace(_database, sqliteLog, NULL);
#endif

        } else {
            const char *errorMessage = sqlite3_errmsg(_database);
            NSString *message = @(errorMessage);
            NSString *title = NSLocalizedString(@"Connect Failed", @"Connect Failed");
            NSString *domain = @"MTSqlite3";
            MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
            error = [NSError errorWithDomain:domain code:4832 userInfo:errorUserInfo.userinfo];
        }
        self.open = true;
    }
}

#ifdef MAD_MTDatabaseSqlite3_DEBUG
void sqliteLog(void *foo, const char* statement);
void sqliteLog(void *foo, const char* statement) {
    MTLogStatic(@"=> %s", statement);
}
#endif

int compare_string_utf8_localized_asc_collation(void* data, int len1, const void* arg1, int len2, const void* arg2) {
    NSString *string1 = [[NSString alloc] initWithBytes:arg1 length:(NSUInteger)abs(len1) encoding:NSUTF8StringEncoding];
    NSString *string2 = [[NSString alloc] initWithBytes:arg2 length:(NSUInteger)abs(len2) encoding:NSUTF8StringEncoding];
    return [string1 localizedCaseInsensitiveCompare:string2];
}

- (void)dealloc {
    if (_bulkStatement != NULL && sqlite3_finalize(_bulkStatement)) {
        NSAssert(0, @"Error: failed to finalize bulk statement with message: '%s, %s'.", __PRETTY_FUNCTION__, sqlite3_errmsg(_database));
    }
    if (_database != NULL && sqlite3_close(_database) != SQLITE_OK) {   // close short circuts (skips) on null database
        //NSAssert(0, @"Error: failed to close database with message '%s, %s'.", __PRETTY_FUNCTION__, sqlite3_errmsg(_database));
    }
}

- (void)connectWithCredentals:(MTDatabaseConnection *)connection completion:(void (^)(id, BOOL, NSError *))completion {
    [self openDatabase];
}

- (BOOL)tableExist:(NSString *)tablename {
    BOOL exist = NO;
	NSString *query = @"SELECT count(tbl_name) FROM sqlite_master WHERE type = 'table' AND name = ?;";
    sqlite3_stmt *statement = NULL;
    const char *queryc = [query UTF8String];
	if (sqlite3_prepare_v2(_database, queryc, -1, &statement, NULL) == SQLITE_OK) {
        sqlite3_bind_text(statement, 1, [tablename UTF8String], (int)strlen([tablename UTF8String]), SQLITE_STATIC);
		if (sqlite3_step(statement) == SQLITE_ROW) {
            exist = sqlite3_column_int(statement, 0) == 1;
        }
    }
    sqlite3_finalize(statement);
    return exist;
}

- (void)getTablesFromConnection:(id)process completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    [self getTables:^(BOOL success, NSError *error, NSArray *tables) {
        completion(success, error, tables);
    }];
}

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL success = NO;
	sqlite3_stmt *statement;
	NSString *queryStart = @"SELECT tbl_name FROM main.sqlite_master WHERE type='table';";
    const char *queryStartChar = [queryStart UTF8String];
	char *sql = sqlite3_mprintf((char *) queryStartChar);

	if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        success = YES;
		while (sqlite3_step(statement) == SQLITE_ROW) {
            
            const unsigned char *resultString = sqlite3_column_text(statement, 0);
            NSString *tableName = @((char *)resultString);
            
            MTDatabaseTable *databaseTable = [[MTDatabaseTable alloc] initWithTableName: tableName];
            [result addObject:databaseTable];
		}
	}
	sqlite3_finalize(statement);
	sqlite3_free(sql);
    completion(success, nil, result);
}

- (void)getFieldsForTableName: (NSString *)tableName connection:(id)process
                   completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    [self getFieldsForTableName:tableName completion:^(BOOL success, NSError *error, NSArray *fields) {
        completion(success, error, fields);
    }];
}

- (void)getFieldsForTableName: (NSString *)tableName
                   completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL success = NO;
	sqlite3_stmt *statement;
	NSString *queryStart = [NSString stringWithFormat: @"PRAGMA \"main\".table_info(\"%@\");", tableName];
    const char *queryStartChar = [queryStart UTF8String];
	char *sql = sqlite3_mprintf((char *) queryStartChar);
    
	if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        success = YES;
		while (sqlite3_step(statement) == SQLITE_ROW) {
            
            const unsigned char *resultName = sqlite3_column_text(statement, 1);
            const unsigned char *resultType = sqlite3_column_text(statement, 2);
            BOOL isPk = sqlite3_column_int(statement, 5) > 0;
            NSString *fieldName = @((char *)resultName);
            NSString *fieldType = @((char *)resultType);
            MTDataType dataType = [MTDatabaseSqlite3 dataTypeForNativeType: fieldType];
            
            MTDatabaseField *databaseField = [[MTDatabaseField alloc] initWithName: fieldName];
            [databaseField setFieldType:dataType];
            [databaseField setFieldTypeNative:dataType];
            [databaseField setPrimaryKey:isPk];
            [result addObject:databaseField];
		}
	}
	sqlite3_finalize(statement);
	sqlite3_free(sql);
    completion(success, nil, result);
}


//Converting native type to affinity type
// using http://www.sqlite.org/datatype3.html

+ (MTDataType)dataTypeForNativeType:(NSString *)nativeType {
    
    NSString *lowerCaseString = [nativeType lowercaseString];
    
    BOOL isInteger = [lowerCaseString rangeOfString:@"int"].location != NSNotFound;
    BOOL isText = NO;
    BOOL isNone = NO;
    BOOL isReal = NO;
    BOOL isNumeric = NO;
    if (isInteger == NO) {
        isText = [lowerCaseString rangeOfString:@"char"].location != NSNotFound ||
                    [lowerCaseString rangeOfString:@"clob"].location != NSNotFound ||
                    [lowerCaseString rangeOfString:@"text"].location != NSNotFound;
        if (isText == NO) {
            isNone = [lowerCaseString length] == 0 ||
                        [lowerCaseString rangeOfString:@"blob"].location != NSNotFound;
            
            if (isNone == NO) {
                isReal = [lowerCaseString rangeOfString:@"real"].location != NSNotFound ||
                    [lowerCaseString rangeOfString:@"floa"].location != NSNotFound ||
                    [lowerCaseString rangeOfString:@"doub"].location != NSNotFound;
                if (isReal == NO) {
                    isNumeric = YES;        //Not read
                }
            }

        }
    }
    
    MTDataType result;
    if (isInteger) {
        result = MTDataTypeInteger;
    } else if (isText) {
        result = MTDataTypeString;
    } else if (isNone) {
        result = MTDataTypeBlob;
    } else if (isReal) {
        result = MTDataTypeDouble;
    } else {
        result = MTDataTypeNumber;
    }
    return result;
}

+ (MTDataType)dataTypeForAffentyType:(int)affentyType {
    MTDataType result;
    switch (affentyType) {
        case SQLITE_INTEGER:
            result = MTDataTypeInteger;
            break;
        case SQLITE_FLOAT:
            result = MTDataTypeDouble;
            break;
        case SQLITE_BLOB:
            result = MTDataTypeBlob;
            break;
        case SQLITE_NULL:
        case SQLITE3_TEXT:
        default:
            result = MTDataTypeString;
            break;
    }
    return result;
}

+ (NSString *)sortDescForColumnType:(MTDataType)columnType ascending:(BOOL)ascending {
    NSString *sortDescription = nil;
    if ([[MTDatabaseSqlite3 nativeTypeForDataType:columnType] isEqualToString:@"TEXT"]) {
        sortDescription = ascending ? @"COLLATE LSASC ASC" : @"COLLATE LSASC DESC";
    } else {
        sortDescription = ascending ? @"ASC" : @"DESC";;
    }
    return sortDescription;
}

+ (MTDataType)dataTypeForNativeTypeNumeric:(MTDataType)dataType {
    MTDataType result;
    switch (dataType) {
        case MTDataTypeBit:
        case MTDataTypeInteger:
        case MTDataTypeShort:
        case MTDataTypeLong:
        case MTDataTypeLongLong:
        case MTDataTypeInt24:
        case MTDataTypeEnum:
            result = MTDataTypeInteger;
            break;
        case MTDataTypeSet:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeString:
        case MTDataTypeVarChar:
        case MTDataTypeGeometry:
            result = MTDataTypeString;
            break;
        case MTDataTypeImage:
        case MTDataTypeBlob: {
            
            result = MTDataTypeBlob;
            break;
        }
        case MTDataTypeFloat:
            result = MTDataTypeFloat;
            break;
        case MTDataTypeDouble:
            result = MTDataTypeDouble;
            break;
        case MTDataTypeDecimal:
        case MTDataTypeNumber:
            result = MTDataTypeDecimal;
            break;
        case MTDataTypeUnknown:
        default:
            result = MTDataTypeString;
            break;
    }
    return result;
}

+ (NSString *)nativeTypeForDataType:(MTDataType)dataType {
    NSString *columnAffinity;
    switch (dataType) {
        case MTDataTypeBit:
        case MTDataTypeInteger:
        case MTDataTypeShort:
        case MTDataTypeLong:
        case MTDataTypeLongLong:
        case MTDataTypeInt24:
        case MTDataTypeEnum:
            columnAffinity = @"INTEGER";
            break;
        case MTDataTypeSet:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeString:
        case MTDataTypeVarChar:
        case MTDataTypeGeometry:
            columnAffinity = @"TEXT";
            break;
        case MTDataTypeImage:
        case MTDataTypeBlob:
            columnAffinity = @"NONE";
            break;
        case MTDataTypeFloat:
        case MTDataTypeDouble:
            columnAffinity = @"REAL";
            break;
        case MTDataTypeDecimal:
        case MTDataTypeNumber:
            columnAffinity = @"NUMERIC";
            break;
        case MTDataTypeUnknown:
        default:
            columnAffinity = @"TEXT";
            break;
    }
    return columnAffinity;
}


- (NSString *)nativeTypeForDataType:(MTDataType)dataType {
    return [MTDatabaseSqlite3 nativeTypeForDataType:dataType];
}

- (sqlite3_stmt *)statementForQuery:(MTQuery *)query andStatement:(sqlite3_stmt *)statement {
    return [query partOfTransactionSet] ? _bulkStatement : statement;
}

- (void)bindStatement:(sqlite3_stmt **)statement withBindings:(MTDatabaseDataBinding *)databinding {

    BOOL success = YES;
    if ([databinding.value isEqual:[NSNull null]]) {
        success = SQLITE_OK == sqlite3_bind_null(*statement, databinding.columnNumber);
    } else {
        switch (databinding.datatype) {
                
            case MTDataTypeBlob: {

                if ([databinding.value isKindOfClass:[NSString class]]) {
                    success = SQLITE_OK ==
                                sqlite3_bind_text(*statement, databinding.columnNumber, ((NSString *)databinding.value).UTF8String, (int)strlen(((NSString *)databinding.value).UTF8String), SQLITE_TRANSIENT);
                } else if ([databinding.value isKindOfClass:[NSData class]]) {
                    success = SQLITE_OK ==
                                sqlite3_bind_blob(*statement, databinding.columnNumber, ((NSData *)databinding.value).bytes, (int)((NSData *)databinding.value).length, SQLITE_TRANSIENT);
                }
                NSAssert(success, @"%s: %s", __PRETTY_FUNCTION__, (char *)sqlite3_errmsg(*&_database));
                break;
            }
                
            case MTDataTypeInteger: {
                success = SQLITE_OK == sqlite3_bind_int64(*statement, databinding.columnNumber, ((NSNumber *)[databinding value]).longLongValue);
                NSAssert(success, @"%s: %s", __PRETTY_FUNCTION__, (char *)sqlite3_errmsg(*&_database));
                break;
            }
                
            case MTDataTypeString: {
                
                if ([databinding.value isKindOfClass:[NSString class]]) {

                    success = SQLITE_OK == sqlite3_bind_text(*statement, databinding.columnNumber, ((NSString *)databinding.value).UTF8String, (int)[((NSString *)databinding.value) lengthOfBytesUsingEncoding:NSUTF8StringEncoding], SQLITE_TRANSIENT);
                    
                } else if ([[databinding value] isKindOfClass:[NSDateComponents class]]) {
                    
                    NSDate *date = [[self currentCalandar] dateFromComponents:[databinding value]];
                    success = SQLITE_OK == sqlite3_bind_double(*statement, databinding.columnNumber, [date timeIntervalSince1970]);
                    
                } else {
                    NSAssert(false, @"What else is there? %s: %s", __PRETTY_FUNCTION__, (char *)sqlite3_errmsg(*&_database));
                }
                NSAssert(success, @"%s: %s", __PRETTY_FUNCTION__, (char *)sqlite3_errmsg(*&_database));
                break;
                
            }
            case MTDataTypeFloat:
            case MTDataTypeDouble:
                
                sqlite3_bind_double(*statement, databinding.columnNumber, ((NSNumber *)databinding.value).doubleValue);
                NSAssert(success, @"%s: %s", __PRETTY_FUNCTION__, (char *)sqlite3_errmsg(*&_database));
                break;
                
            case MTDataTypeNull:
                sqlite3_bind_null(*statement, databinding.columnNumber);
                NSAssert(success, @"%s: %s", __PRETTY_FUNCTION__, (char *)sqlite3_errmsg(*&_database));
                break;
                
            default:
                NSAssert(false, @"This is going to end badly.  Only binding blobs right now.");
                break;
                
        }
    }
    
}

- (void)executeQuery:(MTQuery *)query completion:(void (^)(BOOL, NSError *))completion {
    
    NSError *error = nil;
    BOOL success = YES;
    NSString *queryString = [NSString stringWithString: [query getSqlWithError:&error]];

    if (queryString.length > 0) {

        sqlite3_stmt *statement = NULL;
        statement = [self statementForQuery:query andStatement:statement];
        
        char *errorMessage = NULL;
        char *sql = sqlite3_mprintf(queryString.UTF8String);
        
        
        if (statement == NULL) {
            success = SQLITE_OK == sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
            if (query.binaryBindings.count > 0) {
                for (MTDatabaseDataBinding *databinding in query.binaryBindings) {
                    [self bindStatement:&statement withBindings:databinding];
                }
            }
        } else if ([query partOfTransactionSet]) {
            if (query.binaryBindings.count > 0) {
                for (MTDatabaseDataBinding *databinding in query.binaryBindings) {
                    [self bindStatement:&statement withBindings:databinding];
                }
            }
        }
        
        if ([query returnsResults]) {
            
            if (success) {
                
                int numberOfColumns = sqlite3_column_count(statement);
                numberOfColumns = numberOfColumns >= 0 ? numberOfColumns : 0;
                
                MTDataTable *dataTable = [self.delegate dataTableForQuery:query];
                [dataTable removeAllObjects];
                
                NSUInteger rowCounter = 0;
                
                //NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
                while (SQLITE_ROW == sqlite3_step(statement)) {
                    
                    if (rowCounter == 0) {  //If first time around, calculate column information.
                        for (int columnCounter = 0; columnCounter < numberOfColumns; columnCounter++) {
                            
                            @autoreleasepool {
                                NSString *fieldName = query.fieldKeys[(NSUInteger)columnCounter];
                                
                                MTDataColumn *dataColumn = [[MTDataColumn alloc] initWithIdentifier:fieldName];
                                
                                int affentyType = sqlite3_column_type(statement, (int)columnCounter);
                                NSNumber *nativeColumnType = @(affentyType);
                                
                                const char *columnName = sqlite3_column_name(statement, (int)columnCounter);
                                const char *tableName = sqlite3_column_table_name(statement, (int)columnCounter);
                                const char *databaseName = sqlite3_column_database_name(statement, (int)columnCounter);
                                
                                char const **pzDataType = NULL;
                                char const **pzCollSeq = NULL;
                                int *pNotNull = 0;
                                int *pPrimaryKey = 0;
                                int *pAutoinc = 0;
                            
                                if (tableName != NULL) {
                                    sqlite3_table_column_metadata(_database, databaseName, tableName, columnName, pzDataType, pzCollSeq, pNotNull, pPrimaryKey, pAutoinc);
                                }
                            
                                [dataColumn setFieldName: fieldName];
                                [dataColumn setNativeColumnType:nativeColumnType];
                                NSNumber *columnType = @([MTDatabaseSqlite3 dataTypeForAffentyType:affentyType]);
                                dataColumn.columnType = columnType;
                            
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
                        
                        NSString *fieldName = query.fieldKeys[(NSUInteger)colCtr];
                        id value = [MTDatabaseSqlite3 valueForStatement:statement columnNumber:colCtr];
                        resultsForRow[fieldName] = value;
                        
                    }
                    
                    [dataTable addRowWithDataForFieldKeys:resultsForRow];
                    resultsForRow = nil;
                    rowCounter++;
                }
                [dataTable endBulkInsert];
                
            }
        } else {
            // FIXME: Handle failures.
            sqlite3_step(statement);
        }
        if ([query partOfTransactionSet] == NO) {
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
        if (success == NO) {
            NSString *title = NSLocalizedString(@"Error", @"Error");
            NSString *domain = @"MTSqlite3";
            MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
            error = [NSError errorWithDomain:domain code:4784 userInfo:errorUserInfo.userinfo];
        }
        sqlite3_free(sql);
        
    }
    
    completion(success, error);
}

+ (id)valueForStatement:(sqlite3_stmt *)statement columnNumber:(int)columnNumber {
    id value = nil;
    int affentyType = sqlite3_column_type(statement, columnNumber);   //http://www.sqlite.org/c3ref/c_blob.html
    switch (affentyType) {
        case SQLITE_INTEGER: {
            sqlite3_int64 rint = sqlite3_column_int64(statement, columnNumber);
            value = @(rint);
            break;
        }
        case SQLITE_FLOAT: {
            double rint = sqlite3_column_double(statement, columnNumber);
            value = @(rint);
            break;
        }
        case SQLITE_BLOB: {
            const void *blob = sqlite3_column_blob(statement, columnNumber);
            if (blob != NULL) {
                int numBytes = sqlite3_column_bytes16(statement, columnNumber);
                value = [NSData dataWithBytes:blob length:numBytes];
            }
            break;
        }
        case SQLITE_NULL: {
            value = [NSNull null];
            break;
        }
        case SQLITE3_TEXT: {
            
            const unsigned char *resultString = sqlite3_column_text(statement, columnNumber);
            if (resultString != NULL) {
                value = @((char *) resultString);
            }
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

+ (id)object:(sqlite3_stmt *)statement forColumnNumber:(int)columnCounter withType:(MTDataType)type {
    id columnValue;
    switch (type) {
        case MTDataTypeLong:
            columnValue = @(sqlite3_column_int64(statement, columnCounter));
            break;
        case MTDataTypeLongLong:
            columnValue = @(sqlite3_column_int64(statement, columnCounter));
            break;
        case MTDataTypeInt24:
        case MTDataTypeInteger:
            columnValue = @(sqlite3_column_int64(statement, columnCounter));
            break;
        case MTDataTypeShort:
            columnValue = [NSNumber numberWithShort:sqlite3_column_int(statement, columnCounter)];
            break;
        case MTDataTypeImage:
        case MTDataTypeBlob:
            columnValue = [NSData dataWithBytes: sqlite3_column_blob(statement, columnCounter)
                                         length: sqlite3_column_bytes(statement, columnCounter)];
            break;
        case MTDataTypeFloat:
            columnValue = @(sqlite3_column_double(statement, columnCounter));
            break;
        case MTDataTypeNumber:
        case MTDataTypeDouble:
        case MTDataTypeDecimal:
            columnValue = @(sqlite3_column_double(statement, columnCounter));
            break;
        case MTDataTypeBit:
        case MTDataTypeVarChar:
        case MTDataTypeString:
        case MTDataTypeEnum:
        case MTDataTypeYear:
        case MTDataTypeSet: {
            const unsigned char *text = sqlite3_column_text(statement, columnCounter);
            if (text == NULL) {
                columnValue = [NSNull null];
            } else {
                columnValue = @((const char *) text);
            }
            break;
        }
        case MTDataTypeUnknown:
        case MTDataTypeNull: {
            columnValue = [NSNull null];
            break;
        }
        case MTDataTypeTimeStamp:
        case MTDataTypeTime:
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeGeometry:
        default: {
            //NSAssert(false, @"Type is not expected...  Should really be encapsulated in MTDatabaseSqlite3: %lu", (unsigned long)type);
            if (sqlite3_column_type(statement, columnCounter) == SQLITE3_TEXT) {
                const unsigned char *text = sqlite3_column_text(statement, columnCounter);
                if (text == NULL) {
                    columnValue = [NSNull null];
                } else {
                    columnValue = @((const char *) text);
                }
            }
            break;
        }
    }
    return columnValue;
}

- (BOOL)cleanupBulkInsert {
    BOOL success = SQLITE_OK == sqlite3_finalize(_bulkStatement);
    NSAssert(success, @"Bulk insert sqlite3_finalize failed (%s).", (char *)sqlite3_errmsg(_database));
    _bulkStatement = NULL;
    sqlite3_close(_database);
    _database = NULL;
    return success;
}

- (void)executeQuery:(MTQuery *)query withStatement:(sqlite3_stmt *)statement completion:(void (^)(BOOL, NSError *))completion {

}


- (NSString *)identifier {
    return MADIdentifierDatabaseSqlite3;
}

+ (NSString *)identifier {
    return MADIdentifierDatabaseSqlite3;
}

+ (NSString *)safeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    return [NSString stringWithFormat:MTDatabaseSqlite3SafeFormatField, tableName, fieldName];
}
- (NSString *)safeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    return [MTDatabaseSqlite3 safeQueryField:fieldName andTable:tableName];
}

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName {
    return [NSString stringWithFormat:MTDatabaseSqlite3SafeFormatIdentifier, fieldOrTableName];
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
            NSDictionary *queryDefination = [MTQuery queryDefinitionCacheDeleteAllFromTable:table.name];
            MTQuery *dropTable = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheDeleteAllFromTable object:queryDefination];
            [dropTable performQueryWithDatabase:self completion:^(BOOL success, NSError *error) {
                NSAssert(success && error == nil, @"Error %@ at %s.", error, __PRETTY_FUNCTION__);
            }];
        }
        dispatch_semaphore_signal(s0);
    }];
    dispatch_semaphore_wait(s0, DISPATCH_TIME_FOREVER);
    
    MTQuery *querySyncMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSyncModeOff object:@{}];
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    [querySyncMode performQueryWithDatabase:self completion:^(BOOL success, NSError *error) {
        NSAssert(success, @"%s: %@", __PRETTY_FUNCTION__, error);
        dispatch_semaphore_signal(s1);
    }];
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    
    MTQuery *queryJournalMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheJournalModeOverride object:@{}];
    dispatch_semaphore_t s2 = dispatch_semaphore_create(0);
    [queryJournalMode performQueryWithDatabase:self completion:^(BOOL success, NSError *error) {
        NSAssert(success, @"%s: %@", __PRETTY_FUNCTION__, error);
        dispatch_semaphore_signal(s2);
    }];
    dispatch_semaphore_wait(s2, DISPATCH_TIME_FOREVER);

    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheBeginTransaction object:@{}];
    dispatch_semaphore_t s3 = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:self completion:^(BOOL success, NSError *error) {
        NSAssert(success, @"%s: %@", __PRETTY_FUNCTION__, error);
        dispatch_semaphore_signal(s3);
    }];
    dispatch_semaphore_wait(s3, DISPATCH_TIME_FOREVER);
}

- (void)endBulkInsert {
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheEndTransaction object:@{}];
    dispatch_semaphore_t s1 = dispatch_semaphore_create(0);
    [query performQueryWithDatabase:self completion:^(BOOL success, NSError *error) {
        //NSAssert(success, @"%s: %@", __PRETTY_FUNCTION__, error);
        dispatch_semaphore_signal(s1);
    }];
    dispatch_semaphore_wait(s1, DISPATCH_TIME_FOREVER);
    
    MTQuery *querySyncMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSyncModeDefault object:@{}];
    dispatch_semaphore_t s2 = dispatch_semaphore_create(0);
    [querySyncMode performQueryWithDatabase:self completion:^(BOOL success, NSError *error) {
        //NSAssert(success, @"%s: %@", __PRETTY_FUNCTION__, error);
        dispatch_semaphore_signal(s2);
    }];
    dispatch_semaphore_wait(s2, DISPATCH_TIME_FOREVER);
    
    /*
    dispatch_semaphore_t s3 = dispatch_semaphore_create(0);
    MTQuery *queryJournalMode = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheJournalModeDefault object:@{}];
    [queryJournalMode performQueryWithDatabase:self completion:^(BOOL success, NSError *error) {
        //NSAssert(success, @"%s: %@", __PRETTY_FUNCTION__, error);
        dispatch_semaphore_signal(s3);
    }];
    dispatch_semaphore_wait(s3, DISPATCH_TIME_FOREVER);
    
    */
    
    [self cleanupBulkInsert];
}

@end
