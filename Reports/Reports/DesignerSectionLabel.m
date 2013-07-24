//
//  DesignerSectionLabel.m
//  Reports
//
//  Created by Michael Thomason on 7/24/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "DesignerSectionLabel.h"

@interface DesignerSectionLabel ()

@property (nonatomic, retain) UILabel *labelSectionIdentifer;

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

        UILabel *labelSectionIdentifer = [[UILabel alloc] initWithFrame:frame];
        [labelSectionIdentifer setBackgroundColor:[UIColor clearColor]];
        [labelSectionIdentifer setTextAlignment:NSTextAlignmentCenter];
        [labelSectionIdentifer setFont:[UIFont systemFontOfSize:8.0000f]];
        [labelSectionIdentifer setText: displayText];
        [labelSectionIdentifer setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [labelSectionIdentifer setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self addSubview:labelSectionIdentifer];
        [self setLabelSectionIdentifer:labelSectionIdentifer];
        [labelSectionIdentifer release];

    }
    return self;
}

- (CGSize)intrinsicContentSize {
    CGSize labelIntrinsicContentSize = [[self labelSectionIdentifer] intrinsicContentSize];
    return CGSizeMake(labelIntrinsicContentSize.width + 2.0000f, labelIntrinsicContentSize.height + 2.0000f);
}

@end
