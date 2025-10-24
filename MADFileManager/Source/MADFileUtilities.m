//
//  MADFileUtilities.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADFileUtilities.h"
#import "madlog.h"
#import <MADFoundation/MADURLFactory.h>

#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSFileCoordinator.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSData.h>
#import <Foundation/NSKeyedArchiver.h>
#import <Foundation/NSOperation.h>
#import <Foundation/NSFileWrapper.h>

#import <os/log.h>

static NSString * const MADPathComponentDocuments  = @"Documents";
static NSString * const MADPathComponentCache      = @"Cache";
static NSString * const MADPathComponentAppSupport = @"Application Support";
static NSString * const MADPathComponentTemporary  = @"Temporary";
static NSString * const MADPathComponentData       = @"Data";

@implementation MADFileUtilities

+ (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl {
	[self deleteCoreDataFilesAtDirectory:destinationUrl withCoordinator:YES];
}

+ (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl
					   withCoordinator:(BOOL)coordinator {
	BOOL isDirectory;
	
	NSString *destinationPath = destinationUrl.path.copy;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: destinationPath
													   isDirectory: &isDirectory];
	if (exists) {
		if (isDirectory) {
			
			BOOL(^ErrorHandler)(NSURL *, NSError *) = ^BOOL(NSURL *url, NSError *error) {
				NSAssert(error != nil, @"%s : %@",__PRETTY_FUNCTION__, error);
				return YES;
			};
			
			NSArray *requestedKeys = [[NSArray alloc] initWithObjects:NSURLIsDirectoryKey, nil];
			NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL: destinationUrl
																	 includingPropertiesForKeys: requestedKeys
																						options: NSDirectoryEnumerationSkipsPackageDescendants
																				   errorHandler: ErrorHandler];
			for (NSURL *fileURL in enumerator) {
				NSURL *file = fileURL.copy;
				[MADFileUtilities removeFileAtURL:file withCoordinator:coordinator];
			}
			
			NSURL *file = destinationUrl.copy;
			[MADFileUtilities removeFileAtURL:file withCoordinator:coordinator];
		}
	}
}

+ (void)coordinateCreateDirectoryIfDoesNotExist:(NSURL *)url {
	
	NSString *path = url.path;
	if ([[NSFileManager defaultManager] fileExistsAtPath: path] == NO) {
		
		NSError *error = nil;
		NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
		[coordinator coordinateWritingItemAtURL: url
										options: (NSFileCoordinatorWritingOptions)0 error: &error
									 byAccessor: ^(NSURL *newURL) {
			
			NSError *errorCreateNew = nil;
			NSString *path = newURL.path;

			[[NSFileManager defaultManager] createDirectoryAtPath: path
									  withIntermediateDirectories: YES attributes: nil
															error: &errorCreateNew];
			
			NSAssert(errorCreateNew == nil, @"%s %@", __PRETTY_FUNCTION__, errorCreateNew);
		}];
		
		NSAssert(error == nil, @"%s %@", __PRETTY_FUNCTION__, error);
	}
}

+ (void)copyInitialFiles:(NSString *)fileExtension groupId:(NSString *)groupId {
	NSArray *defaultListURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension: fileExtension
																	   subdirectory: @""];
	
	for (NSURL *url in defaultListURLs) {
		[self copyURLToDocumentsDirectoryIfNotExist:url groupId:groupId];
	}
}

+ (void)migrateLocalFiles:(NSString *)groupID toCloud:(NSString *)ubiquityID
				extension:(NSString *)extension {
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{

		// Note the call to -URLForUbiquityContainerIdentifier: should be on a background queue.
		NSURL *documentsDirectoryURL = [MADURLFactory newURLForCloudDocumentsDirectoryForUbiquityID:ubiquityID];
		NSURL *documentsDirectoryLocal = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:groupID];
		
		NSArray <NSURL *> *urls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL: documentsDirectoryLocal
																includingPropertiesForKeys: nil
																				   options: (NSDirectoryEnumerationOptions)0
																					 error: nil];

		for (NSURL *URL in urls) {
			if ([URL.pathExtension isEqualToString:extension]) {
				[self makeItemUbiquitousAtURL: URL
						documentsDirectoryURL: documentsDirectoryURL];
			}
		}
	});
}

