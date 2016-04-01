//
//  MADDocumentOperationCloseDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/29/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentOperationCloseDocument.h"
#import <MAD/MADocument.h>
#import <MAD/MADErrorUserInfo.h>
#import "MADCreateDocumentOperationCreateDocument.h"

@implementation MADDocumentOperationCloseDocument

- (void)dealloc {
    NSLog(@"Operation deallocated. %s", __PRETTY_FUNCTION__);
}

- (void)execute {
    MADocument *document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADCreateDocumentOperationCreateDocumentProtocol)]) {
            document = ((id <MADCreateDocumentOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        if (document.documentState != UIDocumentStateClosed) {
            [document closeWithCompletionHandler:^(BOOL success) {
                if (success) {
                    [self finish];
                } else {
                    NSString *title = NSLocalizedString(@"Problem Closing Document", @"Problem Closing Document");
                    NSString *message = NSLocalizedString(@"Failed to close the document.", @"Failed to close the document.");
                    MADErrorUserInfo *userInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
                    NSDictionary *userInfoDictionary = [NSDictionary dictionaryWithDictionary:userInfo.userinfo];
                    NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:893 userInfo:userInfoDictionary];
                    [self finishWithError:error];
                }
            }];
        } else {
            [self finish];
        }
    }];
}

@end
