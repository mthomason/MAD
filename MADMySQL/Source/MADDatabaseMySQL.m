//
//  MNSDatabaseMySql.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDatabaseMySQL.h"
#import "MysqlConnection.h"
#import "MysqlServer.h"
#import "MysqlFetch.h"
#import "MysqlFetchField.h"
#import "MADDataTypeMySQL.h"
#import "MysqlFetch+DataTable.h"
#import "madlog.h"

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTableVirtual.h>
#import <MADFoundation/MADCredential.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabaseTable.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADQuery.h>
#import <MADAPI/MADConnectionsPropertiesProtocol.h>

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSError.h>

#import <mysql.h>

@interface MADDatabaseMySQL () <MADMySQLFetchProtocol>

@property (nonatomic, strong) MADDatabaseConnection <MADConnectionsPropertiesProtocol> *databaseConnection;

@end

@implementation MADDatabaseMySQL

@dynamic databaseConnection;

#pragma mark -
#pragma mark Static Functions

+ (NSString *)imageIconName { return @"UIImageExportTypeMySQL"; }
+ (NSString *)driverName { return @"MySQL Native Client"; }

+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
	return [[NSString alloc] initWithFormat:@"`%@`.`%@`", tableName, fieldName];
}

+ (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName {
	return [[NSString alloc] initWithFormat:@"`%@`", fieldOrTableName];
}

+ (NSError *)errorCouldNotGetCredientals {
	return [NSError errorWithDomain:NSStringFromClass([self class])
							   code:43421
						   userInfo:@{
		NSLocalizedDescriptionKey : NSLocalizedString(@"Notice", @"Notice"),
		NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"Could not get credentials.", @"Could not get credentials.")
	}];
}

#pragma mark -
#pragma mark MADDatabaseDataSource

- (void)getTables:(void (^)(BOOL success, NSError *error, NSArray <MADDatabaseTable *> *tables))completion {
	
	id connectionSettings = self.databaseConnection;
	NSError * __autoreleasing connectionError = nil;
	MysqlConnection *conn = [self connectWithConnection:connectionSettings credentals:nil connectionError:&connectionError];
	if (conn && connectionError == nil) {
		
		NSError *fetchError = nil;
		MysqlFetch *myFetch = [[MysqlFetch alloc] init];
		NSString *identifier = @"v999";
		MADDataTable *dataTableVirtual = [[MADDataTableVirtual alloc] initWithId:identifier.hash];
		MADDataTable *dataTable = [myFetch fetchWithCommand:@"SHOW TABLES;" dataTable:&dataTableVirtual
											   onConnection: conn error: &fetchError];
		NSMutableArray <MADDatabaseTable *> *results = nil;
		if (fetchError == nil) {
			NSUInteger resultsCount = [dataTable count];
			results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
			for (NSUInteger i=0; i<[dataTable count]; i++) {
				@autoreleasepool {
					NSString *tableName = [dataTable objectAtRow:i column:0];
					MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:tableName];
					[results addObject:table];
				}
			}
		}
		completion(YES, fetchError, results);
	} else {
		completion(NO, nil, nil);
	}
}

