//
//  MADURL.h
//  MADFileManager
//
//  Created by Michael Thomason on 5/31/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_MADFoundation_MADURL_h
#define MADDesigner_MADFoundation_MADURL_h

#import <Foundation/NSURL.h>

@interface MADURL : NSURL

    + (instancetype)newURLLocalDocumentWithName:(NSString *)name
                                      extention:(NSString *)extention
                                      fileGroup:(NSString *)fileGroup;
    + (instancetype)newURLCacheFilesDirectoryForFilename:(NSString *)filename;
    + (instancetype)newURLDocumentArchiveForFileURL:(NSURL *)madUrl
                                          extension:(NSString *)extension;

    + (instancetype)newURLThumbnailForURL:(NSURL *)madUrl;

    + (instancetype)newURLThumbnailForHandle:(NSString *)handle
                            andRetinaDisplay:(BOOL)retinaDisplay;

    + (instancetype)newURLWithUniqueFilenameForURL:(NSURL *)origionalURL;

    + (instancetype)newURLUniqueUrlInDirectory:(NSURL *)directory
                             withDesiredHandle:(NSString *)desiredFileHandle
                                  andExtension:(NSString *)extension;

    + (instancetype)newURLForLocalDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                                pathComponent:(NSString *)pathComponent
                                          alternativeSelector:(SEL)alternativeSelector;
                                      
    + (instancetype)newURLForURLSelector:(SEL)selector;
    + (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                                           fileURL:(NSURL *)fileURL;
    + (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                                            handle:(NSString *)handle;
    + (instancetype)newURLForLocalDocumentsDirectory;
    + (instancetype)newURLLocalTemporaryDirectory;
    + (instancetype)newURLForLocalCacheDirectory;
    + (instancetype)newURLForLocalDataDirectory;
    + (instancetype)newURLForLocalApplicationSupportDirectory;

    + (instancetype)newURLForCloudDocumentsDirectoryForUbiquityID:(NSString *)ubiquityID;
    + (instancetype)newURLLocalDocumentsDirectoryForGroupIdentifier:(NSString *)groupIdentifier;

    + (instancetype)newURLForLocalDataDirectoryForGroupIdentifier:(NSString *)groupIdentifier;
    + (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier;
    + (instancetype)newURLLocalApplicationSupportDirectoryForGroupID:(NSString *)groupIdentifier;
    + (instancetype)newURLForLocalCacheDirectoryNamed:(NSString *)handle;
    + (instancetype)newURLUniqueURLForURL:(NSURL *)url;
    + (instancetype)newURLForLocalCachedDirectoryForFileUrl:(NSURL *)fileUrl;
    + (instancetype)newURLApplicationSupportFile:(NSString *)filename
                                       extension:(NSString *)extension;

@end

#endif
