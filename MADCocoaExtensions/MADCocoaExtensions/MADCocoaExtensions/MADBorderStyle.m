//
//  MADBorderStyle.m
//  MADCocoaExtensions
//
//  Created by Michael on 2/1/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBorderStyle.h"
#import <Foundation/NSCoder.h>
#import <string.h>

struct MADBorderStyle_t {
    float left;
    float right;
    float top;
    float bottom;
    MADBorderType leftStyle;
    MADBorderType rightStyle;
    MADBorderType topStyle;
    MADBorderType bottomStyle;
};
typedef struct MADBorderStyle_t MADBorderStyle_t;

static inline MADBorderStyle_t MADLayoutBorderStyleMake(float, float,
                                                        float, float,
                                                        MADBorderType, MADBorderType,
                                                        MADBorderType, MADBorderType);

static inline MADBorderStyle_t MADLayoutBorderStyleMake(float l, float r,
                                                        float t, float b,
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
    return YES;
}

- (instancetype)init {
    if (self = [super init]) {
        MADBorderStyle_t borderStyle;
        borderStyle = MADLayoutBorderStyleMake(0, 0, 0, 0,
                                               MADBorderStyleNone,
                                               MADBorderStyleNone,
                                               MADBorderStyleNone,
                                               MADBorderStyleNone);
    }
    return self;
}

- (instancetype)initWithLeft:(float)left right:(float)right
                         top:(float)top bottom:(float)bottom
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
        MADBorderStyle_t borderStyle;
        borderStyle.bottom = [aDecoder decodeFloatForKey:@"b"];
        borderStyle.bottomStyle = (int16_t)[aDecoder decodeInt32ForKey: @"bs"];
        borderStyle.top = [aDecoder decodeFloatForKey:@"t"];
        borderStyle.topStyle = (int16_t)[aDecoder decodeInt32ForKey: @"ts"];
        borderStyle.left = [aDecoder decodeFloatForKey:@"l"];
        borderStyle.leftStyle = (int16_t)[aDecoder decodeInt32ForKey: @"ls"];
        borderStyle.right = [aDecoder decodeFloatForKey:@"r"];
        borderStyle.rightStyle = (int16_t)[aDecoder decodeInt32ForKey: @"rs"];
        _style = borderStyle;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeFloat:_style.bottom forKey:@"b"];
    [aCoder encodeInt32:_style.bottomStyle forKey:@"bs"];
    [aCoder encodeFloat:_style.top forKey:@"t"];
    [aCoder encodeInt32:_style.topStyle forKey:@"ts"];
    [aCoder encodeFloat:_style.left forKey:@"l"];
    [aCoder encodeInt32:_style.leftStyle forKey:@"ls"];
    [aCoder encodeFloat:_style.right forKey:@"r"];
    [aCoder encodeInt32:_style.rightStyle forKey:@"rs"];
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] initWithLeft: _style.left
                                                        right: _style.right
                                                          top: _style.top
                                                       bottom: _style.bottom
                                                    leftStyle: _style.leftStyle
                                                   rightStyle: _style.rightStyle
                                                     topStyle: _style.topStyle
                                                  bottomStyle: _style.bottomStyle];
    return copy;
}

- (float)left {
    return _style.left;
}

- (float)right {
    return _style.right;
}

- (float)top {
    return _style.top;
}

- (float)bottom {
    return _style.bottom;
}

- (void)setLeft:(float)left {
    _style.left = left;
}

- (void)setRight:(float)right {
    _style.right = right;
}

- (void)setTop:(float)top {
    _style.top = top;
}

- (void)setBottom:(float)bottom {
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