+ (void)makeItemUbiquitousAtURL:(NSURL *)sourceURL
		  documentsDirectoryURL:(NSURL *)documentsDirectoryURL {
	
	NSString *destinationFileName = sourceURL.lastPathComponent;
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSURL *destinationURL = [documentsDirectoryURL URLByAppendingPathComponent:destinationFileName];
	
	NSString *path = destinationURL.path;
	if ([fileManager isUbiquitousItemAtURL:destinationURL] ||
		(path != nil && [fileManager fileExistsAtPath:path])) {

		destinationURL = [MADURLFactory newURLUniqueURLForURL:destinationURL];
		
	}
	
	dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
	dispatch_async(defaultQueue, ^{
		[fileManager setUbiquitous:YES itemAtURL:sourceURL destinationURL:destinationURL error:nil];
	});
}

+ (void)readObjectOfClass:(Class)cls
				  fromURL:(NSURL *)url
			   completion:(void (^)(id object, NSError *error))completion {
	
	NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
	BOOL startedAccess = [url startAccessingSecurityScopedResource];
	
	NSFileAccessIntent *intent = [NSFileAccessIntent readingIntentWithURL:url
																  options:NSFileCoordinatorReadingWithoutChanges];
	
	[fileCoordinator coordinateAccessWithIntents:@[intent]
										   queue:[self queue]
									  byAccessor:^(NSError *error) {
		if (error) {
			if (startedAccess) [url stopAccessingSecurityScopedResource];
			if (completion != nil) completion(nil, error);
			return;
		}
		
		NSError *readError = nil;
		NSData *data = [NSData dataWithContentsOfURL:intent.URL options:0 error:&readError];
		if (!data || readError) {
			if (startedAccess) [url stopAccessingSecurityScopedResource];
			if (completion != nil) completion(nil, readError);
			return;
		}
		
		NSError *decodeError = nil;
		id object = [NSKeyedUnarchiver unarchivedObjectOfClass:cls
													  fromData:data
														 error:&decodeError];
		
		if (startedAccess) [url stopAccessingSecurityScopedResource];
		if (completion != nil) completion(object, decodeError);
	}];
}

+ (void)writeObject:(__kindof NSObject<NSCopying, NSSecureCoding> *)object
			  toURL:(NSURL *)url
		 completion:(void (^)(NSError *error))completion {
	
	NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
	NSFileAccessIntent *intent = [NSFileAccessIntent writingIntentWithURL:url
																  options:NSFileCoordinatorWritingForReplacing];
	
	[fileCoordinator coordinateAccessWithIntents:@[intent]
										   queue:[self queue]
									  byAccessor:^(NSError *error) {
		if (error) {
			if (completion != nil) completion(error);
			return;
		}
		
		NSError *archiveError = nil;
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object
											 requiringSecureCoding:YES
															 error:&archiveError];
		if (archiveError != nil) {
			os_log_error(OS_LOG_DEFAULT, "%s: Error archiving object: %@", __PRETTY_FUNCTION__, archiveError);
			if (completion != nil) completion(archiveError);
			return;
		}
		
		NSError *writeError = nil;
		BOOL success = [data writeToURL:intent.URL options:NSDataWritingAtomic error:&writeError];
		
		if (success) {
			NSString *path = intent.URL.path;
			NSError *setAttributesError = nil;
			[[NSFileManager defaultManager] setAttributes:@{ NSFileExtensionHidden: @YES }
											 ofItemAtPath:path
													error:&setAttributesError];
			if (setAttributesError != nil) {
				if (completion != nil) completion(setAttributesError);
				os_log_error(OS_LOG_DEFAULT, "%s: Error setting file attributes: %@", __PRETTY_FUNCTION__, setAttributesError);
			}
			
		} else {
			if (writeError != nil) {
				os_log_error(OS_LOG_DEFAULT, "%s: Error writing data to file: %@", __PRETTY_FUNCTION__, writeError);
			}
		}

		if (completion != nil) completion(writeError);
	}];
}

