//
//  MADFileUtilities.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/5/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADFileUtilities_h
#define MADDesigner_MADFileUtilities_h

#import <Foundation/NSObject.h>

@class MADFile;

@interface MADFileUtilities : NSObject

    + (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl;

    + (void)coordinateCreateDirectoryIfDoesNotExist:(NSURL *)url;

    + (void)copyInitialFiles:(NSString *)fileExtension groupId:(NSString *)groupId;

    + (void)migrateLocalFiles:(NSString *)groupID toCloud:(NSString *)ubiquityID
                    extension:(NSString *)extension;

    + (void)readFileAtURL:(NSURL *)url
               completion:(void (^)(MADFile *list, NSError *error))completion;

    + (void)createFile:(MADFile *)list atURL:(NSURL *)url
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

    + (BOOL)restoreFileWrapper:(NSURL *)originURL archiveURL:(NSURL *)archiveURL
                     overwrite:(BOOL)overwrite;

    + (NSArray <NSURL *> *)contentsOfDocumentsDirectoryWithGroupIdentifier: (NSString *)groupIdentifier
                                                              andExtention: (NSString *)extenstion;
@end

#endif
