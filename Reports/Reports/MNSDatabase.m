//
//  MNSDatabase.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDatabase.h"
#import "MNSDatabaseMySql.h"
#import "MNSDatabaseSalesForce.h"
#import "MNSDatabaseConnection.h"
#import "RptqDatabase.h"
#import "RptqUserCredentals.h"

@implementation MNSDatabase

+ (id)databaseObjectForRptqDatabase:(RptqDatabase *)database {
    
    RptqUserCredentals *userCredentals = [database ownedByUser];
    id result = nil;
    if ([[userCredentals database_driver_type] isEqualToString:[MNSDatabaseMySql identifier]]) {
        MNSDatabaseConnection *databaseConnection = [[MNSDatabaseConnection alloc] init];
        [databaseConnection setUsername:    [userCredentals mysql_username]];
        [databaseConnection setPassword:    [userCredentals mysql_password]];
        [databaseConnection setServer:      [userCredentals mysql_host]];
        [databaseConnection setDatabase:    [userCredentals mysql_database]];
        [databaseConnection setPort:        [[userCredentals mysql_port] integerValue]];
        MNSDatabaseMySql *databaseMySql = [[MNSDatabaseMySql alloc] initWithConnectionSettings:nil];
        result = databaseMySql;
        [databaseMySql autorelease];
    } else if ([[userCredentals database_driver_type] isEqualToString:[MNSDatabaseSalesForce identifier]]) {
        MNSDatabaseSalesForce *databaseSalesForce = [[MNSDatabaseSalesForce alloc] init];
        result = databaseSalesForce;
        [databaseSalesForce autorelease];
    }
    return result;
}

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSString *)getSqlForQuery:(RptqQuery *)query {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)getTables: (void (^)(NSArray *tables))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}


- (void)fieldsInDatabase: (NSString *)database andTable:(RptqTable *)table
              completion: (void (^)(MNSDatabase *database, RptqTable *originTable, NSArray *fields))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)getFieldsForTable: (RptqTable *)table
               completion: (void (^)(NSArray *fields))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)runQuery: (NSString *)query
      completion: (void (^)(MNSDatabase *database, NSArray *results))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)identifier {
    return [MNSDatabase identifier];
}

+ (NSString *)identifier {
    return @"NONE";
}

@end