/// FIXME: Unused, maybe doesn't work... archiving nothing.
+ (void)createFileAtURL:(NSURL *)url
			 completion:(void (^)(NSError *))completion {
	
	NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
	
	NSFileAccessIntent *writing;
	writing = [NSFileAccessIntent writingIntentWithURL:url
											   options:NSFileCoordinatorWritingForReplacing];
	NSArray <NSFileAccessIntent *> *intents = [[NSArray alloc] initWithObjects:writing, nil];
	[fileCoordinator coordinateAccessWithIntents: intents
										   queue: [self queue]
									  byAccessor: ^(NSError *accessError) {
		if (accessError) {
			if (completion) {
				completion(accessError);
			}
			
			return;
		}
		
		NSNumber *zero = @0;
		NSError *archiveError = nil;
		NSData *serializedListData = [NSKeyedArchiver archivedDataWithRootObject:zero requiringSecureCoding:YES error:&archiveError];
		if (archiveError != nil) {
			os_log_error(OS_LOG_DEFAULT, "%s: Error archiving object: %@", __PRETTY_FUNCTION__, archiveError);
			completion(archiveError);
		}
		
		NSError *error;
		BOOL success = [serializedListData writeToURL:writing.URL
											  options:NSDataWritingAtomic error:&error];
		if (error != nil) {
			os_log_error(OS_LOG_DEFAULT, "%s: Error writing data to file: %@", __PRETTY_FUNCTION__, error);
			if (!success) completion(error);
		}
		if (success) {
			NSDictionary <NSString *, NSNumber *> *fileAttributes;
			fileAttributes = @{ NSFileExtensionHidden : @YES };
			NSString *path = writing.URL.path;
			if (path.length > 0) {
				NSError *setAttributesError = nil;
				[[NSFileManager defaultManager] setAttributes: fileAttributes
												 ofItemAtPath: path
														error: &setAttributesError];
				if (setAttributesError != nil) {
					os_log_error(OS_LOG_DEFAULT, "%s: Error setting file attributes: %@", __PRETTY_FUNCTION__, setAttributesError);
				}
			}
		}
		
		if (completion) {
			completion(error);
		}
	}];
}

+ (void)renameFileAtURL:(NSURL *)source toName:(NSString *)name
			 completion:(void (^)(NSURL *sourceURL, NSURL *newURL,
								  NSError *error))completion {
	
	NSString *pathExtension = source.lastPathComponent.pathExtension;
	NSString *filename = [name stringByAppendingPathExtension: pathExtension];
	NSURL *desired = [source.URLByDeletingLastPathComponent URLByAppendingPathComponent: filename
																			isDirectory: NO];
	NSURL *destination = [MADURLFactory newURLUniqueURLForURL:desired];

	NSString *status;
	NSError *errorGettingAttributes = nil;
	BOOL gotResourceValue = [source getResourceValue:&status forKey:NSURLUbiquitousItemDownloadingStatusKey
											   error:&errorGettingAttributes];
	if (gotResourceValue && [status isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent]) {
		[self moveFileAtURL:source toUrl:destination
				   completion:^(NSURL *result, NSError *error) {
			if (completion != nil) completion(source, result, error);
		}];
	} else {
		[self moveRemoveFileAtURL:source toUrl:destination
			completion:^(NSURL *result, NSError *error) {
			if (completion != nil) completion(source, result, error);
		}];
	}
}

+ (void)moveRemoveFileAtURL:(NSURL *)source toUrl:(NSURL *)destination
	  completion:(void (^)(NSURL *, NSError *))completion {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
		[self moveFileAtURL:source toUrl:destination
				   completion:^(NSURL *result, NSError *error) {
			if (completion != nil) completion(destination, error);
		}];
		
	});
}

+ (void)moveFileAtURL:(NSURL *)source toUrl:(NSURL *)destination
								 completion:(void (^)(NSURL *result,
													  NSError *error))completion {
	NSError *coordinatorError = nil;
	
	BOOL successfulSecurityScopedResourceAccess = [source startAccessingSecurityScopedResource];
	NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
	[coordinator coordinateWritingItemAtURL: source
									options: NSFileCoordinatorWritingForMoving
						   writingItemAtURL: destination
									options: NSFileCoordinatorWritingForReplacing
									  error: &coordinatorError
								 byAccessor: ^(NSURL *accessorSource, NSURL *accessorDestination) {
									 
		__block NSError *moveError = nil;
		BOOL success = [[NSFileManager defaultManager] moveItemAtURL: accessorSource
															   toURL: accessorDestination
															   error: &moveError];
		if (success) {
			[coordinator itemAtURL:accessorSource didMoveToURL:accessorDestination];
		}
		if (successfulSecurityScopedResourceAccess) {
			[source stopAccessingSecurityScopedResource];
		}
									 
		if (completion != nil) completion(accessorDestination, moveError);

	}];

}

