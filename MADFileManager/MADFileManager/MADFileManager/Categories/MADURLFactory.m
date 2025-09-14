//
//  NSURL+CommonURLs.m
//  MADFileManager
//
//  Created by Michael Thomason on 5/31/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADURLFactory.h"

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADStringUtilities.h>

#import <Foundation/NSFileManager.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSException.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSFileManager.h>
#import <UIKit/UIScreen.h>
#import <os/log.h>

static NSString * const MADPathComponentData       = @"Data";
static NSString * const MADPathComponentDocuments  = @"Documents";
static NSString * const MADPathComponentCache      = @"Cache";
static NSString * const MADPathComponentAppSupport = @"Application Support";
static NSString * const MADPathComponentTemporary  = @"Temporary";

@implementation MADURLFactory

+ (BOOL)isRetinaDisplay {
	return [UIScreen mainScreen].scale > 1.0;
}

+ (NSString *)filenameID:(NSUInteger)tag {
	return [NSString stringWithFormat:@"%lu", (unsigned long)tag];
}

+ (NSURL *)newURLLocalDocumentWithName:(NSString *)name
								  extention:(NSString *)extention
								  fileGroup:(NSString *)fileGroup {
	NSURL *url = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:fileGroup];
	NSURL *documentURLWithoutExtension = [url URLByAppendingPathComponent:name];
	return [documentURLWithoutExtension URLByAppendingPathExtension:extention];
}

+ (NSURL *)newURLCacheFilesDirectoryForFilename:(NSString *)filename {
	return [MADURLFactory newURLForLocalCacheDirectoryNamed:[MADURLFactory filenameID:filename.hash]];
}

+ (NSURL *)newURLDocumentArchiveForFileURL:(NSURL *)madUrl extension:(NSString *)extension {
	NSString *destinationName = [madUrl.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension: extension];
	NSURL *destinationDirectoryUrl = [MADURLFactory newURLLocalTemporaryDirectory];
	return [destinationDirectoryUrl URLByAppendingPathComponent: destinationName
													isDirectory: YES];
}

+ (NSURL *)newURLThumbnailForURL:(NSURL *)madUrl {
	return [self newURLThumbnailForHandle: madUrl.lastPathComponent.stringByDeletingPathExtension
						 andRetinaDisplay: [self isRetinaDisplay]];
	
}

+ (NSURL *)newURLThumbnailForHandle:(NSString *)handle andRetinaDisplay:(BOOL)retinaDisplay {
	NSString *name = retinaDisplay ? [handle stringByAppendingString:@"@2x"] : handle;
	NSString *filename = [name stringByAppendingPathExtension:@"png"];
	NSURL *cacheDirectory = [MADURLFactory newURLForLocalCacheDirectoryNamed:[MADURLFactory filenameID:handle.hash]];
	return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

+ (NSURL *)newURLWithUniqueFilenameForURL:(NSURL *)originalURL {
	NSString *directoryPath = originalURL.URLByDeletingLastPathComponent.path;
	NSString *baseName = originalURL.lastPathComponent.stringByDeletingPathExtension;
	NSString *extension = originalURL.pathExtension;
	
	NSInteger counter = 0;
	NSURL *candidateURL = nil;
	
	while (true) {
		NSString *filename = (counter == 0) ? baseName : [NSString stringWithFormat:@"%@ %ld", baseName, (long)counter];
		if (extension.length > 0) {
			filename = [filename stringByAppendingPathExtension:extension];
		}
		
		candidateURL = [NSURL fileURLWithPathComponents:@[directoryPath, filename]];
		NSString *path = candidateURL.path;
		if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
			break;
		}
		
		counter++;
	}
	
	return candidateURL;
}

+ (NSURL *)newURLSharedApplicationGroupContainer:(NSString *)groupIdentifier {
	NSURL *url = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
	NSAssert(url != nil, @"The shared application group container is unavailable. "
								  @"Check your entitlements and provisioning profiles for "
								  @"this target. Details on proper setup can be found in the "
								  @"PDFs referenced from the README.");
	return url;
}



