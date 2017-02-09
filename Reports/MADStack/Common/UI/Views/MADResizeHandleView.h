//
//  UIViewResizeHandle.h
//  Reports
//
//  Created by Michael Thomason on 2/17/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADResizeHandleView_h
#define Reports_MADResizeHandleView_h

#import <UIKit/UIView.h>
#import <MADCocoaExtensions/MADCompassDirection.h>

@protocol MADResizeHandleViewDelegate;

@interface MADResizeHandleView : UIView

    @property (weak) IBOutlet id <MADResizeHandleViewDelegate> delegate;
    @property (assign) MADCompassDirection type;
    @property (assign) CGPoint initalPoint;
    @property (assign, getter = isHighlighted) BOOL highlighted;

    - (instancetype)initWithFrame:(CGRect)frame andType:(MADCompassDirection)position;

@end

@protocol MADResizeHandleViewDelegate
    - (void)resizeHandle:(MADResizeHandleView *)handle translate:(CGPoint)distance;
@end

#endif
