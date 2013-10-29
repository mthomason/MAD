//
//  MTDatabaseSqlite3.m
//  MAD
//
//  Created by Michael Thomason on 10/23/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseSqlite3.h"
#import "RptqQueryField+Extras.h"


@interface MTDatabaseSqlite3 ()

@property (readwrite, nonatomic, retain) MTDatabaseConnection *databaseConnection;


@property (assign) sqlite3 *database;

@end

@implementation MTDatabaseSqlite3

- (void)dealloc {
    if (sqlite3_close(_database) != SQLITE_OK) {
        NSAssert1(0, @"Error: failed to close database with message '%s'.", sqlite3_errmsg([self database]));
    }
    [_databaseConnection release];
    [super dealloc];
}

- (id)initWithConnectionSettings: (MTDatabaseConnection *)connectionSettings {
    self = [super init];
    if (self) {

        //Open conneciton... closed in dealloc.
        NSString *filepath = [[connectionSettings databaseUrl] path];
        if (sqlite3_open([filepath UTF8String], &_database) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to open database with message '%s'.", sqlite3_errmsg(_database));
        } else {
            sqlite3_extended_result_codes(_database, true);
        }

        [self setDatabaseConnection:connectionSettings];

    }
    return self;
}

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName {
    // FIXME: Use backticks `` to make more robust.
    return [[[NSString stringWithFormat:@"\"%@\"", fieldOrTableName] retain] autorelease];
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[queryField inQueryTable] queryAlias];
    NSString *fieldName = [[queryField databaseSchemaField] name];
    return [[[NSString stringWithFormat:@"\"%@\".\"%@\"", queryTable, fieldName] retain] autorelease];
}

- (NSString *)safeQuerySchemaField:(RptqDatabaseSchemaField *)schemaField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[schemaField inTable] name];
    NSString *fieldName = [schemaField name];
    return [[[NSString stringWithFormat:@"\"%@\".\"%@\"", queryTable, fieldName] retain] autorelease];
}

- (NSString *)selectPart {
    return @"SELECT\n";
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

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    NSString *tableName = [table name];
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


- (void)cacheReportQueryForDocument:(RptqDocument *)document
                         completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion {
    
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *rquery = [[database hasQueries] anyObject];
    MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
    NSString *queryString = [mnsDatabase getSqlForQuery:rquery];
    RptqQuery *query = [[database hasQueries] anyObject];

    NSArray *results = [[self resultsForQueryString:queryString] retain];
    
    NSString *name = [[[MTActiveDocument sharedDocument] activeDocument] name];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesPath = [paths lastObject];
    NSURL *cachesUrl = [NSURL fileURLWithPath:cachesPath isDirectory:YES];
    NSURL *url = [cachesUrl URLByAppendingPathComponent:name isDirectory:NO];
    NSData *cachedData = [NSPropertyListSerialization dataWithPropertyList:results
                                                                    format:NSPropertyListBinaryFormat_v1_0
                                                                   options:0
                                                                     error:NULL];
    NSError *error = nil;
    [cachedData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    if (error) {
        error = nil;
        [cachedData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    }

    [results release];
    
    NSManagedObjectContext *managedObjectContext = [document managedObjectContext];
    RptqQueryCache *queryCache = [RptqQueryCache initObjectForManagedObjectContext:managedObjectContext];
    [queryCache setCacheDate:[NSDate date]];
    [query setHasQueryCache:queryCache];

    completion(self, [query hasQueryCache]);
    
}

- (NSString *)tableAliasConnector {
    return @" ";
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
                        const char *columnName = sqlite3_column_name(statement, colCtr);
                        const char *tableName = sqlite3_column_table_name(statement, colCtr);
                        const char *originName = sqlite3_column_origin_name(statement, colCtr);
                        const char *databaseName = sqlite3_column_database_name(statement, colCtr);
                        NSString *columnName8 = [self safeIdentifier:[NSString stringWithUTF8String:columnName]];
                        NSString *tableName8 = [self safeIdentifier:[NSString stringWithUTF8String:tableName]];
                        NSString *key = [NSString stringWithFormat:@"%@.%@", tableName8, columnName8];
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

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion {

    NSString *safeField = [self safeQuerySchemaField:schemaField];
    NSString *safeTable = [self safeIdentifier:schemaField.inTable.name];
    NSString *sql = [NSString stringWithFormat:@"SELECT DISTINCT %@ "
                                                @"%@ %@ "
                                                @"LIMIT 255;",
                                                safeField, MTSqlFrom, safeTable];
    NSArray *results = [[self resultsForQueryString:sql] retain];
    completion(YES, nil, [results autorelease]);
}

- (NSString *)sqlLimitClause {
    return [self isLicensedUser] ? @"" : @"\nLIMIT 50";
}

- (NSString *)identifier {
    return [MTDatabaseSqlite3 identifier];
}

+ (NSString *)identifier {
    return @"Sqlite 3";
}

- (id)connectionSettings {
    return [self databaseConnection];
}

@end
