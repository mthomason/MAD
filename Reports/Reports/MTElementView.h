//
//  DataObject.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "UIViewResizeHandle.h"

@interface MTElementView : UIView;

- (void)setResizeHandlesVisable:(BOOL)visable;
- (BOOL)handlesVisable;

- (void)setWobbleRunning:(BOOL)running;
- (BOOL)isWobbleRunning;

- (void)setHighlighted:(BOOL)selected;
- (BOOL)isHighlighted;

- (id)initWithFrame:(CGRect)frame;

@end