//
//  MTCache.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTCache.h"

@interface MTCache ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSArray *cachedResultsSerialized;

@end

@implementation MTCache

- (void)dealloc {
    [[self inputStream] close];
}

- (id)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        NSString *filePath = [url path];
        NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
        [inputStream open];
        NSPropertyListFormat format;
        NSError *error = nil;
        NSArray *data = [NSPropertyListSerialization propertyListWithStream:inputStream options:0 format:&format error:&error];
        [self setUrl:url];
        [self setInputStream:inputStream];
        [self setCachedResultsSerialized:data];
    }
    return self;
}

- (NSArray *)results {
    return [self cachedResultsSerialized];
}

@end