+ (void)duplicateFileAtURL:(NSURL *)url
				completion:(void (^)(NSURL *result, NSError *error))completion {
	
	NSURL *uniqueUrl = [MADURLFactory newURLUniqueUrlInDirectory: url.URLByDeletingLastPathComponent
										withDesiredHandle: url.lastPathComponent.stringByDeletingPathExtension
											 andExtension: url.lastPathComponent.pathExtension];

	// `url` may be a security scoped resource.
	BOOL successfulSecurityScopedResourceAccess = [url startAccessingSecurityScopedResource];

	NSError *error = nil;
	NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
	[coordinator coordinateReadingItemAtURL: url
									options: NSFileCoordinatorReadingWithoutChanges
						   writingItemAtURL: uniqueUrl                              // FIXME: Try copying url to url, and have it auto unique.
									options: NSFileCoordinatorWritingForMoving
									  error: &error
								 byAccessor: ^(NSURL *source, NSURL *destinaion) {
		if (error) {
			if (completion != nil) completion(nil, error);
			return;
		}
		
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSError *errorCopy = nil;

		BOOL success = [fileManager copyItemAtURL: source toURL: destinaion error: &errorCopy];
		if (success) {
			[coordinator itemAtURL:source didMoveToURL:destinaion];
		}
		if (successfulSecurityScopedResourceAccess) {
			[url stopAccessingSecurityScopedResource];
		}
		if (completion != nil) {
			completion(destinaion, errorCopy);
		}

	}];
}

+ (void)removeFileAndArchiveAtURL:(NSURL *)url {
	[MADFileUtilities removeFilesAtURL:url];
	[MADFileUtilities removeFileAtURL:url];
	
}

+ (void)removeFilesAtURL:(NSURL *)url {
	BOOL (^errorHandler)(NSURL *, NSError *) = ^BOOL(NSURL *errorUrl, NSError *error) {
		//NSLog(@"Error %@", error);
		return YES;
	};
	NSArray *propertyKeys = [[NSArray alloc] initWithObjects: NSURLIsDirectoryKey, nil];
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL: url
															 includingPropertiesForKeys: propertyKeys
																				options: NSNotFound
																		   errorHandler: errorHandler];
	for (NSURL *fileURL in enumerator) {
		[MADFileUtilities removeFileAtURL:fileURL];
	}
}

+ (void)removeFileAtURL:(NSURL *)url {
	[self removeFileAtURL:url completion:nil];
}

+ (void)removeFileAtURL:(NSURL *)url withCoordinator:(BOOL)coordinator {
	if (coordinator) {
		[self removeFileAtURL:url completion:nil];
	} else {
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSError *error = nil;
		[fileManager removeItemAtURL:url error:&error];
		if (error != nil) {
			os_log_debug(GetFileManagerLog(), "Error: %@", error);
		}
	}
}

+ (void)removeFileAtURL:(NSURL *)url completion:(void (^)(NSError *error))completion {
	NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
	
	// `url` may be a security scoped resource.
	BOOL successfulSecurityScopedResourceAccess = [url startAccessingSecurityScopedResource];
	
	NSFileAccessIntent *writing = [NSFileAccessIntent writingIntentWithURL: url
																   options: NSFileCoordinatorWritingForDeleting];
	NSArray *intents = [[NSArray alloc] initWithObjects:writing, nil];
	[fileCoordinator coordinateAccessWithIntents:intents
										   queue:[self queue]
									  byAccessor:^(NSError *accessError) {
		if (accessError) {
			os_log_debug(GetFileManagerLog(), "Error: %@", accessError);
			if (completion != nil) completion(accessError);
			return;
		}
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSError *error = nil;
		BOOL successfulDelete = [fileManager removeItemAtURL:writing.URL error:&error];
		if (error != nil) {
			os_log_debug(GetFileManagerLog(), "Error: %@", error);
		}
		if (successfulSecurityScopedResourceAccess) [url stopAccessingSecurityScopedResource];
		if (completion != nil) completion(successfulDelete ? nil : error);
	}];
}

#pragma mark - Convenience

