//
//  MADButtonTwitter.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_UIButton_FollowTwitter_h
#define MAD_Designer_UIButton_FollowTwitter_h

#import <UIKit/UIButton.h>
#import "MADSizeGeneral.h"

@interface MADButtonTwitter : UIButton

    + (instancetype)newButtonTwitterFolllowTwitterWithTarget:(id)target action:(SEL)action;
    + (instancetype)newButtonTwitterFolllowTwitterWithTarget:(id)target action:(SEL)action
                                                        size:(MADSizeGeneral)size;

@end

#endif
