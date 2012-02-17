//
//  DataObject.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ElementView;

@protocol ElementViewDelegate
- (BOOL)elementDidRequestRemoval:(ElementView *)view;
@end

@interface ElementView : UIView {
	NSString *stringElm;
	CGSize originalSize;
	CGSize largeSize;
	CGPoint originalPoint;					//Do not synthsize
	CGPoint lastPointPlusOne;
	CGPoint lastPoint;
	CGPoint currentPoint;
	NSTimeInterval lastTimePlusOne;
	NSTimeInterval lastTime;
	NSTimeInterval currentTime;
}

@property (retain) UIScrollView *containerView;

@property (assign, nonatomic) IBOutlet id <ElementViewDelegate> delegate;

@property (nonatomic, retain) NSString *stringElm;
@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, assign) CGPoint originalPointCenter;

- (id)initWithFrame:(CGRect)frame inView:(UIScrollView *)pview;

- (CGPoint)slide:(float)rateOfChange;

@end