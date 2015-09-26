//
//  MTSliderPageVertical.m
//  MAD
//
//  Created by Michael Thomason on 5/13/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTSliderPageVertical.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import "UIImage+ImageEffects.h"

@interface MTSliderPageVertical ()

@property (nonatomic, strong) NSDictionary *stringAttributes;

@end

@implementation MTSliderPageVertical

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *thumbImage = [MTSliderPageVertical sliderImageEnabled];
        [self setThumbImage:thumbImage forState:UIControlStateNormal];
        UIImage *blank = [UIImage new];
        [self setMinimumTrackImage:blank forState:UIControlStateNormal];
        [self setMaximumTrackImage:blank forState:UIControlStateNormal];
        
        [self setDisplayEnabled];
        self.maximumValue = 0.0000f;
        self.minimumValue = 0.0000f;
        self.continuous = YES;
        self.tintColor = [UIColor tintColorRed];
        self.value = 0.0000f;

    }
    return self;
}

- (void)setDisplayEnabled {
    [self initalizeDisplayAttributesWithColor:[UIColor tintColorRed]];
}

- (void)setDisplayDisabled {
    [self initalizeDisplayAttributesWithColor:[UIColor lightGrayColor]];
}

- (void)initalizeDisplayAttributesWithColor:(UIColor *)tintColor {
    UIFont *font = [UIFont boldSystemFontOfSize:9.0000f];//[UIFont systemFontOfSize:9.0000f];
    NSShadow *shadow = [[NSShadow alloc] init];
    UIColor *shadowColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.75000f];
    [shadow setShadowColor:shadowColor];
    [shadow setShadowOffset:CGSizeMake(0.0000f, 1.0000f)];
    [shadow setShadowBlurRadius:5.0000f];
    NSDictionary *attributes = @{
                                 NSForegroundColorAttributeName : tintColor,
                                 NSFontAttributeName : font,
                                 NSStrokeWidthAttributeName : @(-1.0000f),
                                
                                 NSStrokeColorAttributeName : [UIColor lightTextColor],
                                 NSShadowAttributeName : shadow,
                                 };
    [self setStringAttributes:attributes];

}

- (void)setMaximumValue:(float)maximumValue {
    [super setMaximumValue:maximumValue];
    [self setNeedsDisplay];
}

- (void)setMinimumValue:(float)minimumValue {
    [super setMinimumValue:minimumValue];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSMutableString *pageNumber = [[NSMutableString alloc] initWithString:@"0"];
    
    NSAttributedString *testString = [[NSAttributedString alloc] initWithString:pageNumber attributes:[self stringAttributes]];
    CGFloat stringHeight = [self boundsForAttributedString:testString].height;
    
    CGFloat offsetHeight = (stringHeight / 1.333f);
    rect.origin = CGPointMake(rect.origin.x, rect.origin.y + offsetHeight);
    rect.size = CGSizeMake(rect.size.height, rect.size.width - offsetHeight * 2.0000f);

    CGFloat numberOfTicks = (rect.size.height / stringHeight) - 1;
    
    if (numberOfTicks < 0) { numberOfTicks = 0; }

    if (numberOfTicks > self.maximumValue) {
        numberOfTicks = floor(self.maximumValue) + 1;
    }

    BOOL everyOther = numberOfTicks > 5;
    if (everyOther && (NSInteger)numberOfTicks % 2 == 0) {
        numberOfTicks--;
    }
    
    CGFloat distanceBetweenTicks = numberOfTicks > 1 ?
                            (rect.size.height - (stringHeight * numberOfTicks)) / (numberOfTicks - 1) :
                            CGSizeZero.height;
    CGPoint drawingPoint = CGPointMake(rect.origin.x, rect.origin.y);

    double tickValue = [self maximumValue] / (numberOfTicks - 1);
    
    for (NSInteger i=0; i<numberOfTicks; i++) {
        
            [pageNumber setString: [NSString stringWithFormat:@"%d", (int)roundl(i * tickValue + 1)]];
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:pageNumber attributes:[self stringAttributes]];
        if (everyOther && i % 2 == 0) {
            [self drawString:attributedString atPoint:drawingPoint inContext:context];
        }
        drawingPoint = CGPointMake(drawingPoint.x, drawingPoint.y + stringHeight + distanceBetweenTicks);
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
        thumbImage = [MTSliderPageVertical sliderImageEnabled];
        [self setDisplayEnabled];
    } else {
        thumbImage = [MTSliderPageVertical sliderImageDisabled];
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
    CGFloat angle = 3.0000f / 2.0000f * M_PI;
    CGAffineTransform rotate = CGAffineTransformMakeRotation(angle);
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
