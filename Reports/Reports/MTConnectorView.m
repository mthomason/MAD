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

@end

@implementation MTConnectorView

- (void)dealloc {
    [_anchorViewLeft release];
    [_anchorViewRight release];
    [_topLeftToBottomRight release];
    [super dealloc];
}

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        UIView *anchorLeft = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 1.0000f, 1.0000f)];
        UIView *anchorRight = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height, 1.0000f, 1.0000f)];
        
        [anchorLeft setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin];
        [anchorRight setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];
        
        [self setAnchorViewLeft:anchorLeft];
        [self setAnchorViewRight:anchorRight];

        [self addSubview:[self anchorViewLeft]];
        [self addSubview:[self anchorViewRight]];
        
        [anchorLeft release];
        [anchorRight release];
    }
    return self;
}

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

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    CGContextSetShadow(currentContext, CGSizeMake(5.0000f, 5.0000f), 20.0000f);
    
    CGContextSetLineWidth(currentContext, 5.0000f);

    if ([[self topLeftToBottomRight] boolValue]) {
        [[UIColor greenColor] set];
        CGPoint origin = CGPointMake(rect.origin.x, rect.origin.y);
        CGPoint destination = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
        CGContextMoveToPoint(currentContext, origin.x, origin.y);
        CGContextAddLineToPoint(currentContext, destination.x, destination.y);
    } else {
        [[UIColor redColor] set];
        CGPoint origin = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
        CGPoint destination = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
        CGContextMoveToPoint(currentContext, origin.x, origin.y);
        CGContextAddLineToPoint(currentContext, destination.x, destination.y);
    }
    
    CGContextStrokePath(currentContext);
}

@end
