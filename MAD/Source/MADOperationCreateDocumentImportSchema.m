//
//  MADOperationCreateDocumentImportSchema.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/25/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADOperationCreateDocumentImportSchema.h"
#import "MADOperationCreateDocumentCreateDocument.h"
#import "madlog.h"

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseTable.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADErrorContainer.h>

#import <MADFoundation/MADOperationResultStringProtocol.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADNotificationProgress.h>

#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADocument.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

#import <CoreData/NSManagedObjectContext.h>

@interface MADOperationCreateDocumentImportSchema ()

@property (nonatomic, assign, readwrite, getter=isSuccess) BOOL success;
@property (nonatomic, copy) MADDatabaseConnection *databaseConnection;
@property (nonatomic, copy) MADCredential *credentials;

@end

@implementation MADOperationCreateDocumentImportSchema {
	NSError *_displayError;
	NSUInteger _tag;
}

- (instancetype)init {
	return [self initWithDatabaseConnection:nil];
}

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection {
	MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> initWithDatabaseConnection: %@",
				self, self.name, databaseConnection.identifier);
	if (self = [super init]) {
		self.databaseConnection = [databaseConnection copy];
		self.success = NO;
		_displayError = nil;
		_tag = self.hash;
		if (!databaseConnection) {
			MADLogError("MADOperationCreateDocumentImportSchema <%p:%@> initialized with a NIL databaseConnection. This will likely fail.",
						self, self.name);
		}
	}
	return self;
}

#pragma mark -
#pragma mark MADOperationPromptErrorProtocol

- (BOOL)displayError { return _displayError != nil; }
- (NSError *)error { return _displayError; }
- (NSUInteger)tag { return _tag; }
- (BOOL)isAsynchronous { return YES; }

