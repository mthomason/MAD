//
//  MADOperationCreateDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationCreateDocument.h"

#import <MAD/MADDatabaseConnection.h>
#import <MAD/MADConstants.h>
#import <MAD/MADNotificationProgress.h>
#import <MAD/MTKeyChain.h>
#import <MAD/MADCredential.h>

#import "MADOperationQueue.h"
#import "MADOperationUniqueUrlForFilename.h"
#import "MADGetCredentialsOperation.h"
#import "MADOperationCreateDocumentCreateDocument.h"
#import "MADOperationBackgroundTaskBegin.h"
#import "MADOperationBackgroundTaskEnd.h"
#import "MADOperationCreateDocumentAddConnection.h"
#import "MADOperationCreateDocumentImportSchema.h"
#import "MADOperationCreateDocumentSaveAndCloseNewDocument.h"
#import "MADOperationDocumentCloseDocument.h"
#import "MADOperationCreateDocumentFirstTimeSetup.h"
#import "MADOperationDatabaseTestConnection.h"
#import "MADOperationConditionTestConnectionSuccess.h"
#import "MADPromptOperationPolarQuestion.h"
#import "MADOperationKeyChainDeletePassword.h"
#import "MADKeyChainOperationGet.h"
#import "MADOperationConditionPolarQuestionAffirmative.h"
#import "MADOperationConditionHasResultString.h"

@interface MADOperationCreateDocument ()
    <MADOperationCreateDocumentImportSchemaProtocol>

@end

@implementation MADOperationCreateDocument

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __PRETTY_FUNCTION__);
}

