//
//  MNSDatabaseMySql.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDatabaseMySql.h"

@interface MNSDatabaseMySql ()

@property (nonatomic, retain) MNSDatabaseConnection *databaseConnection;

@end

@implementation MNSDatabaseMySql

- (void)dealloc {
    [_databaseConnection release];
    [super dealloc];
}

- (id)initWithConnectionSettings: (MNSDatabaseConnection *)connectionSettings
                      completion: (void (^)(BOOL success, MNSDatabaseMySql *object))completion {
    self = [super init];
    if (self) {
        [self setDatabaseConnection:connectionSettings];
        completion(YES, self);
    }
    return self;
}

- (void)getTables: (void (^)(NSArray *tables))completion {
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            MysqlServer *serv = [[MysqlServer alloc] init];

            [serv setHost:      [[self databaseConnection] server]];
            [serv setUser:      [[self databaseConnection] username]];
            [serv setPassword:  [[self databaseConnection] password]];
            [serv setSchema:    [[self databaseConnection] database]];
            
            MysqlConnection *conn = [MysqlConnection connectToServer: serv];
            
            //NSInteger colctr = 0;
            
            NSMutableArray *results = nil;
            
            if (conn) {
                MysqlFetch *fetch = [MysqlFetch fetchWithCommand:@"SHOW TABLES;" onConnection:conn];
                if (fetch) {
                    if ([[fetch fields] count] > 0) {
                        
                        MysqlFetchField *resultsTableName = [[fetch fields] objectAtIndex:0];
                        results = [[NSMutableArray alloc] initWithCapacity: [[fetch results] count]];
                        
                        for (NSDictionary *tableName in [fetch results]) {
                            NSString *tn = [tableName objectForKey:[resultsTableName name]];
                            MNSDatabaseTable *databaseTable = [[MNSDatabaseTable alloc] initWithTableName: tn];
                            [results addObject: databaseTable];
                            [databaseTable release];
                        }
                    }
                }
            }
            
            completion(results);
        });
    });
    
}

- (void)getFieldsForTable: (RptqTable *)table
               completion: (void (^)(NSArray *fields))completion {
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_async(queuePriorityBackground, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            MysqlServer *serv = [[MysqlServer alloc] init];
            
            [serv setHost:      [[self databaseConnection] server]];
            [serv setUser:      [[self databaseConnection] username]];
            [serv setPassword:  [[self databaseConnection] password]];
            [serv setSchema:    [[self databaseConnection] database]];
            
            MysqlConnection *conn = [MysqlConnection connectToServer: serv];
                        
            NSMutableArray *results = nil;
            
            if (conn) {
                NSString *command = [NSString stringWithFormat:@"SHOW COLUMNS FROM %@;", [table name]];
                MysqlFetch *fetch = [MysqlFetch fetchWithCommand:command onConnection:conn];
                if (fetch) {
                    if ([[fetch fields] count] > 0) {
                        
                        MysqlFetchField *fieldMetaData = [[fetch fields] objectAtIndex:0];
                        results = [[NSMutableArray alloc] initWithCapacity: [[fetch results] count]];
                        
                        for (NSDictionary *field in [fetch results]) {
                            NSString *fn = [field objectForKey:[fieldMetaData name]];
                            MNSDatabaseField *databaseField = [[MNSDatabaseField alloc] initWithName: fn];
                            [results addObject: databaseField];
                            [databaseField release];
                        }
                    }
                }
            }
            
            completion(results);
        });
    });
    

}

- (void)runQuery: (NSString *)query
      completion: (void (^)(MNSDatabase *database, NSArray *results))completion {
    
}

- (NSString *)identifier {
    return [MNSDatabaseMySql identifier];
}

+ (NSString *)identifier {
    return @"MySQL";
}

@end