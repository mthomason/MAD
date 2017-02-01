//
//  MADPadding.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADPadding_h
#define MADPadding_h

struct MADPadding {
    double left;
    double right;
    double top;
    double bottom;
};
typedef struct MADPadding MADPadding;

static inline MADPadding MADPaddingMake(double, double, double, double);
static inline MADPadding MADPaddingMake(double l, double r, double t, double b) {
    MADPadding p; p.left = l; p.right = r; p.top = t; p.bottom = b; return p;
}

#endif /* MADPadding_h */
