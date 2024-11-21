//
//  MADPageStatusView.m
//  MAD Designer
//
//  Created by Michael on 3/1/17.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADPageStatusView.h"
#import <UIKit/UILabel.h>

@interface MADPageStatusView ()

	@property (nonatomic, weak) UILabel *labelView;

@end

@implementation MADPageStatusView

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		UIColor *bgColor = [[UIColor alloc] initWithWhite: 0.0 alpha: 0.5];
		self.backgroundColor = bgColor;
		self.userInteractionEnabled = NO;
		self.alpha = 0.0;
		self.layer.cornerRadius =  6.0;
		
		UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x,
																	   CGPointZero.y,
																	   frame.size.width,
																	   frame.size.height)];
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
	NSString *text = [[NSString alloc] initWithFormat: @"%lu of %lu", page, total];
	self.labelView.text = text;
}

@end
