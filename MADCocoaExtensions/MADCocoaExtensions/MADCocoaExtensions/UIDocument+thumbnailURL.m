//
//  UIDocument+thumbnailURL.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIDocument+thumbnailURL.h"
#import "UIDevice+Hack.h"
#import <MADFoundation/NSFileManager+Common.h>
#import <MADCocoaExtensions/MADFilename.h>

NSString * const MTDocumentExtentionPoratableNetworkGraphic     = @"png";

/*@implementation MADFilename

+ (instancetype)newFilenameId:(NSUInteger)tag {
    id filenameId = [[self alloc] initWithFormat:@"%lu", (unsigned long)tag];
    return filenameId;
}

+ (instancetype)newFilenameForMadUrl:(NSURL *)madUrl {
    id filename = [[self alloc] initWithString:madUrl.lastPathComponent.stringByDeletingPathExtension];
    return filename;
}

@end*/

@implementation UIDocument (thumbnailURL)

- (NSURL *)thumbnailURL {
    return [UIDocument thumbnailUrlForHandle: self.fileURL.lastPathComponent.stringByDeletingPathExtension
                            andRetinaDisplay: [UIDevice isRetnaDisplay]];
}

+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl {
    return [self thumbnailUrlForHandle: madUrl.lastPathComponent.stringByDeletingPathExtension
                      andRetinaDisplay: [UIDevice isRetnaDisplay]];
}

+ (NSURL *)thumbnailUrlForHandle:(NSString *)handle andRetinaDisplay:(BOOL)retinaDisplay {
    NSString *name = [UIDevice isRetnaDisplay] ? [handle stringByAppendingString:@"@2x"] : handle;
    
    NSString *fileName = [name stringByAppendingPathExtension:MTDocumentExtentionPoratableNetworkGraphic];
    
    NSString *fileNameId = [MADFilename newFilenameId:handle.hash];
    NSURL *cacheDirectory = [[NSFileManager defaultManager] localCacheDirectoryNamed:fileNameId];
    return [cacheDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
}

@end
