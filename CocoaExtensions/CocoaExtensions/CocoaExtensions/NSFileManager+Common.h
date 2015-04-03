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
+ (NSURL *)localDocumentsDirectory;
+ (NSURL *)localCacheDirectory;
+ (NSURL *)localCachedDirectoryForFileUrl:(NSURL *)fileUrl;
- (NSURL *)localDocumentsDirectoryForGroupIdentifier:(NSString *)groupIdentifier;
- (NSArray *)contentsOfDocumentsDirectoryWithGroupIdentifier: (NSString *)groupIdentifier
                                                andExtention: (NSString *)extenstion;
- (NSURL *)localApplicationSupportDirectory;
- (NSURL *)localCacheDirectoryNamed:(NSString *)handle;
- (NSArray *)contentOfLocalDocumentsDirectoryWithExtention:(NSString *)extenstion;

@end

#endif
