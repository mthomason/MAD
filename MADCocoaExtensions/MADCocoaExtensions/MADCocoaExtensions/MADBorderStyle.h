//
//  MADBorderStyle.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADBorderStyle_h
#define MAD_MADBorderStyle_h

#import <Foundation/NSObject.h>

typedef NS_ENUM(int16_t, MADBorderType) {
    MADBorderStyleNone    = 1,
    MADBorderStyleDash    = 2,
    MADBorderStyleDot     = 3,
    MADBorderStyleLine    = 4
};

@interface MADBorderStyle : NSObject
    <NSCoding>

    - (instancetype)initWithLeft:(Float64)left right:(Float64)right
                             top:(Float64)top bottom:(Float64)bottom
                       leftStyle:(MADBorderType)leftStyle rightStyle:(MADBorderType)rightStyle
                        topStyle:(MADBorderType)topStyle bottomStyle:(MADBorderType)bottomStyle;

    @property (nonatomic, assign, readwrite) Float64 left;
    @property (nonatomic, assign, readwrite) Float64 right;
    @property (nonatomic, assign, readwrite) Float64 top;
    @property (nonatomic, assign, readwrite) Float64 bottom;

    @property (nonatomic, assign, readwrite) MADBorderType leftStyle;
    @property (nonatomic, assign, readwrite) MADBorderType rightStyle;
    @property (nonatomic, assign, readwrite) MADBorderType topStyle;
    @property (nonatomic, assign, readwrite) MADBorderType bottomStyle;

@end

#endif /* MADBorderStyle_h */
