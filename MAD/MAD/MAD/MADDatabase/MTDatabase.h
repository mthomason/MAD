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

typedef NSString MADSafeQueryField;

extern NSString * const MADSqlTextFromPart;

typedef NS_ENUM(NSUInteger, MTDatabaseQueryType) {
	MTDatabaseQueryTypeNone = 0,
	MTDatabaseQueryTypeGetTables,
	MTDatabaseQueryTypeGetFields,
	MTDatabaseQueryTypeGetResults,
	MTDatabaseQueryTypeVerify
};

@protocol MTDatabaseProtocol;

@class NSMutableArray;
@class MADCredential;
@class MTDatabaseConnection;
@class MTDatabase;
@class MTDatabaseTable;
@class MTDataTable;
@class MTQuery;

@protocol MADErrorHandler <NSObject>
  @required
    - (void)displayError:(NSError *)error;
@end

@interface MTDatabase : NSObject

    @property (nonatomic, weak) id <MTDatabaseProtocol> delegate;
    @property (nonatomic, weak) id <MADErrorHandler> delegateError;
    @property (nonatomic, copy) MTDatabaseConnection *databaseConnection;

    @property (nonatomic, strong) NSMutableArray *errors;

    + (instancetype)newDatabaseWithConnection:(MTDatabaseConnection *)connection;

    - (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

    - (BOOL)executeSql:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn
       intoResultTable:(MTDataTable *)dataTable withError:(NSError * __autoreleasing *)error;

    - (void)getTablesFromConnection:(id)dbconn completion:(void (^)(BOOL,
                                                                    NSError *,
                                                                    NSArray *))completion;
    - (NSArray *)fieldsForTable: (NSString *)tableName connection:(id)dbconn
                          error:(NSError * __autoreleasing *)error;

    - (void)closeProcess:(id)process;

    - (NSString *)identifier;
    + (NSString *)identifier;

    + (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    - (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
    - (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName;
    - (MADSafeQueryField *)tableAliasForTable:(NSString *)tableName;

    - (NSString *)selectPart;
    - (NSString *)selectPartWithLimitedResults:(NSUInteger)limit;
    - (NSString *)sqlLimitClause;
    - (NSString *)sqlLimitClause:(NSUInteger)limit;
    - (NSString *)fieldAliasForField:(NSString *)field
                   withSafeTableName:(NSString *)safeTableName;
    - (NSString *)fieldAliasForField:(NSString *)fieldName
                        andTableName:(NSString *)tableName;
    - (NSString *)tableAliasConnector;

    - (NSString *)sqlAggregateFunctionLength;
    - (NSString *)sqlAggregateFunctionMax;

    - (NSString *)sqlSampleDataForField:(NSString *)fieldName andTable:(NSString *)tableName;

    - (BOOL)executeQuery:(MTQuery *)query withError:(NSError * __autoreleasing *)error;

    - (MADCredential *)copyCredentalsWithConnection:(MTDatabaseConnection *)connection;
    - (id)connectWithConnection:(MTDatabaseConnection *)connection credentals:(MADCredential *)credentals;

    - (void)readRow:(NSUInteger)row;

    - (NSArray <MTDatabaseTable *> *)getTablesFromConnection:(id)dbconn error:(NSError * __autoreleasing *)error;
    - (void)enumerateTablesFromConnection:(id)dbconn
                               usingBlock:(void (^)(MTDatabaseTable *obj, NSUInteger index, BOOL *stop))block
                               completion:(void (^)(BOOL success, NSError *error, NSArray *results))completion;

    @property (nonatomic, assign, readonly) BOOL isLicensedUser;

@end

#endif
