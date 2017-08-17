//
//  MADOperationCreateDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationCreateDocument.h"

#import <os/log.h>

#import <MAD/MADDatabaseConnection.h>
#import <MAD/MADConstants.h>
#import <MAD/MADNotificationProgress.h>
#import <MAD/MTKeyChain.h>

#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADOperationQueue.h>

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
#import <MAD/MADOperationCreateDocumentSaveAndCloseNewDocument.h>
#import <MAD/MADOperationDocumentCloseDocument.h>
#import "MADOperationGetCredentials.h"
#import "MADOperationDatabaseTestConnection.h"
#import "MADOperationConditionTestConnectionSuccess.h"
#import "MADOperationPromptPolarQuestion.h"
#import "MADOperationConditionPolarQuestionAffirmative.h"
#import "MADOperationConditionHasResultString.h"
#import "MADOperationConditionDisplayedAlertConfirm.h"

@interface MADOperationCreateDocument ()
    <MADOperationCreateDocumentImportSchemaProtocol>

    @property (nonatomic, assign, readwrite, getter=isSuccessConnection) BOOL successConnection;
    @property (nonatomic, assign, readwrite, getter=isSuccessCreate) BOOL successCreate;
 
@end

@implementation MADOperationCreateDocument

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (instancetype)initWithFilename: (NSString *)filename
              documentsDirectory: (NSURL *)documentsDirectory
              databaseConnection: (MADDatabaseConnection *)databaseConnection
                  viewController: (UIViewController *)viewController {
    
    if (self = [super init]) {
        
        _connectionSuccess = NO;
        _successCreate = NO;
        
        NSString *key = databaseConnection.connectionString;
        NSString *keyUsername = [MTKeyChain newKeyForUsernameWithMainKey: key];
        NSString *keyPassword = [MTKeyChain newKeyForPasswordWithMainKey: key];

        MADOperationConditionHasResultString *conditionReadUsername;
        conditionReadUsername = [[MADOperationConditionHasResultString alloc] initWithKey:keyUsername];
        
        MADOperationConditionTestConnectionFailuare *connectionConnectionFail;
        connectionConnectionFail = [[MADOperationConditionTestConnectionFailuare alloc] init];

        // Condition: Confirm user manually entered password
        MADOperationConditionDisplayedAlertConfirm *conditionEnteredPassword;
        conditionEnteredPassword = [[MADOperationConditionDisplayedAlertConfirm alloc] init];
        
        // Condition: Test connection success
        MADOperationConditionTestConnectionSuccess *conditionConnectionConnectionSuccess;
        conditionConnectionConnectionSuccess = [[MADOperationConditionTestConnectionSuccess alloc] init];

        // ---------------------------------------------------
        // Operation 1: Create unique filename/url for document.
        // -------------------------
        
        MADOperationUniqueUrlForFilename *uniqueUrlForFilename;
        uniqueUrlForFilename = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename: filename
                                                                                   pathExtension: MADFileExtentionMobleApplicationDocument
                                                                           andDocumentsDirectory: documentsDirectory];
        uniqueUrlForFilename.name = @"com.everydayapps.mad.operation.uniqueurl";
        
        // ---------------------------------------------------
        // Operation 1: Get database credentials from keychain or user.
        // -------------------------
        
        MADOperationGetCredentials *getCredentials;
        getCredentials = [[MADOperationGetCredentials alloc] initWithDatabaseConnection: databaseConnection
                                                                         viewController: viewController];
        getCredentials.name = @"com.everydayapps.mad.operation.credentials.get";
        
        // ---------------------------------------------------
        // Operation 1: Test the database connection.
        // -------------------------
        
        MADOperationDatabaseTestConnection *testConnectionOperationCredentials;
        testConnectionOperationCredentials = [[MADOperationDatabaseTestConnection alloc] initWithDatabaseConnection: databaseConnection];
        testConnectionOperationCredentials.name = @"com.everydayapps.mad.operation.connection.test";
        [testConnectionOperationCredentials addDependency:getCredentials];
        
        MADOperationPromptError *displayErrorCredentials;
        displayErrorCredentials = [[MADOperationPromptError alloc] initWithViewController:viewController];
        displayErrorCredentials.name = @"com.everydayapps.mad.operation.displayerror";
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
        NSString *TextSaveToKeyChain = @"Save to KeyChain";
        NSString *TextSaveToKeyChainMessage = @"Would you like to save your password?";
        NSString *title = NSLocalizedString(TextSaveToKeyChain, TextSaveToKeyChain);
        NSString *messagePasswordPrompt = NSLocalizedString(TextSaveToKeyChainMessage, TextSaveToKeyChainMessage);
        MADOperationPromptPolarQuestion *promptSavePassword;
        promptSavePassword = [[MADOperationPromptPolarQuestion alloc] initWithTitle: title
                                                                            message: messagePasswordPrompt
                                                                     viewController: viewController];
        promptSavePassword.name = @"com.everydayapps.mad.operation.credentials.prompt.save";
        [promptSavePassword addDependency: testConnectionOperationCredentials];
        [promptSavePassword addDependency: getCredentials];
        [promptSavePassword addCondition: conditionEnteredPassword];
        [promptSavePassword addCondition: conditionConnectionConnectionSuccess];
        
        MADOperationConditionPolarQuestionAffirmative *promptToSaveCredntialsAffirmative;
        promptToSaveCredntialsAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier:promptSavePassword.identifier];
        
        // ---------------------------------------------------
        // Operation:   Save username
        // Dependency:  Prompt save credentials.
        // Conditions:  User said yes to save credentials.
        // ---------------------------------------------------

        MADOperationKeyChainPut *putUsername;
        putUsername = [[MADOperationKeyChainPut alloc] initWithKey:keyUsername description:MTKeyChainUsernameAccountDesc];
        putUsername.name = @"com.everydayapps.mad.operation.credentials.save.username";
        [putUsername addDependency: promptSavePassword];
        [putUsername addDependency: getCredentials];
        [putUsername addCondition: promptToSaveCredntialsAffirmative];
        
        // ---------------------------------------------------
        // Operation:   Save password
        // Dependency:  Prompt save credentials.
        // Conditions:  User said yes to save credentials..
        // ---------------------------------------------------
        MADOperationKeyChainPut *putPassword;
        putPassword = [[MADOperationKeyChainPut alloc] initWithKey:keyPassword description:MTKeyChainPasswordAccountDesc];
        putPassword.name = @"com.everydayapps.mad.operation.credentials.save.password";
        [putPassword addDependency: promptSavePassword];
        [putPassword addDependency: getCredentials];
        [putPassword addCondition: promptToSaveCredntialsAffirmative];
        
        // Create the document file on disk.
        MADOperationCreateDocumentCreateDocument *createDocument;
        createDocument = [[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection:databaseConnection];
        createDocument.name = @"com.everydayapps.mad.operation.document.create.file";
        [createDocument addDependency: getCredentials];  // This is because the document uses this task as delegate to get credentials.
        [createDocument addDependency: uniqueUrlForFilename];
        [createDocument addDependency: taskBegin];
        [createDocument addDependency: displayErrorCredentials];
        [createDocument addDependency: testConnectionOperationCredentials];
        [createDocument addCondition: conditionConnectionConnectionSuccess];
        
        // Do first time document setup.
        MADOperationCreateDocumentFirstTimeSetup *firstTimeSetup;
        firstTimeSetup = [[MADOperationCreateDocumentFirstTimeSetup alloc] init];
        firstTimeSetup.name = @"com.everydayapps.mad.operation.document.create.setup";
        [firstTimeSetup addDependency: createDocument];
        [firstTimeSetup addDependency: displayErrorCredentials];
        [firstTimeSetup addDependency: testConnectionOperationCredentials];
        [firstTimeSetup addCondition: conditionConnectionConnectionSuccess];
        
        // Add databaes connection to document.
        MADOperationCreateDocumentAddConnection *addConnection;
        addConnection = [[MADOperationCreateDocumentAddConnection alloc] initWithDatabaseConnection:databaseConnection];
        addConnection.name = @"com.everydayapps.mad.operation.document.create.connection";
        [addConnection addDependency: createDocument];
        [addConnection addDependency: firstTimeSetup];
        [addConnection addDependency: displayErrorCredentials];
        [addConnection addDependency: testConnectionOperationCredentials];
        [addConnection addCondition: conditionConnectionConnectionSuccess];
        
        // Import schema into document.
        MADOperationCreateDocumentImportSchema *importSchema;
        importSchema = [[MADOperationCreateDocumentImportSchema alloc] initWithDatabaseConnection:databaseConnection];
        importSchema.name = @"com.everydayapps.mad.operation.document.import.schema";
        [importSchema addDependency: createDocument];
        [importSchema addDependency: addConnection];
        [importSchema addDependency: displayErrorCredentials];
        [importSchema addDependency: testConnectionOperationCredentials];
        [importSchema addCondition: conditionConnectionConnectionSuccess];
        importSchema.parentOperation = self;
        
        // Save the new document.
        MADOperationCreateDocumentSaveAndCloseNewDocument *saveOperation;
        saveOperation = [[MADOperationCreateDocumentSaveAndCloseNewDocument alloc] init];
        saveOperation.name = @"com.everydayapps.mad.operation.document.save";
        [saveOperation addDependency: createDocument];
        [saveOperation addDependency: importSchema];
        [saveOperation addDependency: displayErrorCredentials];
        [saveOperation addDependency: testConnectionOperationCredentials];
        [saveOperation addCondition: conditionConnectionConnectionSuccess];
        
        // Close the new document.
        MADOperationDocumentCloseDocument *closeDocument;
        closeDocument = [[MADOperationDocumentCloseDocument alloc] init];
        closeDocument.name = @"com.everydayapps.mad.operation.document.close";
        [closeDocument addDependency: createDocument];
        [closeDocument addDependency: saveOperation];
        [closeDocument addDependency: displayErrorCredentials];
        [closeDocument addDependency: testConnectionOperationCredentials];
        [closeDocument addDependency: displayErrorCredentials];
        [closeDocument addDependency: testConnectionOperationCredentials];
        [closeDocument addCondition: conditionConnectionConnectionSuccess];
        
        //Test if credentals are saved
        MADOperationKeyChainGet *operationGetUsername;
        operationGetUsername = [[MADOperationKeyChainGet alloc] initWithKey: keyUsername
                                                            withDescription: MTKeyChainUsernameAccountDesc];
        operationGetUsername.name = @"com.everydayapps.mad.operation.keychain.read.username";
        operationGetUsername.readOperationType = MADKeyChainReadOperationTypeUsername;
        [operationGetUsername addDependency: displayErrorCredentials];
        [operationGetUsername addDependency: testConnectionOperationCredentials];
        
        //If connection failed and credentals are saved, prompt to delete credentals.
        MADOperationPromptPolarQuestion *promptDeleteCredntials;
        promptDeleteCredntials = [[MADOperationPromptPolarQuestion alloc] initWithTitle: @"Delete saved credentials?"
                                                                                message: @"Would you like to remove the saved credentials"
                                                                         viewController: viewController];
        promptDeleteCredntials.name = @"com.everydayapps.mad.operation.credentials.prompt.delete";
        [promptDeleteCredntials addDependency: displayErrorCredentials];
        [promptDeleteCredntials addDependency: testConnectionOperationCredentials];
        [promptDeleteCredntials addDependency: operationGetUsername];
        [promptDeleteCredntials addCondition: connectionConnectionFail];
        [promptDeleteCredntials addCondition: conditionReadUsername];
        
        
        MADOperationConditionPolarQuestionAffirmative *promptDeletePasswordAffirmative;
        promptDeletePasswordAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier: promptDeleteCredntials.identifier];
        
        MADOperationKeyChainDeletePassword *operationDeletePassword;
        operationDeletePassword = [[MADOperationKeyChainDeletePassword alloc] initWithKey: databaseConnection.connectionString];
        [operationDeletePassword addDependency: promptDeleteCredntials];
        [operationDeletePassword addCondition: promptDeletePasswordAffirmative];
        
        MADOperationBackgroundTaskEnd *taskEnd;
        taskEnd = [[MADOperationBackgroundTaskEnd alloc] init];
        [taskEnd addDependency: putUsername];
        [taskEnd addDependency: putPassword];
        [taskEnd addDependency: promptSavePassword];
        [taskEnd addDependency: taskBegin];
        [taskEnd addDependency: closeDocument];
        
        NSArray <__kindof NSOperation *> *operations = @[promptSavePassword,
                                                         putUsername,
                                                         putPassword,
                                                         uniqueUrlForFilename,
                                                         getCredentials,
                                                         taskBegin,
                                                         createDocument,
                                                         displayErrorCredentials,
                                                         testConnectionOperationCredentials,
                                                         firstTimeSetup,
                                                         addConnection,
                                                         importSchema,
                                                         saveOperation,
                                                         closeDocument,
                                                         taskEnd,
                                                         promptDeleteCredntials,
                                                         operationDeletePassword];
        
        NSBlockOperation *finishingOperation = [NSBlockOperation blockOperationWithBlock:^{ }];
        [self addOperations:operations finishingOperation:finishingOperation];
        
    }
    
    return self;
}

- (void)execute {
    os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);

    if (self.cancelled) return [self finish];

    [super execute];
        
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {
    if ([operation isKindOfClass:[MADOperationBackgroundTaskEnd class]]) {
        [((MADOperation *)operation) cleanup];
        
        [self finish];
        [self cleanup];

    } else if ([operation isKindOfClass:[MADOperationDatabaseTestConnection class]]) {
        [((MADOperation *)operation) cleanup];
        _connectionSuccess = ((MADOperationDatabaseTestConnection *)operation).success;
    } else if ([operation isKindOfClass:[MADOperationCreateDocumentSaveAndCloseNewDocument class]]) {
        [((MADOperation *)operation) cleanup];
        _successCreate = errors.count == 0;
    } else if ([operation isKindOfClass:[MADOperationCreateDocumentImportSchema class]]) {
        [((MADOperation *)operation) cleanup];
        ((MADOperationCreateDocumentImportSchema *)operation).parentOperation = nil;
    } else {
        [((MADOperation *)operation) cleanup];
    }
    
    

}

- (void)updateImportProgressWithMessage:(NSString *)message progress:(float)progress {
    [[MADNotificationProgress sharedObject] updateProgressOfObject:self withMessage:message progress:progress];
}

@end
