//
//  MADMargin.m
//  MADCocoaExtensions
//
//  Created by Michael on 2/1/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADMargin.h"
#import <Foundation/NSCoder.h>
#import <string.h>

struct MADMargin_t {
    Float64 left;
    Float64 right;
    Float64 top;
    Float64 bottom;
};
typedef struct MADMargin_t MADMargin_t;

static inline MADMargin_t MADLayoutMarginMake(Float64, Float64, Float64, Float64);
static inline MADMargin_t MADLayoutMarginMakeQuick(Float64);

static inline MADMargin_t MADLayoutMarginMake(Float64 l, Float64 r, Float64 t, Float64 b) {
    MADMargin_t m; m.left = l; m.right = r; m.top = t; m.bottom = b;
    return m;
}

static inline MADMargin_t MADLayoutMarginMakeQuick(Float64 w) {
    MADMargin_t m; m.left = w; m.right = w; m.top = w; m.bottom = w;
    return m;
}

@implementation MADMargin {
    MADMargin_t _margin;
}

@dynamic left;
@dynamic right;
@dynamic top;
@dynamic bottom;

+ (BOOL)supportsSecureCoding {
    return NO;
}

- (instancetype)initWithLeft:(Float64)left right:(Float64)right
                         top:(Float64)top bottom:(Float64)bottom {
    if (self = [super init]) {
        _margin = MADLayoutMarginMake(left, right, top, bottom);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSUInteger lenght;
        memcpy(&_margin,
               [aDecoder decodeBytesForKey:@"m" returnedLength:&lenght],
               sizeof(MADMargin_t));
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBytes:(uint8_t *)&_margin length:sizeof(MADMargin_t) forKey:@"m"];
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[MADMargin allocWithZone:zone] initWithLeft: _margin.left
                                                     right: _margin.right
                                                       top: _margin.top
                                                    bottom: _margin.bottom];
    return copy;
}

- (Float64)left {
    return _margin.left;
}

- (Float64)right {
    return _margin.right;
}

- (Float64)top {
    return _margin.top;
}

- (Float64)bottom {
    return _margin.bottom;
}

- (void)setLeft:(Float64)left {
    _margin.left = left;
}

- (void)setRight:(Float64)right {
    _margin.right = right;
}

- (void)setTop:(Float64)top {
    _margin.top = top;
}

- (void)setBottom:(Float64)bottom {
    _margin.bottom = bottom;
}

@end
