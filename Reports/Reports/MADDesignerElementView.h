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

@class MADDesignerElementView, MTBarcode, NSManagedObjectID, NSManagedObjectContext;

@protocol MTElementViewDelegate
- (void)didTouchElementView:(MADDesignerElementView *)elementView;
@end

@interface MADDesignerElementView : UIView
    <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <MTElementViewDelegate> delegate;

@property (assign) BOOL displayWobbling;
@property (assign) BOOL displayHighlighted;

@property (nonatomic, strong) NSAttributedString *displayStringAttributed;
@property (nonatomic, strong) UIImage *displayImage;
@property (nonatomic, strong) MTBarcode *displayBarcode;

+ (NSStringDrawingOptions)drawingOptions;

- (void)setWobbleRunning:(BOOL)running;
- (BOOL)isWobbleRunning;
- (void)flash:(void (^)(BOOL finished))completion;

- (instancetype)initWithObjectId:(NSManagedObjectID *)objectId
                 inObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)updateForManagedObjectContent:(NSManagedObjectContext *)context;

@end

#endif
