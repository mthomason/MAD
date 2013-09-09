//
//  DesignerSectionLabel.m
//  Reports
//
//  Created by Michael Thomason on 7/24/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "DesignerSectionLabel.h"
#import "UIDevice+Hack.h"

@interface DesignerSectionLabel ()

@property (nonatomic, assign, readwrite) BOOL selected;

@end

@implementation DesignerSectionLabel

- (void)dealloc {
    [_labelSectionIdentifer release];
    [super dealloc];
}

- (id)initWithDisplayText:(NSString *)displayText {
    CGRect frame = CGRectZero;
    self = [super initWithFrame:frame];
    if (self) {
        [self setSelected:NO];
        UILabel *labelSectionIdentifer = [[UILabel alloc] initWithFrame:frame];
        [labelSectionIdentifer setBackgroundColor:[UIColor clearColor]];
        [labelSectionIdentifer setTextAlignment:NSTextAlignmentCenter];
        [labelSectionIdentifer setFont:[UIFont systemFontOfSize:8.0000f]];
        if ([UIDevice isModernOS]) {
            UIColor *tintColor = [self tintColor];
            [labelSectionIdentifer setTextColor:tintColor];
        }
        [labelSectionIdentifer setText: displayText];
        [labelSectionIdentifer setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [labelSectionIdentifer setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self addSubview:labelSectionIdentifer];
        [self setLabelSectionIdentifer:labelSectionIdentifer];
        [labelSectionIdentifer release];

//        [self setTintColor:[self tintColor]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if ([self selected]) {
        [[self labelSectionIdentifer] setTextColor:[[self tintColor] colorWithAlphaComponent:0.500f]];
    } else {
        [[self labelSectionIdentifer] setTextColor:[self tintColor]];
    }
}

- (CGSize)intrinsicContentSize {
    CGSize labelIntrinsicContentSize = [[self labelSectionIdentifer] intrinsicContentSize];
    return CGSizeMake(labelIntrinsicContentSize.width + 2.0000f, labelIntrinsicContentSize.height + 2.0000f);
}

- (void)dimView {
    //[self setTintAdjustmentMode:UIViewTintAdjustmentModeDimmed];
    [[self labelSectionIdentifer] setTextColor:[[self tintColor] colorWithAlphaComponent:0.500f]];
    [self setSelected:YES];
}

- (void)normalView {
    
    //[self setTintAdjustmentMode:UIViewTintAdjustmentModeNormal];
    [[self labelSectionIdentifer] setTextColor:[self tintColor]];
    [self setSelected:NO];
}


- (void)tintColorDidChange {

}

@end
