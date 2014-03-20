//
//  MTDatabaseSqlServer.h
//  Reports
//
//  Created by Michael Thomason on 6/18/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDatabaseSqlServer_h
#define Reports_MTDatabaseSqlServer_h

#import "MTDatabase.h"
#import "MTDatabaseConnection.h"
#import "MTDatabaseField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDocument+Extras.h"
#import "NSFileManager+Common.h"
#import "sybdb.h"

extern NSString * const MTDatabaseConnectionUsername;
extern NSString * const MTDatabaseConnectionPassword;
extern NSString * const MTDatabaseConnectionDatabase;
extern NSString * const MTDatabaseConnectionPort;
extern NSString * const MTDatabaseConnectionHost;
extern NSString * const MTDatabaseConnectionServer;
extern NSString * const MTDatabaseConnectionAppName;

@interface MTDatabaseSqlServer : MTDatabase

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;

- (NSString *)identifier;
+ (NSString *)identifier;

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName;
- (NSString *)safeQueryField:(RptqQueryField *)queryField;

@end

#endif
