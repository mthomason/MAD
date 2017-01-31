//
//  MADMargin.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADMarginStyle_h
#define MAD_MADMarginStyle_h

struct MADLayoutMargin {
    CGFloat left;
    CGFloat right;
    CGFloat top;
    CGFloat bottom;
};
typedef struct MADLayoutMargin MADLayoutMargin;

static inline MADLayoutMargin MADLayoutMarginMake(float, float, float, float);
static inline MADLayoutMargin MADLayoutMarginMake(float l, float r, float t, float b) {
    MADLayoutMargin m;
    m.left = l;
    m.right = r;
    m.top = t;
    m.bottom = b;
    return m;
}

#endif /* MADMarginStyle_h */
