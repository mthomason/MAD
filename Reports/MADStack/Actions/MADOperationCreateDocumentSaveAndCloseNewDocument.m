//
//  MADCreateDocumentOperationSaveAndCloseNewDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/29/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationCreateDocumentSaveAndCloseNewDocument.h"
#import <MAD/MADocument.h>
#import <MAD/MADErrorUserInfo.h>
#import "MADOperationCreateDocumentCreateDocument.h"
#import <os/log.h>

@implementation MADOperationCreateDocumentSaveAndCloseNewDocument

- (BOOL)isAsynchronous {
    return YES;
}

- (void)execute {
    
    os_log_info(OS_LOG_DEFAULT, "%s", __PRETTY_FUNCTION__);

    MADocument * __weak document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
            document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
    }


    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        MADocument *doc = document;
        if (doc.documentState & UIDocumentStateClosed) {
            os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Document already closed:", __PRETTY_FUNCTION__);
            [self finish];
        } else {
            os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Close document:", __PRETTY_FUNCTION__);
            [MADocument close: doc completion:^(BOOL success, NSURL *fileURL, NSURL *cleanupURL) {
                os_log_info(OS_LOG_DEFAULT, "%s\t%s", "handleCloseCompletion:", __PRETTY_FUNCTION__);
                if (success) {
                    os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish:", __PRETTY_FUNCTION__);
                    [self finish];
                } else {
                    os_log_info(OS_LOG_DEFAULT, "%s\t%s", "Finish with error creating document:", __PRETTY_FUNCTION__);
                    NSString *title = NSLocalizedString(@"Error Creating Document",
                                                        @"Error Creating Document");
                    NSString *message = NSLocalizedString(@"Failed to close.",
                                                          @"Failed to close.");
                    MADErrorUserInfo *userInfo = [[MADErrorUserInfo alloc] initWithTitle: title
                                                                              andMessage: message];
                    NSError *error = [userInfo errorWithDomain: NSStringFromClass(self.class)
                                                          code: 893];
                    [self finishWithError:error];
                }
            }];
        }
        
    }];
    
}

@end
