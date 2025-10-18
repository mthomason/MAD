//
//  MADFileUtilities.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MADDesigner_MADFileUtilities_h
#define MADDesigner_MADFileUtilities_h

#import <Foundation/NSObject.h>

@class MADFile, NSOperationQueue;

@interface MADFileUtilities : NSObject

+ (NSOperationQueue *)queue;

+ (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl;
+ (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl
					   withCoordinator:(BOOL)coordinator;

+ (void)coordinateCreateDirectoryIfDoesNotExist:(NSURL *)url;

+ (void)copyInitialFiles:(NSString *)fileExtension groupId:(NSString *)groupId;

+ (void)migrateLocalFiles:(NSString *)groupID toCloud:(NSString *)ubiquityID
				extension:(NSString *)extension;

+ (void)readObjectOfClass:(Class)cls
				  fromURL:(NSURL *)url
			   completion:(void (^)(id object, NSError *error))completion;

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
