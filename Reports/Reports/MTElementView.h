//
//  MTElementView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTElementView_h
#define Reports_MTElementView_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class MTElementView, MTBarcode;

@protocol MTElementViewDelegate
- (void)didTouchElementView:(MTElementView *)elementView;
- (void)didHighlightElementView:(id)sender;
- (void)didUnhighlightElementView:(id)sender;
- (void)sizeChanged:(id)sender;
@end

@interface MTElementView : UIView
    <UIGestureRecognizerDelegate>

@property (nonatomic, assign) id <MTElementViewDelegate> delegate;

@property (assign) BOOL displayWobbling;
@property (assign) BOOL displayHighlighted;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) UIFont *displayFont;
@property (nonatomic, retain) NSParagraphStyle *paragraphStyle;
@property (nonatomic, retain) NSString *displayText;
@property (nonatomic, retain) NSNumber *underlineStyle;
@property (nonatomic, retain) NSNumber *strikeThroughStyle;
@property (nonatomic, retain) NSAttributedString *displayStringAttributed;
@property (nonatomic, assign) CGRect drawingRect;
@property (nonatomic, assign) NSStringDrawingOptions drawingOptions;
@property (nonatomic, retain) UIImage *displayImage;
@property (nonatomic, retain) MTBarcode *displayBarcode;

- (void)setWobbleRunning:(BOOL)running;
- (BOOL)isWobbleRunning;

- (id)initWithObjectId:(NSManagedObjectID *)objectId inObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

#endif
