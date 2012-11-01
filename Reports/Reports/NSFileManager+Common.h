//
//  NSFileManager-Common.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "Constants.h"

@interface NSFileManager (Common)

+ (NSMutableArray *)contentsOfDocumentsDirectory;
+ (NSMutableArray *)contentsOfDocumentsDirectoryWithPathExtension:(NSString *)extension;
+ (NSMutableArray *)contentsOfTemplateDirectoryWithPathExtension:(NSString *)extension;
+ (NSMutableArray *)contentsOfDirectory:(NSString *)directory withPathExtension:(NSString *)extension;

+ (NSURL *)applicationDocumentsDirectoryUrl;
+ (NSURL *)applicationSupportDirectoryUrl;
+ (NSURL *)applicationLibraryTemplatesDirectoryUrl;

+ (NSString *)applicationSupportDirectory;
+ (NSString *)applicationDocumentsDirectory;
+ (NSString *)applicationLibraryTemplatesDirectory;

@end