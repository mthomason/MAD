//
//  NSAttributedString+Logo.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/7/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "NSAttributedString+Logo.h"

#import <UIKit/NSAttributedString.h>
#import <UIKit/UIFont.h>
#import <UIKit/UIColor.h>

#import "NSParagraphStyle+CommonStyles.h"

@implementation MADAttributedStringLogo

+ (instancetype)newLogoStringForTitle:(NSString *)prompt {
	
	NSRange range, firstRange, secondRange;
	NSString *title, *component;
	NSParagraphStyle *paragraphStyle;
	id attributedStringMadDesigner;
	NSArray <NSString *> *components;
	
	title = prompt.copy;
	paragraphStyle = [NSParagraphStyle newParagraphStyleTitleBar];
	attributedStringMadDesigner = [[NSMutableAttributedString alloc] initWithString:title];
	
	range = NSMakeRange(0, ((MADAttributedStringLogo *)attributedStringMadDesigner).string.length);
	components = [title componentsSeparatedByString:@" "];
	
	if (components.count == 2) {
		
		component = components[0];
		firstRange = [title rangeOfString:component];
		
		component = components[1];
		secondRange = [title rangeOfString:component];
		
	} else {
		firstRange = range;
		secondRange = range;
	}
	
	UIFont *font = [UIFont fontWithName: @"HelveticaNeue-Light"
								   size: 20.0000f];

	[attributedStringMadDesigner addAttribute: NSFontAttributeName
										value: font
										range: firstRange];
	
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
