//
//  NSAttributedString+Logo.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/7/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSAttributedString+Logo.h"

#import <UIKit/NSAttributedString.h>
#import <UIKit/UIFont.h>
#import <UIKit/UIColor.h>

#import "NSParagraphStyle+CommonStyles.h"

@implementation NSAttributedString (Logo)

+ (MADLogoString *)newLogoStringForTitle:(NSString *)title {
    
    NSParagraphStyle *paragraphStyle = [NSParagraphStyle newParagraphStyleTitleBar];
    NSMutableAttributedString *attributedStringMadDesigner = [[NSMutableAttributedString alloc] initWithString:title];
    
    NSRange range = NSMakeRange(0, attributedStringMadDesigner.string.length);
    NSArray <NSString *> *components = [title componentsSeparatedByString:@" "];
    NSRange firstRange;
    NSRange secondRange;
    
    if (components.count == 2) {
        NSString *component = components[0];
        firstRange = [title rangeOfString:component];
        component = components[1];
        secondRange = [title rangeOfString:component];
    } else {
        firstRange = range; secondRange = range;
    }
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0000f];
    [attributedStringMadDesigner addAttribute: NSFontAttributeName
                                        value: font range: firstRange];
    
    font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0000f];
    [attributedStringMadDesigner addAttribute: NSFontAttributeName
                                        value: font range: secondRange];
    
    [attributedStringMadDesigner addAttribute: NSParagraphStyleAttributeName
                                        value: paragraphStyle range: range];
    
    UIColor *foregroundColor = [UIColor whiteColor];
    [attributedStringMadDesigner addAttribute: NSForegroundColorAttributeName
                                        value: foregroundColor range: range];
    
    [attributedStringMadDesigner addAttribute:NSKernAttributeName
                                        value:[NSNull null] range:range];
    return attributedStringMadDesigner;
}

@end
