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
    return self.lastPathComponent.stringByDeletingPathExtension;
}

+ (NSURL *)uniqueUrlInDirectory:(NSURL *)directory withDesiredHandle:(NSString *)desiredFileHandle andExtension:(NSString *)extension {

    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    NSURL *baseUrl = [directory URLByAppendingPathComponent: desiredFileHandle];
    NSURL *applicationFileUrlWithExtention = [extension length] > 0 ?
                                                [baseUrl URLByAppendingPathExtension: extension] :
                                                baseUrl;
    NSInteger ctr = 0;
    BOOL isDir1;
    while ([defaultFileManager fileExistsAtPath:applicationFileUrlWithExtention.path isDirectory:&isDir1]) {
        
        NSString *maybe = [desiredFileHandle stringByAppendingFormat:@" %ld", (long)ctr];
        NSURL *baseUrlFormatted = [directory URLByAppendingPathComponent: maybe];
        applicationFileUrlWithExtention = [baseUrlFormatted URLByAppendingPathExtension: extension];
        ctr++;
    }
    return applicationFileUrlWithExtention;
    
}

- (NSURL *)uniqueUrl {

    NSInteger ctr = 0;
    
    NSURL *uniqueUrl = self;
    while ([[NSFileManager defaultManager] fileExistsAtPath:uniqueUrl.path]) {
        NSString *maybe = [self.lastPathComponent.stringByDeletingPathExtension stringByAppendingFormat:@" %ld", (long)ctr];
        [maybe stringByAppendingPathExtension:self.pathExtension];
        NSURL *result = [self.baseURL URLByAppendingPathComponent:maybe isDirectory:NO];
        uniqueUrl = result;
        ctr++;
    }
    return uniqueUrl;
}

- (NSString *)key {
    return self.absoluteString;
}

@end
