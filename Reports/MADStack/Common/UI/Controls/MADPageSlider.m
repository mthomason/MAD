//
//  MADPageSlider.m
//  MAD Designer
//
//  Created by Michael Thomason on 2/21/16.
//  Copyright © 2020 Everyday Apps LLC. All rights reserved.
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
    //UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    if (self = [super initWithFrame:CGRectZero]) {
        
        self.tintColor = [MADColorEverydayApps newColorBlue];

        UIFont *font = [UIFont boldSystemFontOfSize:9.0];
        NSNumber *strokeWidth = @-1.0;
        NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    font, NSFontAttributeName,
                                    strokeWidth, NSStrokeWidthAttributeName, nil];
        
        NSAttributedString *testString = [[NSAttributedString alloc] initWithString: ConstTestStringValue
                                                                         attributes: attributes];
        
        CGSize bounds = [MADPageSlider BoundsForAttributedString:testString];
        _stringHeight = bounds.height;
        
        self.labels = nil;
        
    }
    return self;
}

#pragma mark -
#pragma mark View

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.pageSlider.frame = self.bounds;
    
    self.frame = CGRectMake(self.superview.frame.size.width - MADSliderPaginationWidth,
                            CGPointZero.y,
                            MADSliderPaginationWidth,
                            self.superview.frame.size.height);
    
    self.pageSlider.frame = CGRectMake(CGPointZero.x, CGPointZero.y,
                                       MADSliderPaginationWidth, self.superview.frame.size.height);

    if (self.labels == nil) {
        return;
    }
    
    CGRect rect = self.bounds;
    unsigned long numberOfTicks = availableLabelSlots(rect.size.height,
                                                      _stringHeight,
                                                      self.maximumValue);
    
    if (CGRectEqualToRect(rect, _lastRect) && numberOfTicks == _lastNumberOfTicks) {
        return;
    }
    
    _lastRect = rect;
    _lastNumberOfTicks = numberOfTicks;
    
    for (UIView *label in self.labels) {
        [label removeFromSuperview];
    }
    [self.labels removeAllObjects];

    static CGFloat offsetTopBottom = 8.0;
    CGFloat distanceBetweenTicks = [MADPageSlider distanceBetweenTicks:numberOfTicks height:_stringHeight
                                                               padding:offsetTopBottom rect:rect];;
    CGPoint drawingPoint = CGPointMake(rect.origin.x, rect.origin.y);
    double tickValue = self.maximumValue / (numberOfTicks - 1);
    for (NSUInteger i=0; i<numberOfTicks; i++) {
        if (i % 2 == 0) {
            
            @autoreleasepool {
                MADLabelPageSlider *label;
                label = [[MADLabelPageSlider alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y,
                                                                             rect.size.width, _stringHeight)];
                label.pageNumber = (NSUInteger)roundl(i * tickValue + 1);
                label.enabled = _enabledColor;
                [label translateToPoint:CGPointMake(drawingPoint.x, drawingPoint.y + offsetTopBottom)];
                [self addSubview:label];
                [self.labels addObject:label];
            }
        }
        drawingPoint = CGPointMake(drawingPoint.x,
                                   drawingPoint.y + _stringHeight + distanceBetweenTicks);
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
    UISlider *slider = (UISlider *)tap.view;
    if (slider.highlighted == NO) {
        CGPoint pt = [tap locationInView: slider];
        [slider setValue: slider.minimumValue +
                          ((float)(pt.x / slider.bounds.size.width)         //Percentage
                           * (slider.maximumValue - slider.minimumValue))   //delta
                animated: YES];
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

- (NSUInteger)maximumNumberOfLabels {
    return availableLabelSlots(MaxDimension(self.frame.size), _stringHeight, self.maximumValue) / 2.0 + 1.0;
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

@end

#pragma mark -
#pragma mark Static functions

inline static double numberOfTicksCalc(CGFloat viewSizeHeight, CGFloat elementSizeHeight) {
    return viewSizeHeight / elementSizeHeight;
}

inline static unsigned long availableLabelSlots(CGFloat viewSizeHeight, CGFloat elementSizeHeight, float maximumValue) {
    if (numberOfTicksCalc(viewSizeHeight, elementSizeHeight) <= 0) {
        return 0;
    } else if (numberOfTicksCalc(viewSizeHeight, elementSizeHeight) > maximumValue) {
        return (unsigned long)floor(maximumValue);
    } else {
        return (unsigned long)numberOfTicksCalc(viewSizeHeight, elementSizeHeight) - 1;
    }
}

static inline CGFloat MaxDimension(CGSize size) {
    return MAX(size.width, size.height);
}

static inline CGAffineTransform translateForward(CGSize size) {
    return CGAffineTransformMakeTranslation(size.width / 2.0, size.width / 2.0);
}

static inline CGAffineTransform rotate() {
    return CGAffineTransformMakeRotation(3.0 / 2.0 * M_PI);
}

static inline CGAffineTransform translateBack(CGSize size) {
    return CGAffineTransformMakeTranslation(-size.width / 2.0, -size.width / 2.0);
}
