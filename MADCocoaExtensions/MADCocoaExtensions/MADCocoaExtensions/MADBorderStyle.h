//
//  MADBorderStyle.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADBorderStyle_h
#define MAD_MADBorderStyle_h

#import <Foundation/NSObject.h>

typedef NS_ENUM(int16_t, MADBorderType) {
    MADBorderStyleNone    = 1,
    MADBorderStyleDash    = 2,
    MADBorderStyleDot     = 3,
    MADBorderStyleLine    = 4
};

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

@interface MADBorderStyle : NSObject
    <NSCoding>

    - (instancetype)initWithLeft:(Float64)left right:(Float64)right
                             top:(Float64)top bottom:(Float64)bottom
                       leftStyle:(MADBorderType)leftStyle rightStyle:(MADBorderType)rightStyle
                        topStyle:(MADBorderType)topStyle bottomStyle:(MADBorderType)bottomStyle;

    @property (nonatomic, assign, readonly) Float64 left;
    @property (nonatomic, assign, readonly) Float64 right;
    @property (nonatomic, assign, readonly) Float64 top;
    @property (nonatomic, assign, readonly) Float64 bottom;

    @property (nonatomic, assign, readonly) MADBorderType leftStyle;
    @property (nonatomic, assign, readonly) MADBorderType rightStyle;
    @property (nonatomic, assign, readonly) MADBorderType topStyle;
    @property (nonatomic, assign, readonly) MADBorderType bottomStyle;

@end

#endif /* MADBorderStyle_h */
