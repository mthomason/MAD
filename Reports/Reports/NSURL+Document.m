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

+ (NSURL *)uniqueUrlForDocumentWithName:(NSString *)name withExtension:(NSString *)extension {
    
    NSURL *documentsDirectoryURL = [[MACloudManager sharedManager] documentsDirectoryURL];

    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    NSURL *baseUrl = [documentsDirectoryURL URLByAppendingPathComponent: name];
    NSURL *applicationFileUrlWithExtention = [extension length] > 0 ?
                                                [baseUrl URLByAppendingPathExtension: extension] :
                                                baseUrl;
    
    NSInteger ctr = 0;
    while ([defaultFileManager fileExistsAtPath:[applicationFileUrlWithExtention path]]) {
        
        NSURL *baseUrlFormatted = [documentsDirectoryURL
                                    URLByAppendingPathComponent: [name stringByAppendingFormat:@" %ld", (long)ctr]];
        
        
        applicationFileUrlWithExtention = [baseUrlFormatted
                                            URLByAppendingPathExtension: extension];
        ctr++;
    }
    return applicationFileUrlWithExtention;
}

@end
