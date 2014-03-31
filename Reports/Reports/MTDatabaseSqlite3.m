//
//  MTDatabaseSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 10/23/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseSqlite3.h"
#import "MTQueryReportSqlite3.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTDatabaseTable.h"
#import "MTDatabaseField.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

@interface MTDatabaseSqlite3 ()

@property (assign) sqlite3 *database;

@end

@implementation MTDatabaseSqlite3

- (void)openDatabase {

    //Open conneciton... closed in dealloc.
    NSString *filepath = [[[self databaseConnection] databaseUrl] path];
    if (sqlite3_open([filepath UTF8String], &_database) != SQLITE_OK) {
        NSAssert1(0, @"Error: failed to open database with message '%s'.", sqlite3_errmsg(_database));
    } else {
        sqlite3_extended_result_codes(_database, true);
    }
    
}

- (void)dealloc {
    if (sqlite3_close(_database) != SQLITE_OK) {
        NSAssert1(0, @"Error: failed to close database with message '%s'.", sqlite3_errmsg([self database]));
    }
    [super dealloc];
}

- (void)maxLengthForFields:(NSArray *)fields inTable:(NSString *)tableName
                completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {

    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL success = NO;
	NSError *error = nil;
    NSString *sqlStr = nil;
    
    if ([fields count] > 0) {
        NSMutableString *selectFields = [[NSMutableString alloc] initWithString:@""];
        for (NSString *field in fields) {
            [selectFields appendFormat: @" MAX( LENGTH(%@) ) %@ %@,", field, [self tableAliasConnector], field];
        }
        NSString *fieldsPart;
        if ([selectFields length] > 0) {
            fieldsPart = [selectFields substringToIndex:[selectFields length] - 1];
        } else {
            fieldsPart = @"";
        }
        sqlStr = [NSString stringWithFormat:@"SELECT %@ from %@;", fieldsPart, tableName];

    }

    if (sqlStr) {
        sqlite3_stmt *statement;
        const char *queryStartChar = [sqlStr UTF8String];
        char *sql = sqlite3_mprintf((char *) queryStartChar);
        
        if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
            success = YES;
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSInteger numberOfColumns = sqlite3_column_count(statement);
                NSMutableDictionary *resultSet = [[NSMutableDictionary alloc] initWithCapacity:numberOfColumns];
                for (NSInteger i=0; i<numberOfColumns; i++) {
                    NSInteger resultString = sqlite3_column_int(statement, (int)i);
                    const  char *columnNameCString = sqlite3_column_name(statement, (int)i);
                    NSString *columnName = [self safeIdentifier: [NSString stringWithUTF8String:(char *)columnNameCString]];
                    [resultSet setObject:@(resultString) forKey:columnName];

                }
                [result addObject:resultSet];
            }
        }
        
        sqlite3_finalize(statement);
        sqlite3_free(sql);

    }
    completion(success, error, [result autorelease]);
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

- (void)executeSql:(NSString *)sql completion:(void (^)(BOOL success, NSError *error, id results))completion {
    id results = [[[self resultsForQueryString:sql] retain] autorelease];
    completion(YES, nil, results);
}

- (NSArray *)resultsForQueryString:(NSString *)queryString {
    NSMutableArray *results = [[NSMutableArray alloc] init];
    BOOL success = NO;
	sqlite3_stmt *statement;
    const char *queryStartChar = [queryString UTF8String];
	char *sql = sqlite3_mprintf((char *) queryStartChar);
    NSCharacterSet *whitespaceCharacters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *trimCharacters = [NSCharacterSet characterSetWithCharactersInString:@","];
    NSArray *components = [queryString componentsSeparatedByCharactersInSet:whitespaceCharacters];
    NSMutableArray *fieldNames = [[NSMutableArray alloc] initWithCapacity:[components count]];
    
    // Get field names from
    for (NSString *component in components) {
        if ([component isEqualToString:@"FROM"]) {
            break;
        }
        NSString *componentCleaned = [component stringByTrimmingCharactersInSet:trimCharacters];
        NSRange doubleQuoteLocation = [componentCleaned rangeOfString:@"\""];
        if (doubleQuoteLocation.location == 0) {
            NSRange connectorLocatoin = [componentCleaned rangeOfString:@"\".\""];
            if (connectorLocatoin.location != NSNotFound) {
                [fieldNames addObject:componentCleaned];
            }
        }
    }
    if ([fieldNames count] == 0 && [[components objectAtIndex:1] isEqualToString: @"*"]) {
        NSString *tableName = [[components objectAtIndex:3] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        __block NSMutableArray *fns = [[NSMutableArray alloc] init];
        
        dispatch_semaphore_t semaphoreGetFields = dispatch_semaphore_create(0);

        [self getFieldsForTableName:tableName completion:^(BOOL success, NSError *error, NSArray *fields) {
            [fns addObjectsFromArray:fields];
            dispatch_semaphore_signal(semaphoreGetFields);
        }];
        
        dispatch_semaphore_wait(semaphoreGetFields, DISPATCH_TIME_FOREVER);
        dispatch_release(semaphoreGetFields);
        

        [fieldNames addObjectsFromArray:fns];
        [fns release];
    }
    
	if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
        success = YES;
        //int numberOfColumns = sqlite3_column_count(statement);
        //if (numberOfColumns > 0) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int numberOfColumns = sqlite3_column_count(statement);
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
                        NSString *fieldName = fieldNames[colCtr];
                        
                        if (NO) {
                            const char *columnName = sqlite3_column_name(statement, colCtr);
                            const char *tableName = sqlite3_column_table_name(statement, colCtr);
                            const char *originName = sqlite3_column_origin_name(statement, colCtr);
                            const char *databaseName = sqlite3_column_database_name(statement, colCtr);
                            NSString *columnName8 = [self safeIdentifier:[NSString stringWithUTF8String:columnName]];
                            NSString *tableName8 = [self safeIdentifier:[NSString stringWithUTF8String:tableName]];
                            NSString *key = [NSString stringWithFormat:@"%@.%@", tableName8, columnName8];
                            NSString *oname = [NSString stringWithUTF8String:originName];
                            NSString *dbname = [NSString stringWithUTF8String:databaseName];
                            NSLog(@"%@-%@-%@", dbname, oname, key);
                        }
                        
                        [resultsForRow setObject:value forKey:fieldName];
                    }
                }
                [results addObject:resultsForRow];
                [resultsForRow release];

            }
        //}
	} else {
        NSLog(@"Caught %s",  sqlite3_errmsg(_database));
    }
    [fieldNames release];
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

- (BOOL)isReachable {
    return NO;
}

@end
