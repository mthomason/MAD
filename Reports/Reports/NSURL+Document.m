//
//  NSURL+Document.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSURL+Document.h"
#import "NSFileManager+Common.h"
#import "MACloudManager.h"

@implementation NSURL (Document)

- (NSString *)filenameMinusExtention {
    return [[self lastPathComponent] stringByDeletingPathExtension];
}

+ (NSURL *)uniqueUrlForDocumentWithName:(NSString *)name withExtension:(NSString *)extension {
    return [NSURL uniqueUrlInDirectory:[[MACloudManager sharedManager] documentsDirectoryURL]
                     withDesiredHandle:name
                          andExtension:extension];
}

+ (NSURL *)uniqueUrlInDirectory:(NSURL *)directory withDesiredHandle:(NSString *)desiredFileHandle andExtension:(NSString *)extension {

    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    NSURL *baseUrl = [directory URLByAppendingPathComponent: desiredFileHandle];
    NSURL *applicationFileUrlWithExtention = [extension length] > 0 ?
    [baseUrl URLByAppendingPathExtension: extension] :
    baseUrl;
    NSInteger ctr = 0;
    while ([defaultFileManager fileExistsAtPath:[applicationFileUrlWithExtention path]]) {
        
        NSString *maybe = [desiredFileHandle stringByAppendingFormat:@" %ld", (long)ctr];
        NSURL *baseUrlFormatted = [directory URLByAppendingPathComponent: maybe];
        applicationFileUrlWithExtention = [baseUrlFormatted URLByAppendingPathExtension: extension];
        ctr++;
    }
    return applicationFileUrlWithExtention;
    
}

@end
