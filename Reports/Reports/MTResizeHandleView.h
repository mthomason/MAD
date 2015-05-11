//
//  UIViewResizeHandle.h
//  Reports
//
//  Created by Michael Thomason on 2/17/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTResizeHandleView_h
#define Reports_MTResizeHandleView_h

#import <UIKit/UIKit.h>
#import "CGGeometry+Extras.h"

@class MTResizeHandleView;

@protocol MTResizeHandleViewDelegate
@optional
- (void)resizeHandle:(MTResizeHandleView *)handle didMoveToPoint:(CGPoint)point;
@end

@interface MTResizeHandleView : UIView {
    CGGradientRef _gradient;
}

@property (weak) IBOutlet id <MTResizeHandleViewDelegate> delegate;
@property (assign) MADCompusDirection type;
@property (assign) CGPoint initalPoint;
@property (assign, getter = isHighlighted) BOOL highlighted;

- (instancetype)initWithFrame:(CGRect)frame andType:(MADCompusDirection)position NS_DESIGNATED_INITIALIZER;

@end

#endif
