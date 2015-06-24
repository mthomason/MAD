//
//  UIButton+FollowTwitter.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MADSizeGeneral.h"

@interface UIButton (FollowTwitter)

+ (instancetype)FolllowTwitterWithTarget:(id)target action:(SEL)action;
+ (instancetype)FolllowTwitterWithTarget:(id)target action:(SEL)action size:(MADSizeGeneral)size;

@end
