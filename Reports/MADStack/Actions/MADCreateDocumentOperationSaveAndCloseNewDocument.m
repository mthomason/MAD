//
//  MADCreateDocumentOperationSaveAndCloseNewDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/29/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADCreateDocumentOperationSaveAndCloseNewDocument.h"
#import <MAD/MADocument.h>
#import <MAD/MADErrorUserInfo.h>
#import "MADCreateDocumentOperationCreateDocument.h"

@implementation MADCreateDocumentOperationSaveAndCloseNewDocument

- (void)dealloc {
    NSLog(@"%@-%s", NSStringFromClass(self.class), __func__);
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)execute {
    MADocument * __weak document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADCreateDocumentOperationCreateDocumentProtocol)]) {
            document = ((id <MADCreateDocumentOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
    }

    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        MADocument *doc = document;
        if (doc.documentState != UIDocumentStateClosed) {
            [doc closeWithCompletionHandler:^(BOOL success) {
                if (success) {
                    [self finish];
                } else {
                    NSString *title = NSLocalizedString(@"Error Creating Document", @"Error Creating Document");
                    NSString *message = NSLocalizedString(@"Failed to close.", @"Failed to close.");
                    MADErrorUserInfo *userInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
                    NSError *error = [userInfo errorWithDomain:NSStringFromClass(self.class) code:893];
                    [self finishWithError:error];
                }
            }];
        } else {
            [self finish];
        }
    }];
}

@end
