//
//  MADPageSlider.m
//  MAD Designer
//
//  Created by Michael Thomason on 2/21/16.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADPageSlider.h"

#import <UIKit/UILabel.h>
#import <UIKit/NSShadow.h>
#import <UIKit/UITapGestureRecognizer.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSStringDrawing.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADViewHelpers.h>

#import "MADSliderPageVertical.h"
#import "MADPageSliderProtocol.h"
#import "MADLabelPageSlider.h"

static const CGFloat MADSliderPaginationWidth = 40.0;
static NSString * const ConstTestStringValue = @"0";
inline static double numberOfTicksCalc(CGFloat viewSizeHeight, CGFloat elementSizeHeight);
inline static unsigned long availableLabelSlots(CGFloat viewSizeHeight, CGFloat elementSizeHeight, float maximumValue);
static inline CGFloat MaxDimension(CGSize size);
static inline CGAffineTransform translateForward(CGSize size);
static inline CGAffineTransform rotate(void);
static inline CGAffineTransform translateBack(CGSize size);

#pragma mark -
#pragma mark Static functions

static inline double numberOfTicksCalc(CGFloat viewHeight, CGFloat elementHeight) { return viewHeight / elementHeight; }
static inline CGFloat MaxDimension(CGSize size) { return MAX(size.width, size.height); }
static inline CGAffineTransform translateForward(CGSize size) { return CGAffineTransformMakeTranslation(size.width / 2.0, size.width / 2.0); }
static inline CGAffineTransform rotate(void) { return CGAffineTransformMakeRotation(3.0 / 2.0 * M_PI); }
static inline CGAffineTransform translateBack(CGSize size) { return CGAffineTransformMakeTranslation(-size.width / 2.0, -size.width / 2.0); }

static inline unsigned long availableLabelSlots(CGFloat viewSizeHeight, CGFloat elementSizeHeight, float maximumValue) {
	double tickCount = numberOfTicksCalc(viewSizeHeight, elementSizeHeight);
	if (tickCount <= 0) {
		return 0;
	} else if (tickCount > maximumValue) {
		return (unsigned long)floor(maximumValue);
	} else {
		return (unsigned long)MAX(1, tickCount) - 1;
	}
}

@interface MADPageSlider ()

	@property (nonatomic, weak, getter=pageSlider) MADSliderPageVertical *slider;
	@property (nonatomic, strong) NSMutableArray <UILabel *> *labels;

@end

@implementation MADPageSlider {
	NSUInteger _numberOfPages;
	CGFloat _stringHeight;
	CGRect _lastRect;
	unsigned long _lastNumberOfTicks;
	BOOL _enabledColor;
}

+ (CGSize)BoundsForAttributedString:(NSAttributedString *)string {
	CGRect bounds = [string boundingRectWithSize: CGSizeMake(300.0, CGFLOAT_MAX)
										 options: (NSStringDrawingOptions)
					 (NSStringDrawingUsesLineFragmentOrigin |
					  NSStringDrawingUsesFontLeading)
										 context: nil];
	return CGSizeMake(bounds.size.width, bounds.size.height);
}

+ (CGFloat)distanceBetweenTicks:(NSUInteger)numberOfTicks height:(CGFloat)height
						padding:(CGFloat)padding rect:(CGRect)rect {
	return numberOfTicks > 1 ?
				((rect.size.height - padding * 2) / numberOfTicks) - height :
				CGSizeZero.height;
}

#pragma mark -
#pragma mark Object

- (void)dealloc {
	_sliderDelegate = nil;
	[_labels removeAllObjects];
}

- (instancetype)init {
	if (self = [super initWithFrame:CGRectZero]) {
		[self setupSliderAppearance];
		[self setupLabelAttributes];
	}
	return self;
}

- (void)setupSliderAppearance {
	self.tintColor = [MADColorEverydayApps newColorBlue];
}

- (void)setupLabelAttributes {
	UIFont *font = [UIFont boldSystemFontOfSize:9.0];
	NSNumber *strokeWidth = @-1.0;
	NSDictionary *attributes = @{
		NSFontAttributeName: font,
		NSStrokeWidthAttributeName: strokeWidth
	};

	NSAttributedString *testString = [[NSAttributedString alloc] initWithString:ConstTestStringValue
																	attributes:attributes];
	CGSize bounds = [MADPageSlider BoundsForAttributedString:testString];
	_stringHeight = bounds.height;
	self.labels = nil;
}

