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
#import "MTKeyChain.h"
#import "MTNotificationDidReadRows.h"
#import "MADCredential.h"
//#import "MADKeyChainGetCredentials.h"

NSString * const MTSqlFrom = @"\nFROM\n";

@interface MTDatabase ()

@property (nonatomic, assign, readwrite) BOOL isLicensedUser;

@end

@implementation MTDatabase

- (id)init {
    if (self = [super init]) {
        NSMutableArray *errors = [[NSMutableArray alloc] init];
        self.errors = errors;
    }
    return self;
}

+ (instancetype)databaseFactory:(MTDatabaseConnection *)connection NS_RETURNS_RETAINED {

    NSString *identifier = [connection databaseTypeIdentifier];
    
    id result = nil;
    
    if ([MADIdentifierDatabaseMySQL isEqualToString:identifier]) {
        
        result = [[MTDatabaseMySql alloc] init];
        
    } else if ([MADIdentifierDatabaseTDS isEqualToString:identifier]) {
        
        result = [[MTDatabaseSqlServer alloc] init];
        
    } else if ([MADIdentifierDatabaseSqlite3 isEqualToString:identifier]) {
        
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
    if (![self.delegate respondsToSelector:@selector(getCredentialsForDatabase:andKey:)]) {
        completion(NO, nil, nil, nil);
    }
    
    MADCredential *c = [self.delegate getCredentialsForDatabase:self andKey:key];
    if (c) {
        completion(YES, nil, c.username, c.password);
    } else {
        completion(NO, nil, nil, nil);
    }
    
    [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *connectionError, NSString *username, NSString *password, BOOL fromKeyChain) {
        
        if (success) {
            
            [[MTKeyChain sharedObject] saveUsername: username
                                        andPassword: password
                                             forKey: key
                                       shortCircuit: fromKeyChain
                                         completion: ^(BOOL success, NSError *error, NSString *username, NSString *password) {
                                             completion(success, error, username, password);
                                         }];
            
        } else {
            completion(NO, connectionError, username, password);
        }
        
    }];
}

- (MADCredential *)getCredentalsWithConnection:(MTDatabaseConnection *)connection {
    
    //completion:(void (^)(BOOL success, NSError *error, NSString *username, NSString *password))completion {
    
    //get credientials
        //credientals are empty prompt for credientials
        //save credientials
    
    
    NSString *key = [connection connectionString];
    [[MTKeyChain sharedObject] getUsernameAndPasswordForKey:key completion:^(BOOL success, NSError *connectionError, NSString *username, NSString *password, BOOL fromKeyChain) {
        
        if (success) {
            
            [[MTKeyChain sharedObject] saveUsername:username
                                        andPassword:password
                                             forKey:key
                                       shortCircuit:fromKeyChain
                                         completion:^(BOOL success, NSError *error, NSString *username, NSString *password) {
                //completion(success, error, username, password);
            }];
            
        } else {
            //completion(NO, connectionError, username, password);
        }
        
    }];
// FIXME: ... sould return something
    return nil;
}

- (void)executeQuery:(MTQuery *)query completion:(void (^)(BOOL, NSError *))completion {
    completion(NO, nil);
}

- (void)connectWithCredentals:(MTDatabaseConnection *)connection completion:(void (^)(id dbconn, BOOL success, NSError *error))completion {
    completion(nil, YES, nil);
}

+ (NSString *)safeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    return [NSString stringWithFormat:@"%@.%@", tableName, fieldName];
}

- (NSString *)safeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    return [MTDatabase safeQueryField:fieldName andTable:tableName];
}

- (NSString *)safeIdentifier:(NSString *)s {
    return s;
}

- (void *)databaseHandle {
    return NULL;
}

- (NSString *)fieldAliasForField:(NSString *)fieldName
                    andTableName:(NSString *)tableName {
    NSString *fieldAlias = [fieldName stringByAppendingString:tableName];
    return [self safeIdentifier:fieldAlias];
}

- (NSString *)fieldAliasForField:(NSString *)field
               withSafeTableName:(NSString *)safeTableName {
    NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
    NSString *fieldName = [self safeIdentifier: field];
    return [tableAlias stringByAppendingString:fieldName];
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

- (NSString *)tableAliasForTable:(NSString *)table {
    return [self safeIdentifier: table];
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

- (NSString *)selectPartWithLimitedResults:(NSInteger)limit {   //Generally limited resuls are in a LIMIT part, but
    return [self selectPart];                                   //  SQL Server uses the TOP part (not default here).
}

- (NSString *)sqlLimitClause {
    return [self sqlLimitClause:  NSNotFound];                    //No limit by default
}

- (NSString *)sqlLimitClause:(NSInteger)limit {
    return (limit > 0 && limit != NSNotFound) ?
                [NSString stringWithFormat: @"\nLIMIT %ld", (long)limit] : @"";
}

- (NSString *)sqlAggregateFunctionLength {
    return @"LENGTH";
}

- (NSString *)sqlAggregateFunctionMax {
    return @"MAX";
}

- (NSString *)sqlSampleDataForField:(NSString *)fieldName andTable:(NSString *)tableName {
    NSString *safeField = [self safeQueryField: fieldName
                                      andTable: tableName];
    NSString *safeFieldAlias = [self fieldAliasForField: fieldName
                                           andTableName: tableName];
    NSString *safeTable = [self safeIdentifier:tableName];
    return [NSString stringWithFormat:@"%@ DISTINCT "
                                                    @"%@ %@ %@ "
                                                    @"%@ %@ "
                                                    @"LIMIT 511;",
                                                    [self selectPart],
                                                    safeField,
                                                    [self tableAliasConnector],
                                                    safeFieldAlias,
                                                    MTSqlFrom,
                                                    safeTable];
}

- (NSString *)nativeTypeForDataType:(MTDataType)dataType {
    return @"";
}

- (void)readRow:(NSUInteger)row {
    [[MTNotificationDidReadRows sharedObject] database:self readRow:row];
}

- (void)closeProcess:(id)process {}

- (void)getTablesFromConnection:(id)process completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    NSError *error = [NSError errorWithDomain:@"MTDatabase" code:383414 userInfo:@{}];
    completion(NO, error, nil);
}

- (void)getFieldsForTableName:(NSString *)tableName connection:(id)dbconn completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    NSError *error = [NSError errorWithDomain:@"MTDatabase" code:382428 userInfo:@{}];
    completion(NO, error, nil);
}

@end
