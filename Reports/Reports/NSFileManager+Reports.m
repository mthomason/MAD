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

+ (NSArray *)schemaFiles {
    return [NSFileManager contentsOfDocumentsDataDirectoryWithPathExtension: MTDocumentExtentionMobleApplicationDocumentArchive];
}

+ (NSArray *)pdfFiles {
    return [NSFileManager contentsOfDocumentsDirectoryWithPathExtension:PDF_PATH_EXTENSION];
}

@end