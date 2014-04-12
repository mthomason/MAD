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

@interface MTDatabaseSqlite3 ()

@property (assign) sqlite3 *database;
@property (nonatomic, assign) BOOL isOpen;

@end

@implementation MTDatabaseSqlite3

- (void)openDatabase {

    NSError *error = nil;
    //Open conneciton... closed in dealloc.
    if ([self isOpen] == NO) {
        NSString *filepath = [[[self databaseConnection] databaseUrl] path];
        BOOL isOpen = sqlite3_open([filepath UTF8String], &_database) == SQLITE_OK;
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

- (void)executeQuery:(MTQuery *)query completion:(void (^)(BOOL, NSError *, MTDataTable *))completion {
    MTDataTable *results = [[[self resultsForQuery:query] retain] autorelease];
    completion(YES, nil, results);
}

- (MTDataTable *)resultsForQuery:(MTQuery *)query {
    NSError *error = nil;
    NSString *queryString = [query getSqlWithError:&error];
    
//    NSMutableArray *results = [[NSMutableArray alloc] init];
    MTDataTable *results = nil;
    BOOL success = NO;
	sqlite3_stmt *statement;
    const char *queryStartChar = [queryString UTF8String];
	char *sql = sqlite3_mprintf((char *) queryStartChar);
    

	if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {

        success = YES;

        int numberOfColumns = sqlite3_column_count(statement);
        results = [[MTDataTable alloc] initWithNumberOfColumns:numberOfColumns];
        
        NSUInteger rowCounter = 0;
        while (sqlite3_step(statement) == SQLITE_ROW) {
            if (rowCounter == 0) {
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
                        
                        [dataColumn setNativeColumnType:nativeColumnType];
                        [dataColumn setPrimaryKey: (pPrimaryKey == NULL) ? NO : *pPrimaryKey];
                        [dataColumn setAutoIncrement: (pAutoinc == NULL) ? NO : *pAutoinc];
                        [dataColumn setNotNull: (pNotNull == NULL) ? NO : *pNotNull];
                        [results addColumn:dataColumn];
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
                        value = [NSNumber numberWithDouble:rint];
                        break;
                    }
                    case SQLITE_FLOAT: {
                        sqlite3_int64 rint = sqlite3_column_double(statement, colCtr);
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
                        break;
                }
                
                if (value != nil) {
                    NSString *fieldName = [query fieldKeys][colCtr];
                    [resultsForRow setObject:value forKey:fieldName];
                }
            }
            
            [results addRowWithDataForFieldKeys:resultsForRow];
            [resultsForRow release];
            
            
            rowCounter++;
        }
        
	} else {
        MTLog(@"Caught %s",  sqlite3_errmsg(_database));
    }
	sqlite3_finalize(statement);
	sqlite3_free(sql);
    return [results autorelease];
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
