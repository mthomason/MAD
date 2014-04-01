//
//  MNSDatabase.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabase.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlite3.h"
#import "MTDatabaseSqlServer.h"
#import "MTDatabaseConnection.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqUserCredentals.h"
#import "RptqDocumentObjectBarcode.h"
#import "MTDatabaseTable.h"
#import "MTStoreKitController.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryField.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryCache.h"
#import "MTKeyChain.h"

NSString * const MTSqlFrom = @"\nFROM\n";

@interface MTDatabase ()

@property (nonatomic, assign, readwrite) BOOL isLicensedUser;

@end

@implementation MTDatabase

+ (id)databaseFactory:(MTDatabaseConnection *)connection {

    NSString *identifier = [connection databaseTypeIdentifier];
    
    id result = nil;
    if ([[MTDatabaseMySql identifier] isEqualToString:identifier]) {
        
        result = [[MTDatabaseMySql alloc] init];
        
    } else if ([[MTDatabaseSqlServer identifier] isEqualToString:identifier]) {
        
        result = [[MTDatabaseSqlServer alloc] init];
        
    } else if ([[MTDatabaseSqlite3 identifier] isEqualToString:identifier]) {
        
        result = [[MTDatabaseSqlite3 alloc] init];
    }
    
    [result setDatabaseConnection:connection];
    
    if ([result respondsToSelector:@selector(openDatabase)]) {
        [result openDatabase];
    }
    
    return result;
}

- (void)getCredentalsWithConnection:(MTDatabaseConnection *)connection completion:(void (^)(BOOL success, NSError *error, NSString *username, NSString *password))completion {
    
    NSString *key = [connection connectionString];
    [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *connectionError, NSString *username, NSString *password, BOOL fromKeyChain) {
        
        if (success) {
            
            [[MTKeyChain sharedObject] saveUsername:username
                                        andPassword:password
                                             forKey:key
                                       shortCircuit:fromKeyChain
                                         completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
                completion(success, error, username, password);
            }];
            
        } else {
            completion(NO, connectionError, username, password);
        }
        
    }];
    
}

- (void)connectWithCredentals:(MTDatabaseConnection *)connection completion:(void (^)(id dbconn, BOOL success, NSError *error))completion {
    completion(nil, YES, nil);
}

- (void)executeSql:(NSString *)sql
        completion:(void (^)(BOOL success, NSError *error, id results))completion {
    
    NSString *message = @"Only call this on subclasses.";
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
    NSError *error = [NSError errorWithDomain:@"MTDatabase" code:484 userInfo:errorInfo];
    completion(NO, error, nil);
}

+ (NSString *)safeQueryField:(RptqQueryField *)queryField {
    return [MTDatabase safeQueryField:queryField];
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    return @"";
}

- (NSString *)safeIdentifier:(NSString *)s {
    return s;
}

- (NSString *)safeQuerySchemaField:(RptqDatabaseSchemaField *)schemaField {
    NSString *queryTable = [[schemaField inTable] name];
    NSString *fieldName = [schemaField name];
    return [NSString stringWithFormat:@"%@.%@", queryTable, fieldName];
}

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)getFieldsForTableName: (NSString *)tableName
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)maxLengthForFields:(NSArray *)fields inTable:(NSString *)tableName
                completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    NSArray *emptyResults = [NSArray array];
    completion(YES, nil, emptyResults);
}

- (NSString *)tableAliasForTable:(RptqDatabaseSchemaTable *)table {
    return [self safeIdentifier: [table toString]];
}
- (NSString *)fieldAliasForField:(RptqDatabaseSchemaField *)field
               withSafeTableName:(NSString *)safeTableName {
    NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
    NSString *fieldName = [self safeIdentifier: [field name]];
    return [tableAlias stringByAppendingString:fieldName];
}

- (NSString *)sqlAllFieldsInTable:(RptqDatabaseSchemaTable *)schemaTable {
    NSUInteger *fieldCounter = 0;
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    NSString *safeTableName = [self tableAliasForTable:schemaTable];
    
    for (RptqDatabaseSchemaField *field in [schemaTable hasFields]) {
        
        NSString *fieldAlias = [self fieldAliasForField:field withSafeTableName:safeTableName];

        if (fieldCounter > 0)  [sql appendString:@",\n"];
        [sql appendFormat: @"\t%@", fieldAlias];
        
        fieldCounter++;
    }
    return sql;
}

- (NSString *)tableAliasConnector {
    return @" AS ";
}

- (NSString *)identifier {
    return [MTDatabase identifier];
}

+ (NSString *)identifier {
    return @"NONE";
}

- (NSString *)selectPart {
    return @"SELECT\n";
}

- (BOOL)isReachable {
    return NO;
}

- (void)removeCredentalsBecauseOfError:(NSError *)error {
    NSString *key = [[self databaseConnection] connectionString];
    [[MTKeyChain sharedObject] deleteKey:key];
    [error presentErrorToUser];
}

@end
