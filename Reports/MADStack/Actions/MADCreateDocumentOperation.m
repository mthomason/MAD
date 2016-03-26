//
//  MADCreateDocumentOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCreateDocumentOperation.h"
#import <MAD/MTDatabaseConnection.h>

#import "MADGetCredentialsOperation.h"
#import "MADCreateDocumentOperationCreateDocument.h"
#import "MADOperationBackgroundTaskBegin.h"
#import "MADOperationBackgroundTaskEnd.h"
#import "MADCreateDocumentOperationAddConnection.h"
#import "MADCreateDocumentOperationImportSchema.h"

@interface MADCreateDocumentOperation ()

@end

@implementation MADCreateDocumentOperation

- (void)dealloc {
    NSLog(@"Operation deallocated.");
}

- (instancetype)initWithDatabaseConnection: (MTDatabaseConnection *)databaseConnection
                            viewController: (UIViewController *)viewController {
    
    if (self = [super init]) {
    
        MADGetCredentialsOperation *getCredentials = [[MADGetCredentialsOperation alloc] initWithDatabaseConnection:databaseConnection viewController:viewController];
      
        MADOperationBackgroundTaskBegin *taskBegin = [[MADOperationBackgroundTaskBegin alloc] init];
        [taskBegin addDependency:getCredentials];
        
        MADCreateDocumentOperationCreateDocument *createDocument = [[MADCreateDocumentOperationCreateDocument alloc] init];
        [createDocument addDependency:taskBegin];
        
        MADCreateDocumentOperationAddConnection *addConnection = [[MADCreateDocumentOperationAddConnection alloc] initWithDatabaseConnection:databaseConnection];
        [addConnection addDependency:createDocument];
        
        MADCreateDocumentOperationImportSchema *importSchema = [[MADCreateDocumentOperationImportSchema alloc] initWithDatabaseConnection:databaseConnection];
        [importSchema addDependency:addConnection];
        
        MADOperationBackgroundTaskEnd *taskEnd = [[MADOperationBackgroundTaskEnd alloc] init];
        [taskEnd addDependency:createDocument];
        
        
        
        
        NSArray <__kindof NSOperation *> *operations = @[getCredentials,
                                                         taskBegin,
                                                         createDocument,
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
