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

extern NSString * const MTSqlFrom;

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

- (void)getFieldsForTableName: (NSString *)tableName
                     completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;


- (NSString *)identifier;
+ (NSString *)identifier;

+ (NSString *)safeQueryField:(RptqQueryField *)queryField;
- (NSString *)safeQueryField:(RptqQueryField *)queryField;
- (NSString *)safeIdentifier:(NSString *)fieldOrTableName;
- (NSString *)safeQuerySchemaField:(RptqDatabaseSchemaField *)schemaField;
- (NSString *)selectPart;
- (NSString *)sqlAllFieldsInTable:(RptqDatabaseSchemaTable *)schemaTable;
- (NSString *)tableAliasForTable:(RptqDatabaseSchemaTable *)table;
- (NSString *)fieldAliasForField:(RptqDatabaseSchemaField *)field
               withSafeTableName:(NSString *)safeTableName;

- (NSString *)tableAliasConnector;

- (void)executeSql:(NSString *)sql
        completion:(void (^)(BOOL success, NSError *error, id results))completion;

- (void)maxLengthForFields:(NSArray *)fields inTable:(NSString *)tableName
                completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;

- (BOOL)isReachable;

@property (nonatomic, assign, readonly) BOOL isLicensedUser;

@end

#endif