+ (void)copyURLToDocumentsDirectoryIfNotExist:(NSURL *)url groupId:(NSString *)groupId {
	NSURL *localDocumentsDirectory = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:groupId];
	NSString *lastPathComponent = url.lastPathComponent;
	NSURL *toURL = [localDocumentsDirectory URLByAppendingPathComponent:lastPathComponent];
	
	// If the file already exists, don't attempt to copy the version from the bundle.
	NSString *path = toURL.path;
	if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
		return;
	}
	
	NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
	__block NSError *error;
	
	BOOL successfulSecurityScopedResourceAccess = [url startAccessingSecurityScopedResource];
	
	NSFileAccessIntent *moving, *replacing;
	moving    = [NSFileAccessIntent writingIntentWithURL: url
												 options: NSFileCoordinatorWritingForMoving];
	replacing = [NSFileAccessIntent writingIntentWithURL: toURL
												 options: NSFileCoordinatorWritingForReplacing];
	NSArray *intents = [[NSArray alloc] initWithObjects:moving, replacing, nil];
	[fileCoordinator coordinateAccessWithIntents: intents
										   queue: [self queue] byAccessor:^(NSError *accessError) {
		if (accessError) {
			// An error occured when trying to coordinate moving URL to toURL.
			//  In your app, handle this gracefully.
			os_log_debug(GetFileManagerLog(), "Error: %@", accessError);
			return;
		}
		
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		
		BOOL success = [fileManager copyItemAtURL:moving.URL toURL:replacing.URL error:&error];
		
		if (success) {
			NSDictionary <NSString *, NSNumber *> *fileAttributes;
			fileAttributes = @{ NSFileExtensionHidden : @YES };
			NSString *path = replacing.URL.path;
			if (path) {
				NSError *setAttributesError = nil;
				[fileManager setAttributes:fileAttributes
							  ofItemAtPath:path
									 error:&setAttributesError];
				if (setAttributesError != nil) {
					os_log_error(OS_LOG_DEFAULT, "%s: Error setting file attributes: %@", __PRETTY_FUNCTION__, setAttributesError);
				}
			}
		}
		
		if (successfulSecurityScopedResourceAccess) {
			[url stopAccessingSecurityScopedResource];
		}
	}];
}

/// An internal queue to the \c AAPLListUtilities class that is used for \c NSFileCoordinator callbacks.
+ (NSOperationQueue *)queue {
	static NSOperationQueue *queue;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		queue = [[NSOperationQueue alloc] init];
	});
	return queue;
}

+ (NSArray <NSURL *> *)contentsOfDocumentsDirectoryWithGroupIdentifier: (NSString *)groupIdentifier
														  andExtention: (NSString *)extenstion {
	NSURL *direcotry = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:groupIdentifier];
	return [self contentsOfDirectory:direcotry withPathExtension:extenstion];
}

- (NSArray <__kindof NSURL *> *)contentOfDirectory:(NSURL *)directory withExtention:(NSString *)extenstion {
	
	NSMutableArray <__kindof NSURL *> *result = [[NSMutableArray alloc] init];
	NSError *error = nil;
	NSString *path = directory.path;
	NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: path
																					 error: &error];
	for (NSString *filename in directoryContents) {
		NSString *fullPath = [directory.path stringByAppendingPathComponent:filename];
		NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
		BOOL isDirectory;
		path = fileURL.path;
		if ([[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory]) {
			if ([fileURL.pathExtension isEqualToString:extenstion]) {
				[result addObject:fileURL];
			}
		}
	}
	return result;
}


+ (NSArray <__kindof NSURL *> *)contentOfLocalDocumentsDirectoryWithExtention:(NSString *)extenstion {
	
	NSMutableArray <__kindof NSURL *> *result = [[NSMutableArray alloc] init];
	NSError *error = nil;
	NSArray *docPaths;
	docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *path = docPaths.firstObject;
	NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
																					 error:&error];
	for (NSString *filename in directoryContents) {
		NSString *fullPath = [docPaths.firstObject stringByAppendingPathComponent:filename];
		NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
		BOOL isDirectory;
		path = fileURL.path;
		if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
			if ([fileURL.pathExtension isEqualToString:extenstion]) {
				[result addObject:fileURL];
			}
		}
	}
	return result;
}

+ (NSArray <NSURL *> *)contentsOfDirectory:(NSURL *)directory
						 withPathExtension:(NSString *)extension {
	NSMutableArray <NSURL *> *result = [[NSMutableArray alloc] init];
	NSError *error = nil;
	NSString *path = directory.path;
	NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
																					 error:&error];
	for (NSString *filename in directoryContents) {
		NSString *fullPath = [directory.path stringByAppendingPathComponent:filename];
		NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
		BOOL isDirectory;
		path = fileURL.path;
		if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
			if ([fileURL.pathExtension isEqualToString:extension]) {
				[result addObject:fileURL];
			}
		}
	}
	return result;
}