- (void)getTablesFromConnection:(id)dbconn completion:(void (^)(BOOL, NSError *, NSArray *))completion {
	
	NSError *error = nil;
	MysqlConnection *conn = dbconn;
	MysqlFetch *myFetch = [[MysqlFetch alloc] init];
	NSString *identifier = @"v999";
	MADDataTable *dataTableVirtual = [[MADDataTableVirtual alloc] initWithId:identifier.hash];
	MADDataTable *dataTable = [myFetch fetchWithCommand: @"SHOW TABLES;"
											  dataTable: &dataTableVirtual
										   onConnection: conn
										  extendedNames: YES
												  error: &error];
	NSMutableArray *results = nil;
	if (error == nil) {
		NSUInteger resultsCount = [dataTable count];
		results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
		for (NSUInteger i=0; i<[dataTable count]; i++) {
			@autoreleasepool {
				NSString *tableName = [dataTable objectAtRow:i column:0];
				MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:tableName];
				[results addObject:table];
			}
		}
	}
	if (completion) completion(error == nil, error, results);
}

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn error:(NSError * __autoreleasing *)outError {
	
	NSError *errorFetch = nil;
	MysqlConnection *conn = dbconn;
	MysqlFetch *myFetch = [[MysqlFetch alloc] init];
	NSString *identifier = @"v999";
	MADDataTable *dataTableVirtual = [[MADDataTableVirtual alloc] initWithId:identifier.hash];
	MADDataTable *dataTable = [myFetch fetchWithCommand: @"SHOW TABLES;"
											  dataTable: &dataTableVirtual
										   onConnection: conn
										  extendedNames: YES
												  error: &errorFetch];
	if (*outError == nil && errorFetch != nil) {
		NSDictionary *userInfo = @{NSUnderlyingErrorKey: errorFetch};
		NSString *domain = NSStringFromClass(self.class);
		*outError = [NSError errorWithDomain:domain code:934 userInfo:userInfo];
	}
	NSMutableArray *results = nil;
	if (errorFetch == nil) {
		NSUInteger resultsCount = [dataTable count];
		results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
		for (NSUInteger i=0; i<resultsCount; i++) {
			@autoreleasepool {
				NSString *tableName = [dataTable objectAtRow:i column:0];
				MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:tableName];
				[results addObject:table];
			}
		}
	}
	return results;
}

- (NSArray<MADDatabaseField *> *)fieldsForTable:(NSString *)tableName
									 connection:(id)dbconn
										  error:(NSError * __autoreleasing *)error {
	MysqlConnection *conn = dbconn;
	NSMutableDictionary *resultsDictionary = [NSMutableDictionary dictionary]; // Initialize the dictionary
	
	MADSafeQueryField *safeTableName = [self newSafeIdentifier:tableName];
	NSString *formatShowColumns = @"SHOW COLUMNS FROM %@;";
	NSString *command = [[NSString alloc] initWithFormat:formatShowColumns, safeTableName];
	
	MysqlFetch *myFetch = [[MysqlFetch alloc] init];
	NSString *identifier = @"v9998";
	MADDataTable *dataTableVirtual1 = [[MADDataTableVirtual alloc] initWithId:identifier.hash];
	NSError *errorShowColumns = nil;
	NSError *errorColumnMetaData = nil;
	
	MADDataTable *dataTable = [myFetch fetchWithCommand:command
											  dataTable:&dataTableVirtual1
										   onConnection:conn
												  error:&errorShowColumns];
	if (errorShowColumns == nil) {
		NSUInteger resultsCount = [dataTable count];
		resultsDictionary = [[NSMutableDictionary alloc] initWithCapacity:resultsCount];
		
		NSUInteger numberOfRows = [dataTable numberOfRows];
		for (NSUInteger i = 0; i < numberOfRows; i++) {
			NSString *name = [dataTable objectAtRow:i column:0];
			MADDatabaseField *field = [[MADDatabaseField alloc] initWithName:name];
			NSString *safeId = [self safeIdentifierForTable:tableName andField:name];
			resultsDictionary[safeId] = field;
		}
		
		NSString *identifier2 = @"v9997";
		MADDataTable *dataTableVirtual2 = [[MADDataTableVirtual alloc] initWithId:identifier2.hash];
		safeTableName = [self newSafeIdentifier:tableName];
		
		NSString *formatSelectAll = @"SELECT * FROM %@ LIMIT 0;";
		NSString *command2 = [[NSString alloc] initWithFormat:formatSelectAll, safeTableName];
		MysqlFetch *myFetch2 = [[MysqlFetch alloc] init];
		MADDataTable *dataTable2 = [myFetch2 fetchWithCommand:command2
													dataTable:&dataTableVirtual2
												 onConnection:conn
														error:&errorColumnMetaData];
		if (errorColumnMetaData == nil) {
			NSEnumerator *columnsEnumerator = [dataTable2 columnsEnumerator];
			
			MADDatabaseField *databaseField;
			for (MADDataColumn *dataColumn in columnsEnumerator) {
				databaseField = resultsDictionary[dataColumn.fieldName];
				if (databaseField) { // Ensure the field exists in the dictionary
					databaseField.fieldTypeNative = dataColumn.nativeType;
					databaseField.fieldType = [MADDataTypeMySQL dataTypeForNativeType:dataColumn.nativeType];
					databaseField.width = dataColumn.dataLength;
					databaseField.decimals = (int16_t)dataColumn.dataPercision;
					databaseField.primaryKey = dataColumn.isPrimaryKey;
				}
			}
		}
	}
	
	NSError *errorResult = errorShowColumns == nil ? errorColumnMetaData : errorShowColumns;
	if (errorResult != nil && error != NULL) { // Check if error is not NULL before dereferencing
		*error = [errorResult copy]; // Use copy to ensure immutability
	}
	
	NSArray *resultValues = resultsDictionary.allValues;
	return resultValues;
}

