//
//  MADLabelTitle.m
//  MAD
//
//  Created by Michael Thomason on 10/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationBarTitleView.h"
#import <UIKit/UIView.h>

#import "NSParagraphStyle+CommonStyles.h"
#import "NSAttributedString+Logo.h"
#import <MADCocoaExtensions/UIView+Animations.h>
#import "MADLabelTitle.h"

@interface MADNavigationBarHeader ()
    @property (nonatomic, weak) MADLabelTitle *labelTitle;
@end

@implementation MADNavigationBarHeader

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {

        id labelTitle;
        UINavigationItem *item;
        
        labelTitle = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
        item = [[UINavigationItem alloc] init];
        [item setTitleView: labelTitle];
        self.labelTitle = labelTitle;
        
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self = [super initWithFrame:frame]) {
        
        id labelTitle;
        UINavigationItem *item;
        
        labelTitle = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
        item = [[UINavigationItem alloc] init];
        [item setTitleView: labelTitle];
        self.labelTitle = labelTitle;
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.labelTitle sizeToFit];
}

- (void)setTitle:(NSString *)title {
    self.labelTitle.text = title.copy;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
}

@end
