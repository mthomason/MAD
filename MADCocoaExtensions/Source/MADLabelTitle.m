//
//  MADLabelTitle.m
//  MAD Designer
//
//  Created by Michael on 1/5/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADLabelTitle.h"
#import "MADViewHelpers.h"

#import <UIKit/UILabel.h>
#import <UIKit/NSAttributedString.h>

@interface MADLabelTitle ()
@property (nonatomic, weak) UILabel *title;
@end

@implementation MADLabelTitle

- (instancetype)initWithFrame:(CGRect)frame {

	UILabel *title = [[UILabel alloc] initWithFrame:frame];
	title.autoresizingMask = MADViewAutoresizingFlexable();
	title.translatesAutoresizingMaskIntoConstraints = YES;
	title.lineBreakMode = NSLineBreakByTruncatingTail;
	title.numberOfLines = 1;
	title.minimumScaleFactor = 0.80000000f;
	title.adjustsFontSizeToFitWidth = YES;
	[title sizeToFit];

	if (self = [super initWithFrame:title.frame]) {
		[self addSubview:title];
		self.title = title;
	}
	return self;
}

- (void)setText:(NSString *)text {

	NSString *safetext = [text copy];
	UILabel *title = self.title;
	title.attributedText = [MADLabelTitle logoAttributedStringForTitle:safetext];
	[title sizeToFit];
	self.bounds = title.bounds;
}

- (NSString *)text {
	return self.title.text;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	self.title.frame = self.bounds;
}

- (CGSize)intrinsicContentSize {
	[super intrinsicContentSize];
	return UILayoutFittingExpandedSize;
}

+ (NSAttributedString *)logoAttributedStringForTitle:(NSString *)title {
	if (!title || title.length == 0) {
		return [[NSAttributedString alloc] initWithString:@""];
	}
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:title];
	NSRange fullRange = NSMakeRange(0, title.length);
	UIFont *lightFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0];
	UIFont *boldFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
	
	if (!lightFont) {
		lightFont = [UIFont systemFontOfSize:20.0 weight:UIFontWeightLight];
	}
	if (!boldFont) {
		boldFont = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];
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
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = NSTextAlignmentNatural;
	[attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:fullRange];
	[attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:fullRange];
	[attributedString addAttribute:NSKernAttributeName value:[NSNull null] range:fullRange];
	
	return attributedString;
}


@end
