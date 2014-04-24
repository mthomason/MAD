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
#import "MTDatabaseField.h"

extern NSString * const MTSqlFrom;

typedef NS_ENUM(NSUInteger, MTDatabaseQueryType) {
	MTDatabaseQueryTypeNone = 0,
	MTDatabaseQueryTypeGetTables,
	MTDatabaseQueryTypeGetFields,
	MTDatabaseQueryTypeGetResults,
	MTDatabaseQueryTypeVerify
};

@class RptqDocument, RptqDatabase, RptqQuery, RptqQueryField, RptqDatabaseSchemaTable, RptqDatabaseSchemaField,
        RptqQueryCache, RptqUserCredentals, MTDatabaseConnection, MTQuery, MTDataTable;

@protocol MTDatabaseProtocol <NSObject>
@required
@optional
- (void)receivedResults:(NSUInteger)resultCount ofTotalResults:(NSUInteger)results;
@end


@interface MTDatabase : NSObject

@property (nonatomic, assign) id <MTDatabaseProtocol> delegate;
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
- (NSString *)sqlLimitClause;
- (NSString *)sqlAllFieldsInTable:(RptqDatabaseSchemaTable *)schemaTable;
- (NSString *)tableAliasForTable:(RptqDatabaseSchemaTable *)table;
- (NSString *)fieldAliasForField:(RptqDatabaseSchemaField *)field
               withSafeTableName:(NSString *)safeTableName;
- (NSString *)fieldAliasForField:(RptqDatabaseSchemaField *)field;

- (NSString *)tableAliasConnector;

- (NSString *)sqlAggregateFunctionLength;
- (NSString *)sqlAggregateFunctionMax;
- (NSString *)sqlSampleDataForField:(RptqDatabaseSchemaField *)schemaField;

- (void)executeQuery:(MTQuery *)query completion:(void (^)(BOOL, NSError *))completion;

- (void)getCredentalsWithConnection:(MTDatabaseConnection *)connection
                         completion:(void (^)(BOOL success, NSError *error, NSString *username, NSString *password))completion;
- (void)connectWithCredentals:(MTDatabaseConnection *)connection completion:(void (^)(id dbconn, BOOL success, NSError *error))completion;
- (void)removeCredentalsBecauseOfError:(NSError *)error;

- (BOOL)limitResults;
- (NSString *)nativeTypeForDataType:(MTDataType)dataType;

- (void)cleanupBulkInsert;

@property (nonatomic, assign, readonly) BOOL isLicensedUser;

@end

#endif
