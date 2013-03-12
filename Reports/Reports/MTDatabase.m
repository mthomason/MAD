//
//  MNSDatabase.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabase.h"
#import "MTDatabaseMySql.h"
#import "MTDatabaseSalesForce.h"
#import "MTDatabaseConnection.h"
#import "RptqDatabase.h"
#import "RptqUserCredentals.h"

@implementation MTDatabase

+ (id)databaseObjectForRptqDatabase:(RptqDatabase *)database {
    //RptqUserCredentals *userCredentals = [database ownedByUser];
    return [MTDatabase databaseForRptqDatabase:database];
}

+ (id)databaseForRptqDatabase:(RptqDatabase *)database {
    id result = nil;
    RptqUserCredentals *userCredentals = [database ownedByUser];    
    if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseMySql identifier]]) {
        MTDatabaseConnection *databaseConnection = [[MTDatabaseConnection alloc] init];
        [databaseConnection setUsername:    [userCredentals mysql_username]];
        [databaseConnection setPassword:    [userCredentals mysql_password]];
        [databaseConnection setServer:      [userCredentals mysql_host]];
        [databaseConnection setDatabase:    [userCredentals mysql_database]];
        [databaseConnection setPort:        [[userCredentals mysql_port] integerValue]];
        MTDatabaseMySql *databaseMySql = [[MTDatabaseMySql alloc] initWithConnectionSettings:databaseConnection];
        result = databaseMySql;
        [databaseMySql autorelease];
    } else if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseSalesForce identifier]]) {
        MTDatabaseSalesForce *databaseSalesForce = [[MTDatabaseSalesForce alloc] init];
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

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}


- (void)fieldsInDatabase: (NSString *)database andTable:(RptqDatabaseSchemaTable *)table
              completion: (void (^)(MTDatabase *database, RptqDatabaseSchemaTable *originTable, NSArray *fields))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)getFieldsForTable: (RptqDatabaseSchemaTable *)table
               completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Subclass MNSDtabase; don't use it directly.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)runQuery: (NSString *)query forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
      completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion {
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
