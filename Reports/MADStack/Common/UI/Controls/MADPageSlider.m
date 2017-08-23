//
//  MADPageSlider.m
//  MAD Designer
//
//  Created by Michael Thomason on 2/21/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADPageSlider.h"

#import <UIKit/UILabel.h>
#import <UIKit/NSShadow.h>
#import <UIKit/UITapGestureRecognizer.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSStringDrawing.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/UIView+Animations.h>

#import "MADSliderPageVertical.h"
#import "MADPageSliderProtocol.h"
#import "MADLabelPageSlider.h"

static const CGFloat MADSliderPaginationWidth = 40.0000f;
static NSString * const ConstTestStringValue = @"0";

inline static double numberOfTicksCalc(CGFloat viewSizeHeight, CGFloat elementSizeHeight);
inline static double numberOfTicksCalc(CGFloat viewSizeHeight, CGFloat elementSizeHeight) {
    return viewSizeHeight / elementSizeHeight;
}

inline static unsigned long availableLabelSlots(CGFloat viewSizeHeight, CGFloat elementSizeHeight, float maximumValue);
inline static unsigned long availableLabelSlots(CGFloat viewSizeHeight, CGFloat elementSizeHeight, float maximumValue) {
    if (numberOfTicksCalc(viewSizeHeight, elementSizeHeight) <= 0) {
        return 0;
    } else if (numberOfTicksCalc(viewSizeHeight, elementSizeHeight) > maximumValue) {
        return (unsigned long)floor(maximumValue);
    } else {
        return (unsigned long)numberOfTicksCalc(viewSizeHeight, elementSizeHeight) - 1;
    }
}

static inline CGFloat MaxDimension(CGSize size);
static inline CGFloat MaxDimension(CGSize size) {
    return MAX(size.width, size.height);
}

@interface MADPageSlider ()

    @property (nonatomic, assign) CGFloat stringHeight;

    @property (nonatomic, assign) CGRect lastRect;
    @property (nonatomic, assign) unsigned long lastNumberOfTicks;

    @property (nonatomic, assign) BOOL enabledColor;

    @property (nonatomic, weak, getter=pageSlider) MADSliderPageVertical *slider;
    @property (nonatomic, weak) UIVisualEffectView *vibrancyView;
    @property (nonatomic, strong) NSMutableArray <UILabel *> *labels;

@end

@implementation MADPageSlider

+ (CGSize)BoundsForAttributedString:(NSAttributedString *)string {
    CGRect bounds = [string boundingRectWithSize: CGSizeMake(300.0000f, CGFLOAT_MAX)
                                         options: (NSStringDrawingOptions)
                     (NSStringDrawingUsesLineFragmentOrigin |
                      NSStringDrawingUsesFontLeading)
                                         context: nil];
    return CGSizeMake(bounds.size.width, bounds.size.height);
}

#pragma mark -
#pragma mark Object

- (void)dealloc {
    _sliderDelegate = nil;
    [_labels removeAllObjects];
}

