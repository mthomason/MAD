//
//  MADBorderStyle.m
//  MADCocoaExtensions
//
//  Created by Michael on 2/1/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADBorderStyle.h"
#import <Foundation/NSCoder.h>
#import <string.h>

struct MADBorderStyle_t {
    Float64 left;
    Float64 right;
    Float64 top;
    Float64 bottom;
    MADBorderType leftStyle;
    MADBorderType rightStyle;
    MADBorderType topStyle;
    MADBorderType bottomStyle;
};
typedef struct MADBorderStyle_t MADBorderStyle_t;

static inline MADBorderStyle_t MADLayoutBorderStyleMake(Float64, Float64,
                                                        Float64, Float64,
                                                        MADBorderType, MADBorderType,
                                                        MADBorderType, MADBorderType);

static inline MADBorderStyle_t MADLayoutBorderStyleMake(Float64 l, Float64 r,
                                                        Float64 t, Float64 b,
                                                        MADBorderType ls, MADBorderType rs,
                                                        MADBorderType ts, MADBorderType bs) {
    MADBorderStyle_t s;
    s.left = l;
    s.right = r;
    s.top = t;
    s.bottom = b;
    s.leftStyle = ls;
    s.rightStyle = rs;
    s.topStyle = ts;
    s.bottomStyle = bs;
    return s;
}

@implementation MADBorderStyle {
    MADBorderStyle_t _style;
}

@dynamic left;
@dynamic right;
@dynamic top;
@dynamic bottom;

@dynamic leftStyle;
@dynamic rightStyle;
@dynamic topStyle;
@dynamic bottomStyle;

+ (BOOL)supportsSecureCoding {
    return NO;
}

- (instancetype)initWithLeft:(Float64)left right:(Float64)right
                         top:(Float64)top bottom:(Float64)bottom
                   leftStyle:(MADBorderType)leftStyle rightStyle:(MADBorderType)rightStyle
                    topStyle:(MADBorderType)topStyle bottomStyle:(MADBorderType)bottomStyle {
    if (self = [super init]) {
        MADBorderStyle_t borderStyle;
        borderStyle = MADLayoutBorderStyleMake(left, right, top, bottom,
                                               leftStyle, rightStyle, topStyle, bottomStyle);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        NSUInteger lenght;
        memcpy(&_style,
               [aDecoder decodeBytesForKey:@"s" returnedLength:&lenght],
               sizeof(MADBorderStyle_t));
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBytes:(uint8_t *)&_style length:sizeof(MADBorderStyle_t) forKey:@"s"];
}


- (Float64)left {
    return _style.left;
}

- (Float64)right {
    return _style.right;
}

- (Float64)top {
    return _style.top;
}

- (Float64)bottom {
    return _style.bottom;
}

- (void)setLeft:(Float64)left {
    _style.left = left;
}

- (void)setRight:(Float64)right {
    _style.right = right;
}

- (void)setTop:(Float64)top {
    _style.top = top;
}

- (void)setBottom:(Float64)bottom {
    _style.bottom = bottom;
}

- (MADBorderType)leftStyle {
    return _style.leftStyle;
}

- (MADBorderType)rightStyle {
    return _style.rightStyle;
}

- (MADBorderType)topStyle {
    return _style.topStyle;
}

- (MADBorderType)bottomStyle {
    return _style.bottomStyle;
}

- (void)setLeftStyle:(MADBorderType)leftStyle {
    _style.leftStyle = leftStyle;
}

- (void)setRightStyle:(MADBorderType)rightStyle {
    _style.rightStyle = rightStyle;
}

- (void)setTopStyle:(MADBorderType)topStyle {
    _style.topStyle = topStyle;
}

- (void)setBottomStyle:(MADBorderType)bottomStyle {
    _style.bottomStyle = bottomStyle;
}

@end
