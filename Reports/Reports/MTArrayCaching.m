//
//  MTArrayCaching.m
//  MAD
//
//  Created by Michael Thomason on 4/14/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//
/*
#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTArrayCaching.h"

@interface MTArrayCaching ()

@property (nonatomic, strong, readwrite) NSMutableArray *urlStore;

@end

@implementation MTArrayCaching

- (id)initWithCapacity:(NSUInteger)capacity {
    self = [super init];
    if (self) {

        NSMutableArray *cachedUrlStore = [[NSMutableArray alloc] initWithCapacity:capacity];
        [self setUrlStore:cachedUrlStore];
        
        
    }
    return self;
}

- (id)addObject:(id)object {
    NSError *error = nil;
    NSData *cache = [NSPropertyListSerialization dataWithPropertyList:data format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if ([self url]) {
        NSDataWritingOptions mask = NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen;
        [cache writeToURL:[self url] options:mask error:&error];
        if (error) {
            NSLog(@"Error: %@", error);
            error = nil;
            [cache writeToURL:[self url] options:mask error:&error];
        }
    }
    
}

- (id)objectAtIndex:(NSUInteger)index {
    
    NSString *path = [[self url] path];
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath: path];
    [inputStream open];
    switch ([inputStream streamStatus]) {
        case NSStreamStatusError:
            NSLog(@"Error %@", [inputStream streamError]);
            break;
            
        default:
            break;
    }
    NSPropertyListFormat format;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithStream:inputStream options:0 format:&format error:&error];
   
}

- (NSUInteger)count {
    return [[self urlStore] count];
}

@end*/
