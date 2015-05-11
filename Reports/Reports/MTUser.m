//
//  MTUser.m
//  MAD
//
//  Created by Michael Thomason on 3/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTUser.h"
#import "NSFileManager+Common.h"
#import "MADConstants.h"

@interface MTUser()

@end

@implementation MTUser

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (BOOL)addDocument:(NSURL *)url error:(NSError **)error {
    NSURL *documentsDirectory = [[NSFileManager defaultManager] localDocumentsDirectoryForGroupIdentifier:MADIdentifierGroup];
    NSURL *destination = [documentsDirectory URLByAppendingPathComponent:url.lastPathComponent];
    BOOL success = [[NSFileManager defaultManager] moveItemAtURL:url toURL:destination error:error];
    return success && error == nil;
}

@end
