//
//  MADPageStatusView.m
//  MAD Designer
//
//  Created by Michael on 3/1/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADPageStatusView.h"
#import <UIKit/UILabel.h>

@interface MADPageStatusView ()

	@property (nonatomic, weak) UILabel *labelView;

@end

@implementation MADPageStatusView

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
		self.userInteractionEnabled = NO;
		self.alpha = 0.0;
		self.layer.cornerRadius =  6.0;
		UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
		labelView.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] + 1.0];
		labelView.textColor = [UIColor whiteColor];
		labelView.textAlignment = NSTextAlignmentCenter;
		labelView.userInteractionEnabled = NO;
		labelView.backgroundColor = [UIColor clearColor];
		[self addSubview:labelView];
		self.labelView = labelView;
	}
	return self;
}

- (void)setPage:(NSUInteger)page ofTotal:(NSUInteger)total {
	self.labelView.text = [[NSString alloc] initWithFormat:
		NSLocalizedString(@"%1$lu of %2$lu", @"Page status; %1$lu is the current page, %2$lu the total."),
		(unsigned long)page, (unsigned long)total];
}

@end
