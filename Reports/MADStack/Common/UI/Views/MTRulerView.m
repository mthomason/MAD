//
//  UIViewRuler.m
//  Reports
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTRulerView.h"
#import "UIView+Extras.h"

const CGFloat MTReportDesignerRulerHeight           = 20.0000f;

@interface MTRulerView ()

@property (nonatomic, strong) NSDictionary *attributes;
@property (nonatomic, strong) NSDictionary *attributesMetric;
@property (nonatomic, assign) CGFloat thinLineWidth;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) CGFloat eigthInchInPoints;
@property (nonatomic, assign) CGFloat cmInPoints;

@end

@implementation MTRulerView


- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.layer.borderWidth = [UIView borderWidthThin];
    self.layer.borderColor = [UIColor blackColor].CGColor;
    self.backgroundColor = [UIColor whiteColor];
    UIFont *font = [UIFont systemFontOfSize: 5.0000f];
    UIFont *font2 = [UIFont systemFontOfSize: 4.0000f];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{
                                 NSFontAttributeName : font,
                                 NSParagraphStyleAttributeName : paragraphStyle
                                     };
    NSDictionary *attributes2 = @{
                                 NSFontAttributeName : font2,
                                 NSParagraphStyleAttributeName : paragraphStyle
                                 };
    self.attributes = attributes;
    self.attributesMetric = attributes2;
    
    CGFloat thinLineWidth = 1.0000f / self.traitCollection.displayScale;
    self.thinLineWidth = thinLineWidth;
    self.lineWidth = 1.0000f;
    
    self.eigthInchInPoints = 72.0000f / 8.0000f;
    self.cmInPoints = (72.0000f / 1.0000f) / 2.5400f;

    self.layer.borderWidth = [UIView borderWidthThin];
    self.layer.borderColor = [UIColor borderColor].CGColor;
    self.translatesAutoresizingMaskIntoConstraints = NO;

}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGMutablePathRef pathInchMarks = CGPathCreateMutable();
    
    for (NSInteger i = CGPointZero.x; i < rect.size.width / [self eigthInchInPoints]; i++) {
        @autoreleasepool {
            CGFloat xPoint = i * [self eigthInchInPoints];
            CGFloat length = 0.0000f;
            if ((i % 8) == 0) {
                CGRect locationRect = CGRectMake(xPoint - 5.000f, rect.size.height - 8.0000f, 10.0000f, 5.0000f);
                NSString *s = [NSString stringWithFormat:@"%ld", (long)i / 8];
                [s drawInRect:locationRect withAttributes:[self attributes]];
                length = 1.0000f;
                CGContextSetLineWidth(currentContext, [self lineWidth] * 2.0000f);
            } else if (i % 2) {
                length = 4.0000f;
                CGContextSetLineWidth(currentContext, [self thinLineWidth]);
            } else if (i % 4) {
                length = 3.0000f;
                CGContextSetLineWidth(currentContext, [self thinLineWidth]);
            } else {
                length = 2.0000f;
                CGContextSetLineWidth(currentContext, [self thinLineWidth]);
            }
            CGPathMoveToPoint(pathInchMarks, NULL, xPoint, rect.size.height);
            CGPathAddLineToPoint(pathInchMarks, NULL, xPoint, rect.size.height - length);
        }
    }
    
    CGFloat offsetInPoints = (72.0000f / 2.5400f) / 10.0000f;   //One cm
    CGMutablePathRef pathCmMarks = CGPathCreateMutable();
    for (NSInteger i = CGPointZero.x; i < rect.size.width / offsetInPoints; i++) {
        @autoreleasepool {
            CGFloat length = 0.0000f;
            CGFloat xPointC = i * ([self cmInPoints] / 10.0000f);
            if ((i % 10) == 0) {
                CGRect locationRect = CGRectMake(xPointC - 5.000f, 1.0000f, 10.0000f, 5.0000f);
                NSString *s = [NSString stringWithFormat:@"%ld", (long)i / 10];
                [s drawInRect:locationRect withAttributes:[self attributesMetric]];
                length = 2.0000f;
                CGContextSetLineWidth(currentContext, [self lineWidth] * 2.0000f);
            } else if (i % 5) {
                length = 2.0000f;
                CGContextSetLineWidth(currentContext, [self thinLineWidth]);
            } else {
                length = 3.0000f;
                CGContextSetLineWidth(currentContext, [self thinLineWidth]);
            }
            CGFloat xPoint = i * offsetInPoints;
            CGPathMoveToPoint(pathCmMarks, NULL, xPoint, CGPointZero.y);
            CGPathAddLineToPoint(pathCmMarks, NULL, xPoint, CGPointZero.y + length);
        }
    }
    
    CGContextAddPath(currentContext, pathCmMarks);
    CGContextAddPath(currentContext, pathInchMarks);
    
    [[UIColor blackColor] setStroke];
    CGContextDrawPath(currentContext, kCGPathStroke);

    CGPathRelease(pathInchMarks);
    CGPathRelease(pathCmMarks);
    
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.bounds.size.width, MTReportDesignerRulerHeight);
}

@end
