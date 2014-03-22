//
//  MNSDatabase.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

// This class is built for subclassing.

#ifndef Reports_MTDatabase_h
#define Reports_MTDatabase_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MTDatabaseQueryType) {
	MTDatabaseQueryTypeNone = 0,
	MTDatabaseQueryTypeGetTables,
	MTDatabaseQueryTypeGetFields,
	MTDatabaseQueryTypeGetResults,
	MTDatabaseQueryTypeVerify
};

@class RptqDocument, RptqDatabase, RptqQuery, RptqQueryField, RptqDatabaseSchemaTable, RptqDatabaseSchemaField,
        RptqQueryCache, RptqUserCredentals, MTDatabaseConnection;

@protocol MTDatabaseCacheProtocol <NSObject>
@required
- (void)cacheQueryResult:(id)queryResult;
@end

@interface MTDatabase : NSObject

@property (nonatomic, assign) id <MTDatabaseCacheProtocol> delegateCacheData;
@property (nonatomic, retain) MTDatabaseConnection *databaseConnection;

+ (id)databaseFactory:(MTDatabaseConnection *)connection;

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (void)getFieldsForTableSchema: (RptqDatabaseSchemaTable *)table
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;


- (NSString *)identifier;
+ (NSString *)identifier;

+ (NSString *)safeQueryField:(RptqQueryField *)queryField;
- (NSString *)safeQueryField:(RptqQueryField *)queryField;
- (NSString *)safeIdentifier:(NSString *)fieldOrTableName;
- (NSString *)safeQuerySchemaField:(RptqDatabaseSchemaField *)schemaField;
- (NSString *)selectPart;

- (NSString *)tableAliasConnector;

- (void)executeSql:(NSString *)sql
        completion:(void (^)(BOOL success, NSError *error, id results))completion;

@property (nonatomic, assign, readonly) BOOL isLicensedUser;

@end

#endif
