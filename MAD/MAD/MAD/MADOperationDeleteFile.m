//
//  MADOperationDeleteFile.m
//  MAD
//
//  Created by Michael on 8/17/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADOperationDeleteFile.h"
#import <os/log.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSURL.h>
#import <MADFileManager/MADFileUtilities.h>
#import <MAD/MADOperationUniqueUrlForFilename.h>
#import <MAD/MADocument.h>
#import <MAD/UIManagedDocument+Extras.h>
#import <MAD/MADOperationCreateDocumentCreateDocument.h>

@implementation MADOperationDeleteFile

- (void)dealloc {
    os_log_info(OS_LOG_DEFAULT, "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)execute {
    os_log_info(OS_LOG_DEFAULT, "Begin %s", NSStringFromClass(self.class).UTF8String);
    
    if (self.cancelled) return [self finish];
    NSURL *fileURL;
    MADocument *document = nil;
    NSArray <NSOperation *> *dependencies = self.dependencies;
    for (NSOperation *dependency in dependencies) {
        if ([dependency conformsToProtocol:@protocol(MADOperationUniqueUrlForFilenameProtocol)]) {
            fileURL = ((id <MADOperationUniqueUrlForFilenameProtocol>)dependency).uniqueUrl.copy;
        }
        if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
            document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
            break;
        }
    }

    if (document != nil) {
        [document deleteFromDiskCompletion:^(BOOL success) {
            if (!success)
                [self finishWithError:nil];
            else
                [self finish];
        }];
    } else {
        os_log_info(OS_LOG_DEFAULT, "Delete file %s", fileURL.relativePath.UTF8String);
        [MADFileUtilities removeFileAtURL:fileURL completion:^(NSError *error) {
            if (error != nil)
                [self finishWithError:error];
            else
                [self finish];
        }];
    }

}

@end
