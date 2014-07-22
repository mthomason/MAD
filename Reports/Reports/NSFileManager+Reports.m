//
//  NSFileManager+Reports.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSFileManager+Reports.h"
#import "NSFileManager+Common.h"
#import "Constants.h"

@implementation NSFileManager (Reports)

- (NSURL *)archiveUrlForMadUrl:(NSURL *)madUrl {
    NSString *destinationName = [[[madUrl lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocumentArchive];
    NSURL *destinationDirectoryUrl = [self localTemporaryDirectory];
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSAutosavedInformationDirectory, NSUserDomainMask, YES);
    [directories lastObject];
    return [destinationDirectoryUrl URLByAppendingPathComponent:destinationName isDirectory:YES];
}

@end
