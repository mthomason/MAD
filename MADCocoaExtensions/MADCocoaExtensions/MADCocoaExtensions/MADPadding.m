//
//  MADPadding.m
//  MADCocoaExtensions
//
//  Created by Michael on 2/1/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADPadding.h"
#import <Foundation/NSCoder.h>
#import <string.h>

struct MADLayoutPadding_t {
    Float64 left;
    Float64 right;
    Float64 top;
    Float64 bottom;
};
typedef struct MADLayoutPadding_t MADLayoutPadding_t;

static inline MADLayoutPadding_t MADLayoutPaddingMake(Float64, Float64, Float64, Float64);
static inline MADLayoutPadding_t MADLayoutPaddingMakeQuick(Float64);

static inline MADLayoutPadding_t MADLayoutPaddingMake(Float64 l, Float64 r, Float64 t, Float64 b) {
    MADLayoutPadding_t p; p.left = l; p.right = r; p.top = t; p.bottom = b; return p;
}

static inline MADLayoutPadding_t MADLayoutPaddingMakeQuick(Float64 p) {
    MADLayoutPadding_t padding;
    padding.top = p; padding.right = p; padding.bottom = p; padding.left = p;
    return padding;
}

@implementation MADPadding {
    MADLayoutPadding_t _padding;
}

@dynamic left;
@dynamic right;
@dynamic top;
@dynamic bottom;

+ (BOOL)supportsSecureCoding {
    return NO;
}

- (instancetype)init {
    if (self = [super init]) {
        _padding = MADLayoutPaddingMake(0, 0, 0, 0);
    }
    return self;
}

- (instancetype)initWithLeft:(Float64)left right:(Float64)right
                         top:(Float64)top bottom:(Float64)bottom {
    if (self = [super init]) {
        _padding = MADLayoutPaddingMake(left, right, top, bottom);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSUInteger lenght;
        memcpy(&_padding,
               [aDecoder decodeBytesForKey:@"p" returnedLength:&lenght],
               sizeof(MADLayoutPadding_t));
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBytes:(uint8_t *)&_padding length:sizeof(MADLayoutPadding_t) forKey:@"p"];
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithLeft:_padding.left
                                                        right:_padding.right
                                                          top:_padding.top
                                                       bottom:_padding.bottom];
    return copy;
}

- (Float64)left {
    return _padding.left;
}

- (Float64)right {
    return _padding.right;
}

- (Float64)top {
    return _padding.top;
}

- (Float64)bottom {
    return _padding.bottom;
}

- (void)setLeft:(Float64)left {
    _padding.left = left;
}

- (void)setRight:(Float64)right {
    _padding.right = right;
}

- (void)setTop:(Float64)top {
    _padding.top = top;
}

- (void)setBottom:(Float64)bottom {
    _padding.bottom = bottom;
}

@end
