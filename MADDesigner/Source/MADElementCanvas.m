//
//  MADElementCanvas.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADElementCanvas.h"
#import <MADCocoaExtensions/MADColor.h>
#import <UIKit/UIGraphics.h>

@implementation MADElementCanvas

- (void)dealloc {
	_canvasDelegate = nil;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect: rect];
	
	id displayObject = [self.canvasDelegate displayObject];
	
	if ([displayObject isKindOfClass: [NSAttributedString class]]) {
		[displayObject drawWithRect: rect
							options: NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
							context: nil];
	} else if ([displayObject isKindOfClass: [MADBarcode class]]) {
		[displayObject loadSampleData];
		//MADColor *color = [[MADColor alloc] initWithColor:[UIColor lightGrayColor]];
		//((MADBarcode *)displayObject).forgroundColor = color;
	} else {
		[displayObject drawInRect:rect];
	}
	
	static const CGFloat kDashedBorderWidth     = (0.5f);
	static const CGFloat kDashedPhase           = (0.0f);
	static const CGFloat kDashedLinesLength[]   = {4.0f, 2.0f};
	static size_t const kDashedCount            = (2.0f);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, kDashedBorderWidth);
	UIColor *tintColor = [UIColor blackColor];
	CGContextSetStrokeColorWithColor(context, tintColor.CGColor);
	CGContextSetLineDash(context, kDashedPhase, kDashedLinesLength, kDashedCount) ;
	CGContextAddRect(context, rect);
	CGContextStrokePath(context);
}

@end
