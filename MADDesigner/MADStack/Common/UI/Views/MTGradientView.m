//
//  UIViewTableSectionHeaderQueryBuilder.m
//  Reports
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MTGradientView.h"
#import <UIKit/UIGraphics.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MTGradientView

@synthesize highlight = _hidden;

- (void)drawRect:(CGRect)rect{
    [super drawRect: rect];

    CGContextRef currentContext =  UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(currentContext);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    UIColor *startColor = [MADColorEverydayApps newColorGreenLight];
    CGFloat *startColorComponents = (CGFloat *)CGColorGetComponents(startColor.CGColor);
    
    UIColor *secondColor = [[UIColor alloc] initWithRed: (132.0/255.0)
                                                  green: (174.0/255.0)
                                                   blue: (98.0/255.0)
                                                  alpha: 1.0];
    CGFloat *secondColorComponents = (CGFloat *)CGColorGetComponents(secondColor.CGColor);
    
    UIColor *thirdColor = [[UIColor alloc] initWithRed: (119.0/255.0)
                                                 green: (166.0/255.0)
                                                  blue: (82.0/255.0)
                                                 alpha: 1.0];
    CGFloat *thirdColorComponents = (CGFloat *)CGColorGetComponents(thirdColor.CGColor);
    
    UIColor *fourthColor = [[UIColor alloc] initWithRed: (102.0/255.0)
                                                  green: (155.0/255.0)
                                                   blue: (61.0/255.0)
                                                  alpha: 1.0];
    CGFloat *fourthColorComponents = (CGFloat *)CGColorGetComponents(fourthColor.CGColor);
    
    UIColor *middleColor = [MADColorEverydayApps newColorGreenDark];
    CGFloat *middleColorComponents = (CGFloat *)CGColorGetComponents(middleColor.CGColor);

    UIColor *sixthColor = [[UIColor alloc] initWithRed: (102.0/255.0)
                                                 green: (155.0/255.0)
                                                  blue: (61.0/255.0)
                                                 alpha: 1.0];
    CGFloat *sixthColorComponents = (CGFloat *)CGColorGetComponents(sixthColor.CGColor);

    UIColor *seventhColor = [[UIColor alloc] initWithRed: (119.0/255.0)
                                                   green: (166.0/255.0)
                                                    blue: (82.0/255.0)
                                                   alpha: 1.0];
    CGFloat *seventhColorComponents = (CGFloat *)CGColorGetComponents(seventhColor.CGColor);
    
    UIColor *eightColor = [[UIColor alloc] initWithRed: (132.0/255.0)
                                                 green: (174.0/255.0)
                                                  blue: (98.0/255.0)
                                                 alpha: 1.0];
    CGFloat *eightColorComponents = (CGFloat *)CGColorGetComponents(eightColor.CGColor);
    
    UIColor *ninthColor = [MADColorEverydayApps newColorGreenLight];
    CGFloat *ninthColorComponents = (CGFloat *)CGColorGetComponents(ninthColor.CGColor);

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
        0.0,
        0.125,
        0.25,
        0.375,
        0.5,
        0.625,
        0.75,
        0.875,
        0.1,
    };
    
    CGGradientRef gradient = 
    CGGradientCreateWithColorComponents
    (colorSpace,
     (const CGFloat *)&colorComponents, 
     (const CGFloat *)&colorIndices, 9.0);
    
    CGColorSpaceRelease(colorSpace);
    
    CGPoint startPoint, endPoint;
    
    startPoint = CGPointMake(rect.origin.x, 
                             rect.origin.y);
    
    endPoint = CGPointMake(rect.origin.x + rect.size.width,
                           rect.origin.y + rect.size.height );
    
    CGContextDrawLinearGradient
    (currentContext, 
     gradient,
     startPoint,
     endPoint, 
     kCGGradientDrawsBeforeStartLocation |
     kCGGradientDrawsAfterEndLocation);
    
    CGGradientRelease(gradient);
    
    // Create the path
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, rect.origin.x, rect.origin.y);
    CGPathAddLineToPoint(path, NULL, rect.size.width, rect.origin.y);
    CGPathMoveToPoint(path, NULL, rect.origin.x, rect.size.height);
    CGPathAddLineToPoint(path, NULL, rect.size.width, rect.size.height);
    
    // Add the path to the context so we can
    // draw it later
    CGContextAddPath(currentContext, path);
    
    // Set the blue color as the stroke color
    if (!self.highlight) {
        [[MADColorEverydayApps newColorYellow] setStroke];
    } else {
        [[MADColorEverydayApps newColorOrange] setStroke];
    }
    
    // Draw the path with stroke color
    CGContextDrawPath(currentContext, kCGPathStroke);
    
    // Finally release the path object
    CGPathRelease(path);
    
    CGContextRestoreGState(currentContext);
}

@end
