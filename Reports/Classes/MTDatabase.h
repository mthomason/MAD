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
        RptqUserCredentals, MTDatabaseConnection, MTQuery, MTDataTable;

@protocol MTDatabaseProtocol <NSObject>
@required
@optional
- (MTDataTable *)dataTableForQuery:(MTQuery *)query;
@end


@interface MTDatabase : NSObject

@property (nonatomic, assign) id <MTDatabaseProtocol> delegate;
@property (nonatomic, strong) MTDatabaseConnection *databaseConnection;

+ (instancetype)databaseFactory:(MTDatabaseConnection *)connection;

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (void)getFieldsForTableName: (NSString *)tableName
                   completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;


- (void)getTablesFromConnection:(id)dbconn completion:(void (^)(BOOL, NSError *, NSArray *))completion;
- (void)getFieldsForTableName: (NSString *)tableName connection:(id)dbconn
                   completion: (void (^)(BOOL success, NSError *error, NSArray *fields))completion;
- (void)closeProcess:(id)process;

- (NSString *)identifier;
+ (NSString *)identifier;

+ (NSString *)safeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
- (NSString *)safeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
- (NSString *)safeIdentifier:(NSString *)fieldOrTableName;

- (NSString *)selectPart;
- (NSString *)selectPartWithLimitedResults:(NSInteger)limit;
- (NSString *)sqlLimitClause;
- (NSString *)sqlLimitClause:(NSInteger)limit;
- (NSString *)sqlAllFieldsInTable:(RptqDatabaseSchemaTable *)schemaTable;
- (NSString *)tableAliasForTable:(NSString *)tableName;
- (NSString *)fieldAliasForField:(NSString *)field
               withSafeTableName:(NSString *)safeTableName;
- (NSString *)fieldAliasForField:(NSString *)fieldName
                    andTableName:(NSString *)tableName;
- (NSString *)tableAliasConnector;

- (NSString *)sqlAggregateFunctionLength;
- (NSString *)sqlAggregateFunctionMax;
- (NSString *)sqlSampleDataForField:(RptqDatabaseSchemaField *)schemaField;

- (void)executeQuery:(MTQuery *)query completion:(void (^)(BOOL, NSError *))completion;

- (void)getCredentalsWithConnection:(MTDatabaseConnection *)connection
                         completion:(void (^)(BOOL success, NSError *error, NSString *username, NSString *password))completion;
- (void)connectWithCredentals:(MTDatabaseConnection *)connection completion:(void (^)(id dbconn, BOOL success, NSError *error))completion;
- (void)removeCredentalsBecauseOfError:(NSError *)error;


- (BOOL)cleanupBulkInsert;

- (void)readRow:(NSUInteger)row;

@property (nonatomic, assign, readonly) BOOL isLicensedUser;

@end

#endif
