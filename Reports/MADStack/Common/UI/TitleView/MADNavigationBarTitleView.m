//
//  MADLabelTitle.m
//  MAD
//
//  Created by Michael Thomason on 10/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationBarTitleView.h"
#import "NSParagraphStyle+CommonStyles.h"
#import "NSAttributedString+Logo.h"
#import <MADCocoaExtensions/UIView+Animations.h>

#import <UIKit/UIView.h>

@interface MADNavigationItemTitle ()
    @property (nonatomic, strong) MADLabelTitle *navigationView;
@end

@implementation MADNavigationItemTitle

- (instancetype)initWithTitle:(NSString *)title {
    if (self = [super initWithTitle:title]) {
        id navigationView;
        navigationView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
        self.navigationView = navigationView;
        
        NSString *text = [[NSString alloc] initWithString:title];
        self.title = text;
        
    }
    return self;
}

@end


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

@implementation MADLabelTitle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = MADViewAutoresizingFlexable();
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.lineBreakMode = NSLineBreakByTruncatingTail;
        self.numberOfLines = 1;
        self.minimumScaleFactor = 0.8f;
        self.adjustsFontSizeToFitWidth = YES;
    }
    return self;
}

- (void)updateConstraints {
    [super updateConstraints];
    [self setContentCompressionResistancePriority:900 forAxis:UILayoutConstraintAxisHorizontal];
}

- (void)setText:(NSString *)text {
    MADLogoString *attributedText;
    NSString *safetext;
    
    safetext = text.copy;
    attributedText = [NSAttributedString newLogoStringForTitle:safetext];
    
    super.text = safetext;
    
    self.attributedText = attributedText;
    
    [self sizeToFit];
    
}

@end
