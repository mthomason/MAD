//
//  MADDatabase.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

// This class is built for subclassing.

#ifndef Reports_MTDatabase_h
#define Reports_MTDatabase_h

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>

extern NSString * const MADSqlTextFromPart;

typedef NS_ENUM(NSUInteger, MTDatabaseQueryType) {
	MTDatabaseQueryTypeNone = 0,
	MTDatabaseQueryTypeGetTables,
	MTDatabaseQueryTypeGetFields,
	MTDatabaseQueryTypeGetResults,
	MTDatabaseQueryTypeVerify
};

@class MADCredential, MTDatabaseConnection, MTDatabase, MTDatabaseTable, MTQuery, MTDataTable;

@protocol MTDatabaseProtocol <NSObject>
@required
@optional
    - (MADCredential *)getCredentialsForKey:(NSString *)key;
    - (MTDataTable *)dataTableForQuery:(MTQuery *)query;
@end

@protocol MADErrorHandler <NSObject>
@required
- (void)displayError:(NSError *)error;
@end

@interface MTDatabase : NSObject

    @property (nonatomic, weak) id <MTDatabaseProtocol> delegate;
    @property (nonatomic, weak) id <MADErrorHandler> delegateError;
    @property (nonatomic, copy) MTDatabaseConnection *databaseConnection;

    @property (nonatomic, strong) NSMutableArray <__kindof NSError *> *errors;

+ (instancetype)newDatabaseWithConnection:(MTDatabaseConnection *)connection NS_RETURNS_RETAINED;

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

- (BOOL)executeSql:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn intoResultTable:(MTDataTable *)dataTable withError:(NSError * __autoreleasing *)error;

- (void)getTablesFromConnection:(id)dbconn completion:(void (^)(BOOL, NSError *, NSArray *))completion;
- (NSArray *)fieldsForTable: (NSString *)tableName connection:(id)dbconn error:(NSError * __autoreleasing *)error;

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
- (NSString *)tableAliasForTable:(NSString *)tableName;
- (NSString *)fieldAliasForField:(NSString *)field
               withSafeTableName:(NSString *)safeTableName;
- (NSString *)fieldAliasForField:(NSString *)fieldName
                    andTableName:(NSString *)tableName;
- (NSString *)tableAliasConnector;

- (NSString *)sqlAggregateFunctionLength;
- (NSString *)sqlAggregateFunctionMax;

- (NSString *)sqlSampleDataForField:(NSString *)fieldName andTable:(NSString *)tableName;

- (BOOL)executeQuery:(MTQuery *)query withError:(NSError * __autoreleasing *)error;

- (MADCredential *)getCredentalsWithConnection:(MTDatabaseConnection *)connection;
- (id)connectWithConnection:(MTDatabaseConnection *)connection credentals:(MADCredential *)credentals;

- (void)readRow:(NSUInteger)row;

- (NSArray <MTDatabaseTable *> *)getTablesFromConnection:(id)dbconn error:(NSError * __autoreleasing *)error;
- (void)enumerateTablesFromConnection:(id)dbconn
                           usingBlock:(void (^)(MTDatabaseTable *obj, NSUInteger index, BOOL *stop))block
                           completion:(void (^)(BOOL success, NSError *error, NSArray *results))completion;

@property (nonatomic, assign, readonly) BOOL isLicensedUser;

@end

#endif
