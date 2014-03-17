//
//  NSURL+Document.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSURL+Document.h"

@implementation NSURL (Document)

+ (NSURL *)uniqueUrlForDocumentWithName:(NSString *)name withExtension:(NSString *)extension {
    
    NSURL *documentsDirectoryURL = [[[MACloudManager sharedManager] documentsDirectoryURL] retain];

    NSFileManager *defaultFileManager = [NSFileManager defaultManager];
    NSURL *baseUrl = [[documentsDirectoryURL URLByAppendingPathComponent: name] retain];
    NSURL *applicationFileUrlWithExtention = [extension length] > 0 ?
                                                [[baseUrl URLByAppendingPathExtension: extension] retain] :
                                                [baseUrl retain];
    [baseUrl release];
    
    NSInteger ctr = 0;
    while ([defaultFileManager fileExistsAtPath:[applicationFileUrlWithExtention path]]) {
        [applicationFileUrlWithExtention release];
        
        NSURL *baseUrlFormatted = [[documentsDirectoryURL
                                    URLByAppendingPathComponent: [name stringByAppendingFormat:@" %ld", (long)ctr]] retain];
        
        
        applicationFileUrlWithExtention = [[baseUrlFormatted
                                            URLByAppendingPathExtension: extension] retain];
        [baseUrlFormatted release];
        ctr++;
    }
    [documentsDirectoryURL release];
    return [applicationFileUrlWithExtention autorelease];
}

@end
