//
//  MTReportFormatterCache.m
//  MAD
//
//  Created by Michael Thomason on 5/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADReportFormatterCache.h"
#import <Foundation/NSDictionary.h>
#import <UIKit/UIGeometry.h>

@interface MADReportFormatterCache ()

    @property (nonatomic, strong) NSMutableDictionary *layout;
    @property (nonatomic, strong) NSMutableDictionary *indexes;

@end

@implementation MADReportFormatterCache

- (void)dealloc {
    [_layout removeAllObjects];
    [_indexes removeAllObjects];
}

- (instancetype)init {
    if (self = [super init]) {
        
        NSMutableDictionary *layout = [[NSMutableDictionary alloc] initWithCapacity:2];
        self.layout = layout;
        
        NSMutableDictionary *indexes = [[NSMutableDictionary alloc] initWithCapacity:2];
        self.indexes = indexes;
    }
    return self;
}

- (void)setLayout:(id)layout andIndexes:(id)indexes forSize:(CGSize)size {
    NSString *key = NSStringFromCGSize(size);
    self.layout[key] = layout;
    self.indexes[key] = indexes;
}

- (id)layoutForSize:(CGSize)size {
    NSString *key = NSStringFromCGSize(size);
    return self.layout[key];
}

- (id)indexesForSize:(CGSize)size {
    NSString *key = NSStringFromCGSize(size);
    return self.indexes[key];
}

- (void)dumpCache {
    [self.layout removeAllObjects];
    [self.indexes removeAllObjects];
}

@end
