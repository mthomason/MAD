//
//  NSURL+CommonURLs.m
//  MADFileManager
//
//  Created by Michael Thomason on 5/31/16.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADURLFactory.h"
#import <Foundation/NSFileManager.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSException.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSFileManager.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADStringUtilities.h>

#if TARGET_OS_MACCATALYST || TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

static NSString * const MADPathComponentData       = @"Data";
static NSString * const MADPathComponentDocuments  = @"Documents";
static NSString * const MADPathComponentCache      = @"Cache";
static NSString * const MADPathComponentAppSupport = @"Application Support";
static NSString * const MADPathComponentTemporary  = @"Temporary";

@implementation MADURLFactory

+ (BOOL)isRetinaDisplay {
#if TARGET_OS_MACCATALYST || TARGET_OS_IOS
	return [UIScreen mainScreen].scale > 1.0;
#elif TARGET_OS_OSX
	return [NSScreen mainScreen].backingScaleFactor > 1.0;
#else
	return NO;
#endif
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
	NSString *filenameId = [MADURLFactory filenameID:filename.hash];
	return [MADURLFactory newURLForLocalCacheDirectoryNamed:filenameId];
}

+ (NSURL *)newURLDocumentArchiveForFileURL:(NSURL *)madUrl extension:(NSString *)extension {
	NSString *name = madUrl.lastPathComponent.stringByDeletingPathExtension;
	NSString *destinationName = [name stringByAppendingPathExtension: extension];
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
	NSString *fileNameId = [MADURLFactory filenameID:handle.hash];
	NSURL *cacheDirectory = [MADURLFactory newURLForLocalCacheDirectoryNamed:fileNameId];
	return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

+ (NSURL *)newURLWithUniqueFilenameForURL:(NSURL *)origionalURL {
	NSInteger ctr = 0;
	NSURL *unqiueURL;
	NSString *pathExtension, *name, *path, *maybe;
	
	pathExtension = origionalURL.pathExtension.copy;
	name = origionalURL.lastPathComponent.stringByDeletingPathExtension.copy;
	
	do {
		maybe = [name stringByAppendingFormat:@" %ld", (long)ctr];
		[maybe stringByAppendingPathExtension: pathExtension];
		
		unqiueURL = [origionalURL.baseURL URLByAppendingPathComponent:maybe isDirectory:NO];
		path = ((NSURL *)unqiueURL).path.copy;
		ctr++;
	} while ([[NSFileManager defaultManager] fileExistsAtPath:path]);
	
	return unqiueURL;
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
	NSURL *fileUrl = extension.length > 0 ?
	[baseUrl URLByAppendingPathExtension: extension] :
	baseUrl;
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
	NSURL *url = [MADURLFactory newURLForLocalCacheDirectory];
	NSURL *cachedArrayDirectories = [url URLByAppendingPathComponent: handle
														 isDirectory: YES];
	BOOL exist, isDirectory;
	NSString *path = ((NSURL *)cachedArrayDirectories).path;
	exist = [[NSFileManager defaultManager] fileExistsAtPath: path
												 isDirectory: &isDirectory];
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
	NSUInteger hash = fileUrl.lastPathComponent.stringByDeletingPathExtension.hash;
	NSString *fileNameId = [[NSString alloc] initWithFormat: @"%lu", (unsigned long)hash];
	return [self newURLForLocalCacheDirectoryNamed:fileNameId];
}

+ (NSURL *)newURLForLocalDirectoryForGroupIdentifier:(NSString *)groupID
											pathComponent:(NSString *)pathComponent
									  alternativeSelector:(SEL)alternativeSelector {
	
	BOOL success = NO, isDirectory = NO;
	NSString *cachePath;
	NSURL *groupUrl, *cacheURL;

	
	groupUrl = [[NSFileManager defaultManager]
					   containerURLForSecurityApplicationGroupIdentifier: groupID];
	
	NSAssert(groupUrl != nil, @"containerURLForSecurityApplicationGroupIdentifier returned nil "
							  @"for %@.  Maybe the fucking entitlment file is missing?!?!",
							  groupID);
	
	cacheURL = [groupUrl URLByAppendingPathComponent: pathComponent
										 isDirectory: YES];
	cachePath = cacheURL.path.copy;
	success = [[NSFileManager defaultManager] fileExistsAtPath: cachePath
												   isDirectory: &isDirectory];
	
	if (!success) {
		NSError *error;
		success = [[NSFileManager defaultManager] createDirectoryAtURL: cacheURL
											   withIntermediateDirectories: YES
																attributes: nil
																	 error: &error];
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
	NSString *fileNameId;
	fileNameId = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)fileURL.lastPathComponent.stringByDeletingPathExtension.hash];
	return [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier handle:fileNameId];
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
	NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																		NSUserDomainMask, YES);
	NSString *firstObject = documentsDirectories.firstObject;
	NSURL *url = [[NSURL alloc] initWithString:firstObject];
	return url;
}

+ (NSURL *)newURLLocalTemporaryDirectory {
	NSURL *fileUrlWithPath = [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
	return [fileUrlWithPath URLByAppendingPathComponent:@"tmp" isDirectory:YES];
}

+ (NSURL *)newURLForLocalCacheDirectory {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *firstObject = paths.firstObject;
	NSURL *url = [[NSURL alloc] initFileURLWithPath:firstObject
										isDirectory:YES];
	return url;
}

+ (NSURL *)newURLForLocalDataDirectory {
	NSString *homeDirectory = NSHomeDirectory();
	NSURL *fileUrlWithPath = [NSURL fileURLWithPath:homeDirectory isDirectory:YES];
	id result = [fileUrlWithPath URLByAppendingPathComponent:MADPathComponentData isDirectory:YES];
	return result;
}

+ (NSURL *)newURLForLocalApplicationSupportDirectory {
	NSArray <NSURL *> *possibleUrls;
	possibleUrls = [[NSFileManager defaultManager] URLsForDirectory: NSApplicationSupportDirectory
														  inDomains: NSUserDomainMask];
	NSURL *appSupportDirectory = nil;
	NSURL *appSupportDirectoryForApp = nil;
	
	if (possibleUrls.count >= 1) {
		appSupportDirectory = possibleUrls[0];
		
		BOOL isDirectory;
		NSString *path = appSupportDirectory.path;
		BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath: path
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
		path = ((NSURL *)appSupportDirectoryForApp).path;
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
