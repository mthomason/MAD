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

@class MTResizeHandleView;

@protocol MTResizeHandleViewDelegate
@optional
- (void)resizeHandle:(MTResizeHandleView *)handle didMoveToPoint:(CGPoint)point;
@end

@interface MTResizeHandleView : UIView {
    CGGradientRef gradient;
}

@property (weak) IBOutlet id <MTResizeHandleViewDelegate> delegate;
@property (assign) MNSCompusPosition type;
@property (assign) CGPoint initalPoint;
@property (assign, getter = isHighlighted) BOOL highlighted;

- (instancetype)initWithFrame:(CGRect)frame andType:(MNSCompusPosition)position NS_DESIGNATED_INITIALIZER;

@end

#endif
