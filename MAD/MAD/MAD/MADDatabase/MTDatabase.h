//
//  MADDatabase.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

// This class is built for subclassing.

#ifndef Reports_MTDatabase_h
#define Reports_MTDatabase_h

#import <Foundation/NSObject.h>

typedef NSString MADSafeQueryField;

extern NSString * const MADSqlTextFromPart;

@protocol MADDatabaseProtocol, MADDatabaseConnectionsProperties;

@class NSMutableArray, MADCredential, MADDatabaseConnection, MTDatabase, MADDatabaseTable,
       MADDataTable, MTQuery, MADDatabaseField;

@protocol MADErrorHandler <NSObject>
  @required
    - (void)displayError:(NSError *)error;
@end

@interface MTDatabase : NSObject

    @property (nonatomic, weak) id <MADDatabaseProtocol> delegate;
    @property (nonatomic, copy) MADDatabaseConnection *databaseConnection;

    @property (nonatomic, strong) NSMutableArray *errors;

    + (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection;

    - (void)getTables: (void (^)(BOOL success, NSError *error, NSArray *tables))completion;

    - (BOOL)executeSql:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn
       intoResultTable:(MADDataTable *)dataTable withError:(NSError * __autoreleasing *)error;

    - (void)getTablesFromConnection:(id)dbconn completion:(void (^)(BOOL,
                                                                    NSError *,
                                                                    NSArray *))completion;
    - (NSArray <MADDatabaseField *> *)fieldsForTable: (NSString *)tableName connection:(id)dbconn
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
    - (BOOL)executeQuery:(MTQuery *)query withDataTable:(MADDataTable *)dataTable
                andError:(NSError * __autoreleasing *)error;

    - (MADCredential *)copyCredentalsWithConnection:(MADDatabaseConnection *)connection;
    - (id)connectWithConnection:(MADDatabaseConnection *)connection credentals:(MADCredential *)credentals
                connectionError:(NSError * __autoreleasing *)error;

    - (void)readRow:(NSUInteger)row;

    - (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn error:(NSError * __autoreleasing *)error;
    - (void)enumerateTablesFromConnection:(id)dbconn
                               usingBlock:(void (^)(MADDatabaseTable *obj, NSUInteger index, BOOL *stop))block
                               completion:(void (^)(BOOL success, NSError *error, NSArray *results))completion;

    @property (nonatomic, assign, readonly) BOOL isLicensedUser;

@end

#endif
