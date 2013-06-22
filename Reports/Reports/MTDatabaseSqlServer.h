//
//  MTDatabaseSqlServer.h
//  Reports
//
//  Created by Michael Thomason on 6/18/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabase.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDocument+Extras.h"
#import "NSFileManager+Common.h"

extern NSString * const MTDatabaseConnectionUsername;
extern NSString * const MTDatabaseConnectionPassword;
extern NSString * const MTDatabaseConnectionDatabase;
extern NSString * const MTDatabaseConnectionPort;
extern NSString * const MTDatabaseConnectionHost;
extern NSString * const MTDatabaseConnectionServer;
extern NSString * const MTDatabaseConnectionAppName;

@interface MTDatabaseSqlServer : MTDatabase

- (id)initWithConnectionSettings: (MTDatabaseConnection *)connectionSettings;

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;

- (void)cacheReportQueryForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                     completion: (void (^)(MTDatabase *database, RptqQueryCache *cache))completion;

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion;

- (NSString *)identifier;
+ (NSString *)identifier;

- (id)connectionSettings;

@end
