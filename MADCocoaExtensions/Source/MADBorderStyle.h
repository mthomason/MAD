//
//  MADBorderStyle.h
//  MADCocoaExtensions
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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

@interface MADBorderStyle : NSObject <NSSecureCoding, NSCopying>

- (instancetype)initWithLeft:(float)left right:(float)right
						 top:(float)top bottom:(float)bottom
				   leftStyle:(MADBorderType)leftStyle rightStyle:(MADBorderType)rightStyle
					topStyle:(MADBorderType)topStyle bottomStyle:(MADBorderType)bottomStyle;

@property (nonatomic, assign, readwrite) float left;
@property (nonatomic, assign, readwrite) float right;
@property (nonatomic, assign, readwrite) float top;
@property (nonatomic, assign, readwrite) float bottom;

@property (nonatomic, assign, readwrite) MADBorderType leftStyle;
@property (nonatomic, assign, readwrite) MADBorderType rightStyle;
@property (nonatomic, assign, readwrite) MADBorderType topStyle;
@property (nonatomic, assign, readwrite) MADBorderType bottomStyle;

@end

#endif /* MADBorderStyle_h */
