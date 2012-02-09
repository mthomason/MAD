//
//  UIViewTableSectionHeaderQueryBuilder.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewTableSectionHeaderQueryBuilder.h"
#import "UIColor+EverydayApps.h"

@implementation UIViewTableSectionHeaderQueryBuilder

@synthesize highlight = _hidden;

- (void)drawRect:(CGRect)rect{
    
    CGContextRef currentContext =  UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(currentContext);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    UIColor *startColor = [UIColor edaGreenLight];
    CGFloat *startColorComponents = (CGFloat *)CGColorGetComponents([startColor CGColor]);
    
    UIColor *secondColor = [UIColor colorWithRed:(132.0000f/255.0000f) green:(174.0000f/255.0000f) blue:(98.0000f/255.0000f) alpha:1.0000f];
    CGFloat *secondColorComponents = (CGFloat *)CGColorGetComponents([secondColor CGColor]);
    
    UIColor *thirdColor = [UIColor colorWithRed:(119.0000f/255.0000f) green:(166.0000f/255.0000f) blue:(82.0000f/255.0000f) alpha:1.0000f];
    CGFloat *thirdColorComponents = (CGFloat *)CGColorGetComponents([thirdColor CGColor]);
    
    UIColor *fourthColor = [UIColor colorWithRed:(102.0000f/255.0000f) green:(155.0000f/255.0000f) blue:(61.0000f/255.0000f) alpha:1.0000f];
    CGFloat *fourthColorComponents = (CGFloat *)CGColorGetComponents([fourthColor CGColor]);
    
    UIColor *middleColor = [UIColor edaGreenDark];
    CGFloat *middleColorComponents = (CGFloat *)CGColorGetComponents([middleColor CGColor]);

    UIColor *sixthColor = [UIColor colorWithRed:(102.0000f/255.0000f) green:(155.0000f/255.0000f) blue:(61.0000f/255.0000f) alpha:1.0000f];
    CGFloat *sixthColorComponents = (CGFloat *)CGColorGetComponents([sixthColor CGColor]);

    UIColor *seventhColor = [UIColor colorWithRed:(119.0000f/255.0000f) green:(166.0000f/255.0000f) blue:(82.0000f/255.0000f) alpha:1.0000f];
    CGFloat *seventhColorComponents = (CGFloat *)CGColorGetComponents([seventhColor CGColor]);
    
    UIColor *eightColor = [UIColor colorWithRed:(132.0000f/255.0000f) green:(174.0000f/255.0000f) blue:(98.0000f/255.0000f) alpha:1.0000f];
    CGFloat *eightColorComponents = (CGFloat *)CGColorGetComponents([eightColor CGColor]);
    
    UIColor *ninthColor = [UIColor edaGreenLight];
    CGFloat *ninthColorComponents = (CGFloat *)CGColorGetComponents([ninthColor CGColor]);

    CGFloat colorComponents[40] = {
        
        startColorComponents[0], 
        startColorComponents[1], 
        startColorComponents[2], 
        startColorComponents[3],

        secondColorComponents[0],
        secondColorComponents[1],
        secondColorComponents[2],
        secondColorComponents[3],
        
        secondColorComponents[0],
        secondColorComponents[1],
        secondColorComponents[2],
        secondColorComponents[3],
        
        thirdColorComponents[0],
        thirdColorComponents[1],
        thirdColorComponents[2],
        thirdColorComponents[3],
        
        fourthColorComponents[0],
        fourthColorComponents[1],
        fourthColorComponents[2],
        fourthColorComponents[3],
        
        middleColorComponents[0],
        middleColorComponents[1],
        middleColorComponents[2],
        middleColorComponents[3],
        
        sixthColorComponents[0],
        sixthColorComponents[1],
        sixthColorComponents[2],
        sixthColorComponents[3],
        
        seventhColorComponents[0],
        seventhColorComponents[1],
        seventhColorComponents[2],
        seventhColorComponents[3],
        
        eightColorComponents[0],
        eightColorComponents[1],
        eightColorComponents[2],
        eightColorComponents[3],
        
        ninthColorComponents[0],
        ninthColorComponents[1],
        ninthColorComponents[2],
        ninthColorComponents[3],
        
    };
    
    CGFloat colorIndices[9] = {
        0.0000f,
        0.1250f,
        0.2500f,
        0.3750f,
        0.5000f,
        0.6250f,
        0.7500f,
        0.8750f,
        0.1000f,
    };
    
    CGGradientRef gradient = 
    CGGradientCreateWithColorComponents
    (colorSpace,
     (const CGFloat *)&colorComponents, 
     (const CGFloat *)&colorIndices, 9);
    
    CGColorSpaceRelease(colorSpace);
    
    CGPoint startPoint, endPoint;
    
    startPoint = CGPointMake(rect.origin.x, 
                             rect.origin.y);
    
    endPoint = CGPointMake(rect.origin.x + rect.size.width,
                           rect.origin.y /* + rect.size.height */ );
    
    CGContextDrawLinearGradient
    (currentContext, 
     gradient,
     startPoint,
     endPoint, 
     kCGGradientDrawsBeforeStartLocation |
     kCGGradientDrawsAfterEndLocation);
    
    CGGradientRelease(gradient);
    
    /* Create the path */
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, rect.origin.x, rect.origin.y);
    CGPathAddLineToPoint(path, NULL, rect.size.width, rect.origin.y);
    CGPathMoveToPoint(path, NULL, rect.origin.x, rect.size.height);
    CGPathAddLineToPoint(path, NULL, rect.size.width, rect.size.height);
    
    /* Add the path to the context so we can
     draw it later */
    CGContextAddPath(currentContext, path);
    
    /* Set the blue color as the stroke color */
    if (![self highlight]) {
        [[UIColor edaYellow] setStroke];
    } else {
        [[UIColor edaOrange] setStroke];
    }
    
    /* Draw the path with stroke color */
    CGContextDrawPath(currentContext, kCGPathStroke);
    
    /* Finally release the path object */
    CGPathRelease(path);
    
    CGContextRestoreGState(currentContext);
    
}

@end