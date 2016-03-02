//
//  UIDocument+thumbnailURL.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
extern NSString * const MTDocumentExtentionPoratableNetworkGraphic;

@interface MADFilename : NSString

+ (instancetype)newFilenameId:(NSUInteger)tag;
+ (instancetype)newFilenameForMadUrl:(NSURL *)madUrl;

@end
