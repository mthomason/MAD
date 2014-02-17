//
//  MNSDatabaseMySql.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

// FIXME: Add @try statements around MySQL calls.

#import "MTDatabaseMySql.h"

@interface MTDatabaseMySql ()

@property (readwrite, nonatomic, retain) MTDatabaseConnection *databaseConnection;

@end

@implementation MTDatabaseMySql
 
- (void)dealloc {
    [_databaseConnection release];
    [super dealloc];
}

- (id)initWithConnectionSettings: (MTDatabaseConnection *)connectionSettings {
    self = [super init];
    if (self) {
        MTDatabaseConnection *settings = [connectionSettings retain];
        [self setDatabaseConnection:settings];
        [settings release];
    }
    return self;
}

- (NSString *)selectPart {
    return @"SELECT\n";
}

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName {
    // FIXME: Use backticks `` to make more robust.
    return [[[NSString stringWithFormat:@"`%@`", fieldOrTableName] retain] autorelease];
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[queryField inQueryTable] queryAlias];
    NSString *fieldName = [[queryField databaseSchemaField] name];
    return [[[NSString stringWithFormat:@"`%@`.`%@`", queryTable, fieldName] retain] autorelease];
}

- (NSString *)safeQuerySchemaField:(RptqDatabaseSchemaField *)schemaField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[schemaField inTable] name];
    NSString *fieldName = [schemaField name];
    return [[[NSString stringWithFormat:@"`%@`.`%@`", queryTable, fieldName] retain] autorelease];
}

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    
    NSString *key = [MTKeyChain keyForServer:[[self databaseConnection] server] port:[[self databaseConnection] port] andDatabase:[[self databaseConnection] database]];
    [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *credentialsError, NSString *username, NSString *password, BOOL fromKeyChain) {
        
        if (success) {
            
            [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key shortCircuit:fromKeyChain completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
                
                __block MysqlServer *serv = [[MysqlServer alloc] init];
                
                [serv setUser:      username];
                [serv setPassword:  password];
                [serv setHost:      [[self databaseConnection] server]];
                [serv setPort:      [[self databaseConnection] port]];
                [serv setSchema:    [[self databaseConnection] database]];
                
                NSError *errorConnection = nil;
                MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&errorConnection];
                BOOL successConnection = conn != nil;
                if (successConnection) {
                    
                    MysqlFetch *fetch = [MysqlFetch fetchWithCommand:@"SHOW TABLES;" onConnection:conn];
                    
                    NSArray *fetchResults = [fetch results], *fetchFields = [fetch fields];
                    NSInteger resultsCount = [fetchResults count], fieldsCount = [fetchFields count];
                    
                    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
                    
                    if (fetch) {
                        if (fieldsCount > 0) {
                            MysqlFetchField *resultsTableName = [fetchFields objectAtIndex:0];
                            
                            for (NSDictionary *tableName in [fetch results]) {
                                
                                NSString *tableKey = [resultsTableName name];
                                NSString *tn = [tableName objectForKey:tableKey];
                                
                                MTDatabaseTable *databaseTable = [[MTDatabaseTable alloc] initWithTableName: tn];
                                [results addObject: databaseTable];
                                [databaseTable release];
                            }
                        }
                    }
                    completion(successConnection, errorConnection, [results autorelease]);
                } else {
                    [[MTKeyChain sharedObject] deleteKey:key];
                    completion(NO, errorConnection, nil);
                }
                
                [serv release];
            }];
            
        } else {
            completion(success, credentialsError, nil);
        }
    }];
}

