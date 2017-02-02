//
//  MADPadding.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADPadding_h
#define MADPadding_h

#import <Foundation/NSObject.h>

struct MADLayoutPadding_t {
    Float64 left;
    Float64 right;
    Float64 top;
    Float64 bottom;
};
typedef struct MADLayoutPadding_t MADLayoutPadding_t;

static inline MADLayoutPadding_t MADLayoutPaddingMake(Float64, Float64, Float64, Float64);
static inline MADLayoutPadding_t MADLayoutPaddingMake(Float64 l, Float64 r, Float64 t, Float64 b) {
    MADLayoutPadding_t p; p.left = l; p.right = r; p.top = t; p.bottom = b; return p;
}

@interface MADPadding : NSObject
    <NSCoding>

    - (instancetype)initWithLeft:(Float64)left right:(Float64)right
                             top:(Float64)top bottom:(Float64)bottom;

    @property (nonatomic, assign, readonly) Float64 left;
    @property (nonatomic, assign, readonly) Float64 right;
    @property (nonatomic, assign, readonly) Float64 top;
    @property (nonatomic, assign, readonly) Float64 bottom;

@end

#endif /* MADPadding_h */
