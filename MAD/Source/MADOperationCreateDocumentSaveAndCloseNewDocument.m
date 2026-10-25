//
//  MADCreateDocumentOperationSaveAndCloseNewDocument.m
//  MAD Designer
//
//  Created by Michael Thomason on 3/29/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADOperationCreateDocumentSaveAndCloseNewDocument.h"
#import <MADFoundation/madlog.h>
#import <MAD/MADocument.h>
#import "MADOperationCreateDocumentCreateDocument.h"

@implementation MADOperationCreateDocumentSaveAndCloseNewDocument

- (void)dealloc { }

- (BOOL)isAsynchronous {
	return YES;
}

- (void)execute {
	if (self.cancelled) return [self finish];

	MADocument *document = nil;
	NSArray <NSOperation *> *dependencies = self.dependencies;
	for (NSOperation *dependency in dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
			document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
			break;
		}
	}

	if (document == nil) {
		NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
											 code:347
										 userInfo:@{NSLocalizedDescriptionKey: @"Document object not found for save and close."}];
		[self finishWithError:error];
		return;
	}

	MADOperation * __weak weakself = self;
	[MADocument close:document completion:^(BOOL success, NSURL *__unused fileURL, NSURL *__unused cleanupURL) {
		MADOperation *strongself = weakself;
		if (!strongself) return;
		if (success) {
			[strongself finish];
		} else {
			NSError *error = [NSError errorWithDomain:NSStringFromClass(strongself.class)
												 code: 893
											 userInfo:@{NSLocalizedDescriptionKey: @"Failed to close the new document."}];
			[strongself finishWithError:error];
		}
	}];
}

@end
