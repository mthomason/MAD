//
//  MADOperationCreateDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADOperationCreateDocument.h"
#import "MADOperationGetCredentials.h"
#import "MADOperationDatabaseTestConnection.h"
#import "MADOperationPromptPolarQuestion.h"
#import "MADOperationConditionPolarQuestionAffirmative.h"
#import "MADOperationConditionDisplayedAlertConfirm.h"
#import "MADOperationConditionSuccess.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADDatabaseConnection.h>
#import <MAD/MADConstants.h>
#import <MADFoundation/MADNotificationProgress.h>
#import <MADFoundation/MADKeyChain.h>

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADOperationConditionTestConnectionSuccess.h>
#import <MADFoundation/MADOperationConditionHasResultString.h>

#import <MAD/MADOperationKeyChainGet.h>
#import <MAD/MADOperationKeyChainPut.h>
#import <MAD/MADOperationKeyChainDeletePassword.h>
#import <MAD/MADOperationUniqueUrlForFilename.h>
#import <MAD/MADOperationCreateDocumentCreateDocument.h>
#import <MAD/MADOperationBackgroundTaskBegin.h>
#import <MAD/MADOperationCreateDocumentFirstTimeSetup.h>
#import <MAD/MADOperationBackgroundTaskEnd.h>
#import <MAD/MADOperationCreateDocumentAddConnection.h>
#import <MAD/MADOperationCreateDocumentImportSchema.h>
//#import <MAD/MADOperationCreateDocumentSaveAndCloseNewDocument.h>
#import <MAD/MADOperationDocumentCloseDocument.h>
#import <MAD/MADOperationDeleteFile.h>

@interface MADOperationCreateDocument () <MADOperationCreateDocumentImportSchemaProtocol>

	@property (nonatomic, assign, readwrite, getter=isSuccessConnection) BOOL successConnection;
	@property (nonatomic, assign, readwrite, getter=isSuccessCreate) BOOL successCreate;
 
@end

@implementation MADOperationCreateDocument

- (void)dealloc { }

