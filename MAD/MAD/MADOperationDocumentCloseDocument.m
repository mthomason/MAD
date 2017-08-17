//
//  MADOperationDocumentCloseDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/29/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationDocumentCloseDocument.h"
#import <os/log.h>
#import <MADFoundation/MADErrorUserInfo.h>
#import <MAD/MADocument.h>
#import "MADOperationCreateDocumentCreateDocument.h"

@implementation MADOperationDocumentCloseDocument

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
    
    
    //[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        MADocument *doc = document;
        if (doc.documentState & UIDocumentStateClosed) {
            [self finish];
        } else {
            [MADocument close:doc completion:^(BOOL success, NSURL *fileURL, NSURL *cleanupURL) {
                if (success) {
                    [self finish];
                } else {
                    NSString *title = NSLocalizedString(@"Problem Closing Document", @"Problem Closing Document");
                    NSString *message = NSLocalizedString(@"Failed to close the document.", @"Failed to close the document.");
                    MADErrorUserInfo *userInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
                    NSError *error = [userInfo errorWithDomain:NSStringFromClass(self.class) code:893];
                    [self finishWithError:error];
                }
            }];
        }
    //}];
}

@end
