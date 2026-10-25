//
//  MADDesignerSectionControl.m
//  Reports
//
//  Created by Michael Thomason on 4/30/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDesignerSectionControl.h"
#import <UIKit/UIGraphics.h>

@implementation MADDesignerSectionControl

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect: rect];
	
	[[UIColor blackColor] setStroke];
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
	CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
	CGContextClosePath(context);
	CGContextDrawPath(context, kCGPathStroke);
}

@end
