//
//  NSURL+Document.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSURL+Document.h"

@implementation MADURL

- (NSString *)filenameMinusExtention {
    return self.lastPathComponent.stringByDeletingPathExtension;
}

- (NSURL *)uniqueUrl {

    NSInteger ctr = 0;
    
    MADURL *uniqueUrl = self;
    while ([[NSFileManager defaultManager] fileExistsAtPath:uniqueUrl.path]) {
        NSString *maybe = [self.lastPathComponent.stringByDeletingPathExtension stringByAppendingFormat:@" %ld", (long)ctr];
        [maybe stringByAppendingPathExtension:self.pathExtension];
        MADURL *result = (MADURL *)[self.baseURL URLByAppendingPathComponent:maybe isDirectory:NO];
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
    NSCharacterSet *alphanumericCharacterSet = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    
    [characterSet formUnionWithCharacterSet:alphanumericCharacterSet];
    [characterSet formUnionWithCharacterSet:whitespaceCharacterSet];
    NSCharacterSet *invertedSet = characterSet.invertedSet;
    NSArray *components = [desiredName componentsSeparatedByCharactersInSet:invertedSet];
    return [components componentsJoinedByString:@""];
}

@end
