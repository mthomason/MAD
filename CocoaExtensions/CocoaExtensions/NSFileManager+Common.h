//
//  NSFileManager-Common.h
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSFileManager_Common_h
#define Reports_NSFileManager_Common_h

#import <Foundation/Foundation.h>

@interface NSFileManager (Common)

+ (NSURL *)localTemporaryDirectory;

- (NSURL *)localApplicationSupportDirectoryForGroupIdentifier:(NSString *)groupIdentifier;
- (NSURL *)localDocumentsDirectoryForGroupIdentifier:(NSString *)groupIdentifier;

- (NSURL *)localCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier
                                         fileURL:(NSURL *)fileURL;

- (NSURL *)localCacheDirectoryForGroupIdentifier:(NSString *)groupIdentifier;

- (NSArray *)contentsOfDocumentsDirectoryWithGroupIdentifier: (NSString *)groupIdentifier
                                                andExtention: (NSString *)extenstion;

- (NSURL *)localCacheDirectoryNamed:(NSString *)handle;
- (BOOL)removeCachedFileForDocumentUrl:(NSURL *)documentUrl
                       groupIdentifier:(NSString *)groupIdentifier;

- (NSArray *)contentOfLocalDocumentsDirectoryWithExtention:(NSString *)extenstion;

@end

#endif
