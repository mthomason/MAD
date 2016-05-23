//
//  NSURL+Document.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "NSURL+Document.h"
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSFileManager.h>

@implementation NSURL (Document)

- (NSURL *)uniqueUrl {

    NSInteger ctr = 0;
    
    NSString *pathExtension = self.pathExtension.copy;
    NSString *name = self.lastPathComponent.stringByDeletingPathExtension.copy;
    NSURL *unqiueURL = self.copy;
    NSString *path = unqiueURL.path.copy;
    while ([[NSFileManager defaultManager] fileExistsAtPath:path]) {

        NSString *maybe = [name stringByAppendingFormat:@" %ld", (long)ctr];
        [maybe stringByAppendingPathExtension: pathExtension];

        NSURL *result = [self.baseURL URLByAppendingPathComponent:maybe isDirectory:NO];
        unqiueURL = result.copy;
        
        ctr++;
        
        path = unqiueURL.path.copy;
    }
    return unqiueURL;
}

- (NSString *)key { return self.absoluteString; }

+ (NSString *)newStringFileNameFilter:(NSString *)desiredName {
    
    NSMutableCharacterSet *characterSet = [[NSMutableCharacterSet alloc] init];

    NSCharacterSet *unionSet = [NSCharacterSet alphanumericCharacterSet];
    [characterSet formUnionWithCharacterSet:unionSet];

    unionSet = [NSCharacterSet whitespaceCharacterSet];
    [characterSet formUnionWithCharacterSet:unionSet];
    
    unionSet = characterSet.invertedSet;
    NSArray *components = [desiredName componentsSeparatedByCharactersInSet:unionSet];
    NSString *result = [components componentsJoinedByString:@""];
    return result.copy;
    
}

@end
