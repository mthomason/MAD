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
#import <MADTdsClient/MADTdsClient.h>

extern NSString * const MTDatabaseConnectionUsername;
extern NSString * const MTDatabaseConnectionPassword;
extern NSString * const MTDatabaseConnectionDatabase;
extern NSString * const MTDatabaseConnectionPort;
extern NSString * const MTDatabaseConnectionHost;
extern NSString * const MTDatabaseConnectionServer;
extern NSString * const MTDatabaseConnectionAppName;

@interface MTDatabaseSqlServer : MTDatabase

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (NSString *)identifier;
+ (NSString *)identifier;

+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
- (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
- (NSString *)safeIdentifier:(NSString *)fieldOrTableName;

@end

#endif