#pragma mark -
#pragma mark View

- (void)layoutSubviews {
	[super layoutSubviews];

	// Ensure the slider's frame matches the bounds of the view
	self.pageSlider.frame = self.bounds;

	// Update the frame of the page slider
	self.frame = CGRectMake(self.superview.frame.size.width - MADSliderPaginationWidth,
							CGPointZero.y,
							MADSliderPaginationWidth,
							self.superview.frame.size.height);

	// Update the slider's frame
	self.pageSlider.frame = CGRectMake(CGPointZero.x, CGPointZero.y,
									   MADSliderPaginationWidth, self.superview.frame.size.height);

	// If labels are not initialized, return
	if (self.labels == nil) {
		return;
	}

	// Calculate the number of ticks based on the available height
	CGRect rect = self.bounds;
	unsigned long numberOfTicks = availableLabelSlots(rect.size.height,
													 _stringHeight,
													 self.maximumValue);

	// If the rect and number of ticks haven't changed, return
	if (CGRectEqualToRect(rect, _lastRect) && numberOfTicks == _lastNumberOfTicks) {
		return;
	}

	// Update the last rect and number of ticks
	_lastRect = rect;
	_lastNumberOfTicks = numberOfTicks;

	// Remove existing labels
	for (UIView *label in self.labels) {
		[label removeFromSuperview];
	}
	[self.labels removeAllObjects];

	// Calculate the distance between ticks
	static CGFloat offsetTopBottom = 8.0;
	CGFloat distanceBetweenTicks = [MADPageSlider distanceBetweenTicks:numberOfTicks height:_stringHeight
															  padding:offsetTopBottom rect:rect];

	// Position the labels
	CGPoint drawingPoint = CGPointMake(rect.origin.x, rect.origin.y);
	double tickValue = numberOfTicks > 0 ? self.maximumValue / (numberOfTicks - 1) : 1;
	for (NSUInteger i = 0; i < numberOfTicks; i++) {
		if (i % 2 == 0) {
			MADLabelPageSlider *label = [[MADLabelPageSlider alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y,
																							 rect.size.width, _stringHeight)];
			label.pageNumber = (NSUInteger)roundl(i * tickValue + 1);
			label.enabled = _enabledColor;
			[label translateToPoint:CGPointMake(drawingPoint.x, drawingPoint.y + offsetTopBottom)];
			[self addSubview:label];
			[self.labels addObject:label];
		}
		drawingPoint.y = drawingPoint.y +  _stringHeight + distanceBetweenTicks;
	}
}

- (void)didMoveToWindow {
	[super didMoveToWindow];
	if (self.window == nil) {
		for (UILabel *label in self.labels) {
			[label removeFromSuperview];
		}
		_lastNumberOfTicks = 0;
		[self.pageSlider removeFromSuperview];
		[self.labels removeAllObjects];
		_slider = nil;
	}
}

#pragma mark -
#pragma mark Lazy load

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warc-repeated-use-of-weak"
- (MADSliderPageVertical *)pageSlider {
	if (_slider == nil) {
		MADSliderPageVertical *slider = [[MADSliderPageVertical alloc] init];
		[slider addTarget: self action: @selector(handleSliderChangedPage:)
		 forControlEvents: UIControlEventValueChanged];
		
		[slider addTarget: self action: @selector(handleSliderDidFinishDrag:)
		 forControlEvents: UIControlEventTouchUpInside];
		
		UITapGestureRecognizer *tap;
		tap = [[UITapGestureRecognizer alloc] initWithTarget: self
													  action: @selector(handleGestureTapSlider:)];
		[slider addGestureRecognizer:tap];
		
		slider.transform = CGAffineTransformRotate(slider.transform, 1.0 / 2.0 * (CGFloat)M_PI);
		self.transform = CGAffineTransformRotate(slider.transform, 3.0 / 2.0 * (CGFloat)M_PI);
		[self addSubview:slider];
		_slider = slider;
	}
	return _slider;
}
#pragma GCC diagnostic pop

#pragma mark -
#pragma mark Page slider wrappers

- (float)value {
	return self.pageSlider.value;
}

