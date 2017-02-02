//
//  MADMargin.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADMarginStyle_h
#define MAD_MADMarginStyle_h

#import <Foundation/NSObject.h>

struct MADMargin_t {
    Float64 left;
    Float64 right;
    Float64 top;
    Float64 bottom;
};
typedef struct MADMargin_t MADMargin_t;

static inline MADMargin_t MADLayoutMarginMake(Float64, Float64, Float64, Float64);
static inline MADMargin_t MADLayoutMarginMake(Float64 l, Float64 r, Float64 t, Float64 b) {
    MADMargin_t m;
    m.left = l;
    m.right = r;
    m.top = t;
    m.bottom = b;
    return m;
}

@interface MADMargin : NSObject
    <NSCoding>

    - (instancetype)initWithLeft:(Float64)left right:(Float64)right
                             top:(Float64)top bottom:(Float64)bottom;

    @property (nonatomic, assign, readonly) Float64 left;
    @property (nonatomic, assign, readonly) Float64 right;
    @property (nonatomic, assign, readonly) Float64 top;
    @property (nonatomic, assign, readonly) Float64 bottom;

@end

#endif /* MADMarginStyle_h */
