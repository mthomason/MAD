//
//  MTElementView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTElementView_h
#define Reports_MTElementView_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MTResizeHandleView.h"
#import "MTBorderedView.h"

@class MTElementView;

@protocol MTElementViewDelegate
- (void)didSelectElementView:(id)sender;
- (void)didDeselectElementView:(id)sender animated:(BOOL)animated;
- (void)didHighlightElementView:(id)sender;
- (void)didUnhighlightElementView:(id)sender;
- (void)sizeChanged:(id)sender;
@end

@interface MTElementView : UIView
    <UIGestureRecognizerDelegate>

@property (nonatomic, assign) id <MTElementViewDelegate> delegate;

@property (nonatomic, assign) BOOL displaySelected;

- (void)setWobbleRunning:(BOOL)running;
- (BOOL)isWobbleRunning;
- (BOOL)isSelected;

- (id)initWithObjectId:(NSManagedObjectID *)objectId inObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)updateDisplayLabel;

@end

#endif
