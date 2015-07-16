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

+ (NSAttributedString *)EverydayAppsOnTwitter {
    NSMutableAttributedString *everyday = [[NSMutableAttributedString alloc] initWithString:@"Everyday Apps "];
    NSAttributedString *twitter = [NSAttributedString Twitter];
    [everyday appendAttributedString:twitter];
    return everyday;
}

+ (NSAttributedString *)Twitter {
    UIColor *color = [UIColor blueTwitter];
    UIFont *fa = [UIFont fontWithName:@"FontAwesome" size:12.0000f];
    NSDictionary *attributesTwitter = @{ NSForegroundColorAttributeName :  color, NSFontAttributeName : fa};
    NSAttributedString *twitter = [[NSAttributedString alloc] initWithString:@"" attributes:attributesTwitter];
    return twitter;
}

+ (NSAttributedString *)FollowUsOnTwitter {
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    
    UIColor *black = [UIColor blackColor];
    NSMutableAttributedString *twitter = [NSAttributedString Twitter].mutableCopy;

    UIFont *sy = [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] fontWithSize:12.0000f];
    NSDictionary *attributesBlack = @{ NSForegroundColorAttributeName :  black, NSFontAttributeName: sy};
    
    NSString *follow = NSLocalizedString(@"Follow", @"Follow");
    NSString *spaceFollow = [@" " stringByAppendingString:follow];
    NSAttributedString *followAttributed = [[NSAttributedString alloc] initWithString:spaceFollow attributes:attributesBlack];
    [twitter appendAttributedString:followAttributed];
    NSDictionary *d = @{NSParagraphStyleAttributeName:style};
    [twitter addAttributes:d range:NSMakeRange(0, twitter.length)];
    return twitter;
}

@end
