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

@end
