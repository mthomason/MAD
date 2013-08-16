//
//  MNSDatabaseMySql.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

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
        [self setDatabaseConnection:connectionSettings];
    }
    return self;
}

- (NSString *)selectPart {
    return @"SELECT\n";
}

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    
    
    __block MysqlServer *serv = [[MysqlServer alloc] init];
    
    [serv setHost:      [[self databaseConnection] server]];
    [serv setPort:      [[self databaseConnection] port]];
    [serv setSchema:    [[self databaseConnection] database]];
    
    NSString *key = [NSString stringWithFormat:@"[%@:%d]%@", [[self databaseConnection] server],  [[self databaseConnection] port], [[self databaseConnection] database]];
    [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *credentialsError, NSString *username, NSString *password, BOOL fromKeyChain) {
        
        dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queuePriorityBackground, ^{
            
            if (success) {
                
                [serv setUser:      username];
                [serv setPassword:  password];
                
                NSError *error = nil;
                MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&error];
                NSMutableArray *results = nil;
                BOOL success = conn != nil;
                
                if (success) {
                    MysqlFetch *fetch = [MysqlFetch fetchWithCommand:@"SHOW TABLES;" onConnection:conn];
                    if (fetch) {
                        if ([[fetch fields] count] > 0) {
                            if (!fromKeyChain) {
                                dispatch_semaphore_t semaphoreSaveCredentials = dispatch_semaphore_create(0);
                                dispatch_sync(dispatch_get_main_queue(), ^{
                                    [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key completion:^(BOOL success, NSError *error) {
                                        dispatch_semaphore_signal(semaphoreSaveCredentials);
                                    }];
                                });
                                dispatch_semaphore_wait(semaphoreSaveCredentials, DISPATCH_TIME_FOREVER);
                                dispatch_release(semaphoreSaveCredentials);
                                
                            }
                            
                            MysqlFetchField *resultsTableName = [[fetch fields] objectAtIndex:0];
                            results = [[NSMutableArray alloc] initWithCapacity: [[fetch results] count]];
                            
                            for (NSDictionary *tableName in [fetch results]) {
                                NSString *tn = [tableName objectForKey:[resultsTableName name]];
                                MTDatabaseTable *databaseTable = [[MTDatabaseTable alloc] initWithTableName: tn];
                                [results addObject: databaseTable];
                                [databaseTable release];
                            }
                        }
                    }
                }
                [serv release];
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completion(success, error, results);
                });
                
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completion(success, credentialsError, nil);
                });
            }
        });
    }];
}

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
            
            __block MysqlServer *serv = [[MysqlServer alloc] init];
            
            [serv setHost:      [[self databaseConnection] server]];
            [serv setSchema:    [[self databaseConnection] database]];
            [serv setPort:      [[self databaseConnection] port]];
            
            NSString *key = [NSString stringWithFormat:@"[%@:%d]%@", [[self databaseConnection] server],  [[self databaseConnection] port], [[self databaseConnection] database]];
            [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *credentialsError, NSString *username, NSString *password, BOOL fromKeyChain) {
                
                if (success) {
                    
                    [serv setUser:      username];
                    [serv setPassword:  password];
                    
                    NSError *error = nil;
                    MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&error];
                    
                    NSMutableArray *results = nil;
                    BOOL success = conn != nil;
                    
                    NSMutableDictionary *resultsDictionary = nil;
                    
                    if (success) {
                        if (!fromKeyChain) {
                            dispatch_semaphore_t semaphoreSaveCredentials = dispatch_semaphore_create(0);
                            [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key completion:^(BOOL success, NSError *error) {
                                
                                dispatch_semaphore_signal(semaphoreSaveCredentials);
                            }];
                            dispatch_semaphore_wait(semaphoreSaveCredentials, DISPATCH_TIME_FOREVER);
                            dispatch_release(semaphoreSaveCredentials);
                        }
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
                            //NSLog(@"Fetch %@", fetch);
                            if ([[fetch2 fields] count] > 0) {
                                
                                for (MysqlFetchField *field in [fetch2 fields]) {
                                    
                                    MTDatabaseField *databaseField = [[resultsDictionary objectForKey:[field name]] retain];
                                    [databaseField setFieldTypeNative:[field fieldType]];
                                    [databaseField setFieldType:[self dataTypeForNativeType:[field fieldType]]];
                                    [databaseField setWidth:[field width]];
                                    [databaseField setDecimals:[field decimals]];
                                    [databaseField setPrimaryKey:[field primaryKey]];
                                    [databaseField release];
                                }
                            }
                        }
                    } else {
                        [error presentErrorToUser];
                    }
                    [serv release];
                    
                    [results release];
                    NSArray *resultsArray = [[resultsDictionary allValues] retain];
                    [resultsDictionary release];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(success, error, [resultsArray autorelease]);
                    });
                    
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(success, credentialsError, nil);
                    });
                }
            }];
    });
}

