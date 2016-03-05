//
//  UIDocument+thumbnailURL.h
//  CocoaExtensions
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MADFilename : NSObject

+ (NSString *)newFilenameId:(NSUInteger)tag;
+ (NSString *)newFilenameForMadUrl:(NSURL *)madUrl;

@end
