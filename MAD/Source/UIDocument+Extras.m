//
//  UIDocument+Extras.m
//  MAD
//
//  Created by Michael Thomason on 6/8/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import "UIDocument+Extras.h"
#import <MADFileManager/MADFileUtilities.h>

typedef void(^MTPerformAsynchronousFileAccessUsingBlock)(void);

@implementation UIDocument (Extras)

- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion {

	MTPerformAsynchronousFileAccessUsingBlock asyncBlock = ^() {
		NSURL *fileURL = self.fileURL;

		NSArray *properties = [[NSArray alloc] initWithObjects:NSURLIsDirectoryKey, nil];

		NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL: fileURL
																 includingPropertiesForKeys: properties
																					options: NSDirectoryEnumerationSkipsHiddenFiles
																			   errorHandler: ^BOOL(NSURL *__unused url, NSError *__unused error) {
																				   return YES;
																			   }];
		for (NSURL *file in enumerator) {
			[MADFileUtilities removeFileAtURL:file];
		}
		[MADFileUtilities removeFileAtURL:fileURL];
		if (completion != nil) {
			completion(YES);
		}
	};

	NSAssert(self.documentState & UIDocumentStateClosed, @"Document must be closed to call this!");

	[self performAsynchronousFileAccessUsingBlock:asyncBlock];
}

@end
#endif
