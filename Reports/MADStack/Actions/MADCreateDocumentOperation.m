//
//  MADCreateDocumentOperation.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/18/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCreateDocumentOperation.h"
#import "MADGetCredentialsOperation.h"

#import <MAD/MTDatabaseConnection.h>

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
        
        

        
        // Operation: Confirm Save Username and Password
        NSArray <__kindof NSOperation *> *operations = @[getCredentials];
        
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

}

@end
