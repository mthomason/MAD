//
//  UIDocument+thumbnailURL.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFilename.h"
#import "MADDevice.h"
#import <MADFoundation/NSFileManager+Common.h>

NSString * const MTDocumentExtentionPoratableNetworkGraphic     = @"png";

@implementation MADFilename

+ (instancetype)newFilenameId:(NSUInteger)tag {
    id filenameId = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)tag];
    return filenameId;
}

+ (instancetype)newFilenameForMadUrl:(NSURL *)madUrl {
    id filename = [[NSString alloc] initWithString:madUrl.lastPathComponent.stringByDeletingPathExtension];
    return filename;
}

@end
