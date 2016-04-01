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

- (BOOL)isAsynchronous {
    return NO;
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

        [document saveToURL: document.fileURL forSaveOperation: UIDocumentSaveForOverwriting completionHandler: ^(BOOL success) {
            if (success) {
                [self finish];
            } else {
                NSString *title = NSLocalizedString(@"Error Creating Document", @"Error Creating Document");
                NSString *message = NSLocalizedString(@"Failed to save.", @"Failed to save.");
                MADErrorUserInfo *userInfo = [[MADErrorUserInfo alloc] initWithTitle:title andMessage:message];
                NSDictionary *userInfoDictionary = [NSDictionary dictionaryWithDictionary:userInfo.userinfo];
                NSError *error = [NSError errorWithDomain:NSStringFromClass(self.class) code:893 userInfo:userInfoDictionary];
                [self finishWithError:error];
            }
        }];
        
    }];
}

@end
