//
//  MADAlignment.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTAlignment_h
#define MAD_MTAlignment_h

#import <Foundation/NSObject.h>
#import <MAD/MADAlignment_t.h>

@interface MADAlignment : NSObject
    <NSCoding>

    - (instancetype)initWithHorizontal:(MADHorizontalAlignment)horizontal
                              vertical:(MADVerticalAlignment)vertical;

    @property (nonatomic, assign, readwrite) MADHorizontalAlignment horizontal;
    @property (nonatomic, assign, readwrite) MADVerticalAlignment vertical;

@end

static inline MADAlignment_t MADAlignmentMake(MADHorizontalAlignment, MADVerticalAlignment);
static inline MADAlignment_t MADAlignmentMake64(int64_t, int64_t);

static inline MADAlignment_t MADAlignmentMake(MADHorizontalAlignment h, MADVerticalAlignment v) {
    MADAlignment_t a; a.horizontal = h; a.vertical = v; return a;
}
static inline MADAlignment_t MADAlignmentMake64(int64_t h, int64_t v) {
    MADAlignment_t a;
    switch (v) {
        case MADVerticalAlignmentTop:
            a.vertical = MADVerticalAlignmentTop;
            break;
        case MADVerticalAlignmentCenter:
            a.vertical = MADVerticalAlignmentCenter;
            break;
        case MADVerticalAlignmentBottom:
            a.vertical = MADVerticalAlignmentBottom;
            break;
        default:
            a.vertical = MADVerticalAlignmentTop;
            break;
    }
    switch (h) {
        case MADHorizontalAlignmentLeft:
            a.horizontal = MADHorizontalAlignmentLeft;
            break;
        case MADHorizontalAlignmentCenter:
            a.horizontal = MADHorizontalAlignmentCenter;
            break;
        case MADHorizontalAlignmentRight:
            a.horizontal = MADHorizontalAlignmentRight;
            break;
        case MADHorizontalAlignmentJustified:
            a.horizontal = MADHorizontalAlignmentJustified;
            break;
        case MADHorizontalAlignmentNatrual:
            a.horizontal = MADHorizontalAlignmentNatrual;
            break;
        default:
            a.horizontal = MADHorizontalAlignmentLeft;
            break;
    }
    return a;
}

#endif
