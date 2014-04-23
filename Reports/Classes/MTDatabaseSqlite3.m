//
//  MTDatabaseSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 10/23/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseSqlite3.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"
#import "MTQuery.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "NSError+Constructors.h"

#import "MTLog.h"

#import "MTDataTable.h"
#import "MTDataColumn.h"

#import "MTDatabaseDataBinding.h"

@interface MTDatabaseSqlite3 ()

@property (assign) sqlite3 *database;
@property (assign) sqlite3_stmt *bulkStatement;

@property (nonatomic, assign) BOOL isOpen;

@end

@implementation MTDatabaseSqlite3

- (id)init {
    self = [super init];
    if (self) {
        _bulkStatement = NULL;
    }
    return self;
}

- (void)openDatabase {

    NSError *error = nil;
    //Open conneciton... closed in dealloc.
    if ([self isOpen] == NO) {
        NSString *filepath = [[[self databaseConnection] databaseUrl] path];
        const char *path = [filepath UTF8String];
        BOOL isOpen = sqlite3_open_v2(path, &_database, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_SHAREDCACHE | SQLITE_OPEN_FULLMUTEX, NULL) == SQLITE_OK;
        if (isOpen) {
            sqlite3_extended_result_codes(_database, true);
        } else {
            const char *errorMessage = sqlite3_errmsg(_database);
            NSString *message = [NSString stringWithUTF8String: errorMessage];
            NSString *title = NSLocalizedString(@"Connect Failed", @"Connect Failed");
            error = [NSError errorWithDomain:@"MTSqlite3" code:4832 title:title andMessage:message];
        }
        [self setIsOpen:YES];
    }
    
}

- (void)dealloc {
    if (sqlite3_close(_database) != SQLITE_OK) {
        NSAssert1(0, @"Error: failed to close database with message '%s'.", sqlite3_errmsg([self database]));
    }
    [super dealloc];
}

- (void)connectWithCredentals:(MTDatabaseConnection *)connection completion:(void (^)(id, BOOL, NSError *))completion {
    [self openDatabase];
}

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL success = NO;
	sqlite3_stmt *statement;
	NSString *queryStart = @"SELECT \"tbl_name\" FROM \"main\".\"sqlite_master\" WHERE \"type\"='table';";
    const char *queryStartChar = [queryStart UTF8String];
	char *sql = sqlite3_mprintf((char *) queryStartChar);

	if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        success = YES;
		while (sqlite3_step(statement) == SQLITE_ROW) {
            
            const unsigned char *resultString = sqlite3_column_text(statement, 0);
            NSString *tableName = [NSString stringWithUTF8String:(char *)resultString];
            
            MTDatabaseTable *databaseTable = [[MTDatabaseTable alloc] initWithTableName: tableName];
            [result addObject:databaseTable];
            [databaseTable release];
		}
	}
	sqlite3_finalize(statement);
	sqlite3_free(sql);
    completion(success, nil, [result autorelease]);
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
            NSString *fieldName = [NSString stringWithUTF8String:(char *)resultName];
            NSString *fieldType = [NSString stringWithUTF8String:(char *)resultType];
            MTDataType dataType = [MTDatabaseSqlite3 dataTypeForNativeType: fieldType];
            
            MTDatabaseField *databaseField = [[MTDatabaseField alloc] initWithName: fieldName];
            [databaseField setFieldType:dataType];
            [databaseField setFieldTypeNative:dataType];
            [databaseField setPrimaryKey:isPk];
            [result addObject:databaseField];
            [databaseField release];
		}
	}
	sqlite3_finalize(statement);
	sqlite3_free(sql);
    completion(success, nil, [result autorelease]);
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

