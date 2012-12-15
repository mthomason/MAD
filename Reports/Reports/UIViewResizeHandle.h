//
//  UIViewResizeHandle.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/17/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MNSCompusPosition) {
	north = 1,
	south,
	east,
	west,
    northEast,
    northWest,
    southEast,
    southWest
};

@class UIViewResizeHandle;

@protocol UIViewResizeHandleDelegate
@optional
- (void)resizeHandle:(UIViewResizeHandle *)handle didMoveToPoint:(CGPoint)point;
@end

@interface UIViewResizeHandle : UIView {
    CGGradientRef gradient;
}

@property (assign) IBOutlet id <UIViewResizeHandleDelegate> delegate;
@property (assign) MNSCompusPosition type;
@property (assign) CGPoint initalPoint;
@property (assign, getter = isHighlighted) BOOL highlighted;

- (id)initWithFrame:(CGRect)frame andType:(MNSCompusPosition)position;

@end