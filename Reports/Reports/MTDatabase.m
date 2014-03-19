//
//  MNSDatabase.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabase.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSqlite3.h"
#import "MTDatabaseConnection.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqUserCredentals.h"
#import "RptqDocumentObjectBarcode.h"
#import "MTDatabaseTable.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryField.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryCache.h"

@interface MTDatabase ()

@property (nonatomic, assign, readwrite) BOOL isLicensedUser;

@end

@implementation MTDatabase

- (void)dealloc {
    [_databaseConnection release];
    [super dealloc];
}

- (void)executeSql:(NSString *)sql
        completion:(void (^)(BOOL success, NSError *error, id results))completion {
    
    NSString *message = @"Only call this on subclasses.";
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey : message};
    NSError *error = [NSError errorWithDomain:@"MTDatabase" code:484 userInfo:errorInfo];
    completion(NO, error, nil);
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    return @"";
}

- (NSString *)safeIdentifier:(NSString *)s {
    return s;
}

+ (id)databaseForRptqDatabase:(RptqDatabase *)database {
    id result = nil;
    RptqUserCredentals *userCredentals = [database ownedByUser];
    if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseMySql identifier]]) {
        
        result = [[MTDatabaseMySql alloc] init];

    } else if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseSqlServer identifier]]) {

        result = [[MTDatabaseSqlServer alloc] init];
        
    } else if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseSqlite3 identifier]]) {
        
        result = [[MTDatabaseSqlite3 alloc] init];
    }
    
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection credentalsFromRptqCredentals:userCredentals];
    [result setDatabaseConnection:databaseConnection];
    
    if ([result respondsToSelector:@selector(openDatabase)]) {
        [result openDatabase];
    }
    
    return [result autorelease];
}

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)tableAliasConnector {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)identifier {
    return [MTDatabase identifier];
}

+ (NSString *)identifier {
    return @"NONE";
}

- (id)connectionSettings {
    return nil;
}

@end
