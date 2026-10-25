//
//  MTTableCell.m
//  MAD
//
//  Created by Michael Thomason on 3/25/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableCell.h"
#import <UIKit/UILabel.h>
#import <QuartzCore/CALayer.h>

@interface MADTableCell ()

	@property (nonatomic, strong, readwrite) UILabel *label;

@end

@implementation MADTableCell

- (void)dealloc {
	_label = nil;
}

- (void)removeFromSuperview {
	[self.label removeFromSuperview];
	[super removeFromSuperview];
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		UILabel *lbl = [[UILabel alloc] initWithFrame:self.contentView.frame];
		lbl.backgroundColor = [UIColor systemBackgroundColor];
		lbl.textColor = [UIColor labelColor];
		
		[self.contentView addSubview:lbl];
		lbl.autoresizingMask = UIViewAutoresizingFlexibleHeight |
								UIViewAutoresizingFlexibleWidth |
								UIViewAutoresizingFlexibleTopMargin |
								UIViewAutoresizingFlexibleBottomMargin |
								UIViewAutoresizingFlexibleRightMargin |
								UIViewAutoresizingFlexibleLeftMargin;
		self.contentView.layer.borderWidth = 1.0000f;
		self.contentView.layer.borderColor = [[UIColor secondarySystemBackgroundColor] CGColor];
		self.label = lbl;
	}
	return self;
}

@end
