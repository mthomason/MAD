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
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = MADViewAutoresizingFlexable();
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.lineBreakMode = NSLineBreakByTruncatingTail;
        self.numberOfLines = 1;
        self.minimumScaleFactor = 0.8f;
        self.adjustsFontSizeToFitWidth = YES;
        [self setContentCompressionResistancePriority: 900
                                              forAxis: UILayoutConstraintAxisHorizontal];
    }
    return self;
}

- (void)setText:(NSString *)text {
    MADAttributedStringLogo *attributedText;
    NSString *safetext;
    
    safetext = text.copy;
    attributedText = [MADAttributedStringLogo newLogoStringForTitle:safetext];
    
    super.text = safetext;
    
    self.attributedText = attributedText;
    
    [self sizeToFit];
    
}

@end