- (instancetype)initWithFilename: (NSString *)filename documentsDirectory:(NSURL *)documentsDirectory
              databaseConnection: (MADDatabaseConnection *)databaseConnection
                  viewController: (UIViewController *)viewController {
    
    if (self = [super init]) {
        
        
        // ---------------------------------------------------
        // Operation 1: Create unique filename/url for document.
        // -------------------------
        
        MADOperationUniqueUrlForFilename *uniqueUrlForFilename;
        uniqueUrlForFilename = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename: filename
                                                                                   pathExtension: MADFileExtentionMobleApplicationDocument
                                                                           andDocumentsDirectory: documentsDirectory];
        
        // ---------------------------------------------------
        // Operation 1: Get database credentials from keychain or user.
        // -------------------------

        MADGetCredentialsOperation *getCredentials;
        getCredentials = [[MADGetCredentialsOperation alloc] initWithDatabaseConnection: databaseConnection
                                                                         viewController: viewController];
      
        // ---------------------------------------------------
        // Operation 1: Test the database connection.
        // -------------------------

        MADOperationDatabaseTestConnection *testConnectionOperationCredentials;
        testConnectionOperationCredentials = [[MADOperationDatabaseTestConnection alloc] initWithDatabaseConnection: databaseConnection];
        [testConnectionOperationCredentials addDependency:getCredentials];
        
        
        
        MADPromptOperationDisplayError *displayErrorCredentials;
        displayErrorCredentials = [[MADPromptOperationDisplayError alloc] initWithViewController:viewController];
        [displayErrorCredentials addDependency:testConnectionOperationCredentials];
        
        
        
        MADOperationBackgroundTaskBegin *taskBegin = [[MADOperationBackgroundTaskBegin alloc] init];
        [taskBegin addDependency: getCredentials];
        [taskBegin addDependency: testConnectionOperationCredentials];
        [taskBegin addDependency: displayErrorCredentials];
        
        
        
        MADOperationCreateDocumentCreateDocument *createDocument;
        createDocument = [[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection:databaseConnection];
        [createDocument addDependency: getCredentials];  // This is because the document uses this task as delegate to get credentials.
        [createDocument addDependency: uniqueUrlForFilename];
        [createDocument addDependency: taskBegin];
        [createDocument addDependency: displayErrorCredentials];
        [createDocument addDependency: testConnectionOperationCredentials];
        MADOperationConditionTestConnectionSuccess *connectionConnectionSuccess;
        connectionConnectionSuccess = [[MADOperationConditionTestConnectionSuccess alloc] init];
        [createDocument addCondition:connectionConnectionSuccess];
        
        MADOperationCreateDocumentFirstTimeSetup *firstTimeSetup;
        firstTimeSetup = [[MADOperationCreateDocumentFirstTimeSetup alloc] init];
        [firstTimeSetup addDependency: createDocument];
        [firstTimeSetup addDependency: displayErrorCredentials];
        [firstTimeSetup addDependency: testConnectionOperationCredentials];
        [firstTimeSetup addCondition:connectionConnectionSuccess];
        
        MADOperationCreateDocumentAddConnection *addConnection;
        addConnection = [[MADOperationCreateDocumentAddConnection alloc] initWithDatabaseConnection:databaseConnection];
        [addConnection addDependency: createDocument];
        [addConnection addDependency: firstTimeSetup];
        [addConnection addDependency: displayErrorCredentials];
        [addConnection addDependency: testConnectionOperationCredentials];
        [addConnection addCondition: connectionConnectionSuccess];
        
        MADOperationCreateDocumentImportSchema *importSchema;
        importSchema = [[MADOperationCreateDocumentImportSchema alloc] initWithDatabaseConnection:databaseConnection];
        [importSchema addDependency: createDocument];
        [importSchema addDependency: addConnection];
        [importSchema addDependency: displayErrorCredentials];
        [importSchema addDependency: testConnectionOperationCredentials];
        [importSchema addCondition: connectionConnectionSuccess];
        importSchema.parentOperation = self;
        
        MADOperationCreateDocumentSaveAndCloseNewDocument *saveOperation;
        saveOperation = [[MADOperationCreateDocumentSaveAndCloseNewDocument alloc] init];
        [saveOperation addDependency: createDocument];
        [saveOperation addDependency: importSchema];
        [saveOperation addDependency: displayErrorCredentials];
        [saveOperation addDependency: testConnectionOperationCredentials];
        [saveOperation addCondition: connectionConnectionSuccess];

        MADOperationDocumentCloseDocument *closeDocument;
        closeDocument = [[MADOperationDocumentCloseDocument alloc] init];
        [closeDocument addDependency: createDocument];
        [closeDocument addDependency: saveOperation];
        [closeDocument addDependency: displayErrorCredentials];
        [closeDocument addDependency: testConnectionOperationCredentials];
        [closeDocument addDependency: displayErrorCredentials];
        [closeDocument addDependency: testConnectionOperationCredentials];
        [closeDocument addCondition: connectionConnectionSuccess];
        
        NSString *key = databaseConnection.connectionString;
        NSString *keyUsername = [MTKeyChain newKeyForUsernameWithMainKey: key];

        MADKeyChainOperationGet *operationGetUsername;
        
        operationGetUsername = [[MADKeyChainOperationGet alloc] initWithKey: keyUsername
                                                            withDescription: MTKeyChainUsernameAccountDesc];
        operationGetUsername.readOperationType = MADKeyChainReadOperationTypeUsername;
        [operationGetUsername addDependency: displayErrorCredentials];
        [operationGetUsername addDependency: testConnectionOperationCredentials];

        MADOperationConditionHasResultString *conditionReadUsername;
        conditionReadUsername = [[MADOperationConditionHasResultString alloc] initWithKey:keyUsername];
        
        MADPromptOperationPolarQuestion *promptDeleteCredntials;
        promptDeleteCredntials = [[MADPromptOperationPolarQuestion alloc] initWithTitle: @"Delete saved credentials?"
                                                                                message: @"Would you like to remove the saved credentials"
                                                                         viewController: viewController];
        
        MADOperationConditionTestConnectionFailuare *connectionConnectionFail;
        connectionConnectionFail = [[MADOperationConditionTestConnectionFailuare alloc] init];

        [promptDeleteCredntials addDependency: displayErrorCredentials];
        [promptDeleteCredntials addDependency: testConnectionOperationCredentials];
        [promptDeleteCredntials addDependency: operationGetUsername];
        [promptDeleteCredntials addCondition: connectionConnectionFail];
        [promptDeleteCredntials addCondition: conditionReadUsername];
        

        MADOperationConditionPolarQuestionAffirmative *promptDeletePasswordAffirmative;
        promptDeletePasswordAffirmative = [[MADOperationConditionPolarQuestionAffirmative alloc] initWithOperationIdentifier: promptDeleteCredntials.identifier];
        
        MADOperationKeyChainDeletePassword *operationDeletePassword;
        operationDeletePassword = [[MADOperationKeyChainDeletePassword alloc] initWithKey: databaseConnection.connectionString];
        [operationDeletePassword addDependency:promptDeleteCredntials];
        [operationDeletePassword addCondition:promptDeletePasswordAffirmative];
        

        MADOperationBackgroundTaskEnd *taskEnd;
        taskEnd = [[MADOperationBackgroundTaskEnd alloc] init];
        [taskEnd addDependency:taskBegin];
        [taskEnd addDependency:closeDocument];
        
        NSArray <__kindof NSOperation *> *operations = @[uniqueUrlForFilename, getCredentials,
                                                         taskBegin, createDocument,
                                                         displayErrorCredentials,
                                                         testConnectionOperationCredentials,
                                                         firstTimeSetup, addConnection,
                                                         importSchema, saveOperation,
                                                         closeDocument, taskEnd,
                                                         promptDeleteCredntials,
                                                         operationDeletePassword];
        
        MADGroupOperation * __weak wself = self;
        NSBlockOperation *finishingOperation = [NSBlockOperation blockOperationWithBlock:^{
            MADGroupOperation *sself = wself;
            [sself finish];
        }];
        [self addOperations:operations finishingOperation:finishingOperation];
    }
    
    return self;
}

- (void)execute {
    if (!self.cancelled) {
        self.internalQueue.suspended = NO;
        [self.internalQueue addOperation:self.finishingOperation];
    }
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {
    //if ([operation isKindOfClass:[MADOperationBackgroundTaskEnd class]]) {
    //    [self finish];
    //}
}

- (void)updateImportProgressWithMessage:(NSString *)message progress:(float)progress {
    [[MADNotificationProgress sharedObject] updateProgressOfObject:self withMessage:message progress:progress];
}

@end
