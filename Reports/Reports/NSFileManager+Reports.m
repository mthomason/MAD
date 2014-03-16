//
//  NSFileManager+Reports.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSFileManager+Reports.h"
#import "NSFileManager+Common.h"
#import "Constants.h"

@implementation NSFileManager (Reports)

+ (NSArray *)schemaFilesOld {
    NSString *dataFile = [[NSFileManager applicationDocumentsDirectory] stringByAppendingPathComponent:@"Data"];
    NSArray *results = nil;
    BOOL directoryExist = [[NSFileManager defaultManager] fileExistsAtPath:dataFile];
    if (directoryExist) {   //User documetns/Data
        results = [[NSFileManager contentsOfDocumentsDataDirectoryWithPathExtension: MTDocumentExtentionMobleApplicationDocumentArchive] retain];
    } else {
        results = [@[] retain];
    }
    return [results autorelease];
}

+ (NSSet *)pdfFiles {
    return [NSFileManager contentsOfDocumentsDirectoryWithPathExtension:PDF_PATH_EXTENSION];
}

@end
