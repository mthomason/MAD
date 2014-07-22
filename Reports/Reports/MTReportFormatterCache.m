//
//  MTReportFormatterCache.m
//  MAD
//
//  Created by Michael Thomason on 5/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportFormatterCache.h"

@interface MTReportFormatterCache ()

@property (nonatomic, strong) NSMutableDictionary *layout;
@property (nonatomic, strong) NSMutableDictionary *indexes;

@end

@implementation MTReportFormatterCache

- (void)dealloc {
    [_layout removeAllObjects];
    [_indexes removeAllObjects];
}

- (id)init {
    if (self = [super init]) {
        
        NSMutableDictionary *layout = [[NSMutableDictionary alloc] initWithCapacity:2];
        [self setLayout:layout];
        
        NSMutableDictionary *indexes = [[NSMutableDictionary alloc] initWithCapacity:2];
        [self setIndexes:indexes];
    }
    return self;
}

- (void)setLayout:(id)layout andIndexes:(id)indexes forSize:(CGSize)size {
    NSString *key = NSStringFromCGSize(size);
    [[self layout] setObject:layout forKey:key];
    [[self indexes] setObject:indexes forKey:key];
}

- (id)layoutForSize:(CGSize)size {
    NSString *key = NSStringFromCGSize(size);
    return [[self layout] objectForKey:key];
}

- (id)indexesForSize:(CGSize)size {
    NSString *key = NSStringFromCGSize(size);
    return [[self indexes] objectForKey:key];
}

- (void)dumpCache {
    [[self layout] removeAllObjects];
    [[self indexes] removeAllObjects];
}

@end
