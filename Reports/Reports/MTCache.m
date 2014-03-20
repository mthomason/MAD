//
//  MTCache.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTCache.h"

@interface MTCache ()

@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSArray *cachedResultsSerialized;

@end

@implementation MTCache

- (void)dealloc {
    [[self lazyInputStream] close];
}

- (id)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        [self setUrl:url];
    }
    return self;
}

- (NSArray *)results {
    if ([self cachedResultsSerialized] == nil) [self reload];
    return [self cachedResultsSerialized];
}

- (void)reload {
    [[self lazyInputStream] open];
    NSPropertyListFormat format;
    NSError *error = nil;
    NSArray *data = [NSPropertyListSerialization propertyListWithStream:[self lazyInputStream]
                                                                options:0
                                                                 format:&format
                                                                  error:&error];
    [self setCachedResultsSerialized:data];
    [[self lazyInputStream] close];
}

- (void)cacheData:(id)data {
    [MTCache cacheData:data toUrl:[self url]];
}

+ (void)cacheData:(id)data toUrl:(NSURL *)url {
    NSError *error = nil;
    NSData *cache = [NSPropertyListSerialization dataWithPropertyList:data format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if (url) {
        NSDataWritingOptions mask = NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen;
        [cache writeToURL:url options:mask error:&error];
        if (error) {
            error = nil;
            [cache writeToURL:url options:mask error:&error];
        }
    }
}

- (NSInputStream *)lazyInputStream {
    if ([self inputStream] == nil) {
        NSString *path = [[self url] path];
        NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath: path];
        [self setInputStream:inputStream];
    }
    return [self inputStream];
}

@end
