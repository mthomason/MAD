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
    return [NSFileManager contentsOfDocumentsDirectoryWithPathExtension: SCHEMA_PATH_EXTENSION];
}

+ (NSArray *)reportFiles {
    return [NSFileManager contentsOfDocumentsDirectoryWithPathExtension:REPORT_PATH_EXTENSION];
}

@end