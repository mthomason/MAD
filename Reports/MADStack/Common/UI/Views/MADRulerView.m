//
//  UIViewRuler.m
//  Reports
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADRulerView.h"

#import <QuartzCore/CALayer.h>

#import <UIKit/UIGraphics.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSParagraphStyle.h>
#import <UIKit/NSStringDrawing.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "UIView+Extras.h"

const CGFloat MTReportDesignerRulerHeight           = 20.0;

static inline double xPoint(NSInteger, double);
static inline double cmInPoints(void);
static inline double eigthInchInPoints(void);

static inline double cmInPoints(void) { return (72.0 / 1.0) / 2.54; }
static inline double eigthInchInPoints(void) { return 72.0 / 8.0; }
static inline double xPoint(NSInteger i, double offset) { return i * offset; }

@interface MADRulerView ()
	@property (readwrite, nonatomic, strong) NSParagraphStyle *paragraphStyle;
	@property (readwrite, nonatomic, strong) UIFontDescriptor *fontDescriptor;
@end

@implementation MADRulerView


- (instancetype)init {
	return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		UIFontDescriptor *fontDescriptor;
		NSMutableParagraphStyle *paragraphStyle;
		
		self.layer.borderWidth = [UIView borderWidthThin];
		self.layer.borderColor = [UIColor blackColor].CGColor;
		self.backgroundColor = [UIColor whiteColor];
		
		self.layer.borderWidth = [UIView borderWidthThin];
		self.layer.borderColor = [MADColorEverydayApps newColorBorderColor].CGColor;
		self.translatesAutoresizingMaskIntoConstraints = NO;
		
		paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		paragraphStyle.lineBreakMode = NSLineBreakByClipping;
		paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
		paragraphStyle.alignment = NSTextAlignmentCenter;
		
		self.paragraphStyle = paragraphStyle;
		
		fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1];
		self.fontDescriptor = fontDescriptor;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect: rect];
	
	CGContextRef currentContext = UIGraphicsGetCurrentContext();
	CGMutablePathRef pathInchMarks = CGPathCreateMutable();
	UIFont *font = [UIFont fontWithDescriptor:_fontDescriptor size:5.0];
	NSDictionary *attributes;
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
				  font, NSFontAttributeName,
				  _paragraphStyle, NSParagraphStyleAttributeName, nil];
	
	NSString *s;
	CGFloat length;
	CGRect locationRect;
	CGFloat thinLineWidth = 1.0 / self.traitCollection.displayScale;
	static const CGFloat lineWidth = 1.0;
	for (NSInteger i = (NSInteger)CGPointZero.x; i < rect.size.width / eigthInchInPoints(); i++) {
		@autoreleasepool {
			if ((i % 8) == 0) {
				locationRect = CGRectMake((CGFloat)xPoint(i, eigthInchInPoints()) - 5.0,
										  rect.size.height - 8.0,
										  10.0, 5.0);
				s = [[NSString alloc] initWithFormat:@"%Lf", (long)i / 8.0L];
				[s drawInRect:locationRect withAttributes:attributes];
				length = 1.0;
				CGContextSetLineWidth(currentContext, lineWidth * 2.0);
			} else if (i % 2) {
				length = 4.0;
				CGContextSetLineWidth(currentContext, thinLineWidth);
			} else if (i % 4) {
				length = 3.0;
				CGContextSetLineWidth(currentContext, thinLineWidth);
			} else {
				length = 2.0;
				CGContextSetLineWidth(currentContext, thinLineWidth);
			}
			CGPathMoveToPoint(pathInchMarks, NULL, (CGFloat)xPoint(i, eigthInchInPoints()), rect.size.height);
			CGPathAddLineToPoint(pathInchMarks, NULL, (CGFloat)xPoint(i, eigthInchInPoints()), rect.size.height - length);
		}
	}
	
	font = [font fontWithSize: 4.0];
	attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
				  font, NSFontAttributeName,
				  _paragraphStyle, NSParagraphStyleAttributeName, nil];
	CGFloat offsetInPoints = (72.0 / 2.54) / 10.0;   //One cm
	CGMutablePathRef pathCmMarks = CGPathCreateMutable();
	for (NSInteger i = (NSInteger)CGPointZero.x; i < rect.size.width / offsetInPoints; i++) {
		@autoreleasepool {
			if ((i % 10) == 0) {
				locationRect = CGRectMake((CGFloat)xPoint(i, cmInPoints() / 10.0) - 5.0,
										  1.0, 10.0, 5.0);
				s = [[NSString alloc] initWithFormat:@"%Lf", (long)i / 10.0L];
				[s drawInRect:locationRect withAttributes:attributes];
				length = 2.0;
				CGContextSetLineWidth(currentContext, lineWidth * 2.0);
			} else if (i % 5) {
				length = 2.0;
				CGContextSetLineWidth(currentContext, thinLineWidth);
			} else {
				length = 3.0;
				CGContextSetLineWidth(currentContext, thinLineWidth);
			}
			CGPathMoveToPoint(pathCmMarks, NULL, (CGFloat)xPoint(i, offsetInPoints), CGPointZero.y);
			CGPathAddLineToPoint(pathCmMarks, NULL, (CGFloat)xPoint(i, offsetInPoints), CGPointZero.y + length);
		}
	}
	
	CGContextAddPath(currentContext, pathCmMarks);
	CGContextAddPath(currentContext, pathInchMarks);
	
	[[UIColor blackColor] setStroke];
	
	CGContextDrawPath(currentContext, kCGPathStroke);
	
	CGPathRelease(pathInchMarks);
	CGPathRelease(pathCmMarks);
	
}

- (CGSize)intrinsicContentSize {
	return CGSizeMake(self.bounds.size.width, MTReportDesignerRulerHeight);
}

- (BOOL)isAccessibilityElement {
	return NO;
}

@end
