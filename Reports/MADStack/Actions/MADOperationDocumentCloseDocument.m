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
#import <os/log.h>

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
            os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finished closing:", __PRETTY_FUNCTION__);
            [self finish];
        } else {
            os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish with error closing document:", __PRETTY_FUNCTION__);
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
        if (doc.documentState & UIDocumentStateClosed) {
            os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish:", __PRETTY_FUNCTION__);
            [self finish];
        } else {
            os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Close:", __PRETTY_FUNCTION__);
            [MADocument close:doc completion:handleCloseCompletion];
        }
    };
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:mainBlock];
}

@end
