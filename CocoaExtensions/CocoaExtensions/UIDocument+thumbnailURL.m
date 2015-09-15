//
//  UIDocument+thumbnailURL.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIDocument+thumbnailURL.h"
#import "UIDevice+Hack.h"
#import "NSFileManager+Common.h"

NSString * const MTDocumentExtentionPoratableNetworkGraphic     = @"png";

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
    
    NSString *fileNameId = [self filenameId:handle.hash];
    NSURL *cacheDirectory = [[NSFileManager defaultManager] localCacheDirectoryNamed:fileNameId];
    return [cacheDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
}

+ (NSString *)filenameId:(NSUInteger)tag {
    return [NSString stringWithFormat:@"%lu", (unsigned long)tag];
}

@end
