//
//  MADLabelTitle.m
//  MAD Designer
//
//  Created by Michael on 1/5/17.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADLabelTitle.h"
#import <UIKit/UILabel.h>
#import "MADAttributedStringLogo.h"
#import "MADViewHelpers.h"

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

	NSString *safetext = text.copy;
	
	MADAttributedStringLogo *attributedText;
	attributedText = [MADAttributedStringLogo newLogoStringForTitle:safetext];
	
	UILabel *title = self.title;
	text = safetext;
	title.attributedText = attributedText;

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

@end
