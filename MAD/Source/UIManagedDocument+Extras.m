//
//  UIManagedDocument+Extras.m
//  MAD
//
//  Created by Michael Thomason on 6/8/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "UIManagedDocument+Extras.h"
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
																			   errorHandler: ^BOOL(NSURL *url, NSError *error) {
																				   return YES;
																			   }];
		for (NSURL *file in enumerator) {
			[MADFileUtilities removeFileAtURL:file];
		}
		[MADFileUtilities removeFileAtURL:fileURL];
		NSAssert(deleteError == nil, @"%@", deleteError);
		completion(YES);
	};
	
	NSAssert(self.documentState & UIDocumentStateClosed, @"Document must be closed to call this!");
	
	//[self resetPersistentStore];
	
	[self performAsynchronousFileAccessUsingBlock:asyncBlock];
}

/*+ (void)deleteFromDisk:(NSURL *)url completion:(void (^)(BOOL success))completion {
	
	MTPerformAsynchronousFileAccessUsingBlock asyncBlock = ^() {
		NSError *deleteError = nil;
		
		NSArray *properties = [[NSArray alloc] initWithObjects:NSURLIsDirectoryKey, nil];
		
		NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL: url
																 includingPropertiesForKeys: properties
																					options: NSDirectoryEnumerationSkipsHiddenFiles
																			   errorHandler: ^BOOL(NSURL *obj, NSError *error) {
																				   return YES;
																			   }];
		for (NSURL *file in enumerator) {
			[MADFileUtilities removeFileAtURL:file];
		}
		[MADFileUtilities removeFileAtURL:fileURL];
		NSAssert(deleteError == nil, @"%@", deleteError);
		completion(YES);
	};
	
	
	[self performAsynchronousFileAccessUsingBlock:asyncBlock];
}*/

- (void)resetPersistentStore {
	NSPersistentStoreCoordinator *persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
	NSPersistentStore *persistentStore = persistentStoreCoordinator.persistentStores.lastObject;
	NSURL *storeURL = [persistentStoreCoordinator URLForPersistentStore:persistentStore];
	

	NSManagedObjectContext *private;
	private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	private.parentContext = self.managedObjectContext;
	[private performBlockAndWait:^{
		[private reset];//to drop pending changes
	}];
	NSError *error = nil;
	
	//delete the store from the current managedObjectContext
	BOOL success = [persistentStoreCoordinator removePersistentStore: persistentStore
															   error: &error];
	if (success) {
		
		[MADFileUtilities removeFileAtURL:storeURL];
		
		NSNumber *o1 = @YES;
		NSNumber *o2 = @YES;
		id options = [[NSDictionary alloc] initWithObjectsAndKeys:
					  o1, NSMigratePersistentStoresAutomaticallyOption,
					  o2, NSInferMappingModelAutomaticallyOption, nil];
		
		[persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
												 configuration: nil
														   URL: storeURL
													   options: options
														 error: &error];
	}
	
}

@end