- (NSString *)nativeTypeForDataType:(MTDataType)dataType {
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

- (void)executeQuery:(MTQuery *)query completion:(void (^)(BOOL, NSError *))completion {
    sqlite3_stmt *statement = [query partOfTransactionSet] ? _bulkStatement : NULL;
    NSError *error = nil;
    NSString *queryString = [query getSqlWithError:&error];
    
    char *errorMessage = NULL;
    const char *queryStartChar = [queryString UTF8String];
	char *sql = sqlite3_mprintf((char *) queryStartChar);
    
    BOOL success = YES;
    if (statement == NULL) {
        success = SQLITE_OK == sqlite3_prepare_v2(_database, sql, -1, &statement, NULL);
    }
    
    if ([[query binaryBindings] count] > 0) {
        for (MTDatabaseDataBinding *databinding in [query binaryBindings]) {
            switch ([databinding datatype]) {
                case MTDataTypeBlob: {
                    NSData *data = [databinding value];
                    int columnNumber = (int)[databinding fieldIndex] + 1;
                    success = SQLITE_OK == sqlite3_bind_blob(statement, columnNumber, [data bytes], (int)[data length], SQLITE_TRANSIENT);
                    NSAssert(success, @"%s", (char *)sqlite3_errmsg(_database));
                    break;
                }
                case MTDataTypeInteger: {
                    long long integerValue = [[databinding value] longLongValue];
                    int columnNumber = (int)[databinding fieldIndex] + 1;
                    success = SQLITE_OK == sqlite3_bind_int64(statement, columnNumber, integerValue);
                    NSAssert(success, @"%s", (char *)sqlite3_errmsg(_database));
                    break;
                }
                case MTDataTypeString: {
                    NSString *stringValue = [databinding value];
                    const char *cstr = [stringValue UTF8String];
                    int len = strlen(cstr);
                    int columnNumber = (int)[databinding fieldIndex] + 1;
                    success = SQLITE_OK == sqlite3_bind_text(statement, columnNumber, cstr, len, SQLITE_TRANSIENT);
                    NSAssert(success, @"%s", (char *)sqlite3_errmsg(_database));
                    break;
                }
                case MTDataTypeFloat:
                case MTDataTypeDouble: {
                    double doubeValue = [[databinding value] doubleValue];
                    int columnNumber = (int)[databinding fieldIndex] + 1;
                    success = SQLITE_OK == sqlite3_bind_double(statement, columnNumber, doubeValue);
                    NSAssert(success, @"%s", (char *)sqlite3_errmsg(_database));
                    break;
                }
                default:
                    NSAssert(false, @"This is going to end badly.  Only binding blobs right now.");
                    break;
            }
        }
    }
    
    
    if ([query returnsResults]) {
        
        if (success) {
            
            int numberOfColumns = sqlite3_column_count(statement);
            
            [[query datatable] removeAllObjects];
            
            NSUInteger rowCounter = 0;
            
            [[query datatable] beginBulkInsert];
            
            while (SQLITE_ROW == sqlite3_step(statement)) {
                
                if (rowCounter == 0) {  //If first time around, calculate column information.
                    for (NSUInteger columnCounter = 0; columnCounter < numberOfColumns; columnCounter++) {
                        
                        @autoreleasepool {
                            NSString *fieldName = [query fieldKeys][columnCounter];
                            MTDataColumn *dataColumn = [[MTDataColumn alloc] initWithIdentifier:fieldName];
                            
                            int affentyType = sqlite3_column_type(statement, (int)columnCounter);
                            NSNumber *nativeColumnType = @(affentyType);
                            
                            const char *columnName = sqlite3_column_name(statement, (int)columnCounter);
                            const char *tableName = sqlite3_column_table_name(statement, (int)columnCounter);
                            //const char *originName = sqlite3_column_origin_name(statement, columnCounter);
                            const char *databaseName = sqlite3_column_database_name(statement, (int)columnCounter);
                            
                            char const **pzDataType = NULL;
                            char const **pzCollSeq = NULL;
                            int *pNotNull = 0;
                            int *pPrimaryKey = 0;
                            int *pAutoinc = 0;
                            
                            sqlite3_table_column_metadata(_database, databaseName, tableName, columnName, pzDataType, pzCollSeq, pNotNull, pPrimaryKey, pAutoinc);
                            
                            [dataColumn setFieldName: fieldName];
                            [dataColumn setNativeColumnType:nativeColumnType];
                            NSNumber *columnType = @([MTDatabaseSqlite3 dataTypeForAffentyType:affentyType]);
                            [dataColumn setColumnType:columnType];
                            [dataColumn setPrimaryKey: (pPrimaryKey == NULL) ? NO : *pPrimaryKey];
                            [dataColumn setAutoIncrement: (pAutoinc == NULL) ? NO : *pAutoinc];
                            [dataColumn setNotNull: (pNotNull == NULL) ? NO : *pNotNull];
                            [[query datatable] addColumn:dataColumn];
                            [dataColumn release];
                        }
                        
                    }
                }
                
                NSMutableDictionary *resultsForRow = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
                
                for (int colCtr = 0; colCtr < numberOfColumns; colCtr++) {
                    
                    
                    int affentyType = sqlite3_column_type(statement, colCtr);   //http://www.sqlite.org/c3ref/c_blob.html
                    id value = nil;
                    switch (affentyType) {
                        case SQLITE_INTEGER: {
                            sqlite3_int64 rint = sqlite3_column_int64(statement, colCtr);
                            value = [NSNumber numberWithLongLong:rint];
                            break;
                        }
                        case SQLITE_FLOAT: {
                            double rint = sqlite3_column_double(statement, colCtr);
                            value = [NSNumber numberWithDouble:rint];
                            break;
                        }
                        case SQLITE_BLOB: {
                            const void *blob = sqlite3_column_blob(statement, colCtr);
                            if (blob != NULL) {
                                int numBytes = sqlite3_column_bytes16(statement, colCtr);
                                value = [NSData dataWithBytes:blob length:numBytes];
                            }
                            break;
                        }
                        case SQLITE_NULL: {
                            break;
                        }
                        case SQLITE3_TEXT: {
                            
                            const unsigned char *resultString = sqlite3_column_text(statement, colCtr);
                            if (resultString != NULL) {
                                value = [NSString stringWithUTF8String:(char *) resultString];
                            }
                            break;
                        }
                        default:
                            NSAssert(false, @"Unhandled case");
                            break;
                    }
                    
                    if (value != nil) {
                        NSString *fieldName = [query fieldKeys][colCtr];
                        [resultsForRow setObject:value forKey:fieldName];
                    }
                }
                
                [[query datatable] addRowWithDataForFieldKeys:resultsForRow];
                [resultsForRow release];
                
                
                rowCounter++;
            }
            [[query datatable] endBulkInsert];
            
        }
    } else {
        int result = sqlite3_step(statement);
        NSAssert(SQLITE_ROW == result || SQLITE_DONE == result, @"%s", (char *)sqlite3_errmsg(_database));
        NSAssert(success, @"%s", (char *)sqlite3_errmsg(_database));
    }
    if ([query partOfTransactionSet] == NO) {
        success = SQLITE_OK == sqlite3_finalize(statement);
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
        error = [NSError errorWithDomain:@"MTDatabaseSqlite3" code:4784 title:title andMessage:message];
        NSLog(@"Sqlite3Error: %@\nQuery\n%@", error, queryString);
    }
    //    NSAssert(<#condition#>, <#desc, ...#>)
	sqlite3_free(sql);
    completion(success, error);
}

- (void)cleanupBulkInsert {
    BOOL success = SQLITE_OK == sqlite3_finalize(_bulkStatement);
    NSAssert(success, @"Bulk insert sqlite3_finalize failed (%s).", (char *)sqlite3_errmsg(_database));
}

- (void)executeQuery:(MTQuery *)query withStatement:(sqlite3_stmt *)statement completion:(void (^)(BOOL, NSError *))completion {

}


- (NSString *)identifier {
    return [MTDatabaseConnectionSqlite3 identifier];
}

+ (NSString *)identifier {
    return [MTDatabaseConnectionSqlite3 identifier];
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    return [MTDatabaseSqlite3 safeQueryField:queryField];
}

+ (NSString *)safeQueryField:(RptqQueryField *)queryField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[queryField inQueryTable] queryAlias];
    NSString *fieldName = [[queryField databaseSchemaField] name];
    return [NSString stringWithFormat:@"\"%@\".\"%@\"", queryTable, fieldName];
}

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName {
    // FIXME: Use backticks `` to make more robust.
    return [NSString stringWithFormat:@"\"%@\"", fieldOrTableName];
}

- (NSString *)safeQuerySchemaField:(RptqDatabaseSchemaField *)schemaField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[schemaField inTable] name];
    NSString *fieldName = [schemaField name];
    return [NSString stringWithFormat:@"\"%@\".\"%@\"", queryTable, fieldName];
}

- (NSString *)tableAliasConnector {
    return @" ";
}

@end
