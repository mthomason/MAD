//
//  MTTableCellHeader.m
//  MAD
//
//  Created by Michael Thomason on 3/25/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTTableCellHeader.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <UIKit/UILabel.h>
#import <QuartzCore/CALayer.h>

@interface MADTableCellHeader ()

@property (nonatomic, strong, readwrite) UILabel *label;

@end

@implementation MADTableCellHeader

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initialize];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initialize];
	}
	return self;
}

- (instancetype)init {
	if (self = [super init]) {
		[self initialize];
	}
	return self;
}

- (void)initialize {
	UILabel *lbl = [[UILabel alloc] initWithFrame:self.bounds];
	lbl.backgroundColor = [MADColorEverydayApps blueHeaderSecondaryColor];
	lbl.textColor = [UIColor labelColor];
	lbl.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin |
						   UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	[self addSubview:lbl];
	self.label = lbl;
	self.layer.borderWidth = 1.0000f;
	self.layer.borderColor = [[UIColor secondarySystemBackgroundColor] CGColor];
}

@end
