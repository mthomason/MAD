//
//  MTTextView.h
//  Reports
//
//  Created by Michael Thomason on 1/2/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTTextView : UIView

@property (nonatomic, retain) UITextView *textView;

- (void)verticalAlignTop;
- (void)verticalAlignBottom;
- (void)verticalAlignMiddle;

@end