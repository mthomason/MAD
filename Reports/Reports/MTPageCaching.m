//
//  MTPageCaching.m
//  MAD
//
//  Created by Michael Thomason on 5/8/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTPageCaching.h"

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#define CACHE_SIZE 5

@interface MTPageCaching ()

@property (nonatomic, strong) NSMutableDictionary *pageCache;

@end

@implementation MTPageCaching

- (id)init {
    self = [super init];
    if (self) {
        NSMutableDictionary *pageCache = [[NSMutableDictionary alloc] init];
        [self setPageCache:pageCache];
    }
    return self;
}

- (NSArray *)objectsForPage:(NSUInteger)index {
    return [[self pageCache] objectForKey:[self keyForPage:index]];
}

- (void)cacheObjects:(NSArray *)objects forPage:(NSUInteger)index {
    [[self pageCache] setObject:objects forKey:[self keyForPage:index]];
    if ([[self pageCache] count] > CACHE_SIZE) {
        [self trimCache:index];
    }
    
}

- (void)dumpCache {
    [[self pageCache] removeAllObjects];
}

- (void)trimCache:(NSUInteger)index {
    NSUInteger initalStartPage = [self initalCachePage:index];
    NSMutableArray *keysToRemove = [[NSMutableArray alloc] initWithCapacity:CACHE_SIZE];
    for (NSNumber *page in [[self pageCache] keyEnumerator]) {
        NSInteger i = [page integerValue];
        BOOL includePage = i >= initalStartPage || i < initalStartPage + CACHE_SIZE;
        if (includePage == NO) {
            [keysToRemove addObject:[self keyForPage:i]];
        }
    }
    for (id key in keysToRemove) {
        [[self pageCache] removeObjectForKey:key];
    }
}

- (NSUInteger)initalCachePage:(NSUInteger)index {
    NSUInteger halfCacheSize = CACHE_SIZE / 2;
    NSInteger desiredStartPage = index - halfCacheSize;
    return desiredStartPage >= 0 ? desiredStartPage : 0;
}

- (id)keyForPage:(NSUInteger)index {
    return @(index);
}

@end
