//
//  MTTextView.h
//  Reports
//
//  Created by Michael Thomason on 1/2/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTTextView_h
#define Reports_MTTextView_h

#import <UIKit/UIView.h>

@class UITextView;

@interface MTTextView : UIView

    @property (nonatomic, strong) UITextView *textView;

    - (void)verticalAlignTop;
    - (void)verticalAlignBottom;
    - (void)verticalAlignMiddle;

@end

#endif