+ (NSURL *)newURLUniqueUrlInDirectory:(NSURL *)directory
					withDesiredHandle:(NSString *)desiredFileHandle
						 andExtension:(NSString *)extension {
	NSAssert(directory != nil, @"Requires a url.");
	NSURL *baseUrl = [directory URLByAppendingPathComponent: desiredFileHandle];
	NSURL *fileUrl = extension.length > 0 ? [baseUrl URLByAppendingPathExtension: extension] : baseUrl;
	NSInteger ctr = 0;
	BOOL isDir1;
	NSString *path = fileUrl.path;
	while ([[NSFileManager defaultManager] fileExistsAtPath: path
												  isDirectory: &isDir1] ||
			 [[NSFileManager defaultManager] isUbiquitousItemAtURL:fileUrl]) {
		
			NSString *maybe = [desiredFileHandle stringByAppendingFormat:@" %ld", (long)ctr];
			NSURL *baseUrlFormatted = [directory URLByAppendingPathComponent: maybe];
			fileUrl = [baseUrlFormatted URLByAppendingPathExtension: extension];
			path = ((NSURL *)fileUrl).path;
			ctr++;
	}
	return fileUrl;
	
}

+ (NSURL *)newURLUniqueURLForURL:(NSURL *)url {
	NSAssert(url != nil, @"Requires a url.");
	return [self newURLUniqueUrlInDirectory: url.URLByDeletingLastPathComponent
						  withDesiredHandle: url.lastPathComponent.stringByDeletingPathExtension
							   andExtension: url.lastPathComponent.pathExtension];
}

+ (NSURL *)newURLForLocalCacheDirectoryNamed:(NSString *)handle {
	NSURL *cachedArrayDirectories = [[MADURLFactory newURLForLocalCacheDirectory] URLByAppendingPathComponent: handle
																								  isDirectory: YES];
	BOOL isDirectory = NO;
	NSString *path = ((NSURL *)cachedArrayDirectories).path;
	BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory];
	if (exist == NO || isDirectory == NO) {
		NSError *error = nil;
		[[NSFileManager defaultManager] createDirectoryAtURL: cachedArrayDirectories
								 withIntermediateDirectories: YES attributes: nil error: &error];
		if (error) {
			error = nil;
			[[NSFileManager defaultManager] createDirectoryAtURL:cachedArrayDirectories
									 withIntermediateDirectories:YES attributes:nil error:&error];
		}
		NSAssert(error == nil, @"Error at %s: %@", __PRETTY_FUNCTION__, error);
	}
	return cachedArrayDirectories;
}

+ (NSURL *)newURLForLocalCachedDirectoryForFileUrl:(NSURL *)fileUrl {
	NSString *fileNameId = [[NSString alloc] initWithFormat: @"%lu", (unsigned long)fileUrl.lastPathComponent.stringByDeletingPathExtension.hash];
	return [self newURLForLocalCacheDirectoryNamed:fileNameId];
}

+ (NSURL *)newURLForLocalDirectoryForGroupIdentifier:(NSString *)groupID
									   pathComponent:(NSString *)pathComponent
								 alternativeSelector:(SEL)alternativeSelector {

	NSURL *groupUrl = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier: groupID];
	NSAssert(groupUrl != nil, @"containerURLForSecurityApplicationGroupIdentifier returned nil "
							  @"for %@.  Maybe the fucking entitlment file is missing?!?!", groupID);
	
	NSURL *cacheURL = [groupUrl URLByAppendingPathComponent: pathComponent isDirectory: YES];
	BOOL isDirectory = NO;
	BOOL success = NO;
	NSString *path = cacheURL.path;
	if (path != nil && path.length > 0) {
		success = [[NSFileManager defaultManager] fileExistsAtPath:path  isDirectory: &isDirectory];
		
		if (!success) {
			NSError *error = nil;
			success = [[NSFileManager defaultManager] createDirectoryAtURL: cacheURL
											   withIntermediateDirectories: YES
																attributes: nil
																	 error: &error];
			if (!success && error != nil) {
				os_log_error(OS_LOG_DEFAULT, "%s %@", __PRETTY_FUNCTION__, error);
			}
		}
	}
	return success ? cacheURL : [self newURLForURLSelector:alternativeSelector];
}

+ (NSURL *)newURLForURLSelector:(SEL)selector {
	IMP imp = [self methodForSelector:selector];
	id (*func)(id, SEL) = (void *)imp;
	return func(self, selector);
}

+ (NSURL *)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
													   fileURL:(NSURL *)fileURL {
	return [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier
																  handle:[NSString stringWithFormat:@"%lu", (unsigned long)fileURL.lastPathComponent.stringByDeletingPathExtension.hash]];
}

