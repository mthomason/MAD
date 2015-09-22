//
//  UIDocument+thumbnailURL.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
extern NSString * const MTDocumentExtentionPoratableNetworkGraphic;

@interface UIDocument (thumbnailURL)

- (NSURL *)thumbnailURL;
+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl;
+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl;
+ (NSURL *)cacheFilesDirectoryForFilename:(NSString *)filename;
+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl;
+ (NSString *)filenameId:(NSUInteger)tag;

@end
