//
//  MTSliderPageVertical.m
//  MAD
//
//  Created by Michael Thomason on 5/13/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTSliderPageVertical.h"
#import "UIColor+EverydayApps.h"
#import <CoreGraphics/CoreGraphics.h>

@interface MTSliderPageVertical ()

@property (nonatomic, strong) NSDictionary *stringAttributes;

@end

@implementation MTSliderPageVertical

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *thumbImage = [UIImage imageNamed:@"MTSliderThumbRotate"];
        [self setThumbImage:thumbImage forState:UIControlStateNormal];
        UIImage *blank = [UIImage new];
        [self setMinimumTrackImage:blank forState:UIControlStateNormal];
        [self setMaximumTrackImage:blank forState:UIControlStateNormal];
        
        UIColor *textColor = [UIColor tintColorRed];
        UIFont *font = [UIFont systemFontOfSize:9.0000f];
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[UIColor colorWithRed:0.0000f green:0.00000f blue:0.0000f alpha:0.8000f]];
        [shadow setShadowOffset:CGSizeMake(0.0000f, 1.0000f)];
        [shadow setShadowBlurRadius:5.0000f];
        NSDictionary *attributes = @{ NSForegroundColorAttributeName : textColor,
                                      NSFontAttributeName : font,
                                      NSShadowAttributeName : shadow,
                                      };
        [self setStringAttributes:attributes];
        
    }
    return self;
}

- (void)setMaximumValue:(float)maximumValue {
    [super setMaximumValue:maximumValue];
    [self setNeedsDisplay];
}

- (void)setMinimumValue:(float)minimumValue {
    [super setMinimumValue:minimumValue];
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self drawBackgroundWithRect:rect inContext:context];
    
    NSMutableString *pageNumber = [[NSMutableString alloc] initWithString:@"0"];
    
    NSAttributedString *testString = [[NSAttributedString alloc] initWithString:pageNumber attributes:[self stringAttributes]];
    CGFloat stringHeight = [self boundsForAttributedString:testString].height;
    
    rect.origin = CGPointMake(rect.origin.x, rect.origin.y + (stringHeight / 2.0));
    rect.size = CGSizeMake(rect.size.height, rect.size.width - (stringHeight / 2.0) * 2.0);

    NSInteger numberOfTicks = (rect.size.height / stringHeight) - 1;
    
    if (numberOfTicks < 0) { numberOfTicks = 0; }

    if (numberOfTicks > self.maximumValue) { numberOfTicks = floor(self.maximumValue) + 1; }

    CGFloat distanceBetweenTicks = numberOfTicks > 1 ? (rect.size.height - (stringHeight * numberOfTicks)) / (numberOfTicks - 1) : CGSizeZero.height;
    CGPoint drawingPoint = CGPointMake(rect.origin.x, rect.origin.y);

    double tickValue = [self maximumValue] / (numberOfTicks - 1);
    
    for (NSInteger i=0; i<numberOfTicks; i++) {

        [pageNumber setString: [NSString stringWithFormat:@"%d", (int)roundl(i * tickValue + 1)]];
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:pageNumber attributes:[self stringAttributes]];
        [self drawString:attributedString atPoint:drawingPoint inContext:context];
        drawingPoint = CGPointMake(drawingPoint.x, drawingPoint.y + stringHeight + distanceBetweenTicks);
    }
}

- (void)drawBackgroundWithRect:(CGRect)rect inContext:(CGContextRef)context {
    
    CGContextSaveGState(context);
    
    [self rotateBoundingSize:rect.size inContext:context];
    CGRect rectBg = CGRectMake(rect.origin.x + rect.size.width / 2.0000f, CGPointZero.y, rect.size.width / 2.0000f, rect.size.height);
    CGMutablePathRef pathBackground = CGPathCreateMutable();
    CGPathAddRect(pathBackground, NULL, rectBg);
    UIColor *tintColor = [UIColor colorWithRed:(13.0000f / 256.0000f) green:(158.0000f / 256.0000f) blue:(215.0000f / 256.0000f) alpha:0.6000f];
    [tintColor setFill];
    CGContextDrawPath(context, kCGPathFill);
    CGContextRestoreGState(context);
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
