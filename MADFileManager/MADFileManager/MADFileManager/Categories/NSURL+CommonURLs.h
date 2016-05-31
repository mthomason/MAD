//
//  NSURL+CommonURLs.h
//  MADFileManager
//
//  Created by Michael Thomason on 5/31/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (CommonURLs)

+ (instancetype)newURLUniqueUrlInDirectory:(NSURL *)directory
                         withDesiredHandle:(NSString *)desiredFileHandle
                              andExtension:(NSString *)extension;

+ (instancetype)newUrlForLocalDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                            pathComponent:(NSString *)pathComponent
                                      alternativeSelector:(SEL)alternativeSelector;
                                      
+ (instancetype)newUrlForURLSelector:(SEL)selector;
+ (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                                       fileURL:(NSURL *)fileURL;
+ (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                                        handle:(NSString *)handle;
+ (instancetype)newUrlForLocalDocumentsDirectory;
+ (instancetype)newURLLocalTemporaryDirectory;
+ (instancetype)newUrlForLocalCacheDirectory;
+ (instancetype)newUrlForLocalDataDirectory;
+ (instancetype)newUrlForLocalApplicationSupportDirectory;

+ (instancetype)newURLForCloudDocumentsDirectoryForUbiquityID:(NSString *)ubiquityID;
+ (instancetype)newURLLocalDocumentsDirectoryForGroupIdentifier:(NSString *)groupIdentifier;

+ (instancetype)newURLForLocalDataDirectoryForGroupIdentifier:(NSString *)groupIdentifier;
+ (instancetype)newURLForLocalCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier;
+ (instancetype)newUrlForLocalApplicationSupportDirectoryForGroupIdentifier:(NSString *)groupIdentifier;
+ (instancetype)newURLForLocalCacheDirectoryNamed:(NSString *)handle;
+ (instancetype)newURLUniqueURLForURL:(NSURL *)url;
+ (instancetype)newURLForLocalCachedDirectoryForFileUrl:(NSURL *)fileUrl;

@end
