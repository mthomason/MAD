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

- (NSURL *)localApplicationSupportDirectory;
- (NSURL *)localTemporaryDirectory;

- (NSURL *)localDocumentsDirectory;

- (NSURL *)localCacheDirectory;

- (NSURL *)cacheDirectoryNamed:(NSString *)handle;
- (NSURL *)cachedDirectoryForFileUrl:(NSURL *)fileUrl;
- (NSData *)dataForUrl:(NSURL *)url;

@end

#endif
