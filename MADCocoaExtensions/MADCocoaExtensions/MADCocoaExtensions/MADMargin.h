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
    double left;
    double right;
    double top;
    double bottom;
};
typedef struct MADLayoutMargin MADLayoutMargin;

static inline MADLayoutMargin MADLayoutMarginMake(double, double, double, double);
static inline MADLayoutMargin MADLayoutMarginMake(double l, double r, double t, double b) {
    MADLayoutMargin m;
    m.left = l;
    m.right = r;
    m.top = t;
    m.bottom = b;
    return m;
}

#endif /* MADMarginStyle_h */
