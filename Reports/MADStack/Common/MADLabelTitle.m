//
//  MADLabelTitle.m
//  MAD Designer
//
//  Created by Michael on 1/5/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADLabelTitle.h"
#import "NSAttributedString+Logo.h"
#import <MADCocoaExtensions/UIView+Animations.h>

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