- (NSString *)tableAliasConnector {
    return @" AS ";
}

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    
    
    __block MysqlServer *serv = [[MysqlServer alloc] init];
    
    [serv setHost:      [[self databaseConnection] server]];
    [serv setSchema:    [[self databaseConnection] database]];
    [serv setPort:      [[self databaseConnection] port]];
    
    NSString *key = [MTKeyChain keyForServer:[[self databaseConnection] server] port:[[self databaseConnection] port] andDatabase:[[self databaseConnection] database]];
    
    [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *credentialsError, NSString *username, NSString *password, BOOL fromKeyChain) {
        
        if (success) {
            
            [serv setUser:      username];
            [serv setPassword:  password];
            
            [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key shortCircuit:fromKeyChain completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
                
                NSError *errorConnection = nil;
                MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&errorConnection];
                
                NSMutableArray *results = nil;
                BOOL successConnection = conn != nil;
                
                NSMutableDictionary *resultsDictionary = nil;
                
                if (successConnection) {
                    NSString *command = [NSString stringWithFormat:@"SHOW COLUMNS FROM %@;", [table name]];
                    MysqlFetch *fetch = [MysqlFetch fetchWithCommand:command onConnection:conn];
                    if (fetch) {
                        if ([[fetch fields] count] > 0) {
                            
                            MysqlFetchField *fieldMetaData = [[fetch fields] objectAtIndex:0];
                            results = [[NSMutableArray alloc] initWithCapacity: [[fetch results] count]];
                            resultsDictionary = [[NSMutableDictionary alloc] initWithCapacity:[[fetch results] count]];
                            
                            for (NSDictionary *field in [fetch results]) {
                                NSString *fieldName = [field objectForKey:[fieldMetaData name]];
                                
                                MTDatabaseField *databaseField = [[MTDatabaseField alloc] initWithName: fieldName];
                                //[databaseField setDatatype:[field objectForKey:@"Type"]];
                                [results addObject: databaseField];
                                [resultsDictionary setObject:databaseField forKey:fieldName];
                                [databaseField release];
                            }
                        }
                    }
                    
                    NSString *command2 = [NSString stringWithFormat:@"SELECT * FROM %@ LIMIT 0;", [table name]];
                    MysqlFetch *fetch2 = [MysqlFetch fetchWithCommand:command2 onConnection:conn];
                    if (fetch) {
                        
                        if ([[fetch2 fields] count] > 0) {
                            
                            for (MysqlFetchField *field in [fetch2 fields]) {
                                
                                MTDataType dataType = [MTDatabaseMySql dataTypeForNativeType:[field fieldType]];
                                NSString *fieldNameKey = [field name];
                                NSArray *fieldNameParts = [fieldNameKey componentsSeparatedByString:@"."];
                                NSString *fieldNameKeyLastPart = [fieldNameParts lastObject];
                                NSString *fieldName = [fieldNameKeyLastPart stringByReplacingOccurrencesOfString:@"`" withString:@""];
                                MTDatabaseField *databaseField = [[resultsDictionary objectForKey:fieldName] retain];
                                [databaseField setFieldTypeNative:[field fieldType]];
                                [databaseField setFieldType:dataType];
                                [databaseField setWidth:[field width]];
                                [databaseField setDecimals:[field decimals]];
                                [databaseField setPrimaryKey:[field primaryKey]];
                                [databaseField release];
                            }
                        }
                    }
                } else {
                    [[MTKeyChain sharedObject] deleteKey:key];
                    [error presentErrorToUser];
                }
                [serv release];
                
                [results release];
                NSArray *resultsArray = [[resultsDictionary allValues] retain];
                [resultsDictionary release];
                
                completion(successConnection, errorConnection, [resultsArray autorelease]);
                
            }];
            
        } else {
            completion(success, credentialsError, nil);
        }
    }];
}

+ (MTDataType)dataTypeForNativeType:(NSInteger)nativeType {
    MTDataType result;
    switch (nativeType) {
        //case MAX_NO_FIELD_TYPES:
        //    result = MTDataTypeString;
        //    break;
        case MYSQL_TYPE_BIT:
            result = MTDataTypeBit;
            break;
        case MYSQL_TYPE_BLOB:
            result = MTDataTypeBlob;
            break;
        case MYSQL_TYPE_DATE:
            result = MTDataTypeDate;
            break;
        case MYSQL_TYPE_DATETIME:
            result = MTDataTypeDateTime;
            break;
        case MYSQL_TYPE_DECIMAL:
            result = MTDataTypeDecimal;
            break;
        case MYSQL_TYPE_DOUBLE:
            result = MTDataTypeDouble;
            break;
        case MYSQL_TYPE_ENUM:
            result = MTDataTypeEnum;
            break;
        case MYSQL_TYPE_FLOAT:
            result = MTDataTypeFloat;
            break;
        case MYSQL_TYPE_GEOMETRY:
            result = MTDataTypeGeometry;
            break;
        case MYSQL_TYPE_INT24:
            result = MTDataTypeInteger;
            break;
        case MYSQL_TYPE_LONG:
            result = MTDataTypeLong;
            break;
        case MYSQL_TYPE_LONG_BLOB:
            result = MTDataTypeBlob;
            break;
        case MYSQL_TYPE_LONGLONG:
            result = MTDataTypeLongLong;
            break;
        case MYSQL_TYPE_MEDIUM_BLOB:
            result = MTDataTypeBlob;
            break;
        case MYSQL_TYPE_NEWDATE:
            result = MTDataTypeDate;
            break;
        case MYSQL_TYPE_NEWDECIMAL:
            result = MTDataTypeDecimal;
            break;
        case MYSQL_TYPE_NULL:
            result = MTDataTypeNumber;
            break;
        case MYSQL_TYPE_SET:
            result = MTDataTypeSet;
            break;
        case MYSQL_TYPE_SHORT:
            result = MTDataTypeShort;
            break;
        case MYSQL_TYPE_STRING:
            result = MTDataTypeString;
            break;
        case MYSQL_TYPE_TIME:
            result = MTDataTypeDateTime;
            break;
        case MYSQL_TYPE_TIMESTAMP:
            result = MTDataTypeTimeStamp;
            break;
        case MYSQL_TYPE_TINY:
            result = MTDataTypeShort;
            break;
        case MYSQL_TYPE_TINY_BLOB:
            result = MTDataTypeBlob;
            break;
        case MYSQL_TYPE_VAR_STRING:
            result = MTDataTypeVarChar;
            break;
        case MYSQL_TYPE_VARCHAR:
             result = MTDataTypeVarChar;
            break;
        case MYSQL_TYPE_YEAR:
            result = MTDataTypeYear;
            break;
        default:
            result = MTDataTypeString;
            break;
    }
    return result;
}

