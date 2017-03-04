//
//  MADOperationDocumentCloseDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/29/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationDocumentCloseDocument.h"
#import <MAD/MADocument.h>
#import <MAD/MADErrorUserInfo.h>
#import "MADOperationCreateDocumentCreateDocument.h"

@implementation MADOperationDocumentCloseDocument

- (void)dealloc {
    //NSLog(@"%@-%s", NSStringFromClass(self.class), __PRETTY_FUNCTION__);
}

- (void)execute {

    MADocument * __weak document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
            document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
    }
    
    void (^handleCloseCompletion)(BOOL, NSURL *, NSURL *);
    handleCloseCompletion = ^(BOOL success, NSURL *fileURL, NSURL *cleanupURL) {
        if (success) {
            [self finish];
        } else {
            NSString *title = NSLocalizedString(@"Problem Closing Document", @"Problem Closing Document");
            NSString *message = NSLocalizedString(@"Failed to close the document.", @"Failed to close the document.");
            MADErrorUserInfo *userInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
            NSError *error = [userInfo errorWithDomain:NSStringFromClass(self.class) code:893];
            [self finishWithError:error];
        }
    };
    
    void (^mainBlock)(void);
    mainBlock = ^ {
        MADocument *doc = document;
        switch (doc.documentState) {
            case UIDocumentStateClosed:
                [self finish];
                break;
            default:
                [MADocument close:doc completion:handleCloseCompletion];
                break;
        }
    };
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:mainBlock];
}

@end
