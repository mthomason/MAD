//
//  MADPageSlider.m
//  MAD Designer
//
//  Created by Michael Thomason on 2/21/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADPageSlider.h"
#import "MADSliderPageVertical.h"
#import "MADLabelPageSlider.h"
#import <MADFoundation/madlog.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADViewHelpers.h>
#import <UIKit/UILabel.h>
#import <UIKit/NSShadow.h>
#import <UIKit/UITapGestureRecognizer.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSStringDrawing.h>

static const CGFloat MADSliderPaginationWidth = 40.0;

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

	@property (nonatomic, strong, getter=pageSlider) MADSliderPageVertical *slider;
	@property (nonatomic, strong) NSMutableArray <UILabel *> *labels;

@end

@implementation MADPageSlider {
	NSUInteger _numberOfPages;
	CGFloat _stringHeight;
	CGRect _lastRect;
	unsigned long _lastNumberOfTicks;
	BOOL _enabledColor;
}

#pragma mark -
#pragma mark Static Functions

+ (CGSize)BoundsForAttributedString:(NSAttributedString *)string {
	CGRect bounds = [string boundingRectWithSize: CGSizeMake(300.0, CGFLOAT_MAX)
										 options: (NSStringDrawingOptions) (NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
										 context: nil];
	return bounds.size;
}

+ (CGFloat)distanceBetweenTicks:(NSUInteger)numberOfTicks height:(CGFloat)height
						padding:(CGFloat)padding rect:(CGRect)rect {
	return numberOfTicks > 1 ? ((rect.size.height - padding * 2) / (CGFloat)numberOfTicks) - height : CGSizeZero.height;
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
	NSAttributedString *testString = [[NSAttributedString alloc] initWithString:@"0" attributes:@{
		NSFontAttributeName: [UIFont boldSystemFontOfSize:9.0],
		NSStrokeWidthAttributeName: @-1.0
	}];
	CGSize bounds = [MADPageSlider BoundsForAttributedString:testString];
	_stringHeight = bounds.height;
	self.labels = nil;
}

#pragma mark -
#pragma mark View

- (void)layoutSubviews {
	[super layoutSubviews];

	// Calculate the frame this view should have based on its superview.
	CGRect desiredFrame = CGRectMake(self.superview.frame.size.width - MADSliderPaginationWidth,
									 CGPointZero.y,
									 MADSliderPaginationWidth,
									 self.superview.frame.size.height);
	
	// By checking if the frame is already correct, we break the layout-recursion loop.
	if (!CGRectEqualToRect(self.frame, desiredFrame)) {
		self.frame = desiredFrame;
		// After changing our own frame, we must return. The layout system will call
		// this method again with the correct geometry.
		//return;
	}
	
	// Ensure the slider's frame matches the bounds of the view
	//self.pageSlider.frame = self.bounds;

	// Update the frame of the page slider
	//self.frame = CGRectMake(self.superview.frame.size.width - MADSliderPaginationWidth, CGPointZero.y, MADSliderPaginationWidth, self.superview.frame.size.height);

	// Update the slider's frame
	self.pageSlider.frame = CGRectMake(CGPointZero.x, CGPointZero.y, MADSliderPaginationWidth, self.superview.frame.size.height);
	if (self.labels == nil) {
		return;
	}

	// Calculate the number of ticks based on the available height
	CGRect rect = self.bounds;
	unsigned long numberOfTicks = availableLabelSlots(rect.size.height, _stringHeight, self.maximumValue);

	// If the rect and number of ticks haven't changed, return
	//if (CGRectEqualToRect(rect, _lastRect) && numberOfTicks == _lastNumberOfTicks) {
	//	return;
	//}

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
	double tickValue = numberOfTicks > 1 ? self.maximumValue / (float)(numberOfTicks - 1) : 1;
	for (NSUInteger i = 0; i < numberOfTicks; i++) {
		if (i % 2 == 0) {
			MADLabelPageSlider *label = [[MADLabelPageSlider alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, rect.size.width, _stringHeight)];
			label.pageNumber = (NSUInteger)roundl((long double)i * tickValue + 1);
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

//#pragma GCC diagnostic push
//#pragma GCC diagnostic ignored "-Warc-repeated-use-of-weak"
- (MADSliderPageVertical *)pageSlider {
	if (_slider == nil) {
		MADSliderPageVertical *slider = [[MADSliderPageVertical alloc] init];
		[slider addTarget: self action: @selector(handleSliderChangedPage:) forControlEvents: UIControlEventValueChanged];
		[slider addTarget: self action: @selector(handleSliderDidFinishDrag:) forControlEvents: UIControlEventTouchUpInside];
		
		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: self
																			  action: @selector(handleGestureTapSlider:)];
		[slider addGestureRecognizer:tap];
		
		slider.transform = CGAffineTransformRotate(slider.transform, 1.0 / 2.0 * (CGFloat)M_PI);
		self.transform = CGAffineTransformRotate(slider.transform, 3.0 / 2.0 * (CGFloat)M_PI);
		[self addSubview:slider];
		_slider = slider;
	}
	return _slider;
}
//#pragma GCC diagnostic pop

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
	//[self setNeedsLayout];
}

- (NSMutableArray <UILabel *> *)labels {
	if (_labels == nil) {
		NSMutableArray *labels = [[NSMutableArray alloc] initWithCapacity: [self maximumNumberOfLabels]];
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
	if ([NSThread isMainThread]) {
		[self configureEnabledState:enabled];
	} else {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self configureEnabledState:enabled];
		});
	}
}

