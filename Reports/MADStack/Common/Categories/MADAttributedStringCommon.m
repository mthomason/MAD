//
//  NSAttributedString+Common.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADAttributedStringCommon.h"
#import <MAD/MADConstants.h>
#import <UIKit/UIInterface.h>
#import <UIKit/UIFont.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSParagraphStyle.h>
#import <UIKit/UIColor.h>

#import <CoreText/CTStringAttributes.h>

#import <MADCocoaExtensions/MADColorSocial.h>

@implementation MADAttributedStringCommon

+ (instancetype)newAttributedStringEDATwitter {
    id everyday = [[NSMutableAttributedString alloc] initWithString:@"Everyday Apps "];
    id twitter = [MADAttributedStringCommon newAttributedStringTwitter];
    [everyday appendAttributedString:twitter];
    return everyday;
}

+ (instancetype)newAttributedStringTwitter {
    UIFont *fa = [UIFont fontWithName:@"FontAwesome" size:12.0000f];
    id color = [MADColorSocial newBlueTwitter];
    NSDictionary *attributesTwitter = [[NSDictionary alloc] initWithObjectsAndKeys: color, NSForegroundColorAttributeName, fa, NSFontAttributeName, nil];
    id twitter = [[NSAttributedString alloc] initWithString:@"" attributes:attributesTwitter];
    return twitter;
}

+ (instancetype)newAttributedStringFollowOnTwitter {
    
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSTextAlignmentCenter;
    style.lineBreakMode = NSLineBreakByWordWrapping;
    
    UIColor *black = [UIColor blackColor];
    id twit = [MADAttributedStringCommon newAttributedStringTwitter];
    id twitter = [twit mutableCopy];
    UIFont *sy = [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] fontWithSize:12.0000f];
    NSDictionary *attributesBlack = @{ NSForegroundColorAttributeName :  black, NSFontAttributeName: sy};
    
    NSString *follow = NSLocalizedString(@"Follow", @"Follow");
    NSString *spaceFollow = [@" " stringByAppendingString:follow];
    NSAttributedString *followAttributed = [[NSAttributedString alloc] initWithString:spaceFollow attributes:attributesBlack];
    [twitter appendAttributedString:followAttributed];
    NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys: style, NSParagraphStyleAttributeName, nil];
    [((NSMutableAttributedString *)twitter) addAttributes:d range:NSMakeRange(0, ((NSMutableAttributedString *)twitter).length)];
    return twitter;
}

+ (instancetype)newAttributedStringTrademarkStatement {
    NSNumber *superscript = @(1);
    UIFont *font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                superscript, (__bridge NSString *)kCTSuperscriptAttributeName,
                                font, NSFontAttributeName, nil];
    NSAttributedString *r = [[NSAttributedString alloc] initWithString: @"®"
                                                            attributes: attributes];
    NSAttributedString *mad = [[NSAttributedString alloc] initWithString: MADTrademark
                                                              attributes: nil];
    
    id tm = [[NSMutableAttributedString alloc] initWithAttributedString: mad];
    [((NSMutableAttributedString *)tm) appendAttributedString:r];
    NSString *loc = NSLocalizedString(@" is a registered trademark of Michael Thomason.",
                                      @"Trademark statement.");
    NSAttributedString *statement = [[NSAttributedString alloc] initWithString: loc
                                                                    attributes: nil];
    [tm appendAttributedString: statement];
    
    return tm;
}

@end
