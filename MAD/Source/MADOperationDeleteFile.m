//
//  MADOperationDeleteFile.m
//  MAD
//
//  Created by Michael on 8/17/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADOperationDeleteFile.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSURL.h>

#import <MADFileManager/MADFileUtilities.h>
#import <MAD/MADOperationUniqueUrlForFilename.h>
#import <MAD/MADocument.h>
#import <MAD/UIDocument+Extras.h>
#import <MAD/MADOperationCreateDocumentCreateDocument.h>
#import <MADFoundation/MADOperationTestResults.h>
#import <MADFoundation/madlog.h>

@implementation MADOperationDeleteFile

- (void)dealloc { }

- (BOOL)isAsynchronous {
	return YES;
}

- (void)execute {
	if (self.cancelled) return [self finish];
	NSURL *fileURL;
	MADocument *document = nil;
	NSArray <NSOperation *> *dependencies = self.dependencies;
	BOOL deleteFile = NO;
	for (NSOperation *dependency in dependencies) {
		if ([dependency conformsToProtocol:@protocol(MADOperationUniqueUrlForFilenameProtocol)]) {
			fileURL = ((id <MADOperationUniqueUrlForFilenameProtocol>)dependency).uniqueUrl.copy;
		}
		if ([dependency conformsToProtocol:@protocol(MADOperationCreateDocumentProtocol)]) {
			document = ((id <MADOperationCreateDocumentProtocol>)dependency).document;
			break;
		}
		if ([dependency conformsToProtocol:@protocol(MADOperationTestResults)]) {
			deleteFile = !((NSObject <MADOperationTestResults> *)dependency).success;
		}
	}
	if (!deleteFile) return [self finish];

	if (document != nil) {
		[document deleteFromDiskCompletion:^(BOOL success) {
			if (!success)
				[self finishWithError:nil];
			else
				[self finish];
		}];
	} else {
		[MADFileUtilities removeFileAtURL:fileURL completion:^(NSError *error) {
			if (error != nil)
				[self finishWithError:error];
			else
				[self finish];
		}];
	}

}

@end
