//
//  MADOperationDocumentCloseDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/29/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationDocumentCloseDocument.h"
#import "MADOperationCreateDocumentCreateDocument.h"
#import "madlog.h"

#import <MAD/MADocument.h>

@implementation MADOperationDocumentCloseDocument

- (void)dealloc {
    os_log_info(GetMadLog(), "Dealloc %s", NSStringFromClass(self.class).UTF8String);
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)execute {
	if (self.cancelled) return [self finish];

	MADocument * __weak document = nil;
	NSArray <NSOperation *> *dependencies = self.dependencies;
	for (NSOperation *dependency in dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
			document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
			break;
		}
	}
	
	MADocument *doc = document;
	if (doc.documentState & UIDocumentStateClosed) {
		[self finish];
	} else {
		[MADocument close:doc completion:^(BOOL success, NSURL *fileURL, NSURL *cleanupURL) {
			if (success) {
				[self finish];
			} else {
				NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:893 userInfo:@{
					NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Problem Closing Document", @"Problem Closing Document"),
					NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to close the document.", @"Failed to close the document.")
				}];
				[self finishWithError:error];
			}
		}];
	}
}

@end
