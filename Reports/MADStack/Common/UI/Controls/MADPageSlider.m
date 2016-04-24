//
//  MADPageSlider.m
//  MAD Designer
//
//  Created by Michael Thomason on 2/21/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADPageSlider.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import "MADSliderPageVertical.h"

static const CGFloat MADSliderPaginationWidth = 40.0000f;
static const CGFloat MADBarButtonItemsMargin = 8.0000f;
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

    @property (nonatomic, weak) MADSliderPageVertical *slider;

    @property (nonatomic, weak)   UIVibrancyEffect *effectVibrancy;
    @property (nonatomic, strong) UIVisualEffectView *vibrancyView;

    @property (nonatomic, strong) NSMutableArray <UILabel *> *labels;
    @property (nonatomic, assign) CGFloat stringHeight;

    @property (nonatomic, assign) CGRect lastRect;
    @property (nonatomic, assign) unsigned long lastNumberOfTicks;

    @property (nonatomic, strong) NSShadow *shadow;

    @property (nonatomic, assign) bool enabledColor;

@end

@implementation MADPageSlider

- (void)dealloc { }

- (void)removeFromSuperview {
    [super removeFromSuperview];
    NSArray <UILabel *> *labels = self.labels;
    for (UILabel *label in labels) {
        [label removeFromSuperview];
    }
    [self.slider removeFromSuperview];
    [self.vibrancyView removeFromSuperview];
    [self.labels removeAllObjects];
}

- (NSShadow *)shadow {
    if (_shadow == nil) {
        NSShadow *shadow = [[NSShadow alloc] init];
        UIColor *shadowColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.75000f];
        shadow.shadowColor = shadowColor;
        shadow.shadowOffset = CGSizeMake(0.0000f, -1.0000f);
        _shadow = shadow;
    }
    return _shadow;
}

- (instancetype)initWithEffect:(UIBlurEffect *)effect {
    if (self = [super initWithEffect:effect]) {
        self.contentView.tintColor = [UIColor blueColor];
        UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:effect];
        self.effectVibrancy = vibrancy;
        
        UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        vibrancyView.frame = self.frame;
        vibrancyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        vibrancyView.contentView.tintColor = [UIColor redColor];
        [self.contentView addSubview:vibrancyView];
        self.vibrancyView = vibrancyView;
        
        MADSliderPageVertical *vertSlider = [[MADSliderPageVertical alloc] init];
        [vertSlider addTarget:self action:@selector(handleSliderChangedPage:) forControlEvents:UIControlEventValueChanged];
        [vertSlider addTarget:self action:@selector(handleSliderDidFinishDrag:) forControlEvents:UIControlEventTouchUpInside];
        
        UITapGestureRecognizer *sliderTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureTapSlider:)];
        [vertSlider addGestureRecognizer:sliderTapped];
        
        vertSlider.transform = CGAffineTransformRotate(vertSlider.transform, 1.0000f / 2.0000f * (CGFloat)M_PI);
        self.transform = CGAffineTransformRotate(vertSlider.transform, 3.0000f / 2.0000f * (CGFloat)M_PI);
        [self.contentView addSubview:vertSlider];
        
        self.backgroundColor = [[MADColorEverydayApps newColorBlueLight] colorWithAlphaComponent:0.3333f];
        self.slider = vertSlider;
        
        UIFont *font = [UIFont boldSystemFontOfSize:9.0000f];
        NSNumber *strokeWidth = @-1.0000f;
        NSDictionary *attributes = @{
                                     NSFontAttributeName : font,
                                     NSStrokeWidthAttributeName : strokeWidth,
                                     };
        
        NSAttributedString *testString = [[NSAttributedString alloc] initWithString: ConstTestStringValue
                                                                         attributes: attributes];

        self.stringHeight = [self boundsForAttributedString:testString].height;
        self.labels = nil;

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.frame = CGRectMake(self.superview.frame.size.width - MADSliderPaginationWidth, CGPointZero.y, MADSliderPaginationWidth, self.superview.frame.size.height);
    self.pageSlider.frame = CGRectMake(CGPointZero.x, CGPointZero.y, MADSliderPaginationWidth, self.superview.frame.size.height);

    if (self.labels == nil) {
        return;
    }
    
    CGRect rect = self.bounds;
    unsigned long numberOfTicks = availableLabelSlots(rect.size.height, self.stringHeight, self.maximumValue);
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
    CGFloat distanceBetweenTicks = numberOfTicks > 1 ?
    ((rect.size.height - offsetTopBottom*2) / numberOfTicks) - self.stringHeight : CGSizeZero.height;
    CGPoint drawingPoint = CGPointMake(rect.origin.x, rect.origin.y);
    
    double tickValue = self.maximumValue / (numberOfTicks - 1);
    
    UIColor *darkTextColor = [UIColor darkTextColor];
    UIColor *textColor = [darkTextColor colorWithAlphaComponent:0.80000000f];
    UIColor *clearColor = [UIColor clearColor];
    UIColor *drawingColor = [self drawingColor];
    UIColor *blueColor = [MADColorEverydayApps newColorBlue];
    
    UIFont *boldFont = [UIFont boldSystemFontOfSize:9.0000f];
    
    for (NSUInteger i=0; i<numberOfTicks; i++) {
        if (i % 2 == 0) {
            
            NSString *pageNumber = [[NSString alloc] initWithFormat:@"%d", (int)roundl(i * tickValue + 1)];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, rect.size.width, self.stringHeight)];
            label.backgroundColor = clearColor;
            label.textAlignment = NSTextAlignmentRight;
            label.text = pageNumber;
            label.font = boldFont;
            label.textColor = textColor;
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            label.translatesAutoresizingMaskIntoConstraints = YES;
            label.tintColor = drawingColor;

            label.transform = CGAffineTransformTranslate(label.transform,
                                                         label.frame.origin.x > 0 ? -1 * label.frame.origin.x : label.frame.origin.x,
                                                         label.frame.origin.y > 0 ? -1 * label.frame.origin.y : label.frame.origin.y);
            
            label.transform = CGAffineTransformTranslate(label.transform, drawingPoint.x , drawingPoint.y + offsetTopBottom);
            
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            label.translatesAutoresizingMaskIntoConstraints = YES;
            label.layer.shadowOpacity = 6.0;
            label.layer.shadowRadius = 0.0;
            label.layer.shadowOffset = CGSizeMake(0.75000f, 0.750000f);
            label.layer.shadowColor = blueColor.CGColor;
            
            [self.vibrancyView addSubview:label];
            [self.labels addObject:label];
        }
        drawingPoint = CGPointMake(drawingPoint.x, drawingPoint.y + self.stringHeight + distanceBetweenTicks);
    }
}

