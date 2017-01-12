//
//  MADCreateDocumentOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCreateDocumentOperation.h"

#import <MAD/MADDatabaseConnection.h>
#import <MAD/MADConstants.h>
#import <MAD/MADNotificationProgress.h>

#import "MADOperationQueue.h"
#import "MADOperationUniqueUrlForFilename.h"
#import "MADGetCredentialsOperation.h"
#import "MADCreateDocumentOperationCreateDocument.h"
#import "MADOperationBackgroundTaskBegin.h"
#import "MADOperationBackgroundTaskEnd.h"
#import "MADCreateDocumentOperationAddConnection.h"
#import "MADCreateDocumentOperationImportSchema.h"
#import "MADCreateDocumentOperationSaveAndCloseNewDocument.h"
#import "MADDocumentOperationCloseDocument.h"
#import "MADCreateDocumentOperationFirstTimeSetup.h"

@interface MADCreateDocumentOperation ()
    <MADCreateDocumentOperationImportSchemaProtocol>

@end

@implementation MADCreateDocumentOperation

- (void)dealloc { }

- (instancetype)initWithFilename: (NSString *)filename documentsDirectory:(NSURL *)documentsDirectory
              databaseConnection: (MADDatabaseConnection *)databaseConnection
                  viewController: (UIViewController *)viewController {
    
    if (self = [super init]) {
        
        MADOperationUniqueUrlForFilename *uniqueUrlForFilename = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename: filename
                                                                                                                     pathExtension: MADFileExtentionMobleApplicationDocument
                                                                                                             andDocumentsDirectory: documentsDirectory];
        
        MADGetCredentialsOperation *getCredentials = [[MADGetCredentialsOperation alloc] initWithDatabaseConnection: databaseConnection
                                                                                                     viewController: viewController];
      
        MADOperationBackgroundTaskBegin *taskBegin = [[MADOperationBackgroundTaskBegin alloc] init];
        [taskBegin addDependency:getCredentials];
        
        MADCreateDocumentOperationCreateDocument *createDocument;
        createDocument = [[MADCreateDocumentOperationCreateDocument alloc] init];
        [createDocument addDependency:getCredentials];  // This is because the document uses this task as delegate to get credentials.
        [createDocument addDependency:uniqueUrlForFilename];
        [createDocument addDependency:taskBegin];
        
        MADCreateDocumentOperationFirstTimeSetup *firstTimeSetup;
        firstTimeSetup = [[MADCreateDocumentOperationFirstTimeSetup alloc] init];
        [firstTimeSetup addDependency:createDocument];

        MADCreateDocumentOperationAddConnection *addConnection;
        addConnection = [[MADCreateDocumentOperationAddConnection alloc] initWithDatabaseConnection:databaseConnection];
        [addConnection addDependency:createDocument];
        [addConnection addDependency:firstTimeSetup];
        
        MADCreateDocumentOperationImportSchema *importSchema;
        importSchema = [[MADCreateDocumentOperationImportSchema alloc] initWithDatabaseConnection:databaseConnection];
        [importSchema addDependency:createDocument];
        [importSchema addDependency:addConnection];
        importSchema.parentOperation = self;
        
        MADCreateDocumentOperationSaveAndCloseNewDocument *saveOperation;
        saveOperation = [[MADCreateDocumentOperationSaveAndCloseNewDocument alloc] init];
        [saveOperation addDependency:createDocument];
        [saveOperation addDependency:importSchema];
        
        MADDocumentOperationCloseDocument *closeDocument;
        closeDocument = [[MADDocumentOperationCloseDocument alloc] init];
        [closeDocument addDependency:createDocument];
        [closeDocument addDependency:saveOperation];
        
        MADOperationBackgroundTaskEnd *taskEnd;
        taskEnd = [[MADOperationBackgroundTaskEnd alloc] init];
        [taskEnd addDependency:taskBegin];
        [taskEnd addDependency:closeDocument];
        
        NSArray <__kindof NSOperation *> *operations = @[uniqueUrlForFilename, getCredentials,
                                                         taskBegin, createDocument,
                                                         firstTimeSetup, addConnection,
                                                         importSchema, saveOperation,
                                                         closeDocument, taskEnd];
        
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
    if (self.cancelled) goto CANCEL_execute;
    self.internalQueue.suspended = NO;
    [self.internalQueue addOperation:self.finishingOperation];
CANCEL_execute:;
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
