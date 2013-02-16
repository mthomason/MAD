//
//  MTConnectorView.m
//  Reports
//
//  Created by Michael Thomason on 2/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTConnectorView.h"
#import <QuartzCore/QuartzCore.h>

@interface MTConnectorView ()

@property (nonatomic, retain) NSNumber *topLeftToBottomRight;

@end

@implementation MTConnectorView

- (id)initWithOriginView:(CGPoint)originPoint andDestinationPoint:(CGPoint)destinationPoint {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOriginPoint:originPoint andDestinationPoint:destinationPoint];
    }
    return self;
}

- (void)setOriginPoint:(CGPoint)originPoint andDestinationPoint:(CGPoint)destinationPoint {
    CGRect frame = [self rectForOriginPoint:originPoint andDestinationPoint:destinationPoint];
    [self setFrame:frame];
}

- (CGRect)rectForOriginPoint:(CGPoint)originPoint andDestinationPoint:(CGPoint)destinationPoint {
    CGFloat originX = CGPointZero.x;
    CGFloat originY = CGPointZero.y;
    CGFloat sizeWidth = CGSizeZero.width;
    CGFloat sizeHeight = CGSizeZero.height;
    BOOL topLeftToBottomRight;
    
    if (originPoint.x < destinationPoint.x && originPoint.y < destinationPoint.y) {
        topLeftToBottomRight = YES;
        originX = originPoint.x;
        originY = originPoint.y;
        sizeWidth = destinationPoint.x - originPoint.x;
        sizeHeight = destinationPoint.y - originPoint.y;
    } else if (originPoint.x > destinationPoint.x && originPoint.y > destinationPoint.y) {
        topLeftToBottomRight = YES;
        originX = destinationPoint.x;
        originY = destinationPoint.y;
        sizeWidth = originPoint.x - destinationPoint.x;
        sizeHeight = originPoint.y - destinationPoint.y;
    } else {
        topLeftToBottomRight = NO;
        if (originPoint.x < destinationPoint.x) {
            originX = originPoint.x;
            originY = destinationPoint.y;
            sizeWidth = destinationPoint.x - originPoint.x;
            sizeHeight = originPoint.y - destinationPoint.y;
        } else {
            originX = destinationPoint.x;
            originY = originPoint.y;
            sizeWidth = originPoint.x - destinationPoint.x;
            sizeHeight = destinationPoint.y - originPoint.y;
        }
    }

    NSNumber *topLeftToBottomRightWrapper = [[NSNumber alloc] initWithBool:topLeftToBottomRight];
    [self setTopLeftToBottomRight:topLeftToBottomRightWrapper];
    [topLeftToBottomRightWrapper release];
    
    [self setNeedsDisplay];
    
    return CGRectMake(originX, originY, sizeWidth, sizeHeight);
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [(UIColor *)[UIColor edaBlueDark] set];
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(currentContext, 5.0000f);
    
    CGPoint origin = CGPointMake(rect.origin.x, rect.origin.y);
    CGPoint destination = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    if ([[self topLeftToBottomRight] boolValue]) {
        CGContextMoveToPoint(currentContext, origin.x, origin.y);
        CGContextAddLineToPoint(currentContext, destination.x, destination.y);
    } else {
        CGContextMoveToPoint(currentContext, destination.x, destination.y);
        CGContextAddLineToPoint(currentContext, destination.x, destination.y);
    }
    
    CGContextStrokePath(currentContext);
}

@end
