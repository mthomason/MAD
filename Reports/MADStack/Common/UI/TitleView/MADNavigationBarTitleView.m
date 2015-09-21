//
//  MADNavigationBarTitleView.m
//  MAD
//
//  Created by Michael Thomason on 10/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationBarTitleView.h"
#import "NSParagraphStyle+CommonStyles.h"
#import "NSAttributedString+Logo.h"

@implementation MADNavigationBarTitleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
    NSAttributedString *attributedText = [NSAttributedString logoForTitle:text];
    super.text = text;
    self.attributedText = attributedText;
    [self sizeToFit];
}

@end
