//
//  MADStyle.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADTextStyle_h
#define MAD_MADTextStyle_h

struct MADTextStyle {
    BOOL bold;
    BOOL italic;
    BOOL underline;
    BOOL strikethrough;
};
typedef struct MADTextStyle MADTextStyle;

static inline MADTextStyle MADTextStyleMake(BOOL, BOOL, BOOL, BOOL);
static inline MADTextStyle MADTextStyleMake(BOOL b, BOOL i, BOOL u, BOOL s) {
    MADTextStyle style;
    style.bold = b;
    style.italic = i;
    style.underline = u;
    style.strikethrough = s;
    return style;
}

#endif /* MADStyle_h */