- (void)configureEnabledState:(BOOL)enabled {
	//if (self.pageSlider.isEnabled == enabled && _enabledColor == enabled) {
	//	return;
	//}
	
	self.pageSlider.enabled = enabled;
	
	if (enabled) {
		self.tintColor = [MADColorEverydayApps newColorRed];
		_enabledColor = YES;
	} else {
		self.tintColor = [UIColor lightGrayColor];
		_enabledColor = NO;
	}
	[self setNeedsDisplay];
}

- (BOOL)isEnabled {
	if (![NSThread isMainThread]) {
		os_log_info(GetDesignerLog(), "Warning: isEnabled called from a background thread.");
	}
	return self.pageSlider.isEnabled;
}

#pragma mark -
#pragma mark Event handlers

- (void)handleSliderChangedPage:(UISlider *)sender {
	[self.sliderDelegate sliderDidChangeToPage:(NSUInteger)lroundf(sender.value)];
}

- (void)handleSliderDidFinishDrag:(UISlider *)sender {
	sender.value = (float)lroundf(sender.value);               // Sets your slider to this value
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
		[slider setValue:slider.minimumValue + (float)(percentage * delta) animated:YES];
		[self handleSliderDidFinishDrag:slider];
		[self handleSliderChangedPage:slider];
	}
}

#pragma mark -
#pragma mark Custom

- (void)rotateBoundingSize:(CGSize)size inContext:(CGContextRef)context {
	CGContextConcatCTM(context, translateForward(size));
	CGContextConcatCTM(context, rotate());
	CGContextConcatCTM(context, translateBack(size));
}

#pragma mark -
#pragma mark Drawing

- (CGRect)drawString:(NSAttributedString *)string atPoint:(CGPoint)point inContext:(CGContextRef)context {
	CGContextSaveGState(context);
	CGSize boundingSize = [MADPageSlider BoundsForAttributedString:string];
	[self rotateBoundingSize:boundingSize inContext:context];
	[string drawAtPoint:point];
	CGContextRestoreGState(context);
	
	return CGRectMake(point.x, point.y, boundingSize.width, boundingSize.height);
}

- (NSUInteger)maximumNumberOfLabels {
	return (NSUInteger)(availableLabelSlots(MaxDimension(self.frame.size), _stringHeight, self.maximumValue) / 2) + 1;
}

#pragma mark -
#pragma mark Debugging

- (NSString *)debugDescription {
	// It's crucial to check if we are on the main thread before accessing UI properties
	// to ensure thread safety in our logging.
	if (![NSThread isMainThread]) {
		__block NSString *descriptionOnMain;
		dispatch_sync(dispatch_get_main_queue(), ^{
			descriptionOnMain = [self debugDescription];
		});
		return descriptionOnMain;
	}
	
	NSString *sliderState = [NSString stringWithFormat:@"enabled: %@, value: %.2f, pages: %lu",
							 self.isEnabled ? @"YES" : @"NO", self.value, (unsigned long)self.numberOfPages];
	return [NSString stringWithFormat:@"<%@: %p> frame: %@; state: {%@}",
			NSStringFromClass([self class]), self, NSStringFromCGRect(self.frame), sliderState];
}

@end
