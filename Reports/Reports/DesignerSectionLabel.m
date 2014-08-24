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
#import "RptqDocumentSection+Extras.h"
#import <CoreData/CoreData.h>

@interface DesignerSectionLabel ()
    <UIGestureRecognizerDelegate>

@property (nonatomic, assign, readwrite) BOOL selected;
@property (nonatomic, strong) RptqDocumentSection *section;

@end

@implementation DesignerSectionLabel

- (instancetype)initWithSection:(RptqDocumentSection *)section {
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
        labelSectionIdentifer.text = [section localizedDisplayName];
        [labelSectionIdentifer setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [labelSectionIdentifer setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self addSubview:labelSectionIdentifer];
        [self setLabelSectionIdentifer:labelSectionIdentifer];

        
        self.backgroundColor = [UIColor clearColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layer.cornerRadius = 0.0000f;
        self.clipsToBounds = YES;
        [self setContentHuggingPriority: UILayoutPriorityDefaultLow
                                forAxis: UILayoutConstraintAxisHorizontal];
        [self setContentCompressionResistancePriority: UILayoutPriorityDefaultHigh
                                              forAxis: UILayoutConstraintAxisHorizontal];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                               action: @selector(toggleSectionControlPanel:)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        tapGestureRecognizer.numberOfTouchesRequired = 1;
        tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer: tapGestureRecognizer];
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

- (void)toggleSectionControlPanel:(UITapGestureRecognizer *)sender {
    
    if ([sender state] == UIGestureRecognizerStateEnded) {
        [self.delegate toggleSectionControlPanel:self];
    }
}

@end
