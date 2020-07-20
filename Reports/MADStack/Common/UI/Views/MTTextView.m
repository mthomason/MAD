//
//  MTTextView.m
//  Reports
//
//  Created by Michael Thomason on 1/2/13.
//  Copyright © 2020 Everyday Apps LLC. All rights reserved.
//

#import "MTTextView.h"
#import <UIKit/UITextView.h>

@interface MTTextView ()

    @property (nonatomic, assign) CGRect initalFrame;

@end

@implementation MTTextView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        [self setClipsToBounds:YES];
        self.backgroundColor = [UIColor clearColor];
        CGRect textViewFrame = CGRectInset(frame, -4.0, -4.0);
        self.initalFrame = textViewFrame;
        UITextView *textView = [[UITextView alloc] initWithFrame:textViewFrame];
        [textView setUserInteractionEnabled:NO];
        
        textView.backgroundColor = [UIColor clearColor];
        [self addSubview:textView];
        [textView setClipsToBounds:YES];
        self.textView = textView;

    }
    return self;
}

- (void)verticalAlignTop {
    [self.textView sizeToFit];
    CGFloat originX = self.frame.origin.x;
    CGFloat originY = self.frame.origin.y - 8.0;
    CGFloat sizeWidth = self.bounds.size.width;
    CGFloat sizeHeight = self.textView.bounds.size.height;
    CGRect newFrame = CGRectMake(originX, originY, sizeWidth, sizeHeight);
    newFrame = CGRectInset(newFrame, -4.0, -4.0);
    self.textView.frame = newFrame;
}

- (void)verticalAlignBottom {
    [self.textView sizeToFit];
    CGFloat originX = self.frame.origin.x;
    CGFloat originY = self.frame.origin.y + self.frame.size.height - self.textView.bounds.size.height + 8.0;
    CGFloat sizeWidth = self.bounds.size.width;
    CGFloat sizeHeight = self.textView.bounds.size.height;
    CGRect newFrame = CGRectMake(originX, originY, sizeWidth, sizeHeight);
    newFrame = CGRectInset(newFrame, -4.0, -4.0);
    self.textView.frame = newFrame;
}

- (void)verticalAlignMiddle {
    CGRect textViewFrame = CGRectInset(self.frame, -4.0, -4.0);
    self.textView.frame = textViewFrame;
    CGFloat topCorrect = (self.textView.bounds.size.height - self.textView.contentSize.height * self.textView.zoomScale)  / 2.0;
    topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
    self.textView.contentOffset = (CGPoint){.x = 0, .y = -topCorrect};
}

@end
