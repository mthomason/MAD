//
//  UIManagedDocument+Extras.m
//  MAD
//
//  Created by Michael Thomason on 6/8/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "UIManagedDocument+Extras.h"
#import <MAD/RptqStoreContext.h>
#import <MADFileManager/MADFileUtilities.h>
#import <CoreData/NSPersistentStoreCoordinator.h>
#import <CoreData/NSManagedObjectContext.h>

typedef void(^MTPerformAsynchronousFileAccessUsingBlock)(void);

@implementation UIManagedDocument (Extras)

- (void)deleteFromDiskCompletion:(void (^)(BOOL success))completion {
	
	MTPerformAsynchronousFileAccessUsingBlock asyncBlock = ^() {
		NSURL *fileURL = self.fileURL;
		NSError *deleteError = nil;
		
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
		NSAssert(deleteError == nil, @"%@", deleteError);
		if (completion != nil) {
			completion(YES);
		}
	};
	
	NSAssert(self.documentState & UIDocumentStateClosed, @"Document must be closed to call this!");
	
	//[self resetPersistentStore];
	
	[self performAsynchronousFileAccessUsingBlock:asyncBlock];
}

@end
