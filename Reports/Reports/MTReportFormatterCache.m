//
//  MTReportFormatterCache.m
//  MAD
//
//  Created by Michael Thomason on 5/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportFormatterCache.h"

NSString * const MTDeviceOrientationLandscape = @"l";
NSString * const MTDeviceOrientationPortrait = @"p";

@interface MTReportFormatterCache ()

@property (nonatomic, strong) NSMutableDictionary *layoutByOrientation;
@property (nonatomic, strong) NSMutableDictionary *indexesByOrientation;

@end

@implementation MTReportFormatterCache

- (id)init {
    if (self = [super init]) {
        NSMutableDictionary *layout = [[NSMutableDictionary alloc] initWithCapacity:2];
        [self setLayoutByOrientation:layout];
        
        NSMutableDictionary *indexes = [[NSMutableDictionary alloc] initWithCapacity:2];
        [self setIndexesByOrientation:indexes];
    }
    return self;
}

- (void)setLayout:(NSArray *)layout andIndexes:(NSArray *)indexes forKey:(NSString *)key {
    [self layoutByOrientation][key] = layout;
    [self indexesByOrientation][key] = layout;
}

- (NSArray *)layoutForOrientation:(UIDeviceOrientation)orientation {
    return [self layoutByOrientation][[self keyForOrientation:orientation]];
}

- (NSArray *)indexesByOrientation:(UIDeviceOrientation)orientation {
    return [self indexesByOrientation][[self keyForOrientation:orientation]];
}

- (NSString *)keyForOrientation:(UIDeviceOrientation)orientation {
    return UIDeviceOrientationIsLandscape(orientation) ? MTDeviceOrientationLandscape : MTDeviceOrientationPortrait;
}

- (void)dumpCache {
    [[self layoutByOrientation] removeAllObjects];
    [[self indexesByOrientation] removeAllObjects];
}

@end
