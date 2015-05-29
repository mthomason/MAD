//
//  NSURL+Document.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSURL+Document.h"
#import "NSFileManager+Common.h"

@implementation NSURL (Document)

- (NSString *)filenameMinusExtention {
    return self.lastPathComponent.stringByDeletingPathExtension;
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

+ (NSString *)fileNameFilter:(NSString *)desiredName {
    
    NSMutableCharacterSet *characterSet = [[NSMutableCharacterSet alloc] init];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    NSCharacterSet *invertedSet = characterSet.invertedSet;
    NSArray *components = [desiredName componentsSeparatedByCharactersInSet:invertedSet];
    return [components componentsJoinedByString:@""];
    
}

@end
