//
//  MTCache.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTCache.h"
#import <CoreData/CoreData.h>
#import "MTDataTable.h"

@interface MTCache ()

@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) MTDataTable *cachedPlistSerialized;

@end

@implementation MTCache

- (void)dealloc {
    [[self lazyInputStream] close];
}

- (id)initWithString:(NSString *)string {
    return [self initWithTag:[string hash]];
}

- (id)initWithTag:(NSUInteger)tag {
    self = [super init];
    if (self) {
        NSString *filename = [MTCache filename:tag];
        NSURL *cacheDirectory = [MTCache cacheDirectory];
        NSURL *fileUrl = [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
        [self setUrl:fileUrl];
    }
    return self;
}

- (id)initWithObjectID:(NSManagedObjectID *)objectID {
    NSUInteger hash = [[[objectID URIRepresentation] absoluteString] hash];
    return [self initWithTag:hash];
}

- (MTDataTable *)results {
    if ([self cachedPlistSerialized] == nil) [self reload];
    return [self cachedPlistSerialized];
}

- (void)reload {
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
    MTDataTable *dataTable = [[MTDataTable alloc] initWithPlist:plist];
    [self setCachedPlistSerialized:dataTable];
    [inputStream close];
}

- (void)cacheDataTable:(MTDataTable *)dataTable {
    NSDictionary *plist = [[NSDictionary alloc] initWithDictionary:[dataTable plist]];
    [self cachePlist:plist];
}

- (void)cachePlist:(id)data {
    NSError *error = nil;
    NSData *cache = [NSPropertyListSerialization dataWithPropertyList:data format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if ([self url]) {
        NSDataWritingOptions mask = NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen;
        [cache writeToURL:[self url] options:mask error:&error];
        [self setCachedPlistSerialized:nil];
        if (error) {
            NSLog(@"Error: %@", error);
            error = nil;
            [cache writeToURL:[self url] options:mask error:&error];
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

- (NSOutputStream *)lazyOutputStream {
    if ([self outputStream] == nil) {
        NSString *path = [[self url] path];
        NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
        [self setOutputStream:outputStream];
    }
    return [self outputStream];
}
                              
+ (NSString *)filename:(NSUInteger)tag {
    NSString *filename = [NSString stringWithFormat:@"%lu", (unsigned long)tag];
    NSString *extention = @"mcache";
    return [filename stringByAppendingPathExtension:extention];
}

+ (NSURL *)cacheDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesPath = [paths objectAtIndex:0];
    return [NSURL fileURLWithPath:cachesPath isDirectory:YES];
}

@end
