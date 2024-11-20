//
//  MADDatabaseSQLServer.h
//  Reports
//
//  Created by Michael Thomason on 6/18/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTDatabaseSqlServer_h
#define Reports_MTDatabaseSqlServer_h

#import <MADAPI/MADDatabase.h>

extern NSString * const MTDatabaseConnectionUsername;
extern NSString * const MTDatabaseConnectionPassword;
extern NSString * const MTDatabaseConnectionDatabase;
extern NSString * const MTDatabaseConnectionPort;
extern NSString * const MTDatabaseConnectionHost;
extern NSString * const MTDatabaseConnectionServer;
extern NSString * const MTDatabaseConnectionAppName;

@interface MADDatabaseSQLServer : MADDatabase

    - (NSString *)identifier;

    + (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    - (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName;
    - (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName;

@end

#endif
