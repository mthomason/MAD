//
//  MADNavigationBarTitleView.m
//  MAD
//
//  Created by Michael Thomason on 10/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADNavigationBarTitleView.h"
#import "NSParagraphStyle+CommonStyles.h"

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
    NSAttributedString *attributedText = [self logoForTitle:text];
    super.text = text;
    self.attributedText = attributedText;
    [self sizeToFit];
}

- (NSAttributedString *)logoForTitle:(NSString *)title {
    
    NSParagraphStyle *paragraphStyle = [NSParagraphStyle titleBarStyle];
    NSMutableAttributedString *attributedStringMadDesigner = [[NSMutableAttributedString alloc] initWithString:title];
    NSInteger length = [[attributedStringMadDesigner string] length];
    
    UIFont *fonta = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0000f];
    UIFont *fontb = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0000f];
    NSRange range = NSMakeRange(0, length);
    UIColor *foregroundColor = [UIColor whiteColor];
    NSArray *components = [title componentsSeparatedByString:@" "];
    NSRange firstRange;
    NSRange secondRange;
    
    if (components.count == 2) {
        firstRange = [title rangeOfString:components[0]];
        secondRange = [title rangeOfString:components[1]];
    } else {
        firstRange = range; secondRange = range;
    }
    
    [attributedStringMadDesigner addAttribute: NSFontAttributeName
                                        value: fonta
                                        range: firstRange];
    
    [attributedStringMadDesigner addAttribute: NSFontAttributeName
                                        value: fontb
                                        range: secondRange];
    
    [attributedStringMadDesigner addAttribute: NSParagraphStyleAttributeName
                                        value: paragraphStyle
                                        range: range];
    
    [attributedStringMadDesigner addAttribute: NSForegroundColorAttributeName
                                        value: foregroundColor
                                        range: range];
    
    [attributedStringMadDesigner addAttribute: NSKernAttributeName
                                        value: [NSNull null]
                                        range: range];
    
    return attributedStringMadDesigner;
}

@end