- (id)connectWithConnection:(MADDatabaseConnection <MADConnectionsPropertiesProtocol> *)connection
				 credentals:(MADCredential *)credentals
			connectionError:(NSError * __autoreleasing *)error {

	if (credentals == nil) {
		credentals = [self credentalsWithConnection:connection];
	}

	BOOL success = NO;
	MysqlConnection *conn = nil;
	
	NSError *connError = nil;
	if (connection && credentals) {
		MysqlServer *serv = [[MysqlServer alloc] init];
		
		NSString *server = [connection server];
		serv.host = server.copy;
		
		NSString *database = connection.database;
		serv.schema = database.copy;
		
		serv.port = (unsigned int)connection.port;
		serv.user = credentals.username.copy;
		serv.password = credentals.password.copy;
		
		conn = [MysqlConnection connectToServer:serv error:&connError];
		
		success = (conn && connError == nil);
		if (!success && error != NULL) {
			*error = [connError copy];
		}
	} else {
		if (error != NULL) {
			*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:1001 userInfo:@{
				NSLocalizedDescriptionKey: NSLocalizedString(@"Error", @"Error"),
				NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Missing connection or credentials.", @"Missing connection or credentials."),
			}];
		}
	}
	
	return success ? conn : nil;
}

- (BOOL)executeSQL:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn intoResultTable:(MADDataTable *)dataTable
		 withError:(NSError * __autoreleasing *)error {
	
	MysqlFetch *myFetch = [[MysqlFetch alloc] init];
	myFetch.delegate = self;
	
	NSError *fetchError = nil;
	[myFetch fetchWithCommand: sql dataTable: &dataTable onConnection:dbconn extendedNames:YES error: &fetchError];
	
	return fetchError == nil;
}

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError * __autoreleasing *)error {
	MADDataTable *dataTable;
	if ([query conformsToProtocol:@protocol(MADQueryDataTableProtocol)] &&
		((MADQuery <MADQueryDataTableProtocol> *)query).dataTable != nil) {
		dataTable = ((MADQuery <MADQueryDataTableProtocol> *)query).dataTable;
	} else {
		dataTable = [self.delegate dataTableForQuery:query];
	}
	NSError *executeError = nil;
	BOOL result = [self executeQuery:query withDataTable:dataTable andError:&executeError];
	if (executeError != nil && error != NULL) {
		*error = [executeError copy];
	}
	return result;
}