- (instancetype)initWithFilename: (NSString *)filename
			  documentsDirectory: (NSURL *)documentsDirectory
			  databaseConnection: (MADDatabaseConnection *)databaseConnection
				  viewController: (UIViewController *)viewController {
	
	MADLogDebug("MADOperationCreateDocument <%p> initializing with Filename:\"%@\", DB Connection ID:\"%@\" (Type:%d)",
				self, filename, databaseConnection.identifier, (int)databaseConnection.databaseType);
	
	if (self = [super init]) {
		
		_connectionSuccess = NO;
		_successCreate = NO;
		self.name = [NSString stringWithFormat:@"CreateDocumentGroupOp_for_%@", filename];
		NSString *key = databaseConnection.connectionString;
		NSString *keyUsername = [MADKeyChain newKeyForUsernameWithMainKey: key];
		NSString *keyPassword = [MADKeyChain newKeyForPasswordWithMainKey: key];
		MADLogDebug("MADOperationCreateDocument <%p> Keychain keys generated. MainKey (connStr):\"%@\", UserKey:\"%@\", PassKey:\"%@\"",
					self, key, keyUsername, keyPassword);
		
		// --- Conditions Setup ---
		MADLogDebug("MADOperationCreateDocument <%p> Setting up conditions...", self);
		MADOperationConditionHasResultString *conditionReadUsername = [[MADOperationConditionHasResultString alloc] initWithKey:keyUsername];
		MADOperationConditionTestConnectionFailuare *connectionConnectionFail = [[MADOperationConditionTestConnectionFailuare alloc] init];
		MADOperationConditionDisplayedAlertConfirm *conditionEnteredPassword = [[MADOperationConditionDisplayedAlertConfirm alloc] init];
		MADOperationConditionTestConnectionSuccess *conditionConnectionConnectionSuccess = [[MADOperationConditionTestConnectionSuccess alloc] init];

		MADLogDebug("MADOperationCreateDocument <%p> Instantiating sub-operations...", self);
		MADOperationUniqueUrlForFilename *uniqueUrlForFilename = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename: filename
																													 pathExtension: MADFileExtentionMobleApplicationDocument
																											 andDocumentsDirectory: documentsDirectory];
		uniqueUrlForFilename.name = @"com.everydayapps.mad.operation.uniqueurl";

		// ---------------------------------------------------
		// Operation 1: Get database credentials from keychain or user.
		// -------------------------
		
		MADOperationGetCredentials *getCredentials = [[MADOperationGetCredentials alloc] initWithDatabaseConnection: databaseConnection
																									 viewController: viewController];
		getCredentials.name = @"com.everydayapps.mad.operation.credentials.get";

		
		// ---------------------------------------------------
		// Operation 1: Test the database connection.
		// -------------------------
		
		MADOperationDatabaseTestConnection *testConnectionOperationCredentials = [[MADOperationDatabaseTestConnection alloc] initWithDatabaseConnection: databaseConnection];
		testConnectionOperationCredentials.name = @"com.everydayapps.mad.operation.connection.test";
		[testConnectionOperationCredentials addDependency:getCredentials];
		
		MADOperationPromptError *displayErrorCredentials = [[MADOperationPromptError alloc] initWithViewController:viewController];
		displayErrorCredentials.name = @"com.everydayapps.mad.operation.display.error.credentials";
		[displayErrorCredentials addDependency:testConnectionOperationCredentials];
		
		
		// Start a background task
		MADOperationBackgroundTaskBegin *taskBegin = [[MADOperationBackgroundTaskBegin alloc] init];
		taskBegin.name = @"com.everydayapps.mad.operation.document.create.begin";
		[taskBegin addDependency: getCredentials];
		[taskBegin addDependency: testConnectionOperationCredentials];
		[taskBegin addDependency: displayErrorCredentials];
		
		// ---------------------------------------------------
		// Operation:   Prompt save credentials
		// Conditions:  User entered a credentials.
		// ---------------------------------------------------
		MADOperationPromptPolarQuestion *promptSavePassword = [[MADOperationPromptPolarQuestion alloc] initWithTitle: NSLocalizedString(@"Save to KeyChain", @"Save to KeyChain")
																											 message: NSLocalizedString(@"Would you like to save your password?", @"Would you like to save your password?")
																									  viewController: viewController];
		promptSavePassword.name = @"com.everydayapps.mad.operation.credentials.prompt.save";
		[promptSavePassword addDependency: testConnectionOperationCredentials];
		[promptSavePassword addDependency: getCredentials];
		[promptSavePassword addCondition: conditionEnteredPassword];
		[promptSavePassword addCondition: conditionConnectionConnectionSuccess];
		
		MADOperationConditionPolarQuestionAffirmative *promptToSaveCredntialsAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:promptSavePassword.identifier];
		
		// ---------------------------------------------------
		// Operation:   Save username
		// Dependency:  Prompt save credentials.
		// Conditions:  User said yes to save credentials.
		// ---------------------------------------------------

		MADOperationKeyChainPut *putUsername = [[MADOperationKeyChainPut alloc] initWithKey:keyUsername description:MADKeyChainUsernameAccountDesc];
		putUsername.name = @"com.everydayapps.mad.operation.credentials.save.username";
		[putUsername addDependency: promptSavePassword];
		[putUsername addDependency: getCredentials];
		[putUsername addCondition: promptToSaveCredntialsAffirmative];
		
		// ---------------------------------------------------
		// Operation:   Save password
		// Dependency:  Prompt save credentials.
		// Conditions:  User said yes to save credentials..
		// ---------------------------------------------------
		MADOperationKeyChainPut *putPassword = [[MADOperationKeyChainPut alloc] initWithKey:keyPassword description:MADKeyChainPasswordAccountDesc];
		putPassword.name = @"com.everydayapps.mad.operation.credentials.save.password";
		[putPassword addDependency: promptSavePassword];
		[putPassword addDependency: getCredentials];
		[putPassword addCondition: promptToSaveCredntialsAffirmative];
		
		// Create the document file on disk.
		MADOperationCreateDocumentCreateDocument *createDocument = [[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection:databaseConnection];
		createDocument.name = @"com.everydayapps.mad.operation.document.create.file";
		[createDocument addDependency: getCredentials];  // This is because the document uses this task as delegate to get credentials.
		[createDocument addDependency: uniqueUrlForFilename];
		[createDocument addDependency: taskBegin];
		[createDocument addDependency: displayErrorCredentials];
		[createDocument addDependency: testConnectionOperationCredentials];
		[createDocument addCondition: conditionConnectionConnectionSuccess];
		
		// Do first time document setup.
		MADOperationCreateDocumentFirstTimeSetup *firstTimeSetup = [[MADOperationCreateDocumentFirstTimeSetup alloc] init];
		firstTimeSetup.name = @"com.everydayapps.mad.operation.document.create.setup";
		[firstTimeSetup addDependency: createDocument];
		[firstTimeSetup addDependency: displayErrorCredentials];
		[firstTimeSetup addDependency: testConnectionOperationCredentials];
		[firstTimeSetup addCondition: conditionConnectionConnectionSuccess];
		
		// Add databaes connection to document.
		MADOperationCreateDocumentAddConnection *addConnection = [[MADOperationCreateDocumentAddConnection alloc] initWithDatabaseConnection:databaseConnection];
		addConnection.name = @"com.everydayapps.mad.operation.document.create.connection";
		[addConnection addDependency: createDocument];
		[addConnection addDependency: firstTimeSetup];
		[addConnection addDependency: displayErrorCredentials];
		[addConnection addDependency: testConnectionOperationCredentials];
		[addConnection addCondition: conditionConnectionConnectionSuccess];
		
		// Import schema into document.
		MADOperationCreateDocumentImportSchema *importSchema = [[MADOperationCreateDocumentImportSchema alloc] initWithDatabaseConnection:databaseConnection];
		importSchema.name = @"com.everydayapps.mad.operation.document.import.schema";
		[importSchema addDependency: createDocument];
		[importSchema addDependency: addConnection];
		[importSchema addDependency: getCredentials];
		[importSchema addDependency: displayErrorCredentials];
		[importSchema addDependency: testConnectionOperationCredentials];
		[importSchema addCondition: conditionConnectionConnectionSuccess];
		importSchema.parentOperation = self;
		
		//MADOperationConditionSuccess *conditionSuccessImport = [[MADOperationConditionSuccess alloc] initWithKey: importSchema.name];

		MADOperationConditionSuccess *conditionFailedImport = [[MADOperationConditionSuccess alloc] initWithKey: importSchema.name];
		conditionFailedImport.reverseCondition = YES;

		MADOperationPromptError *displayErrorImport = [[MADOperationPromptError alloc] initWithViewController:viewController];
		displayErrorImport.name = @"com.everydayapps.mad.operation.display.error.import.schema";
		[displayErrorImport addDependency: importSchema];
		[displayErrorImport addCondition: conditionFailedImport];
		/*
		// Save the new document.
		MADOperationCreateDocumentSaveAndCloseNewDocument *saveOperation;
		saveOperation = [[MADOperationCreateDocumentSaveAndCloseNewDocument alloc] init];
		saveOperation.name = @"com.everydayapps.mad.operation.document.save";
		[saveOperation addDependency: createDocument];
		[saveOperation addDependency: importSchema];
		[saveOperation addDependency: displayErrorCredentials];
		[saveOperation addDependency: testConnectionOperationCredentials];
		[saveOperation addCondition: conditionConnectionConnectionSuccess];
		[saveOperation addCondition: conditionSuccessImport];
		*/
		// Close the new document.
		MADOperationDocumentCloseDocument *closeDocument = [[MADOperationDocumentCloseDocument alloc] init];
		closeDocument.name = @"com.everydayapps.mad.operation.document.close";
		[closeDocument addDependency: createDocument];
		[closeDocument addDependency: importSchema];
		[closeDocument addDependency: displayErrorCredentials];
		[closeDocument addDependency: testConnectionOperationCredentials];
		//[closeDocument addDependency: saveOperation];
		
		//Test if credentals are saved
		MADOperationKeyChainGet *operationGetUsername = [[MADOperationKeyChainGet alloc] initWithKey: keyUsername
																					 withDescription: MADKeyChainUsernameAccountDesc];
		operationGetUsername.name = @"com.everydayapps.mad.operation.keychain.read.username";
		operationGetUsername.readOperationType = MADKeyChainReadOperationTypeUsername;
		[operationGetUsername addDependency: displayErrorCredentials];
		[operationGetUsername addDependency: testConnectionOperationCredentials];

		//If connection failed and credentals are saved, prompt to delete credentals.
		MADOperationPromptPolarQuestion *promptDeleteCredntials = [[MADOperationPromptPolarQuestion alloc] initWithTitle: @"Delete saved credentials?"
																												 message: @"Would you like to remove the saved credentials"
																										  viewController: viewController];
		promptDeleteCredntials.name = @"com.everydayapps.mad.operation.credentials.prompt.delete";
		[promptDeleteCredntials addDependency: operationGetUsername];
		[promptDeleteCredntials addDependency: displayErrorCredentials];
		[promptDeleteCredntials addDependency: testConnectionOperationCredentials];
		[promptDeleteCredntials addCondition: connectionConnectionFail];
		[promptDeleteCredntials addCondition: conditionReadUsername];
		
		MADOperationConditionPolarQuestionAffirmative *promptDeletePasswordAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier: promptDeleteCredntials.identifier];
		MADOperationKeyChainDeletePassword *operationDeletePassword = [[MADOperationKeyChainDeletePassword alloc] initWithKey: databaseConnection.connectionString];
		operationDeletePassword.name = @"com.everydayapps.mad.operation.delete.password";
		[operationDeletePassword addDependency: promptDeleteCredntials];
		[operationDeletePassword addCondition: promptDeletePasswordAffirmative];
		
		MADOperationDeleteFile *operationDeleteFile = [[MADOperationDeleteFile alloc] init];
		operationDeleteFile.name = @"com.everydayapps.mad.operation.delete.file";
		[operationDeleteFile addDependency: uniqueUrlForFilename];
		//[operationDeleteFile addDependency: createDocument];
		[operationDeleteFile addDependency: importSchema];
		//[operationDeleteFile addDependency: saveOperation];
		[operationDeleteFile addDependency: closeDocument];
		[operationDeleteFile addCondition: conditionFailedImport];

		MADOperationBackgroundTaskEnd *taskEnd = [[MADOperationBackgroundTaskEnd alloc] init];
		taskEnd.name = @"com.everydayapps.mad.operation.create.document.end";
		[taskEnd addDependency: putUsername];
		[taskEnd addDependency: putPassword];
		[taskEnd addDependency: promptSavePassword];
		[taskEnd addDependency: taskBegin];
		[taskEnd addDependency: importSchema];
		[taskEnd addDependency: operationGetUsername];
		//[taskEnd addDependency: saveOperation];
		[taskEnd addDependency: closeDocument];
		[taskEnd addDependency: promptDeleteCredntials];
		[taskEnd addDependency: operationDeletePassword];
		
		NSArray <__kindof NSOperation *> *operations = @[promptSavePassword,
														 putUsername,
														 putPassword,
														 uniqueUrlForFilename,
														 getCredentials,
														 taskBegin,
														 displayErrorImport,
														 createDocument,
														 displayErrorCredentials,
														 testConnectionOperationCredentials,
														 firstTimeSetup,
														 addConnection,
														 importSchema,
														 //saveOperation,
														 closeDocument,
														 taskEnd,
														 operationGetUsername,
														 operationDeleteFile,
														 promptDeleteCredntials,
														 operationDeletePassword];
		
		NSBlockOperation *groupFinishingSignal = [NSBlockOperation blockOperationWithBlock:^{
			MADLogDebug("MADOperationCreateDocument <%p> All internal operations for group have completed (groupFinishingSignal executed).", self);
		}];
		[self addOperations:operations finishingOperation:groupFinishingSignal];
		
	}
	
	return self;
}

