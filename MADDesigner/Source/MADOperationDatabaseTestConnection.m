//
//  MADDatabaseOperationTest.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/16/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationDatabaseTestConnection.h"
#import <MADFoundation/madlog.h>

#import <MADFoundation/MADDataTableType.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADDataTableVirtual.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>

#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADQueryTest.h>
#import <MAD/MADOperationKeyChainGet.h>
#import <MAD/MADDatabase+Constructor.h>

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSError.h>

@interface MADOperationDatabaseTestConnection () <MADDatabaseResultsProtocol>

//Parameters
@property (nonatomic, copy) MADDatabaseConnection *databaseConnection;
@property (nonatomic, copy) MADCredential *credentials;

//Store
@property (nonatomic, strong) MADDatabase *database;
@property (nonatomic, strong) MADDataTable *datatable;

//Results
@property (nonatomic, readwrite, strong) NSError *error;
@property (nonatomic, readwrite, assign) BOOL success;

@end

@implementation MADOperationDatabaseTestConnection

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection {
	MADLogDebug("MADOperationDatabaseTestConnection <%p:%@> initWithDatabaseConnection: %@",
				self, self.name, connection.identifier);
	if (self = [super init]) {
		_databaseConnection = [connection copy];
		_credentials = nil;
		_success = NO;
		if (!connection) {
			MADLogInfo("MADOperationDatabaseTestConnection <%p:%@> initialized with a NIL databaseConnection.", self, self.name);
		}
	}
	return self;
}

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)connection
							   credentials:(MADCredential *)credentials {
	MADLogDebug("MADOperationDatabaseTestConnection <%p:%@> initWithDatabaseConnection: %@, credentials: %s",
				self, self.name, connection.identifier, credentials ? "provided" : "nil");
	if (self = [super init]) {
		_databaseConnection = [connection copy];
		_credentials = [credentials copy];
		_success = NO;
		if (!connection) {
			MADLogInfo("MADOperationDatabaseTestConnection <%p:%@> initialized with a NIL databaseConnection.", self, self.name);
		}
	}
	return self;
}

- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	MADLogDebug("MADOperationDatabaseTestConnection <%p:%@> execute started. Cancelled: %s. DB Connection ID: %@",
				self, self.name, self.isCancelled ? "YES" : "NO", self.databaseConnection.identifier);

	if (self.isCancelled) {
		MADLogDebug("MADOperationDatabaseTestConnection <%p:%@> cancelled before execution. Finishing.", self, self.name);
		return [self finish];
	}
	if (!self.databaseConnection) {
		MADLogError("MADOperationDatabaseTestConnection <%p:%@> databaseConnection is nil. Cannot proceed. Finishing with error.", self, self.name);
		self.error = [NSError errorWithDomain:NSStringFromClass([self class])
										 code:-2001
									 userInfo:@{NSLocalizedDescriptionKey: @"Database connection not provided for connection test."}];
		self.success = NO;
		[self finishWithError:self.error];
		return;
	}
	
	if (self.credentials == nil) {
		MADLogDebug("MADOperationDatabaseTestConnection <%p:%@> Credentials not set directly, attempting to find from dependencies.",
					self, self.name);
		NSString *username = nil;
		NSString *password = nil;
		
		NSArray <NSOperation *> *dependencies = self.dependencies;
		for (NSOperation *operation in dependencies) {

			if ([operation conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)]) {
 
				if (((NSOperation <MADOperationHoldsCredentialsProtocol> *)operation).gotCredentials) {
					MADCredential *credentials;
					credentials = ((NSOperation <MADOperationHoldsCredentialsProtocol> *)operation).credentials.copy;
					self.credentials = credentials;
					break;
				}
				
			} else if ([operation conformsToProtocol:@protocol(MADOperationResultStringProtocol)]) {
				if (((NSObject <MADOperationResultStringProtocol> *)operation).success) {
					NSString *value;
					value = ((NSObject <MADOperationResultStringProtocol> *)operation).value.copy;
					switch (((NSObject <MADOperationResultStringProtocol> *)operation).readOperationType) {
						case MADKeyChainReadOperationTypeUsername:
							username = value;
							break;
						case MADKeyChainReadOperationTypePassword:
							password = value;
							break;
							
						default:
							break;
					}
				}
			}
		}
		
		if (self.credentials == nil) {
			if (username != nil && password != nil) {
				MADCredential *credentials = [[MADCredential alloc] initWithUsername: username
																		 andPassword: password];
				self.credentials = credentials;
			}
		}
	}
	
	// If we still don't have credentials, then fail.
	if (self.credentials == nil) {
		NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:@{
			NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Test Failed", @"Test Failed"),
			NSLocalizedDescriptionKey: NSLocalizedString(@"Credentials not found.", @"Credentials not found.")
		}];
		self.error = [error copy];
		[self finishWithError:error];
		return;
	}
	
	MADDatabaseConnection *databaseConnection = self.databaseConnection;
	MADQueryTest *queryTest = [[MADQueryTest alloc] initWithObject: databaseConnection];
	__kindof MADDataTable *datatable = [[MADDataTableVirtual alloc] initWithId: databaseConnection.hash];
	self.datatable = datatable;
	
	MADDatabase *db = [MADDatabase newDatabaseWithConnection:databaseConnection];
	db.delegate = self;
	queryTest.database = db;
	self.database = db;
	
	NSError *error = nil;
	BOOL success = [queryTest.database executeQuery:queryTest withError:&error];
	if (!success && error != nil) {
		MADLogError("MADOperationDatabaseTestConnection <%p:%@> Test query failed.", self, self.name);
	}
	self.success = success;
	
	_databaseConnection = nil;
	
	if (self.success) {
		[self finish];
	} else {
		if (error == NULL) {
			self.error = nil;
			[self finishWithError:nil];
		} else {
			NSError *err = error;
			self.error = error;
			[self finishWithError:err];
		}
	}
}

- (void)cleanup {
	[super cleanup];
	_credentials = nil;
	_database = nil;
	_datatable = nil;
	_databaseConnection = nil;
}

- (BOOL)isSuccess { return _success; }
- (BOOL)displayError { return !self.success && self.error != nil; }
- (NSUInteger)tag { return self.hash; }
- (MADCredential *)getCredentialsForKey:(NSString *)key { return self.credentials; }
- (MADDataTable *)dataTableForQuery:(MADQuery *)query { return self.datatable; }

@end
