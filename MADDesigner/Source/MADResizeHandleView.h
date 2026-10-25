//
//  UIViewResizeHandle.h
//  Reports
//
//  Created by Michael Thomason on 2/17/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADResizeHandleView_h
#define Reports_MADResizeHandleView_h

#import <UIKit/UIView.h>
#import <MADCocoaExtensions/MADCompassDirection.h>

@protocol MADResizeHandleViewDelegate;

@interface MADResizeHandleView : UIView

    @property (nonatomic, weak) IBOutlet id <MADResizeHandleViewDelegate> delegate;
    @property (nonatomic, assign) MADCompassDirection type;
    @property (nonatomic, assign) CGPoint initalPoint;
    @property (nonatomic, assign, getter = isHighlighted) BOOL highlighted;

    - (instancetype)initWithFrame:(CGRect)frame andType:(MADCompassDirection)position;

@end

@protocol MADResizeHandleViewDelegate
    - (void)resizeHandle:(MADResizeHandleView *)handle translate:(CGPoint)distance;
@end

#endif
