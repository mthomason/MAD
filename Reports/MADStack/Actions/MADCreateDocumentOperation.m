//
//  MADCreateDocumentOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCreateDocumentOperation.h"
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MADConstants.h>

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

@end

@implementation MADCreateDocumentOperation

- (void)dealloc {
    NSLog(@"Operation deallocated.");
}

- (instancetype)initWithFilename: (NSString *)filename documentsDirectory:(NSURL *)documentsDirectory
              databaseConnection: (MTDatabaseConnection *)databaseConnection
                  viewController: (UIViewController *)viewController {
    
    if (self = [super init]) {
    
        NSLog(@"%s", __PRETTY_FUNCTION__);
        MADOperationUniqueUrlForFilename *uniqueUrlForFilename = [[MADOperationUniqueUrlForFilename alloc] initWithDesiredFilename: filename
                                                                                                                     pathExtension: MADFileExtentionMobleApplicationDocument
                                                                                                             andDocumentsDirectory: documentsDirectory];
        
        MADGetCredentialsOperation *getCredentials = [[MADGetCredentialsOperation alloc] initWithDatabaseConnection: databaseConnection
                                                                                                     viewController: viewController];
      
        MADOperationBackgroundTaskBegin *taskBegin = [[MADOperationBackgroundTaskBegin alloc] init];
        [taskBegin addDependency:getCredentials];
        
        MADCreateDocumentOperationCreateDocument *createDocument = [[MADCreateDocumentOperationCreateDocument alloc] init];
        [createDocument addDependency:getCredentials];  // This is because the document uses this task as delegate to get credentials.
        [createDocument addDependency:uniqueUrlForFilename];
        [createDocument addDependency:taskBegin];
        
        
        MADCreateDocumentOperationFirstTimeSetup *firstTimeSetup = [[MADCreateDocumentOperationFirstTimeSetup alloc] init];
        [firstTimeSetup addDependency:createDocument];

        MADCreateDocumentOperationAddConnection *addConnection = [[MADCreateDocumentOperationAddConnection alloc] initWithDatabaseConnection:databaseConnection];
        [addConnection addDependency:createDocument];
        [addConnection addDependency:firstTimeSetup];
        
        MADCreateDocumentOperationImportSchema *importSchema = [[MADCreateDocumentOperationImportSchema alloc] initWithDatabaseConnection:databaseConnection];
        [importSchema addDependency:createDocument];
        [importSchema addDependency:addConnection];
        
        MADCreateDocumentOperationSaveAndCloseNewDocument *saveOperation = [[MADCreateDocumentOperationSaveAndCloseNewDocument alloc] init];
        [saveOperation addDependency:importSchema];
        
        MADDocumentOperationCloseDocument *closeDocument = [[MADDocumentOperationCloseDocument alloc] init];
        [closeDocument addDependency:saveOperation];
        
        MADOperationBackgroundTaskEnd *taskEnd = [[MADOperationBackgroundTaskEnd alloc] init];
        [taskEnd addDependency:closeDocument];
        
        NSArray <__kindof NSOperation *> *operations = @[uniqueUrlForFilename,
                                                         getCredentials,
                                                         taskBegin,
                                                         createDocument,
                                                         firstTimeSetup,
                                                         addConnection,
                                                         importSchema,
                                                         saveOperation,
                                                         closeDocument,
                                                         taskEnd];
        
        MADGroupOperation * __weak wself = self;
        NSBlockOperation *finishingOperation = [NSBlockOperation blockOperationWithBlock:^{
            MADGroupOperation *sself = wself;
            [sself finish];
        }];
        
        [self addOperations:operations finishingOperation:finishingOperation];
    }
    
    return self;
}

- (void)operationDidFinish:(NSOperation *)operation withErrors:(NSArray *)errors {
    /*if ([operation conformsToProtocol:@protocol(MADOperationHoldsCredentialsProtocol)]) {
        NSObject <MADOperationHoldsCredentialsProtocol> *credentialsObject = (NSObject <MADOperationHoldsCredentialsProtocol> *)operation;
        if ([credentialsObject gotCredentials]) {
            
        }
    }*/
}

@end
