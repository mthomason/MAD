//
//  MTViewTableHeader.m
//  Reports
//
//  Created by Michael Thomason on 1/27/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTViewTableHeader.h"
#import "UIColor+EverydayApps.h"

@interface MTViewTableHeader ()

@end

@implementation MTViewTableHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        NSArray *nibContents =[[NSBundle mainBundle] loadNibNamed: @"MTViewTableHeader"
                                                            owner: self
                                                          options: nil];
        UIView *view = nibContents.firstObject;
        view.frame = self.frame;
        
        [self addSubview:nibContents.firstObject];
        self.labelTitle.numberOfLines = 0;
        self.labelTitle.textColor = [UIColor whiteColor];
        self.labelTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self sizeToFit];
}

@end
