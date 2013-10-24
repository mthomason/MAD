//
//  NSFileManager-Common.h
//  Reports
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "Constants.h"

@interface NSFileManager (Common)

+ (NSMutableArray *)contentsOfDocumentsDirectory;
+ (NSMutableArray *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension;
+ (NSMutableArray *)contentsOfDirectory:(NSString *)directory withPathExtension:(NSString *)extension;
+ (NSMutableArray *)contentsOfDocumentsDataDirectoryWithPathExtension:(NSString *)extension;

+ (NSURL *)applicationSupportDirectory;
+ (NSString *)applicationSupportDirectoryPath;
+ (NSString *)applicationDocumentsDirectory;
+ (NSString *)applicationLibraryTemplatesDirectory;

+ (NSURL *)localTemporaryDirectory;
+ (void)wrapFile:(NSURL *)fileToAttach withExtention:(NSString *)extention overwrite:(BOOL)overwrite completion:(void (^)(BOOL success, NSURL *resultUrl))completion;

@end