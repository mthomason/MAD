//
//  MADBorderStyle.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADBorderStyle_h
#define MAD_MADBorderStyle_h

typedef NS_ENUM(short, MADBorderStyle) {
    MADBorderStyleNone    = 1,
    MADBorderStyleDash    = 2,
    MADBorderStyleDot     = 3,
    MADBorderStyleLine    = 4
};

struct MADLayoutBorderStyle {
    float left;
    float right;
    float top;
    float bottom;
    MADBorderStyle leftStyle;
    MADBorderStyle rightStyle;
    MADBorderStyle topStyle;
    MADBorderStyle bottomStyle;
};
typedef struct MADLayoutBorderStyle MADLayoutBorderStyle;

static inline MADLayoutBorderStyle MADLayoutBorderStyleMake(float, float, float, float, MADBorderStyle, MADBorderStyle, MADBorderStyle, MADBorderStyle);
static inline MADLayoutBorderStyle MADLayoutBorderStyleMake(float l, float r, float t, float b, MADBorderStyle ls, MADBorderStyle rs, MADBorderStyle ts, MADBorderStyle bs) {
    MADLayoutBorderStyle s;
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

#endif /* MADBorderStyle_h */
