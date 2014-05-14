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

@implementation MTSliderPageVertical

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor redColor]];
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
    rect.size = CGSizeMake(rect.size.height, rect.size.width);
    NSDictionary *attributes = @{NSBackgroundColorAttributeName : [UIColor greenColor]};
    NSMutableString *pageNumber = [[NSMutableString alloc] initWithString:@"0"];
    
    NSAttributedString *testString = [[NSAttributedString alloc] initWithString:pageNumber attributes:attributes];
    CGFloat stringHeight = [self boundsForAttributedString:testString].height;

    NSInteger numberOfTicks = (rect.size.height / stringHeight) - 1;
    if (numberOfTicks < 0) {
        numberOfTicks = 0;
    }
    if (numberOfTicks > self.maximumValue) {
        numberOfTicks = floor(self.maximumValue) + 1;
    }

    CGFloat distanceBetweenTicks = numberOfTicks > 1 ? (rect.size.height - (stringHeight * numberOfTicks)) / (numberOfTicks - 1) : CGSizeZero.height;
    CGPoint drawingPoint = CGPointMake(CGPointZero.x, CGPointZero.y);

    double tickValue = [self maximumValue] / (numberOfTicks - 1);
    
    for (NSInteger i=0; i<numberOfTicks; i++) {

        [pageNumber setString: [NSString stringWithFormat:@"%d", (int)roundl(i * tickValue + 1)]];
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:pageNumber attributes:attributes];
        [self drawString:attributedString atPoint:drawingPoint];
        drawingPoint = CGPointMake(drawingPoint.x, drawingPoint.y + stringHeight + distanceBetweenTicks);
    }
}

- (CGRect)drawString:(NSAttributedString *)string atPoint:(CGPoint)point {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGSize boundingSize = [self boundsForAttributedString:string];
    CGAffineTransform affineTransformTranslate1 = CGAffineTransformMakeTranslation(boundingSize.width / 2.0000f, boundingSize.width / 2.0000f);
    CGFloat angle = 3.0000f / 2.0000f * M_PI;
    CGAffineTransform rotate = CGAffineTransformMakeRotation(angle);
    CGAffineTransform affineTransformTranslateBack = CGAffineTransformMakeTranslation(-boundingSize.width / 2.0000f, -boundingSize.width / 2.0000f);
    CGContextConcatCTM(context, affineTransformTranslate1);
    CGContextConcatCTM(context, rotate);
    CGContextConcatCTM(context, affineTransformTranslateBack);
    [string drawAtPoint:point];
    CGContextRestoreGState(context);
    return CGRectMake(point.x, point.y, boundingSize.width, boundingSize.height);
}

- (CGSize)boundsForAttributedString:(NSAttributedString *)string {
    NSStringDrawingOptions drawingOptions = (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading);
    CGRect boundingRect = [string boundingRectWithSize: CGSizeMake(300.0000f, CGFLOAT_MAX)
                                               options: drawingOptions context:nil];
    return CGSizeMake(boundingRect.size.width, boundingRect.size.height);
}

@end
