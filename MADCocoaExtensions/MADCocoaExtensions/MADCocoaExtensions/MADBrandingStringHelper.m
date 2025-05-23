//
//  NSAttributedString+Logo.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/7/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBrandingStringHelper.h"

#import <UIKit/NSAttributedString.h>
#import <UIKit/UIFont.h>
#import <UIKit/UIColor.h>
#import <UIKit/UIInterface.h>
#import "NSParagraphStyle+CommonStyles.h"

@interface NSParagraphStyle (MADPrivateExtensions)
+ (NSParagraphStyle *)newParagraphStyleTitleBar;
@end

@implementation NSParagraphStyle (MADPrivateExtensions)
+ (NSParagraphStyle *)newParagraphStyleTitleBar {
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	paragraphStyle.alignment = NSTextAlignmentNatural;
	return paragraphStyle;
}
@end

@implementation MADBrandingStringHelper

+ (NSAttributedString *)logoAttributedStringForTitle:(NSString *)title {
	if (!title || title.length == 0) {
		return [[NSAttributedString alloc] initWithString:@""];
	}
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:title];
	NSRange fullRange = NSMakeRange(0, title.length);
	UIFont *lightFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0];
	UIFont *boldFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
	
	if (!lightFont) {
		lightFont = [UIFont systemFontOfSize:20.0f weight:UIFontWeightLight];
	}
	if (!boldFont) {
		boldFont = [UIFont systemFontOfSize:20.0f weight:UIFontWeightBold];
	}
	
	NSArray<NSString *> *components = [title componentsSeparatedByString:@" "];
	if (components.count >= 2) {
		NSRange firstWordRange = [title rangeOfString:components[0]];
		NSRange secondWordRange = NSMakeRange(NSNotFound, 0);
		if (firstWordRange.location != NSNotFound && (firstWordRange.location + firstWordRange.length < title.length)) {
			NSString *remainingString = [title substringFromIndex:NSMaxRange(firstWordRange)];
			NSRange rangeInRemaining = [remainingString rangeOfString:components[1]];
			if (rangeInRemaining.location != NSNotFound) {
				secondWordRange = NSMakeRange(NSMaxRange(firstWordRange) + rangeInRemaining.location, rangeInRemaining.length);
			}
		}
		
		
		if (firstWordRange.location != NSNotFound) {
			[attributedString addAttribute:NSFontAttributeName value:lightFont range:firstWordRange];
		}
		if (secondWordRange.location != NSNotFound) {
			[attributedString addAttribute:NSFontAttributeName value:boldFont range:secondWordRange];
		} else {
			if (firstWordRange.location != NSNotFound && secondWordRange.location == NSNotFound) {
				NSRange restRange = NSMakeRange(NSMaxRange(firstWordRange), title.length - NSMaxRange(firstWordRange));
				if (restRange.length > 0) {
					[attributedString addAttribute:NSFontAttributeName value:lightFont range:restRange];
				}
			}
		}
		if (firstWordRange.location == NSNotFound && secondWordRange.location == NSNotFound) {
			[attributedString addAttribute:NSFontAttributeName value:lightFont range:fullRange];
		}
	} else {
		[attributedString addAttribute:NSFontAttributeName value:lightFont range:fullRange];
	}
	NSParagraphStyle *paragraphStyle = [NSParagraphStyle newParagraphStyleTitleBar];
	if (paragraphStyle) {
		[attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:fullRange];
	}
	
	[attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fullRange];
	[attributedString addAttribute:NSKernAttributeName value:[NSNull null] range:fullRange];
	
	
	return attributedString;
}

@end