- (void)execute {
	MADLogDebug("MADOperationCreateDocument <%p:%@> execute called. Delegating to [super execute].", self, self.name);
	[super execute];
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray<NSError *> *)errors {
	MADLogDebug("MADOperationCreateDocument <%p:%@> (as delegate) received operationDidFinish: <%p:%@>, Error count: %lu",
				self, self.name, operation, operation.name, (unsigned long)errors.count);
	if (errors.count > 0) {
		MADLogError("MADOperationCreateDocument <%p:%@> Sub-operation <%p:%@> finished with %lu error(s). First error: %@",
					self, self.name, operation, operation.name, (unsigned long)errors.count, errors.firstObject);
	}
	if ([operation isKindOfClass:[MADOperationBackgroundTaskEnd class]]) {
		//[((MADOperation *)operation) cleanup];
		
		[self finish];
		[self cleanup];

	} else if ([operation isKindOfClass:[MADOperationDatabaseTestConnection class]]) {
		//[((MADOperation *)operation) cleanup];
		_connectionSuccess = ((MADOperationDatabaseTestConnection *)operation).success;
	} else if ([operation isKindOfClass:[MADOperationDocumentCloseDocument class]]) {
		//[((MADOperation *)operation) cleanup];
		_successCreate = errors.count == 0;
	} else if ([operation isKindOfClass:[MADOperationCreateDocumentImportSchema class]]) {
		//[((MADOperation *)operation) cleanup];
		((MADOperationCreateDocumentImportSchema *)operation).parentOperation = nil;
	} else {
		//[((MADOperation *)operation) cleanup];
	}
}

- (void)updateImportProgressWithMessage:(NSString *)message progress:(float)progress {
	MADLogDebug("MADOperationCreateDocument <%p:%@> updateImportProgressWithMessage: \"%@\", progress: %.2f",
				self, self.name, message, progress);
	[[MADNotificationProgress sharedObject] updateProgressOfObject: self
													   withMessage: message
														  progress: progress];
}

@end
