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
        
        MADOperationUniqueUrlForFilename *uniqueUrlForFilename = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename: filename
                                                                                                                     pathExtension: MADFileExtentionMobleApplicationDocument
                                                                                                             andDocumentsDirectory: documentsDirectory];
        
        MADGetCredentialsOperation *getCredentials = [[MADGetCredentialsOperation alloc] initWithDatabaseConnection: databaseConnection
                                                                                                     viewController: viewController];
      
        MADOperationBackgroundTaskBegin *taskBegin = [[MADOperationBackgroundTaskBegin alloc] init];
        [taskBegin addDependency:getCredentials];
        
        MADOperationCreateDocumentCreateDocument *createDocument;
        createDocument = [[MADOperationCreateDocumentCreateDocument alloc] initWithDatabaseConnection:databaseConnection];
        [createDocument addDependency:getCredentials];  // This is because the document uses this task as delegate to get credentials.
        [createDocument addDependency:uniqueUrlForFilename];
        [createDocument addDependency:taskBegin];
        
        MADOperationCreateDocumentFirstTimeSetup *firstTimeSetup;
        firstTimeSetup = [[MADOperationCreateDocumentFirstTimeSetup alloc] init];
        [firstTimeSetup addDependency:createDocument];

        MADOperationCreateDocumentAddConnection *addConnection;
        addConnection = [[MADOperationCreateDocumentAddConnection alloc] initWithDatabaseConnection:databaseConnection];
        [addConnection addDependency:createDocument];
        [addConnection addDependency:firstTimeSetup];
        
        MADOperationCreateDocumentImportSchema *importSchema;
        importSchema = [[MADOperationCreateDocumentImportSchema alloc] initWithDatabaseConnection:databaseConnection];
        [importSchema addDependency:createDocument];
        [importSchema addDependency:addConnection];
        importSchema.parentOperation = self;
        
        MADOperationCreateDocumentSaveAndCloseNewDocument *saveOperation;
        saveOperation = [[MADOperationCreateDocumentSaveAndCloseNewDocument alloc] init];
        [saveOperation addDependency:createDocument];
        [saveOperation addDependency:importSchema];
        
        MADOperationDocumentCloseDocument *closeDocument;
        closeDocument = [[MADOperationDocumentCloseDocument alloc] init];
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
