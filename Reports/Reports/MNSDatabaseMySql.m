//
//  MNSDatabaseMySql.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MNSDatabaseMySql.h"

@implementation MNSDatabaseMySql

- (id)initWithConnectionSettings: (NSDictionary *)connectionSettings
                      completion: (void (^)(BOOL success))completion {
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)getTables: (void (^)(NSArray *tables))completion {
    

    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_queue_t queuePriorityMain = dispatch_get_main_queue();
    
    dispatch_async(queuePriorityBackground, ^{
        dispatch_async(queuePriorityMain, ^{
            
            MysqlServer *serv = [[MysqlServer alloc] init];
            
            MysqlConnection *conn = [MysqlConnection connectToServer: serv];
            
            NSInteger colctr = 0;
            
            NSMutableArray *results = nil;
            
            if (conn) {
                MysqlFetch *fetch = [MysqlFetch fetchWithCommand:@"SHOW TABLES;" onConnection:conn];
                if (fetch) {
                    if ([[fetch fields] count] > 0) {
                        
                        MysqlFetchField *resultsTableName = [[fetch fields] objectAtIndex:0];
                        results = [[NSMutableArray alloc] initWithCapacity: [[fetch results] count]];
                        
                        for (NSDictionary *tableName in [fetch results]) {
                            NSString *tn = [tableName objectForKey:[resultsTableName name]];
                            [results addObject: tn];
                            
                            
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
    
}

- (void)runQuery: (NSString *)query
      completion: (void (^)(MNSDatabase *database, NSArray *results))completion {
    
}

@end