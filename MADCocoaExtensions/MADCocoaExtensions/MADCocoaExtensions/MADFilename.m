//
//  UIDocument+thumbnailURL.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFilename.h"

@implementation MADFilename

+ (NSString *)newFilenameId:(NSUInteger)tag {
    id filenameId = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)tag];
    return filenameId;
}

+ (NSString *)newFilenameForMadUrl:(NSURL *)madUrl {
    id name = madUrl.lastPathComponent.stringByDeletingPathExtension;
    id filename = [[NSString alloc] initWithString:name];
    return filename;
}

@end
