//
//  MADMargin.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADMarginStyle_h
#define MAD_MADMarginStyle_h

#import <Foundation/NSObject.h>

@interface MADMargin : NSObject
    <NSCoding>

    - (instancetype)initWithLeft:(Float64)left right:(Float64)right
                             top:(Float64)top bottom:(Float64)bottom;

    @property (nonatomic, assign, readwrite) Float64 left;
    @property (nonatomic, assign, readwrite) Float64 right;
    @property (nonatomic, assign, readwrite) Float64 top;
    @property (nonatomic, assign, readwrite) Float64 bottom;

@end

#endif /* MADMarginStyle_h */