+ (BOOL)createDirectoryForUrlIfItDoesNotExist:(NSURL *)url {
	NSError *error = nil;
	NSString *path;
	if ((path = url.path) == nil) return NO;
	BOOL directoryGood = [[NSFileManager defaultManager] createDirectoryAtPath: path
												   withIntermediateDirectories: YES
																	attributes: nil
																		 error: &error];
	if (error != nil) {
		directoryGood = NO;
		NSAssert(error, @"Error creating directory!  %@", error);
	}
	return directoryGood;
}

+ (void)removeCachedFileForDocumentUrl:(NSURL *)documentUrl {
	NSError *error = nil;
	NSURL *cachedDirectory = [MADURLFactory newURLForLocalCachedDirectoryForFileUrl: documentUrl];
	NSArray <NSURL *> *cachedFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL: cachedDirectory
																   includingPropertiesForKeys: nil
																					  options: (NSDirectoryEnumerationOptions)0
																						error: &error];
	if (error != nil) {
		os_log_error(GetFileManagerLog(), "%s: Error getting contents of directory: %@", __PRETTY_FUNCTION__, error);
	}
	NSURL *cachedFile;
	for (cachedFile in cachedFiles) {
		NSError *removeItemError = nil;
		[[NSFileManager defaultManager] removeItemAtURL:cachedFile error:&removeItemError];
		if (removeItemError != nil) {
			os_log_error(GetFileManagerLog(), "%s: Error removing item at URL: %@", __PRETTY_FUNCTION__, removeItemError);
		}
	}
	NSError *removeDirError = nil;
	[[NSFileManager defaultManager] removeItemAtURL:cachedDirectory error:&removeDirError];
	if (removeDirError != nil) {
		os_log_error(GetFileManagerLog(), "%s: Error removing directory at URL: %@", __PRETTY_FUNCTION__, removeDirError);
	}
}

+ (BOOL)removeCachedFileForDocumentUrl:(NSURL *)documentUrl
					   groupIdentifier:(NSString *)groupIdentifier {
	NSURL *cachedDirectory = [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier: groupIdentifier
																				   fileURL: documentUrl];
	return [MADFileUtilities removeContentsOfDirectory:cachedDirectory];
}

+ (BOOL)removeContentsOfDirectory:(NSURL *)directory {
	NSError *error = nil;
	NSArray <NSURL *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL: directory
															 includingPropertiesForKeys: nil
																				options: (NSDirectoryEnumerationOptions)0
																				  error: &error];
	if (error != nil) {
		os_log_error(GetFileManagerLog(), "%s: Error getting contents of directory: %@", __PRETTY_FUNCTION__, error);
		return NO;
	}
	for (NSURL *file in files) {
		NSError *removeItemError = nil;
		[[NSFileManager defaultManager] removeItemAtURL: file error: &removeItemError];
		if (removeItemError != nil) {
			os_log_error(GetFileManagerLog(), "%s: Error removing item at URL: %@", __PRETTY_FUNCTION__, removeItemError);
		}
	}
	NSError *removeDirError = nil;
	[[NSFileManager defaultManager] removeItemAtURL: directory error: &removeDirError];
	if (removeDirError != nil) {
		os_log_error(GetFileManagerLog(), "%s: Error removing directory at URL: %@", __PRETTY_FUNCTION__, removeDirError);
	}
	return YES;
}

+ (BOOL)restoreFileWrapper:(NSURL *)originURL archiveURL:(NSURL *)archiveURL
				 overwrite:(BOOL)overwrite {
	BOOL success = NO;
	NSError *fileWrapperError = nil;
	NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL: originURL
															options: NSFileWrapperReadingImmediate
															  error: &fileWrapperError];
	if (fileWrapperError != nil) {
		os_log_error(GetFileManagerLog(), "%s: Error creating file wrapper from URL: %@", __PRETTY_FUNCTION__, fileWrapperError);
	}
	
	if (fileWrapperError == nil) {
		if (overwrite) {
			NSData *data = fileWrapper.serializedRepresentation;
			NSError *errorWriting = nil;
			success = [data writeToURL: archiveURL
							   options: NSDataWritingAtomic
								 error: &errorWriting];
			if (errorWriting != nil) {
				os_log_error(GetFileManagerLog(), "%s: Error writing data to URL: %@", __PRETTY_FUNCTION__, errorWriting);
			}
		} else {
			NSURL *resultUrl = [MADURLFactory newURLWithUniqueFilenameForURL:archiveURL];
			NSData *data = fileWrapper.serializedRepresentation;
			success = [data writeToURL:resultUrl atomically:YES];
		}
	}
	return success;
}

@end
