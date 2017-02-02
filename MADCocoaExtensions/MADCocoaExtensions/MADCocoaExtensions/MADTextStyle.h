//
//  MADStyle.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADTextStyle_h
#define MAD_MADTextStyle_h

#import <Foundation/NSObject.h>

struct MADTextStyle_t {
    BOOL bold;
    BOOL italic;
    BOOL underline;
    BOOL strikethrough;
};
typedef struct MADTextStyle_t MADTextStyle_t;

static inline MADTextStyle_t MADLayoutTextStyleMake(BOOL, BOOL, BOOL, BOOL);
static inline MADTextStyle_t MADLayoutTextStyleMake(BOOL b, BOOL i, BOOL u, BOOL s) {
    MADTextStyle_t style;
    style.bold = b;
    style.italic = i;
    style.underline = u;
    style.strikethrough = s;
    return style;
}

@interface MADTextStyle : NSObject
    <NSCoding>

    - (instancetype)initWithBold:(BOOL)bold italic:(BOOL)italic
                       underline:(BOOL)underline strikethrough:(BOOL)strikethrough;

    @property (nonatomic, assign, readonly) BOOL bold;
    @property (nonatomic, assign, readonly) BOOL italic;
    @property (nonatomic, assign, readonly) BOOL underline;
    @property (nonatomic, assign, readonly) BOOL strikethrough;

@end

#endif /* MADStyle_h */
