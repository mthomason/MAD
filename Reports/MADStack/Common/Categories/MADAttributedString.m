//
//  NSAttributedString+Logo.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/7/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADAttributedString.h"
#import "NSParagraphStyle+CommonStyles.h"
#import <MADCocoaExtensions/MADColor.h>

@implementation MADAttributedString

+ (instancetype)newAttributedStringLogoForTitle:(NSString *)title {
    
    NSParagraphStyle *paragraphStyle = [NSParagraphStyle titleBarStyle];
    NSMutableAttributedString *attributedStringMadDesigner = [[NSMutableAttributedString alloc] initWithString:title];
    
    NSRange range = NSMakeRange(0, attributedStringMadDesigner.string.length);
    UIColor *foregroundColor = [UIColor whiteColor];
    NSArray *components = [title componentsSeparatedByString:@" "];

    NSDictionary *attributesRangeAll = @{
                                         NSParagraphStyleAttributeName:paragraphStyle,
                                         NSForegroundColorAttributeName:foregroundColor,
                                         NSKernAttributeName:[NSNull null]
                                       };
    
    [attributedStringMadDesigner addAttributes: attributesRangeAll range: range];

    UIFont *fonta = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0000f];
    [attributedStringMadDesigner addAttribute: NSFontAttributeName
                                        value: fonta
                                        range: components.count == 2 ? [title rangeOfString:components[0]] : range];
    
    UIFont *fontb = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0000f];
    [attributedStringMadDesigner addAttribute: NSFontAttributeName
                                        value: fontb
                                        range: components.count == 2 ? [title rangeOfString:components[1]] : range];
    
    return (MADAttributedString *)attributedStringMadDesigner;
}

+ (instancetype)newAttributedStringEverydayAppsOnTwitter {
    NSMutableAttributedString *everyday = [[NSMutableAttributedString alloc] initWithString:@"Everyday Apps "];
    NSAttributedString *twitter = [self newAttributedStringTwitter];
    [everyday appendAttributedString:twitter];
    return (MADAttributedString *)everyday;
}

+ (instancetype)newAttributedStringTwitter {
    UIColor *color = [MADColor blueTwitter];
    UIFont *fa = [UIFont fontWithName:@"FontAwesome" size:12.0000f];
    NSDictionary *attributesTwitter = @{ NSForegroundColorAttributeName :  color, NSFontAttributeName : fa};
    id twitter = [[self alloc] initWithString:@"" attributes:attributesTwitter];
    return twitter;
}

+ (instancetype)newAttributedStringFollowUsOnTwitter {
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    
    UIColor *black = [UIColor blackColor];
    NSMutableAttributedString *twitter = [self newAttributedStringTwitter];
    
    UIFont *sy = [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] fontWithSize:12.0000f];
    NSDictionary *attributesBlack = @{ NSForegroundColorAttributeName :  black, NSFontAttributeName: sy};
    
    NSString *follow = NSLocalizedString(@"Follow", @"Follow");
    NSString *spaceFollow = [@" " stringByAppendingString:follow];
    NSAttributedString *followAttributed = [[NSAttributedString alloc] initWithString:spaceFollow attributes:attributesBlack];
    [twitter appendAttributedString:followAttributed];
    NSDictionary *d = @{NSParagraphStyleAttributeName:style};
    [twitter addAttributes:d range:NSMakeRange(0, twitter.length)];
    return (MADAttributedString *)twitter;
}

@end
