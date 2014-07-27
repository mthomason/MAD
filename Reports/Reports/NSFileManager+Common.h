//
//  NSFileManager-Common.h
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_NSFileManager_Common_h
#define Reports_NSFileManager_Common_h

#import "Constants.h"

@interface NSFileManager (Common)

- (NSURL *)duplicateUrl:(NSURL *)urlToDupe;

- (NSSet *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension;

- (NSSet *)contentsOfDocumentsDataDirectoryWithPathExtension:(NSString *)extension;

- (NSURL *)applicationSupportDirectory;
- (NSString *)applicationDocumentsDirectory;

- (NSURL *)localTemporaryDirectory;
+ (NSString *)cachedPath;
+ (NSURL *)cacheDirectory;

+ (NSString *)filenameId:(NSUInteger)tag;
+ (NSString *)filenameId:(NSUInteger)tag extention:(NSString *)fileExtention;

- (NSURL *)cacheDirectoryNamed:(NSString *)handle;
- (NSURL *)cachedDirectoryForFileUrl:(NSURL *)fileUrl;
- (void)deleteCoreDataFilesAtDirectory:(NSURL *)destinationUrl;
- (void)closeAndDelete:(UIManagedDocument *)managedDocument completion:(void (^)(BOOL success))completion;
- (NSURL *)unpackMadFile:(NSURL *)url toDestinationUrl:(NSURL *)destinationUrl;
- (NSData *)dataForUrl:(NSURL *)url;

@end

#endif