- (MTDataType)dataTypeForNativeType:(NSInteger)nativeType {
    MTDataType result;
    switch (nativeType) {
        case MAX_NO_FIELD_TYPES:
            result = MTDataTypeString;
            break;
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

- (void)cacheReportQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                     completion:(void (^)(MTDatabase *database, RptqQueryCache *cache))completion {
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *rquery = [[database hasQueries] anyObject];
    MTDatabase *mnsDatabase = [MTDatabase databaseForRptqDatabase: database];
    NSString *queryString = [mnsDatabase getSqlForQuery:rquery];

    __block RptqQueryCache *queryCache = nil;
    RptqQuery *query = [[database hasQueries] anyObject];

    __block MysqlServer *serv = [[MysqlServer alloc] init];
        
    [serv setHost:      [[self databaseConnection] server]];
    [serv setSchema:    [[self databaseConnection] database]];
    [serv setPort:      [[self databaseConnection] port]];
    
    NSString *key = [NSString stringWithFormat:@"[%@:%d]%@", [[self databaseConnection] server],  [[self databaseConnection] port], [[self databaseConnection] database]];
    [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain) {
        
        if (success) {
            [serv setUser:      username];
            [serv setPassword:  password];

            NSError *connError = nil;
            MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&connError];
            if (conn && connError == nil) {
                if (!fromKeyChain) {
                    dispatch_semaphore_t semaphoreSaveCredentials = dispatch_semaphore_create(0);
                    [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key completion:^(BOOL success, NSError *error) {
                        
                        dispatch_semaphore_signal(semaphoreSaveCredentials);
                    }];
                    dispatch_semaphore_wait(semaphoreSaveCredentials, DISPATCH_TIME_FOREVER);
                    dispatch_release(semaphoreSaveCredentials);
                }
                MysqlFetch *fetch = [MysqlFetch fetchWithCommand:queryString onConnection:conn extendedNames:YES];
                queryCache = [RptqQueryCache initObjectForManagedObjectContext:managedObjectContext];
                
                NSData *cachedData = [NSPropertyListSerialization dataWithPropertyList:[fetch results]
                                                                                format:NSPropertyListBinaryFormat_v1_0
                                                                               options:0
                                                                                 error:NULL];
                
                NSString *name = [[[MTActiveDocument sharedDocument] activeDocument] name];
                NSURL *url = [[NSFileManager  localTemporaryDirectory] URLByAppendingPathComponent:name isDirectory:NO];
                [cachedData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&connError];
                if (connError) {
                    connError = nil;
                    [cachedData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&connError];
                }
                [queryCache setCacheDate:[NSDate date]];
                [query setHasQueryCache:queryCache];
                
            } else {
                [connError presentErrorToUser];
            }
            
            [serv release];
            
            completion(self, [query hasQueryCache]);
            
        } else {
            completion(nil, nil);
        }
    }];
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
            
            NSString *key = [NSString stringWithFormat:@"[%@:%d]%@", [[self databaseConnection] server],  [[self databaseConnection] port], [[self databaseConnection] database]];
            [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *error, NSString *username, NSString *password, BOOL fromKeyChain) {
                NSArray *results = nil;
                if (success) {
                    [serv setUser:      username];
                    [serv setPassword:  password];
                    
                    NSError *connError = nil;
                    MysqlConnection *conn = [MysqlConnection connectToServer: serv error:&connError];
                    BOOL success = conn != nil;
                    if (success) {
                        if (!fromKeyChain) {
                            dispatch_semaphore_t semaphoreSaveCredentials = dispatch_semaphore_create(0);
                            [[MTKeyChain sharedObject] saveUsername:username andPassword:password forKey:key completion:^(BOOL success, NSError *error) {
                                
                                dispatch_semaphore_signal(semaphoreSaveCredentials);
                            }];
                            dispatch_semaphore_wait(semaphoreSaveCredentials, DISPATCH_TIME_FOREVER);
                            dispatch_release(semaphoreSaveCredentials);
                        }
                        NSString *sql = [NSString stringWithFormat:@"SELECT %@ "
                                         @"%@ %@ "
                                         @"LIMIT 100;",
                                         schemaField.name, MTSqlFrom, schemaField.inTable.name];
                        fetch = [[[MysqlFetch fetchWithCommand:sql onConnection:conn] retain] autorelease];
                        results = [[fetch results] retain];
                    }
                    [serv release];
                    completion(success, connError, [results autorelease]);
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
