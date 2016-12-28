//
//  MTTableCell.m
//  MAD
//
//  Created by Michael Thomason on 3/25/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableCell.h"
#import <UIKit/UILabel.h>
#import <QuartzCore/CALayer.h>

@interface MADTableCell ()

    @property (nonatomic, weak, readwrite) UILabel *label;

@end

@implementation MADTableCell

- (void)removeFromSuperview {
    [super removeFromSuperview];
    [self.label removeFromSuperview];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIColor *color = [UIColor darkGrayColor];
        UILabel *lbl = [[UILabel alloc] initWithFrame:self.contentView.frame];
        
        lbl.backgroundColor = [UIColor whiteColor];
        
        [self.contentView addSubview:lbl];
        lbl.autoresizingMask = UIViewAutoresizingFlexibleHeight |
                                UIViewAutoresizingFlexibleWidth |
                                UIViewAutoresizingFlexibleTopMargin |
                                UIViewAutoresizingFlexibleBottomMargin |
                                UIViewAutoresizingFlexibleRightMargin |
                                UIViewAutoresizingFlexibleLeftMargin;
        self.contentView.layer.borderWidth = 1.0000f;
        self.contentView.layer.borderColor = color.CGColor;
        self.label = lbl;
    }
    return self;
}

@end
