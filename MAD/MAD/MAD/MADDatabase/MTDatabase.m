//
//  MNSDatabase.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabase.h"
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>

#import <MADFoundation/NSString+Common.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADErrorUserInfo.h>

#import "MADDataTable.h"

#import "MADDatabaseConnection.h"
#import "MADNotificationDidReadRows.h"
#import "MADDatabaseResultsProtocol.h"

NSString * const MADSqlTextFromPart = @"\nFROM\n";

static NSString * const MADTextSqlSelectSampleDataForField = @"%@ DISTINCT "
                                                                @"%@ %@ %@ "
                                                                @"%@ %@ "
                                                                @"LIMIT 511;";

@implementation MTDatabase

- (instancetype)init {
    if (self = [super init]) {
        NSMutableArray *errors = [[NSMutableArray alloc] init];
        self.errors = errors;
    }
    return self;
}

- (MADCredential *)credentalsWithConnection:(MADDatabaseConnection *)connection {
    NSString *key = [connection connectionString];
    id <MADDatabaseResultsProtocol> delegate = _delegate;
    BOOL responds = [delegate respondsToSelector:@selector(getCredentialsForKey:)];
    MADCredential *results = nil;
    if (responds) {
        MADCredential *c = [delegate getCredentialsForKey:key];
        if (c) {
            results = c.copy;
        }
        
    }
    return results;
}

- (BOOL)executeQuery:(MTQuery *)query withDataTable:(MADDataTable *)dataTable
            andError:(NSError * __autoreleasing *)error {
    NSString *reason;
    NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
    reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: reason
                                 userInfo: nil];
}

- (BOOL)executeQuery:(MTQuery *)query withError:(NSError * __autoreleasing *)error {
    NSString *reason;
    NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
    reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: reason
                                 userInfo: nil];
}

- (id)connectWithConnection:(MADDatabaseConnection *)connection credentals:(MADCredential *)credentals
            connectionError:(NSError * __autoreleasing *)error {
    return nil;
}

+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    NSString *result = [tableName stringByAppendingPeriod];
    return [result stringByAppendingString:fieldName];
}

- (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
    id safeField = [MTDatabase newSafeQueryField:fieldName andTable:tableName];
    return safeField;
}

+ (MADSafeQueryField *)newSafeIdentifier:(NSString *)s {
    id result = [[MADSafeQueryField alloc] initWithString: s];
    return result;
}

- (MADSafeQueryField *)newSafeIdentifier:(NSString *)s {
    id result = s.copy;
    return result;
}

- (void *)databaseHandle {
    return NULL;
}

- (MADSafeQueryField *)fieldAliasForField:(NSString *)fieldName
                             andTableName:(NSString *)tableName {
    NSString *fieldAlias;
    if (fieldName.length && tableName.length) {
        fieldAlias = [fieldName stringByAppendingPeriod];
        fieldAlias = [fieldAlias stringByAppendingString:tableName];
    } else {
        fieldAlias = [fieldName stringByAppendingString:tableName];
    }
    //NSString *result = [self newSafeIdentifier:fieldAlias];
    return fieldAlias;
}

- (NSString *)fieldAliasForField:(NSString *)field
               withSafeTableName:(NSString *)safeTableName {
    NSString *tableAlias = [safeTableName stringByAppendingPeriod];
    MADSafeQueryField *fieldName = [self newSafeIdentifier: field];
    NSString * __autoreleasing alias = [tableAlias stringByAppendingString:fieldName];
    return alias;
}

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray <MADDatabaseTable *> *tables))completion {
    NSString *reason;
    NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
    reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: reason
                                 userInfo: nil];
}

- (NSArray <MADDatabaseField *> *)fieldsForTable:(NSString *)tableName connection:(id)dbconn error:(NSError *__autoreleasing *)error {
    NSString *reason;
    NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
    reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: reason
                                 userInfo: nil];
}

- (MADSafeQueryField *)tableAliasForTable:(NSString *)table {
    return [self newSafeIdentifier: table];
}

- (NSString *)tableAliasConnector {
    return @" AS ";
}

- (NSString *)identifier {
    return @"NONE";
}

+ (NSString *)identifier {
    return @"NONE";
}

- (NSString *)selectPart {
    return @"SELECT\n";
}

- (NSString *)selectPartWithLimitedResults:(NSUInteger)limit {   //Generally limited resuls are in a LIMIT part, but
    return @"SELECT\n";                                   //  SQL Server uses the TOP part (not default here).
}

- (NSString *)sqlLimitClause {
    return [self sqlLimitClause:  NSUIntegerMax];                    //No limit by default
}

- (NSString *)sqlLimitClause:(NSUInteger)limit {
    NSString *sqlLimitClause = (limit > 0 && limit != NSUIntegerMax) ?
        [[NSString alloc] initWithFormat: @"\nLIMIT %ld", (unsigned long)limit] :
        @"";
    return sqlLimitClause;
}

- (NSString *)sqlAggregateFunctionLength {
    return @"LENGTH";
}

- (NSString *)sqlAggregateFunctionMax {
    return @"MAX";
}

- (NSString *)sqlSampleDataForField:(NSString *)fieldName andTable:(NSString *)tableName {
    MADSafeQueryField *safeField = [self newSafeQueryField: fieldName andTable: tableName];
    NSString *safeFieldAlias = [self fieldAliasForField: fieldName
                                           andTableName: tableName];
    MADSafeQueryField *safeTable = [self newSafeIdentifier:tableName];

    NSString *selectPart = [self selectPart];
    NSString *tableAliasConnector = [self tableAliasConnector];
    return [NSString stringWithFormat:MADTextSqlSelectSampleDataForField,
                                                    selectPart, safeField, tableAliasConnector,
                                                    safeFieldAlias, @"\nFROM\n", safeTable];
}

- (void)readRow:(NSUInteger)row {
    [[MADNotificationDidReadRows sharedObject] database:self readRow:row];
}

- (void)closeConnection:(id)process {}

- (BOOL)executeSQL:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn
   intoResultTable:(MADDataTable *)dataTable withError:(NSError * __autoreleasing *)error {
    NSString *reason;
    NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
    reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: reason
                                 userInfo: nil];
}

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn
                                                   error:(NSError *__autoreleasing *)error {
    NSString *reason;
    NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
    reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: reason
                                 userInfo: nil];
}

- (void)getTablesFromConnection:(id)process
                     completion:(void (^)(BOOL, NSError *, NSArray *))completion {
    NSString *reason;
    NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
    reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: reason
                                 userInfo: nil];
}

- (void)enumerateTablesFromConnection:(id)dbconn
                           usingBlock:(void (^)(MADDatabaseTable *obj, NSUInteger index, BOOL *stop))block
                           completion:(void (^)(BOOL success, NSError *error, NSArray *results))completion {
    NSString *reason;
    NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
    reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: reason
                                 userInfo: nil];
}

@end