+ (NSURL *)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
												   handle:(NSString *)handle {
	NSURL *cacheDirectory = [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
	NSURL *cacheURL = [cacheDirectory URLByAppendingPathComponent:handle isDirectory:YES];
	BOOL isDirectory;
	NSString *path = cacheURL.path;
	if (path != nil &&
		![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
		NSError * __autoreleasing error = NULL;
		isDirectory = [[NSFileManager defaultManager] createDirectoryAtURL: cacheURL
											   withIntermediateDirectories: YES attributes: nil
																	 error: &error];
	}
	return cacheURL;
}

+ (NSURL *)newURLForLocalDocumentsDirectory {
	NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *firstObject = documentsDirectories.firstObject;
	NSURL *url = [[NSURL alloc] initWithString:firstObject];
	return url;
}

+ (NSURL *)newURLLocalTemporaryDirectory {
	return [[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES] URLByAppendingPathComponent:@"tmp" isDirectory:YES];
}

static NSURL *urlForCacheDirectory;
+ (NSURL *)newURLForLocalCacheDirectory {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSAssert(paths.count > 0, @"Expect a path.");
		NSString *firstObject = paths.firstObject;
		urlForCacheDirectory = [[NSURL alloc] initFileURLWithPath:firstObject isDirectory:YES];
	});
	return urlForCacheDirectory;
}

+ (NSURL *)newURLForLocalDataDirectory {
	return [[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES] URLByAppendingPathComponent:MADPathComponentData isDirectory:YES];
}

+ (NSURL *)newURLForLocalApplicationSupportDirectory {
	NSArray <NSURL *> *possibleUrls = [[NSFileManager defaultManager] URLsForDirectory: NSApplicationSupportDirectory
																			 inDomains: NSUserDomainMask];
	NSURL *appSupportDirectory = nil;
	NSURL *appSupportDirectoryForApp = nil;
	
	if (possibleUrls.count >= 1) {
		appSupportDirectory = possibleUrls[0];
		
		BOOL isDirectory;
		NSString *appSupportPath = appSupportDirectory.path;
		BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath: appSupportPath
															  isDirectory: &isDirectory];
		if (fileExist == NO) {
			NSError *error = nil;
			[[NSFileManager defaultManager] createDirectoryAtURL: appSupportDirectory
									 withIntermediateDirectories: YES
													  attributes: nil
														   error: &error];
		}
		
		NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier.copy;
		appSupportDirectoryForApp = [appSupportDirectory URLByAppendingPathComponent:bundleIdentifier];
		NSString *path = ((NSURL *)appSupportDirectoryForApp).path;
		fileExist = [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory];
		
		if (fileExist == NO) {
			NSError *error = nil;
			[[NSFileManager defaultManager] createDirectoryAtURL: appSupportDirectoryForApp
									 withIntermediateDirectories: YES
													  attributes: nil
														   error: &error];
		}
		
	}
	return appSupportDirectoryForApp;
}

+ (NSURL *)newURLApplicationSupportFile:(NSString *)filename extension:(NSString *)extension {
	NSString *groupID = [MADApplication groupIdentifier];
	NSURL *appSupportDirectory = [MADURLFactory newURLLocalApplicationSupportDirectoryForGroupID: groupID];
	NSString *fileHandle = [MADStringUtilities stringByAppendingKeyPath: extension
															   toString: filename];
	return [appSupportDirectory URLByAppendingPathComponent:fileHandle
												isDirectory:NO];
}

+ (NSURL *)newURLForCloudDocumentsDirectoryForUbiquityID:(NSString *)ubiquityID {
	NSURL *cloudDirectory = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:ubiquityID];
	return [cloudDirectory URLByAppendingPathComponent:MADPathComponentDocuments];
}

+ (NSURL *)newURLLocalDocumentsDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
	return [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
											 pathComponent: MADPathComponentDocuments
									   alternativeSelector: @selector(newURLForLocalDocumentsDirectory)];
}

+ (NSURL *)newURLForLocalDataDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
	return [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
											 pathComponent: MADPathComponentData
									   alternativeSelector: @selector(newURLForLocalDataDirectory)];
}

+ (NSURL *)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
	return [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
											 pathComponent: MADPathComponentCache
									   alternativeSelector: @selector(newURLForLocalCacheDirectory)];
}

+ (NSURL *)newURLLocalApplicationSupportDirectoryForGroupID:(NSString *)groupIdentifier {
	return [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
											 pathComponent: MADPathComponentAppSupport
									   alternativeSelector: @selector(newURLForLocalApplicationSupportDirectory)];
}

+ (NSURL *)newURLForLocalTemporaryDirectoryForGroupIdentifier:(NSString *)groupIdentifier {
	return [self newURLForLocalDirectoryForGroupIdentifier: groupIdentifier
											 pathComponent: MADPathComponentTemporary
									   alternativeSelector: @selector(newURLLocalTemporaryDirectory)];
}

@end
