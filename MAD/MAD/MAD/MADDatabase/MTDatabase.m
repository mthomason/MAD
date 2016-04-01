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
#import "MADNotificationDidReadRows.h"
#import "MADCredential.h"
#import "MADErrorUserInfo.h"


NSString * const MADSqlTextFromPart = @"\nFROM\n";
NSString * const MADSqlSqlite3SelectPart = @"SELECT\n";
NSString * const MADSqlSqlite3Identifier = @"NONE";
NSString * const MADSqlSqlite3TableAliasConnector = @" AS ";

@interface MTDatabase ()

@end

@implementation MTDatabase

- (id)init {
    if (self = [super init]) {
        NSMutableArray *errors = [[NSMutableArray alloc] init];
        self.errors = errors;
    }
    return self;
}

+ (instancetype)newDatabaseWithConnection:(MTDatabaseConnection *)connection NS_RETURNS_RETAINED {
    
    id result = nil;
    
    if ([MADIdentifierDatabaseMySQL isEqualToString:connection.databaseTypeIdentifier]) {
        
        result = [[MTDatabaseMySql alloc] init];
        
    } else if ([MADIdentifierDatabaseTDS isEqualToString:connection.databaseTypeIdentifier]) {
        
        result = [[MTDatabaseSqlServer alloc] init];
        
    } else if ([MADIdentifierDatabaseSqlite3 isEqualToString:connection.databaseTypeIdentifier]) {
        
        result = [[MTDatabaseSqlite3 alloc] init];
    }
    
    [result setDatabaseConnection:connection];
    
    if ([result respondsToSelector:@selector(openDatabase)]) {
        [result openDatabase];
    }
    
    return result;
}

- (MADCredential *)getCredentalsWithConnection:(MTDatabaseConnection *)connection {
    NSString *key = [connection connectionString];
    bool responds = [self.delegate respondsToSelector:@selector(getCredentialsForKey:)];
    MADCredential *results = nil;
    if (responds) {
        MADCredential *c = [self.delegate getCredentialsForKey:key];
        if (c) {
            results = c.copy;
        }
        
    }
    return results;
}

- (BOOL)executeQuery:(MTQuery *)query withError:(NSError * __autoreleasing *)error {
    if (error != NULL) {
        NSString *title = @"Abstract function.";
        NSString *message = @"Don't go there.";
        MADErrorUserInfo *errorUserInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
        *error = [errorUserInfo errorWithDomain:@"MTDatabase" code:3190];
    }
    return NO;
}

- (id)connectWithConnection:(MTDatabaseConnection *)connection credentals:(MADCredential *)credentals {
    return nil;
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
    NSString * __autoreleasing alias = [tableAlias stringByAppendingString:fieldName];
    return alias;
}

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSArray *)fieldsForTable:(NSString *)tableName connection:(id)dbconn error:(NSError *__autoreleasing *)error {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)tableAliasForTable:(NSString *)table {
    return [self safeIdentifier: table];
}

- (NSString *)tableAliasConnector {
    return MADSqlSqlite3TableAliasConnector;
}

- (NSString *)identifier {
    return MADSqlSqlite3Identifier;
}

+ (NSString *)identifier {
    return MADSqlSqlite3Identifier;
}

- (NSString *)selectPart {
    return MADSqlSqlite3SelectPart;
}

- (NSString *)selectPartWithLimitedResults:(NSInteger)limit {   //Generally limited resuls are in a LIMIT part, but
    return MADSqlSqlite3SelectPart;                                   //  SQL Server uses the TOP part (not default here).
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

static NSString * const MADTextSqlSelectSampleDataForField = @"%@ DISTINCT "
                                                @"%@ %@ %@ "
                                                @"%@ %@ "
                                                @"LIMIT 511;";

- (NSString *)sqlSampleDataForField:(NSString *)fieldName andTable:(NSString *)tableName {
    NSString *safeField = [self safeQueryField: fieldName
                                      andTable: tableName];
    NSString *safeFieldAlias = [self fieldAliasForField: fieldName
                                           andTableName: tableName];
    NSString *safeTable = [self safeIdentifier:tableName];

    NSString *selectPart = [self selectPart];
    NSString *tableAliasConnector = [self tableAliasConnector];
    return [NSString stringWithFormat:MADTextSqlSelectSampleDataForField,
                                                    selectPart, safeField, tableAliasConnector,
                                                    safeFieldAlias, MADSqlTextFromPart, safeTable];
}

- (NSString *)nativeTypeForDataType:(MTDataType)dataType {
    return @"";
}

- (void)readRow:(NSUInteger)row {
    [[MADNotificationDidReadRows sharedObject] database:self readRow:row];
}

- (void)closeProcess:(id)process {}

- (NSArray <MTDatabaseTable *> *)getTablesFromConnection:(id)dbconn error:(NSError *__autoreleasing *)error {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)getTablesFromConnection:(id)process completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)enumerateTablesFromConnection:(id)dbconn
                           usingBlock:(void (^)(MTDatabaseTable *obj, NSUInteger index, BOOL *stop))block
                           completion:(void (^)(BOOL success, NSError *error, NSArray *results))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

@end
