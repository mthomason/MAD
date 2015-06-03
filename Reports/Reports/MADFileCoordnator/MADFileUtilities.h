//
//  MADFileUtilities.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADFileUtilities_h
#define MADDesigner_MADFileUtilities_h

#import <Foundation/Foundation.h>

@class MADFile;
@interface MADFileUtilities : NSObject

+ (void)copyInitialFiles:(NSString *)fileExtension groupId:(NSString *)groupId;

+ (void)migrateLocalFiles:(NSString *)groupID toCloud:(NSString *)ubiquityID extension:(NSString *)extension;

+ (void)readFileAtURL:(NSURL *)url withCompletionHandler:(void (^)(MADFile *list, NSError *error))completionHandler;

+ (void)createFile:(MADFile *)list atURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *error))completionHandler;

+ (void)duplicateFileAtURL:(NSURL *)url withCompletionHandler:(void (^)(NSURL *result, NSError *error))completionHandler;

+ (void)removeFileAtURL:(NSURL *)url withCompletionHandler:(void (^)(NSError *error))completionHandler;

+ (void)renameFileAtURL:(NSURL *)source toName:(NSString *)name withCompletionHandler:(void (^)(NSURL *sourceURL, NSURL *newURL, NSError *error))completionHandler;

+ (void)moveFileAtURL:(NSURL *)source toUrl:(NSURL *)destination withCompletionHandler:(void (^)(NSURL *result, NSError *error))completionHandler;

+ (NSURL *)uniqueURLForURL:(NSURL *)url;;

@end

#endif
