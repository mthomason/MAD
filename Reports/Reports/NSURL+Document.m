//
//  NSURL+Document.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "NSURL+Document.h"

@implementation NSURL (Document)

+ (NSURL *)uniqueUrlForDocumentWithName:(NSString *)name withExtension:(NSString *)extension {
    
    NSURL *documentsDirectoryURL = [[[CloudManager sharedManager] documentsDirectoryURL] retain];

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
                                    URLByAppendingPathComponent: [name stringByAppendingFormat:@" %d", ctr]] retain];
        
        
        applicationFileUrlWithExtention = [[baseUrlFormatted
                                            URLByAppendingPathExtension: extension] retain];
        [baseUrlFormatted release];
        ctr++;
    }
    return [applicationFileUrlWithExtention autorelease];
}

+ (NSURL *)uniqueTmpUrlForDocumentWithName:(NSString *)name withExtension:(NSString *)extension {
    
    NSURL *documentsDirectoryURL = [[NSFileManager localTemporaryDirectory] retain];
    
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
                                    URLByAppendingPathComponent: [name stringByAppendingFormat:@" %d", ctr]] retain];
        
        
        applicationFileUrlWithExtention = [[baseUrlFormatted
                                            URLByAppendingPathExtension: extension] retain];
        [baseUrlFormatted release];
        ctr++;
    }
    return [applicationFileUrlWithExtention autorelease];
}


@end