- (instancetype)init {
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    if (self = [super initWithEffect:effect]) {
        
        self.contentView.tintColor = [UIColor blueColor];
        /*
        UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:effect];
        UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        vibrancyView.frame = self.frame;
        vibrancyView.autoresizingMask = MADViewAutoresizingFlexable();
        vibrancyView.contentView.tintColor = [UIColor redColor];
        [self.contentView addSubview:vibrancyView];
        self.vibrancyView = vibrancyView;
        
        MADSliderPageVertical *slider = [[MADSliderPageVertical alloc] init];
        [slider addTarget: self action: @selector(handleSliderChangedPage:)
         forControlEvents: UIControlEventValueChanged];
        
        [slider addTarget: self action: @selector(handleSliderDidFinishDrag:)
         forControlEvents: UIControlEventTouchUpInside];
        
        UITapGestureRecognizer *tapGestureRecognizer;
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                       action: @selector(handleGestureTapSlider:)];
        [slider addGestureRecognizer:tapGestureRecognizer];
        
        slider.transform = CGAffineTransformRotate(slider.transform, 1.0000f / 2.0000f * (CGFloat)M_PI);
        self.transform = CGAffineTransformRotate(slider.transform, 3.0000f / 2.0000f * (CGFloat)M_PI);
        [self.contentView addSubview:slider];
        
        UIColor *lightBlue = [MADColorEverydayApps newColorBlueLight];
        self.backgroundColor = [lightBlue colorWithAlphaComponent:0.3333f];
        
        self.slider = slider;
        */
        UIFont *font = [UIFont boldSystemFontOfSize:9.0000f];
        NSNumber *strokeWidth = @-1.0000f;
        NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    font, NSFontAttributeName,
                                    strokeWidth, NSStrokeWidthAttributeName, nil];
        
        NSAttributedString *testString = [[NSAttributedString alloc] initWithString: ConstTestStringValue
                                                                         attributes: attributes];
        
        CGSize bounds = [MADPageSlider BoundsForAttributedString:testString];
        self.stringHeight = bounds.height;
        
        self.labels = nil;
        
    }
    return self;
}

#pragma mark -
#pragma mark Lazy load

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warc-repeated-use-of-weak"
- (UIVisualEffectView *)vibrancyView {
    if (_vibrancyView == nil) {
        NSAssert([self.effect isKindOfClass:[UIBlurEffect class]], @"We expect a blur effect.");
        UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:(UIBlurEffect *)self.effect];
        UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        vibrancyView.frame = self.frame;
        vibrancyView.autoresizingMask = MADViewAutoresizingFlexable();
        vibrancyView.contentView.tintColor = [UIColor redColor];
        [self.contentView addSubview:vibrancyView];
        _vibrancyView = vibrancyView;
    }
    return _vibrancyView;
}
#pragma GCC diagnostic pop

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warc-repeated-use-of-weak"
- (MADSliderPageVertical *)pageSlider {
    if (_slider == nil) {
        MADSliderPageVertical *slider = [[MADSliderPageVertical alloc] init];
        [slider addTarget: self action: @selector(handleSliderChangedPage:)
         forControlEvents: UIControlEventValueChanged];
        
        [slider addTarget: self action: @selector(handleSliderDidFinishDrag:)
         forControlEvents: UIControlEventTouchUpInside];
        
        UITapGestureRecognizer *tapGestureRecognizer;
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                       action: @selector(handleGestureTapSlider:)];
        [slider addGestureRecognizer:tapGestureRecognizer];
        
        slider.transform = CGAffineTransformRotate(slider.transform, 1.0000f / 2.0000f * (CGFloat)M_PI);
        self.transform = CGAffineTransformRotate(slider.transform, 3.0000f / 2.0000f * (CGFloat)M_PI);
        [self.contentView addSubview:slider];
        _slider = slider;
    }
    return _slider;
}
#pragma GCC diagnostic pop

#pragma mark -
#pragma mark View

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.vibrancyView.frame = self.bounds;
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
                                                      self.stringHeight,
                                                      self.maximumValue);
    
    if (CGRectEqualToRect(rect, self.lastRect) && numberOfTicks == self.lastNumberOfTicks) {
        return;
    }
    
    self.lastRect = rect;
    self.lastNumberOfTicks = numberOfTicks;
    
    for (UIView *label in self.labels) {
        [label removeFromSuperview];
    }
    [self.labels removeAllObjects];
    static CGFloat offsetTopBottom = 8.0000f;

    CGFloat distanceBetweenTicks = [MADPageSlider distanceBetweenTicks:numberOfTicks height:_stringHeight
                                                               padding:offsetTopBottom rect:rect];;
    CGPoint drawingPoint = CGPointMake(rect.origin.x, rect.origin.y);
    
    double tickValue = self.maximumValue / (numberOfTicks - 1);
    

    typeof(self) __weak weakself = self;
    for (NSUInteger i=0; i<numberOfTicks; i++) {
        if (i % 2 == 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                @autoreleasepool {
                    typeof(self) strongself = weakself;
                    
                    MADLabelPageSlider *label;
                    label = [[MADLabelPageSlider alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y,
                                                                      rect.size.width, strongself.stringHeight)];
                    label.pageNumber = (NSUInteger)roundl(i * tickValue + 1);
                    label.enabled = strongself.enabledColor;
                    [label translateToPoint:CGPointMake(drawingPoint.x, drawingPoint.y + offsetTopBottom)];
                    [strongself.vibrancyView addSubview:label];
                    [strongself.labels addObject:label];
                    
                }

            });
        });
        }
        drawingPoint = CGPointMake(drawingPoint.x,
                                   drawingPoint.y + _stringHeight + distanceBetweenTicks);
    }
}

