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

+ (NSSet *)contentsOfDocumentsDirectory;
+ (NSSet *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension;
+ (NSMutableArray *)contentsOfDirectory:(NSString *)directory withPathExtension:(NSString *)extension;
+ (NSMutableArray *)contentsOfDocumentsDataDirectoryWithPathExtension:(NSString *)extension;

+ (NSURL *)applicationSupportDirectory;
+ (NSString *)applicationSupportDirectoryPath;
+ (NSString *)applicationDocumentsDirectory;

+ (NSURL *)localTemporaryDirectory;
+ (NSURL *)cacheDirectory;

+ (void)wrapFile:(NSURL *)fileToAttach withExtention:(NSString *)extention overwrite:(BOOL)overwrite completion:(void (^)(BOOL success, NSURL *resultUrl))completion;

+ (NSString *)filenameId:(NSUInteger)tag extention:(NSString *)fileExtention;

@end

#endif
