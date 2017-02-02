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

typedef NS_ENUM(int16_t, MADVerticalAlignment) {
    MADVerticalAlignmentUnknown = -1,
    MADVerticalAlignmentTop = 0,
    MADVerticalAlignmentCenter = 1,
    MADVerticalAlignmentBottom = 2

};

typedef NS_ENUM(int16_t, MADHorizontalAlignment) {
    MADHorizontalAlignmentUnknown = -1,
    MADHorizontalAlignmentLeft = 0,
    MADHorizontalAlignmentCenter = 1,
    MADHorizontalAlignmentRight = 2,
    MADHorizontalAlignmentJustified = 3,
    MADHorizontalAlignmentNatrual = 4,
    
};

struct MADAlignment_t {
    MADHorizontalAlignment horizontal;
    MADVerticalAlignment vertical;
};
typedef struct MADAlignment_t MADAlignment_t;

static inline MADAlignment_t MADAlignmentMake(MADHorizontalAlignment, MADVerticalAlignment);
static inline MADAlignment_t MADAlignmentMake(MADHorizontalAlignment h, MADVerticalAlignment v) {
    MADAlignment_t a; a.horizontal = h; a.vertical = v; return a;
}

static inline MADAlignment_t MADAlignmentMake64(int64_t, int64_t);
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

@interface MADAlignment : NSObject
    <NSCoding>

    - (instancetype)initWithHorizontal:(MADHorizontalAlignment)horizontal
                              vertical:(MADVerticalAlignment)vertical;

    @property (nonatomic, assign, readonly) MADHorizontalAlignment horizontal;
    @property (nonatomic, assign, readonly) MADVerticalAlignment vertical;

@end

#endif
