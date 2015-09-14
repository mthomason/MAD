//
//  MADThumbnail.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/14/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADThumbnail.h"
#import <MADFileManager/MADFileManager.h>
#import "UIDevice+Hack.h"

@implementation MADThumbnail

//MTDocumentExtentionPoratableNetworkGraphic
+ (NSURL *)thumbnail1024UrlForMadUrl:(NSURL *)madUrl withExtension:(NSString *)extension {
    NSString *handle = madUrl.lastPathComponent.stringByDeletingPathExtension;
    NSString *fileName = [handle stringByAppendingString:@"1024"];
    fileName = [fileName stringByAppendingPathExtension:extension];
    
    NSString *fileNameId = [self filenameId:handle.hash];
    NSURL *cacheDirectory = [[NSFileManager defaultManager] localCacheDirectoryNamed:fileNameId];
    return [cacheDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
    
}

//MTDocumentExtentionPoratableNetworkGraphic
+ (NSURL *)thumbnailUrlForHandle:(NSString *)handle andRetinaDisplay:(BOOL)retinaDisplay withExtension:(NSString *)extension {
    NSString *name = [UIDevice isRetnaDisplay] ? [handle stringByAppendingString:@"@2x"] : handle;
    
    NSString *fileName = [name stringByAppendingPathExtension:extension];
    
    NSString *fileNameId = [self filenameId:handle.hash];
    NSURL *cacheDirectory = [[NSFileManager defaultManager] localCacheDirectoryNamed:fileNameId];
    return [cacheDirectory URLByAppendingPathComponent:fileName isDirectory:NO];
}

+ (NSURL *)thumbnailUrlForMadUrl:(NSURL *)madUrl withExtension:(NSString *)extension {
    return [self thumbnailUrlForHandle: madUrl.lastPathComponent.stringByDeletingPathExtension
                      andRetinaDisplay: [UIDevice isRetnaDisplay] withExtension:extension];
}

+ (NSURL *)thumbnailWithBorderUrlForMadUrl:(NSURL *)madUrl withExtension:(NSString *)extension {
    return [self thumbnailUrlForMadUrl:madUrl withExtension:extension];
}

+ (NSString *)filenameId:(NSUInteger)tag {
    return [NSString stringWithFormat:@"%lu", (unsigned long)tag];
}

//MADFileExtentionMobleApplicationDocumentArchive
+ (NSURL *)archiveUrlForMadUrl:(NSURL *)madUrl withExtension:(NSString *)extension {
    NSString *destinationName = [madUrl.lastPathComponent.stringByDeletingPathExtension stringByAppendingPathExtension:extension];
    NSURL *destinationDirectoryUrl = [NSFileManager localTemporaryDirectory];
    return [destinationDirectoryUrl URLByAppendingPathComponent: destinationName
                                                    isDirectory: YES];
}

+ (NSURL *)cacheFilesDirectoryForFilename:(NSString *)filename {
    NSString *filenameId = [self filenameId:filename.hash];
    return [[NSFileManager defaultManager] localCacheDirectoryNamed:filenameId];
}

+ (NSString *)fileNameForMadUrl:(NSURL *)madUrl {
    return [madUrl.lastPathComponent stringByDeletingPathExtension];
}

@end
