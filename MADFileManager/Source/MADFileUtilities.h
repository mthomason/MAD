//
//  MADFileUtilities.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDesigner_MADFileUtilities_h
#define MADDesigner_MADFileUtilities_h

#import <Foundation/NSObject.h>

@class MADFile, NSOperationQueue;

@interface MADFileUtilities : NSObject

+ (NSOperationQueue *)queue;

+ (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl
					   withCoordinator:(BOOL)coordinator;

+ (void)coordinateCreateDirectoryIfDoesNotExist:(NSURL *)url;

/// The iCloud container's Documents directory, for the cloud browsing code below.
/// This helper lived in MADURLFactory until Phase D; iCloud document sync is no
/// longer offered, so it moved in with the (now unused) code that still names it --
/// the headless base framework must not reference iCloud (MAD_LINUX.md).
+ (NSURL *)newURLForCloudDocumentsDirectoryForUbiquityID:(NSString *)ubiquityID;

+ (void)migrateLocalFiles:(NSString *)groupID toCloud:(NSString *)ubiquityID
				extension:(NSString *)extension;

+ (void)createFileAtURL:(NSURL *)url
			 completion:(void (^)(NSError *error))completion;

+ (void)duplicateFileAtURL:(NSURL *)url
				completion:(void (^)(NSURL *result, NSError *error))completion;

+ (void)removeFileAndArchiveAtURL:(NSURL *)url;

+ (void)removeFileAtURL:(NSURL *)url;

+ (void)removeFileAtURL:(NSURL *)url
			 completion:(void (^)(NSError *error))completion;

+ (void)renameFileAtURL:(NSURL *)source toName:(NSString *)name
			 completion:(void (^)(NSURL *sourceURL, NSURL *newURL, NSError *error))completion;

+ (void)moveFileAtURL:(NSURL *)source
				toUrl:(NSURL *)destination
		   completion:(void (^)(NSURL *result, NSError *error))completion;

@end

#endif
