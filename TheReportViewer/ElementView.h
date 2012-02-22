//
//  DataObject.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewResizeHandle.h"

@class ElementView;

@protocol ElementViewDelegate
- (BOOL)elementDidRequestRemoval:(ElementView *)view;
@end

@interface ElementView : UIView
    <UIViewResizeHandleDelegate>

@property (retain) UIScrollView *containerView;

@property (assign) IBOutlet id <ElementViewDelegate> delegate;

@property (retain) NSString *stringElm;
@property (assign) CGSize originalSize;
@property (assign) CGPoint originalPointCenter;

@property (assign) NSTimeInterval lastTime;
@property (assign) NSTimeInterval currentTime;

@property (retain) UIViewResizeHandle *handleEdgeRight;
@property (retain) UIViewResizeHandle *handleEdgeLeft;
@property (retain) UIViewResizeHandle *handleEdgeTop;
@property (retain) UIViewResizeHandle *handleEdgeBottom;
@property (retain) UIViewResizeHandle *handleCornerTopRight;
@property (retain) UIViewResizeHandle *handleCornerTopLeft;
@property (retain) UIViewResizeHandle *handleCornerBottomRight;
@property (retain) UIViewResizeHandle *handleCornerBottomLeft;

- (id)initWithFrame:(CGRect)frame inView:(UIScrollView *)pview;

@end