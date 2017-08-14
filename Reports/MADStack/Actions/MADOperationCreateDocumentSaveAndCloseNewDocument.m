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

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)execute {
    os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);

    if (self.cancelled) return [self finish];

    MADocument * __weak document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
            document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
    }

    MADOperation * __weak weakself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        MADOperation *strongself = weakself;
        MADocument *doc = document;
        if (doc.documentState & UIDocumentStateClosed) {
            [strongself finish];
        } else {
            MADOperation * __weak weakself2 = self;
            [MADocument close: doc completion:^(BOOL success, NSURL *fileURL, NSURL *cleanupURL) {
                MADOperation *strongself2 = weakself2;
                os_log_info(OS_LOG_DEFAULT, "%s\t%s", "handleCloseCompletion:", __PRETTY_FUNCTION__);
                if (success) {
                    [strongself2 finish];
                } else {
                    NSString *title = NSLocalizedString(@"Error Creating Document",
                                                        @"Error Creating Document");
                    NSString *message = NSLocalizedString(@"Failed to close.",
                                                          @"Failed to close.");
                    MADErrorUserInfo *userInfo = [[MADErrorUserInfo alloc] initWithTitle: title
                                                                              andMessage: message];
                    NSError *error = [userInfo errorWithDomain: NSStringFromClass(strongself2.class)
                                                          code: 893];
                    [strongself2 finishWithError:error];
                }
            }];
        }
        
    }];
    
}

@end
