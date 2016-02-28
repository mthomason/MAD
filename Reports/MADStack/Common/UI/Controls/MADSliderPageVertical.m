//
//  MTSliderPageVertical.m
//  MAD
//
//  Created by Michael Thomason on 5/13/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADSliderPageVertical.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import "UIImage+ImageEffects.h"

static NSString * const ConstTestStringValue = @"0";

@interface MADSliderPageVertical ()

@property (nonatomic, strong) NSDictionary *stringAttributes;
@property (nonatomic, strong) NSMutableArray <UILabel *>*labels;
@property (nonatomic, assign) CGFloat stringHeight;
@property (nonatomic, strong) UIColor *drawingColor;

@property (nonatomic, assign) CGRect lastRect;
@property (nonatomic, assign) unsigned long lastNumberOfTicks;

@end

@implementation MADSliderPageVertical

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        UIImage *thumbImage = [MADSliderPageVertical sliderImageEnabled];
        UIImage *blank = [UIImage new];
        [self setThumbImage:thumbImage forState:UIControlStateNormal];
        [self setMinimumTrackImage:blank forState:UIControlStateNormal];
        [self setMaximumTrackImage:blank forState:UIControlStateNormal];
        
        [self setDisplayEnabled];
        self.maximumValue = 0.0000f;
        self.minimumValue = 0.0000f;
        self.continuous = YES;
        self.tintColor = [UIColor tintColorRed];
        self.value = 0.0000f;
        self.backgroundColor = [UIColor yellowColor];
        
        UIFont *font = [UIFont boldSystemFontOfSize:9.0000f];
        NSShadow *shadow = [[NSShadow alloc] init];
        UIColor *shadowColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.75000f];
        shadow.shadowColor = shadowColor;
        shadow.shadowOffset = CGSizeMake(0.0000f, 1.0000f);
        shadow.shadowBlurRadius = 5.0000f;
        NSNumber *strokeWidth = @(-1.0000f);
        NSDictionary *attributes = @{
                                     NSFontAttributeName : font,
                                     NSStrokeWidthAttributeName : strokeWidth,
                                     NSStrokeColorAttributeName : [UIColor lightTextColor],
                                     NSShadowAttributeName : shadow,
                                     };
        
        NSAttributedString *testString = [[NSAttributedString alloc] initWithString: ConstTestStringValue
                                                                         attributes: attributes];
        self.stringHeight = [self boundsForAttributedString:testString].height;

        self.stringAttributes = attributes;
        
        self.labels = nil;
        //self.
        
    }
    return self;
}

- (void)setDisplayEnabled {
    self.drawingColor = [UIColor tintColorRed];
}

- (void)setDisplayDisabled {
    self.drawingColor = [UIColor lightGrayColor];
}

- (void)setMaximumValue:(float)maximumValue {
    [super setMaximumValue:maximumValue];
    if (self.labels == nil) {
        
        NSMutableArray *labels = [[NSMutableArray alloc] initWithCapacity:
                                  availableLabelSlots(MAX(self.frame.size.width, self.frame.size.height), self.stringHeight, self.maximumValue) / 2 + 1
                                  ];
        self.labels = labels;

    }
    [self setNeedsLayout];
}

- (void)setMinimumValue:(float)minimumValue {
    [super setMinimumValue:minimumValue];
    [self setNeedsLayout];
}

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



- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.labels == nil) {
        return;
    }
    
    CGRect rect = self.frame;
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

    NSDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:self.stringAttributes];
    [attributes setValue:self.drawingColor forKey:NSForegroundColorAttributeName];

    for (NSUInteger i=0; i<numberOfTicks; i++) {
        if (i % 2 == 0) {
            NSString *pageNumber = [NSString stringWithFormat:@"%d", (int)roundl(i * tickValue + 1)];
            NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: pageNumber
                                                                                   attributes: attributes];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, rect.size.width, self.stringHeight)];
            label.backgroundColor = [UIColor greenColor];
            label.textAlignment = NSTextAlignmentRight;
            label.attributedText = attributedString;
            label.transform = CGAffineTransformRotate(label.transform, 3 * M_PI / 2);
            label.transform = CGAffineTransformTranslate(label.transform,
                                                         label.frame.origin.x > 0 ? -1 * label.frame.origin.x : label.frame.origin.x,
                                                         label.frame.origin.y > 0 ? -1 * label.frame.origin.y : label.frame.origin.y);
            label.transform = CGAffineTransformTranslate(label.transform, drawingPoint.x , drawingPoint.y + offsetTopBottom);
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            label.translatesAutoresizingMaskIntoConstraints = YES;
            //label.layout
            
            [self addSubview:label];
            [self.labels addObject:label];
        }
        drawingPoint = CGPointMake(drawingPoint.x, drawingPoint.y + self.stringHeight + distanceBetweenTicks);
    }
    
}

+ (UIImage *)sliderImageEnabled {
    return [UIImage imageNamed:@"MTSliderThumbRotate"];
}

+ (UIImage *)sliderImageDisabled {
    return [UIImage imageNamed:@"MTSliderThumbRotateDisabled"];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    UIImage *thumbImage = nil;
    if (enabled) {
        thumbImage = [MADSliderPageVertical sliderImageEnabled];
        [self setDisplayEnabled];
    } else {
        thumbImage = [MADSliderPageVertical sliderImageDisabled];
        [self setDisplayDisabled];
    }
    [self setThumbImage:thumbImage forState:UIControlStateNormal];
}

- (BOOL)isEnabled {
    return [super isEnabled];
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

- (CGSize)boundsForAttributedString:(NSAttributedString *)string {
    NSStringDrawingOptions drawingOptions = (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading);
    CGRect boundingRect = [string boundingRectWithSize: CGSizeMake(300.0000f, CGFLOAT_MAX)
                                               options: drawingOptions context:nil];
    return CGSizeMake(boundingRect.size.width, boundingRect.size.height);
}

@end