- (BOOL)executeQuery:(MADQuery *)query withDataTable:(MADDataTable *)dataTable andError:(NSError * __autoreleasing *)error {
	BOOL result = NO;
	id connectionSettings = self.databaseConnection;
	NSError * __autoreleasing dberror = nil;
	MADCredential *c = nil;
	if ([query conformsToProtocol:@protocol(MADQueryCredentialProtocol)]) {
		c = ((MADQuery <MADQueryCredentialProtocol> *)query).credential.copy;
	}
	
	MysqlConnection *dbconn = [self connectWithConnection:connectionSettings
											   credentals:c
										  connectionError:&dberror];
	if (dbconn && dberror == nil) {
		MysqlFetch *myFetch = [[MysqlFetch alloc] init];
		myFetch.delegate = self;
		
		NSError * __autoreleasing sqlError = nil;
		NSString *queryString = [query getSql:self error:&sqlError];
		if (queryString != nil && queryString.length > 0 && sqlError == nil) {
			[myFetch fetchWithCommand:queryString
							 dataTable:&dataTable
						  onConnection:dbconn
								 error:&sqlError];
		}
		if (sqlError) {
			if (error != NULL) {
				*error = [NSError errorWithDomain:NSStringFromClass([self class]) code:sqlError.code userInfo:@{
					NSLocalizedDescriptionKey: sqlError.localizedDescription,
					NSLocalizedFailureReasonErrorKey: sqlError.localizedFailureReason ?: @"Unknown error",
				}];
			}
		} else {
			result = YES;
		}
	} else {
		if (dberror != nil && error != NULL) {
			*error = [dberror copy];
		}
	}
	return result;
}

- (NSString *)domain { return NSStringFromClass([self class]); }

- (void)closeConnection:(id)process {
	mysql_close(((MysqlConnection *)process).connection);
}

- (NSString *)identifier {
	return self.databaseConnection.identifier;
}

- (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName {
	return [MADDatabaseMySQL newSafeQueryField:fieldName andTable:tableName];
}

- (MADSafeQueryField *)safeIdentifierForTable:(NSString *)tableName andField:(NSString *)fieldName {
	return [[NSString alloc] initWithFormat:@"`%@`.`%@`", tableName, fieldName];
}

- (MADSafeQueryField *)newSafeIdentifier:(NSString *)fieldOrTableName {
	return [[NSString alloc] initWithFormat:@"`%@`", fieldOrTableName];
}

#pragma mark - MADDatabase

- (void)enumerateTablesFromConnection:(id)dbconn
						   usingBlock:(void (^)(MADDatabaseTable *obj, NSUInteger index, BOOL *stop))block
						   completion:(void (^)(BOOL, NSError *, NSArray *))completion {
	NSError *error = nil;
	MysqlConnection *connection = dbconn;
	MysqlFetch *myFetch = [[MysqlFetch alloc] init];
	NSString *identifier = @"v999";
	MADDataTable *dataTableVirtual = [[MADDataTableVirtual alloc] initWithId:identifier.hash];
	MADDataTable *dataTable = [myFetch fetchWithCommand: @"SHOW TABLES;"
											 dataTable: &dataTableVirtual
										  onConnection: connection
												 error: &error];
	
	
	NSMutableArray *results = nil;
	if (error == nil) {

		NSUInteger resultsCount = [dataTable count];
		results = [[NSMutableArray alloc] initWithCapacity: resultsCount];
		NSUInteger counter = 0;

		BOOL stop = NO;
		for (NSUInteger i=0; i<[dataTable count]; i++) {
			@autoreleasepool {

				NSString *tableName = [dataTable objectAtRow:i column:0];
				MADDatabaseTable *table = [[MADDatabaseTable alloc] initWithTableName:tableName];

				[results addObject:table];

				block(table, counter, &stop);
				if (stop) break;
				counter++;

			}
		}
	}
	if (completion) completion(error == nil, error, results);
}

#pragma mark -
#pragma mark MADMySQLFetchProtocol

- (MADDataTable *)dataTableForQuery:(MADQuery *)query {
	return [self.delegate dataTableForQuery:query];
}

- (void)didFetchRow:(NSUInteger)row {
	[self readRow:row];
}

@end