+ (CGFloat)distanceBetweenTicks:(NSUInteger)numberOfTicks height:(CGFloat)height
                        padding:(CGFloat)padding rect:(CGRect)rect {
    return numberOfTicks > 1 ?
                ((rect.size.height - padding * 2) / numberOfTicks) - height :
                CGSizeZero.height;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window == nil) {
        for (UILabel *label in self.labels) {
            [label removeFromSuperview];
        }
        [self.vibrancyView removeFromSuperview];
        [self.pageSlider removeFromSuperview];
        [self.labels removeAllObjects];
        _vibrancyView = nil;
        _slider = nil;
    }
}

#pragma mark -
#pragma mark Custom

- (void)setDisplayEnabled {
    self.enabledColor = YES;
}

- (void)setDisplayDisabled {
    self.enabledColor = NO;
}

- (void)handleGestureTapSlider:(UIGestureRecognizer *)tap {
    UISlider *slider = (UISlider *)tap.view;
    if (slider.highlighted == NO) {
        CGPoint pt = [tap locationInView: slider];
        float percentage = (float)(pt.x / slider.bounds.size.width);
        float delta = percentage * (slider.maximumValue - slider.minimumValue);
        float value = slider.minimumValue + delta;
        [slider setValue:value animated:YES];
        [self handleSliderDidFinishDrag:slider];
        [self handleSliderChangedPage:slider];
    }
}

- (void)handleSliderChangedPage:(UISlider *)sender {
    [self.sliderDelegate sliderDidChangeToPage:(NSUInteger)lroundf(sender.value)];
}

- (void)handleSliderDidFinishDrag:(UISlider *)sender {
    sender.value = lroundf(sender.value);               // Sets your slider to this value
}

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
    //[[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.pageSlider.minimumValue = minimumValue;
        [self setNeedsLayout];
    //}];
}

- (float)maximumValue {
    return self.pageSlider.maximumValue;
}

- (NSUInteger)maximumNumberOfLabels {
    return availableLabelSlots(MaxDimension(self.frame.size),
                               self.stringHeight,
                               self.maximumValue) / 2 + 1;
}

- (void)setMaximumValue:(float)maximumValue {
    if (_labels == nil) {
        NSMutableArray *labels;
        labels = [[NSMutableArray alloc] initWithCapacity: [self maximumNumberOfLabels]];
        _labels = labels;
    }
    //[[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.pageSlider.maximumValue = maximumValue;
        [self setNeedsLayout];
    //}];
}


- (void)setEnabled:(BOOL)enabled {
    
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

- (void)rotateBoundingSize:(CGSize)boundingSize inContext:(CGContextRef)context {
    CGAffineTransform translate1 = CGAffineTransformMakeTranslation(boundingSize.width / 2.0000f,
                                                                    boundingSize.width / 2.0000f);
    CGAffineTransform rotate = CGAffineTransformMakeRotation(3.0000f / 2.0000f * (CGFloat)M_PI);
    CGAffineTransform translateBack = CGAffineTransformMakeTranslation(-boundingSize.width / 2.0000f,
                                                                       -boundingSize.width / 2.0000f);
    CGContextConcatCTM(context, translate1);
    CGContextConcatCTM(context, rotate);
    CGContextConcatCTM(context, translateBack);
}

@end