- (void)execute {
	MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> execute started. Cancelled: %s", self, self.name, self.isCancelled ? "YES" : "NO");
	
	if (self.isCancelled) {
		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> cancelled before execution. Finishing.", self, self.name);
		return [self finish];
	}

	if (!self.databaseConnection) {
		MADLogError("MADOperationCreateDocumentImportSchema <%p:%@> databaseConnection is nil. Cannot proceed. Finishing with error.", self, self.name);
		NSError *configError = [NSError errorWithDomain:NSStringFromClass([self class])
												   code:-1001
											   userInfo:@{NSLocalizedDescriptionKey: @"Database connection not provided for schema import."}];
		[self finishWithError:configError];
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
					NSString *value = ((NSObject <MADOperationResultStringProtocol> *)operation).value.copy;
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
			if (username != nil || password != nil) {
				MADCredential *credentials = [[MADCredential alloc] initWithUsername: username
																		 andPassword: password];
				self.credentials = credentials;
			}
		}
	}
	
	MADocument * document = nil;
	NSArray <NSOperation *> *currentDependencies = self.dependencies;
	MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> searching for document in %lu dependencies.",
				self, self.name, (unsigned long)currentDependencies.count);
	for (NSOperation *dependency in currentDependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
			document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
			MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> found document <%p> from dependency <%p:%@>",
						self, self.name, document, dependency, dependency.name);
			break;
		}
	}
	
	if (!document) {
		MADLogError("MADOperationCreateDocumentImportSchema <%p:%@> Failed to find MADocument from dependencies. Cannot proceed.", self, self.name);
		NSError *docError = [NSError errorWithDomain:NSStringFromClass([self class])
												code:-1000
											userInfo:@{NSLocalizedDescriptionKey: @"Document object not found for schema import."}];
		[self finishWithError:docError];
		return;
	}
	MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> Using document: <%p> with MOC: <%p>",
				self, self.name, document, document.managedObjectContext);
	
	if (self.isCancelled) {
		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> cancelled after finding document. Finishing.", self, self.name);
		return [self finish];
	}

	BOOL __block operationSuccess = NO;
	NSError __block *operationError = nil;
	NSManagedObjectContext *privateMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	privateMOC.parentContext = document.managedObjectContext;
	MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> Created private MOC <%p> with parent MOC <%p>",
				self, self.name, privateMOC, document.managedObjectContext);
	
	//MADocument * __weak weakdoc = document;
	MADOperationCreateDocumentImportSchema * __weak weakself = self;
	
	[privateMOC performBlockAndWait:^{
		MADOperationCreateDocumentImportSchema *strongSelf = weakself;
		if (!strongSelf || strongSelf.isCancelled) {
			MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> (in privateMOC block) self is nil or operation cancelled. Aborting.",
						strongSelf, strongSelf.name);
			if (strongSelf.isCancelled) operationSuccess = NO; // Ensure success is not inadvertently true
			return;
		}
		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> (in privateMOC block) starting schema import logic.",
					strongSelf, strongSelf.name);
		
		RptqDocument *rptqDocument = [RptqDocument newDocumentReadFromManagedObjectContext: privateMOC];
		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>   RptqDocument created/read.", strongSelf, strongSelf.name);
		
		[rptqDocument storeDatabaseConnectionDefination:document.database forManagedObjectContext:privateMOC];
		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>   Stored DB connection definition in RptqDocument.", strongSelf, strongSelf.name);
		
		MADErrorContainer *errorContainer = [MADErrorContainer new];
		NSError *dbConnectionError = nil;
		id actualDBConnection = [document.database connectWithConnection: document.database.databaseConnection
															  credentals: self.credentials
														 connectionError: &dbConnectionError];
		
		if (dbConnectionError != nil) {
			MADLogError("MADOperationCreateDocumentImportSchema <%p:%@>   DB CONNECTION FAILED for schema import. Error: %@",
						strongSelf, strongSelf.name, dbConnectionError);
			operationSuccess = NO;
			operationError = [dbConnectionError copy];
			return; // Exit performBlockAndWait's block
		}

		if (!actualDBConnection) {
			MADLogError("MADOperationCreateDocumentImportSchema <%p:%@>   DB CONNECTION FAILED (nil connection object, no error reported) for schema import. This indicates an issue with the driver or connection logic.", strongSelf, strongSelf.name);
			operationSuccess = NO;
			// Create a generic error if dbConnectionError was also nil
			operationError = [NSError errorWithDomain:NSStringFromClass([strongSelf class])
												 code:-1002
											 userInfo:@{NSLocalizedDescriptionKey: @"Failed to establish database connection for schema import (nil connection object)."}];
			return; // Exit performBlockAndWait's block
		}
		
		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>   DB connection for schema import ESTABLISHED successfully. Connection object: <%p>",
					strongSelf, strongSelf.name, actualDBConnection);
		NSMutableDictionary *tablesAndFields = [[NSMutableDictionary alloc] init];
		NSMutableArray <MADDatabaseTable *> *tables = [[NSMutableArray alloc] init];
		
		NSError *getTableErr = nil;
		NSArray *resultTables = [document.database getTablesFromConnection: actualDBConnection
																	 error: &getTableErr];
		if (getTableErr != nil) {
			MADLogError("MADOperationCreateDocumentImportSchema <%p:%@>   FAILED to get tables from source database. Error: %@",
						strongSelf, strongSelf.name, getTableErr);
			operationSuccess = NO;
			operationError = [getTableErr copy];
			return;
		}
		
		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>   Successfully fetched %lu tables from source database.",
					strongSelf, strongSelf.name, (unsigned long)resultTables.count);
		if (resultTables.count == 0) {
			MADLogInfo("MADOperationCreateDocumentImportSchema <%p:%@>   Fetched 0 tables from source database. This might be the cause of 'empty schema'. Check DB permissions and driver behavior.", strongSelf, strongSelf.name);
			// This is not necessarily an error that stops the operation, but it's a critical warning.
		}
		
		[tables setArray:resultTables];
		
		NSUInteger counter = 0;
		NSUInteger numberOfTables = tables.count;
		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>   Processing %lu tables for fields...",
					strongSelf, strongSelf.name, (unsigned long)numberOfTables);
		for (MADDatabaseTable *databaseTable in tables) {
			if (strongSelf.isCancelled) {
				MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>   (in table loop) Operation cancelled. Aborting field fetch.", strongSelf, strongSelf.name);
				operationSuccess = NO; // Or reflect partial success/cancellation
				[document.database closeConnection:actualDBConnection];
				return;
			}
			@autoreleasepool {
				
				NSString *tableName = [databaseTable.name copy]; // Defensive copy
				MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>     Processing table: \"%@\" (%lu/%lu)",
							strongSelf, strongSelf.name, tableName, (unsigned long)(counter + 1), (unsigned long)numberOfTables);
				
				[strongSelf.parentOperation updateImportProgressWithMessage: tableName
																   progress: (float)(counter + 1) / (float)numberOfTables];
				
				NSError *getFieldsError = nil;
				NSArray *fieldsForTable = [document.database fieldsForTable: tableName
																 connection: actualDBConnection
																	  error: &getFieldsError];
				if (getFieldsError != nil) {
					MADLogError("MADOperationCreateDocumentImportSchema <%p:%@>     FAILED to get fields for table \"%@\". Error: %@",
								strongSelf, strongSelf.name, tableName, getFieldsError);
				} else {
					MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>     Table \"%@\" has %lu fields.",
								strongSelf, strongSelf.name, tableName, (unsigned long)fieldsForTable.count);
					if (fieldsForTable.count == 0) {
						MADLogInfo("MADOperationCreateDocumentImportSchema <%p:%@>     Table \"%@\" has 0 fields. This may be unexpected.", strongSelf, strongSelf.name, tableName);
					}
				}
				
				NSArray *fields = [[NSArray alloc] initWithArray:fieldsForTable];
				tablesAndFields[databaseTable.name] = fields;
				
			}
			counter++;
		}
		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>   Finished processing fields for all tables.", strongSelf, strongSelf.name);
		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>   Storing tables and fields into RptqDocument...", strongSelf, strongSelf.name);
		MADErrorContainer *additionalStorageErrors = [rptqDocument storeTablesAndFieldsForTables: tables
																				   fieldsByTable: tablesAndFields
																		 andManagedObjectContext: privateMOC];
		[errorContainer addErrorsFromContainer:additionalStorageErrors];
		if ([additionalStorageErrors count] > 0) {
			MADLogError("MADOperationCreateDocumentImportSchema <%p:%@>   Errors encountered while storing tables/fields in RptqDocument: %@",
						strongSelf, strongSelf.name, [additionalStorageErrors allObjects]);
		} else {
			MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>   Successfully stored tables/fields in RptqDocument.", strongSelf, strongSelf.name);
		}

		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@>   Closing source database connection.", strongSelf, strongSelf.name);
		[document.database closeConnection:actualDBConnection];

		operationSuccess = YES;
		
		NSError *saveError = nil;
		operationSuccess = [privateMOC save:&saveError];
		if (!operationSuccess && saveError != nil) {
			os_log_error(GetMadLog(), "Error saving managed object: %@", saveError);
		}
		if (saveError) {
			operationError = [saveError copy];
		}

	}];
	
	MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> (after privateMOC block) Finalizing. Operation success state: %s",
				self, self.name, operationSuccess ? "YES" : "NO");
	if (!self.isCancelled) { // Check cancellation again before final state update
		[document updateChangeCount:UIDocumentChangeDone]; // Mark document as changed
		self.success = operationSuccess; // Set the operation's public success property
		_displayError = [operationError copy]; // Copy the primary error, if any
		
		if (self.success) {
			MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> Finishing successfully.", self, self.name);
			[self finish];
		} else {
			MADLogError("MADOperationCreateDocumentImportSchema <%p:%@> Finishing with error: %@", self, self.name, operationError);
			[self finishWithError:operationError]; // Pass the specific error
		}
	} else {
		MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> was cancelled during MOC block or just before finish. Forcing failure state.", self, self.name);
		self.success = NO;
		// Ensure an error is reported if cancelled mid-process
		if (!operationError) {
			operationError = [NSError errorWithDomain:NSStringFromClass([self class]) code:NSUserCancelledError userInfo:@{NSLocalizedDescriptionKey:@"Schema import was cancelled."}];
		}
		_displayError = [operationError copy];
		[self finishWithError:operationError];
	}
}

- (void)finishWithError:(NSError *)error {
	MADLogDebug("MADOperationCreateDocumentImportSchema <%p:%@> finishWithError called. Error: %@", self, self.name, error);
	if (error && !_displayError) { // If an external error is passed (e.g. from super on cancel) and we don't have one yet
		_displayError = [error copy];
	}
	[super finishWithError:error];
}

@end
