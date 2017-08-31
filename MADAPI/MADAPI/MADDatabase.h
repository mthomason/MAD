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
#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseProtocol.h>

typedef NSString MADSafeQueryField;

extern NSString * const MADSqlTextFromPart;

@protocol MADDatabaseResultsProtocol, MADDatabaseConnectionsProperties;

@class NSMutableArray, MADCredential, MADDatabaseConnection, MADDatabase, MADDatabaseTable,
       MADDataTable, MADQuery, MADDatabaseField;

@protocol MADErrorHandler <NSObject>
  @required
    - (void)displayError:(NSError *)error;
@end

@interface MADDatabase : NSObject
    <MADDatabaseResultsProtocol, MADDatabaseDataSource, MADDatabaseDBProtocol>

    //+ (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection;

    @property (nonatomic, weak) id <MADDatabaseResultsProtocol> delegate;
    @property (nonatomic, copy) MADDatabaseConnection *databaseConnection;

    @property (nonatomic, strong) NSMutableArray *errors;

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

    - (MADCredential *)credentalsWithConnection:(MADDatabaseConnection *)connection;

    - (void)readRow:(NSUInteger)row;

    - (void)enumerateTablesFromConnection:(id)dbconn
                               usingBlock:(void (^)(MADDatabaseTable *obj, NSUInteger index, BOOL *stop))block
                               completion:(void (^)(BOOL success, NSError *error, NSArray *results))completion;

    @property (nonatomic, assign, readonly) BOOL isLicensedUser;

@end

#endif
