//
//  NSAttributedString+Common.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSAttributedString+Common.h"
#import "UIColor+Social.h"

@implementation NSAttributedString (Common)

+ (NSAttributedString *)FollowUsOnTwitter {
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    UIColor *black = [UIColor blackColor];
    UIFont *sy = [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] fontWithSize:12.0000f];
    NSDictionary *attributesBlack = @{ NSForegroundColorAttributeName :  black, NSFontAttributeName: sy};
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:@"Follow Us on " attributes:attributesBlack];
    UIColor *color = [UIColor blueTwitter];
    UIFont *fa = [UIFont fontWithName:@"FontAwesome" size:12.0000f];
    NSDictionary *attributesTwitter = @{ NSForegroundColorAttributeName :  color, NSFontAttributeName : fa };
    NSAttributedString *twitter = [[NSAttributedString alloc] initWithString:@"" attributes:attributesTwitter];
    [s appendAttributedString:twitter];
    NSDictionary *d = @{NSParagraphStyleAttributeName:style};
    [s addAttributes:d range:NSMakeRange(0, s.length)];
    return s;
}

@end
