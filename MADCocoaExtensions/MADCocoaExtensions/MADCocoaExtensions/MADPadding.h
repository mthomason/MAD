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
    float left;
    float right;
    float top;
    float bottom;
};
typedef struct MADPadding MADPadding;

static inline MADPadding MADPaddingMake(float, float, float, float);
static inline MADPadding MADPaddingMake(float l, float r, float t, float b) {
    MADPadding p; p.left = l; p.right = r; p.top = t; p.bottom = b; return p;
}

#endif /* MADPadding_h */