- (void)cacheReportQueryForDocument:(RptqDocument *)document
                                     completion:(void (^)(MTDatabase *database, RptqQueryCache *cache))completion {
    
    @autoreleasepool {
        
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        RptqQuery *rquery = [[database hasQueries] anyObject];
        MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
        NSString *queryString = [mnsDatabase getSqlForQuery:rquery];
        
        
        RptqQuery *query = [[database hasQueries] anyObject];
        
        __block MysqlServer *serv = [[MysqlServer alloc] init];
        
        [serv setHost:      [[self databaseConnection] server]];
        [serv setSchema:    [[self databaseConnection] database]];
        [serv setPort:      [[self databaseConnection] port]];
        
        NSString *key = [MTKeyChain keyForServer:[[self databaseConnection] server] port:[[self databaseConnection] port] andDatabase:[[self databaseConnection] database]];
        [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain) {
            
            if (success) {
                [serv setUser:      username];
                [serv setPassword:  password];
                
                [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key shortCircuit:fromKeyChain completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
                    
                    @try
                    {
                        NSError *connError = nil;
                        MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&connError];
                        if (conn && connError == nil) {
                            
                            @autoreleasepool {
                                //__block NSString *s = @"Select LSJDF FROM LDSJFLKJSDF.sDSF sLj;";
                                MysqlFetch *fetch = [MysqlFetch fetchWithCommand:queryString onConnection:conn extendedNames:YES];
                                NSManagedObjectContext *managedObjectContext = [document managedObjectContext];
                                RptqQueryCache *queryCache = [RptqQueryCache initObjectForManagedObjectContext:managedObjectContext];
                                
                                id queryResults = [[fetch results] retain];
                                [[self delegateCacheData] cacheQueryResult:queryResults];
                                [queryResults release];

                                [queryCache setCacheDate:[NSDate date]];
                                [query setHasQueryCache:queryCache];
                            }
                            
                        } else {
                            [connError presentErrorToUser];
                            [[MTKeyChain sharedObject] deleteKey:key];
                        }
                        
                        
                        completion(self, [query hasQueryCache]);
                    }
                    @catch(NSException *ex)
                    {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ex.name message:ex.reason delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
                        [alertView show];
                        [alertView release];
                        completion(nil, nil);
                    }
                }];
            } else {
                completion(nil, nil);
            }
            
        }];
        [serv release];
    }
}

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion {
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            __block MysqlFetch *fetch = nil;
            
            __block MysqlServer *serv = [[MysqlServer alloc] init];
            
            [serv setHost:      [[self databaseConnection] server]];
            [serv setSchema:    [[self databaseConnection] database]];
            [serv setPort:      [[self databaseConnection] port]];
            
            NSString *server = [[self databaseConnection] server];
            NSString *database = [[self databaseConnection] database];
            NSInteger port = [[self databaseConnection] port];

            NSString *key = [MTKeyChain keyForServer:server port:port andDatabase:database];
            [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain) {
                if (success) {
                    [serv setUser:      username];
                    [serv setPassword:  password];
                    [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key shortCircuit:fromKeyChain completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {

                        NSArray *results = nil;
                        NSError *connError = nil;
                        MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&connError];
                        BOOL successConnection = conn != nil;
                        if (successConnection) {
                            NSString *safeField = [self safeQuerySchemaField:schemaField];
                            NSString *safeTable = [self safeIdentifier:schemaField.inTable.name];
                            NSString *sql = [NSString stringWithFormat:@"SELECT DISTINCT %@ "
                                                                        @"%@ %@ "
                                                                        @"LIMIT 100;",
                                                                        safeField, MTSqlFrom, safeTable];
                            fetch = [[[MysqlFetch fetchWithCommand:sql onConnection:conn] retain] autorelease];
                            results = [[fetch results] retain];
                        } else {
                            [[MTKeyChain sharedObject] deleteKey:key];
                        }
                        [serv release];
                        completion(successConnection, connError, [results autorelease]);
                    }];
                } else {
                    completion(success, error, nil);
                }
            }];
        });
    });

}

- (NSString *)sqlLimitClause {
    return [self isLicensedUser] ? @"" : @"\nLIMIT 50";
}

- (NSString *)identifier {
    return [MTDatabaseMySql identifier];
}

+ (NSString *)identifier {
    return @"MySQL";
}

- (id)connectionSettings {
    return [self databaseConnection];
}

@end