- (void)setValue:(float)value {
	self.pageSlider.value = value;
}

- (float)minimumValue {
	return self.slider.minimumValue;
}

- (void)setMinimumValue:(float)minimumValue {
	if (self.pageSlider.minimumValue != minimumValue || minimumValue == 0.0) {
		_lastNumberOfTicks = 0;
	}
	self.pageSlider.minimumValue = minimumValue;
	[self setNeedsLayout];
}

- (float)maximumValue {
	return self.pageSlider.maximumValue;
}

- (void)setNumberOfPages:(NSUInteger)numberOfPages {
	UISlider *s = self.slider;
	s.maximumValue = (float)(numberOfPages > 0 ? numberOfPages - 1 : 0);
	s.minimumValue = (float)0;
	_numberOfPages = numberOfPages;
	[self setNeedsLayout];
}

- (NSMutableArray <UILabel *> *)labels {
	if (_labels == nil) {
		NSMutableArray *labels;
		labels = [[NSMutableArray alloc] initWithCapacity: [self maximumNumberOfLabels]];
		_labels = labels;
	}
	return _labels;
}

- (void)setMaximumValue:(float)maximumValue {
	if ((int)roundf(self.pageSlider.minimumValue) != (int)roundf(maximumValue) &&
		(int)roundf(self.pageSlider.minimumValue) != (int)roundf(maximumValue) == 0) {
		_lastNumberOfTicks = 0;
	}
	self.pageSlider.maximumValue = maximumValue;
	[self setNeedsLayout];
}

- (void)setEnabled:(BOOL)enabled {
	self.pageSlider.enabled = enabled;
	if (self.pageSlider.enabled) {
		self.tintColor = [MADColorEverydayApps newColorRed];
		[self setDisplayEnabled];
		
	} else {
		self.tintColor = [UIColor lightGrayColor];
		[self setDisplayDisabled];
	}
}

- (BOOL)isEnabled {
	return self.pageSlider.isEnabled;
}

#pragma mark -
#pragma mark Event handlers

- (void)handleSliderChangedPage:(UISlider *)sender {
	[self.sliderDelegate sliderDidChangeToPage:(NSUInteger)lroundf(sender.value)];
}

- (void)handleSliderDidFinishDrag:(UISlider *)sender {
	sender.value = lroundf(sender.value);               // Sets your slider to this value
}

- (void)handleGestureTapSlider:(UIGestureRecognizer *)tap {
	if (![tap.view isKindOfClass:[UISlider class]]) {
		return; // Ensure the view is a UISlider
	}

	UISlider *slider = (UISlider *)tap.view;
	if (!slider.highlighted) {
		CGPoint pt = [tap locationInView:slider];
		CGFloat percentage = pt.x / slider.bounds.size.width;
		CGFloat delta = slider.maximumValue - slider.minimumValue;
		CGFloat newValue = slider.minimumValue + (percentage * delta);
		[slider setValue:(float)newValue animated:YES];
		[self handleSliderDidFinishDrag:slider];
		[self handleSliderChangedPage:slider];
	}
}

#pragma mark -
#pragma mark Custom

- (void)setDisplayEnabled {
	_enabledColor = YES;
}

- (void)setDisplayDisabled {
	_enabledColor = NO;
}

- (void)rotateBoundingSize:(CGSize)size inContext:(CGContextRef)context {
	CGContextConcatCTM(context, translateForward(size));
	CGContextConcatCTM(context, rotate());
	CGContextConcatCTM(context, translateBack(size));
}

#pragma mark Drawing

- (CGRect)drawString:(NSAttributedString *)string atPoint:(CGPoint)point
		   inContext:(CGContextRef)context {
	
	CGSize boundingSize;
	CGContextSaveGState(context);
	boundingSize = [MADPageSlider BoundsForAttributedString:string];
	[self rotateBoundingSize:boundingSize inContext:context];
	[string drawAtPoint:point];
	CGContextRestoreGState(context);
	
	return CGRectMake(point.x, point.y, boundingSize.width, boundingSize.height);
	
}

- (NSUInteger)maximumNumberOfLabels {
	return (NSUInteger)(availableLabelSlots(MaxDimension(self.frame.size), _stringHeight, self.maximumValue) / 2) + 1;
}

@end