- (UIColor *)drawingColor {
    return self.enabledColor ? [MADColorEverydayApps newColorRed] : [UIColor lightGrayColor];
}

- (void)setDisplayEnabled {
    self.enabledColor = true;
}

- (void)setDisplayDisabled {
    self.enabledColor = false;
}

- (MADSliderPageVertical *)pageSlider { return self.slider; }

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
    [self.sliderDelegate sliderDidChangeToPage:(NSUInteger)abs(lroundf(sender.value))];
}

- (void)handleSliderDidFinishDrag:(UISlider *)sender {
    sender.value = lroundf(sender.value);               // Sets your slider to this value
}

- (CGSize)boundsForAttributedString:(NSAttributedString *)string {
    CGRect boundingRect = [string boundingRectWithSize: CGSizeMake(300.0000f, CGFLOAT_MAX)
                                               options: (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                               context: nil];
    return CGSizeMake(boundingRect.size.width, boundingRect.size.height);
}

- (float)value {
    return self.pageSlider.value;
}

- (void)setValue:(float)value {
    self.pageSlider.value = value;
}

-(float)minimumValue {
    return self.pageSlider.minimumValue;
}

- (void)setMinimumValue:(float)minimumValue {
    self.pageSlider.minimumValue = minimumValue;
    [self setNeedsLayout];
}

- (float)maximumValue {
    return self.pageSlider.maximumValue;
}

- (NSUInteger)maximumNumberOfLabels {
    return availableLabelSlots(MaxDimension(self.frame.size), self.stringHeight, self.maximumValue) / 2 + 1;
}

- (void)setMaximumValue:(float)maximumValue {
    if (self.labels == nil) {
        NSMutableArray *labels = [[NSMutableArray alloc] initWithCapacity: [self maximumNumberOfLabels]];
        self.labels = labels;
    }
    self.pageSlider.maximumValue = maximumValue;
    [self setNeedsLayout];
}


- (void)setEnabled:(BOOL)enabled {
    [self.pageSlider setEnabled:enabled];
    
    UIColor *tintColor = nil;
    UIImage *thumbImage = nil;
    if (enabled) {
        tintColor = [MADColorEverydayApps newColorRed];
        thumbImage = [MADSliderPageVertical sliderImageEnabled];
        [self setDisplayEnabled];
    } else {
        tintColor = [UIColor lightGrayColor];
        thumbImage = [MADSliderPageVertical sliderImageDisabled];
        [self setDisplayDisabled];
    }
    self.tintColor = tintColor;
    [self.pageSlider setThumbImage:thumbImage forState:UIControlStateNormal];
}

- (BOOL)isEnabled {
    return self.pageSlider.isEnabled;
}

- (CGRect)drawString:(NSAttributedString *)string atPoint:(CGPoint)point inContext:(CGContextRef)context {
    CGContextSaveGState(context);
    CGSize boundingSize = [self boundsForAttributedString:string];
    [self rotateBoundingSize:boundingSize inContext:context];
    [string drawAtPoint:point];
    CGContextRestoreGState(context);
    return CGRectMake(point.x, point.y, boundingSize.width, boundingSize.height);
}

- (void)rotateBoundingSize:(CGSize)boundingSize inContext:(CGContextRef)context {
    CGAffineTransform affineTransformTranslate1 = CGAffineTransformMakeTranslation(boundingSize.width / 2.0000f, boundingSize.width / 2.0000f);
    CGAffineTransform rotate = CGAffineTransformMakeRotation(3.0000f / 2.0000f * (CGFloat)M_PI);
    CGAffineTransform affineTransformTranslateBack = CGAffineTransformMakeTranslation(-boundingSize.width / 2.0000f, -boundingSize.width / 2.0000f);
    CGContextConcatCTM(context, affineTransformTranslate1);
    CGContextConcatCTM(context, rotate);
    CGContextConcatCTM(context, affineTransformTranslateBack);
    
}

@end
