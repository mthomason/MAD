//
//  NSAttributedString+Logo.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/7/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSAttributedString+Logo.h"
#import "NSParagraphStyle+CommonStyles.h"

@implementation NSAttributedString (Logo)

+ (NSAttributedString *)logoForTitle:(NSString *)title {
    
    NSParagraphStyle *paragraphStyle = [NSParagraphStyle titleBarStyle];
    NSMutableAttributedString *attributedStringMadDesigner = [[NSMutableAttributedString alloc] initWithString:title];
    
    UIFont *fonta = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0000f];
    UIFont *fontb = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0000f];
    NSRange range = NSMakeRange(0, attributedStringMadDesigner.string.length);
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
    
    [attributedStringMadDesigner addAttribute:NSKernAttributeName
                                        value:[NSNull null]
                                        range:range];
    return attributedStringMadDesigner;
}

@end
