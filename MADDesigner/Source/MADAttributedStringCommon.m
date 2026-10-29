//
//  NSAttributedString+Common.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADAttributedStringCommon.h"
#import <UIKit/UIInterface.h>
#import <UIKit/UIFont.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSParagraphStyle.h>
#import <UIKit/UIColor.h>

#import <MADCocoaExtensions/MADColorSocial.h>

@implementation MADAttributedStringCommon

+ (NSAttributedString *)AttributedStringTwitter {
	UIFont *fa = [UIFont fontWithName:@"FontAwesome" size:12.0000f];
	id color = [MADColorSocial newBlueTwitter];
	NSDictionary *attributesTwitter = [[NSDictionary alloc] initWithObjectsAndKeys: color, NSForegroundColorAttributeName, fa, NSFontAttributeName, nil];
	id twitter = [[NSAttributedString alloc] initWithString:@"" attributes:attributesTwitter];
	return twitter;
}

+ (NSAttributedString *)AttributedStringFollowOnTwitter {
	
	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	style.alignment = NSTextAlignmentCenter;
	style.lineBreakMode = NSLineBreakByWordWrapping;
	
	NSMutableAttributedString *twitter = [[MADAttributedStringCommon AttributedStringTwitter] mutableCopy];
	UIFont *sy = [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] fontWithSize:12.0000f];
	NSDictionary *attributesBlack = @{
		NSFontAttributeName: sy
	};
	
	NSAttributedString *followAttributed = [[NSAttributedString alloc] initWithString:[@" " stringByAppendingString:NSLocalizedString(@"Follow", @"Follow")]
																		   attributes:attributesBlack];
	[twitter appendAttributedString:followAttributed];
	NSDictionary *d = [[NSDictionary alloc] initWithObjectsAndKeys: style, NSParagraphStyleAttributeName, nil];
	[((NSMutableAttributedString *)twitter) addAttributes:d range:NSMakeRange(0, ((NSMutableAttributedString *)twitter).length)];
	return twitter;
}

@end
