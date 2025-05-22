//
//  MADDatabase.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

// This class is built for subclassing.

#ifndef Reports_MTDatabase_h
#define Reports_MTDatabase_h

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseProtocol.h>
#import <MADAPI/MADDatabaseSQLProtocol.h>
#import <MADAPI/MADPluginProtocol.h>

typedef NSString MADSafeQueryField;

extern NSString * const MADSqlTextFromPart;

@protocol MADDatabaseResultsProtocol, MADDatabaseConnectionsProperties;

@class NSMutableArray, MADCredential, MADDatabaseConnection, MADDatabase, MADDatabaseTable, MADDataTable, MADQuery, MADDatabaseField;

@protocol MADErrorHandler <NSObject>
@required
- (void)displayError:(NSError *)error;
@end

@interface MADDatabase : NSObject
	<MADPluginProtocol, MADDatabaseResultsProtocol, MADDatabaseDataSource, MADDatabaseDBProtocol, MADDatabaseSQLProtocol, NSCoding, NSCopying>

	+ (NSString *)imageIconName;
	+ (NSString *)driverName;

	@property (nonatomic, weak) id <MADDatabaseResultsProtocol> delegate;
	@property (nonatomic, copy) MADDatabaseConnection *databaseConnection;

	@property (nonatomic, strong) NSMutableArray *errors;

	- (NSString *)identifier;
	+ (NSString *)identifier;

	- (MADCredential *)credentalsWithConnection:(MADDatabaseConnection *)connection;

	- (void)readRow:(NSUInteger)row;

	- (void)enumerateTablesFromConnection:(id)dbconn
							   usingBlock:(void (^)(MADDatabaseTable *obj, NSUInteger index, BOOL *stop))block
							   completion:(void (^)(BOOL success, NSError *error, NSArray *results))completion;

	@property (nonatomic, assign, readonly) BOOL isLicensedUser;

@end

#endif
