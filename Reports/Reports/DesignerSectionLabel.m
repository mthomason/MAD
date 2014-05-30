//
//  DesignerSectionLabel.m
//  Reports
//
//  Created by Michael Thomason on 7/24/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "DesignerSectionLabel.h"
#import "UIDevice+Hack.h"
#import "UIColor+EverydayApps.h"

@interface DesignerSectionLabel ()

@property (nonatomic, assign, readwrite) BOOL selected;

@end

@implementation DesignerSectionLabel


- (id)initWithDisplayText:(NSString *)displayText {
    CGRect frame = CGRectZero;
    self = [super initWithFrame:frame];
    if (self) {
        [self setSelected:NO];
        UILabel *labelSectionIdentifer = [[UILabel alloc] initWithFrame:frame];
        [labelSectionIdentifer setBackgroundColor:[UIColor clearColor]];
        [labelSectionIdentifer setTextAlignment:NSTextAlignmentCenter];
        [labelSectionIdentifer setFont:[UIFont systemFontOfSize:10.0000f]];
        UIColor *tintColor = [UIColor tintColorBlue];
        [labelSectionIdentifer setTextColor:tintColor];
        [labelSectionIdentifer setText: displayText];
        [labelSectionIdentifer setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [labelSectionIdentifer setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self addSubview:labelSectionIdentifer];
        [self setLabelSectionIdentifer:labelSectionIdentifer];

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIColor *color = [UIColor tintColorBlue];
    if ([self selected]) {
        [[self labelSectionIdentifer] setTextColor:[color colorWithAlphaComponent:0.500f]];
    } else {
        [[self labelSectionIdentifer] setTextColor:color];
    }
}

- (CGSize)intrinsicContentSize {
    CGSize labelIntrinsicContentSize = [[self labelSectionIdentifer] intrinsicContentSize];
    return CGSizeMake(labelIntrinsicContentSize.width + 2.0000f, labelIntrinsicContentSize.height + 2.0000f);
}

- (void)dimView {
    UIColor *tintColor = [UIColor tintColorBlue];
    [[self labelSectionIdentifer] setTextColor:[tintColor colorWithAlphaComponent:0.500f]];
    [self setSelected:YES];
}

- (void)normalView {
    
    UIColor *tintColor = [UIColor tintColorBlue];
    [[self labelSectionIdentifer] setTextColor:tintColor];
    [self setSelected:NO];
}


- (void)tintColorDidChange {

}

@end
