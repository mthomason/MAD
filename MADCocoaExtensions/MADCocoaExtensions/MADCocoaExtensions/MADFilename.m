//
//  UIDocument+thumbnailURL.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADFilename.h"
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSPathUtilities.h>

@implementation MADFilename

+ (NSString *)newFilenameId:(NSUInteger)tag {
    id filenameId = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)tag];
    return filenameId;
}

@end
