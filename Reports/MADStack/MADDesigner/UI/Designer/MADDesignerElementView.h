//
//  MTElementView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTElementView_h
#define Reports_MTElementView_h

#import "MADManagedObjectView.h"
#import <UIKit/UIGestureRecognizer.h>

@class UIPanGestureRecognizer;

@class NSManagedObjectID;
@class NSManagedObjectContext;

@class MADDesignerElementView;

@class MTBarcode;

@class RptqDocumentObject;

@interface MADDesignerElementView : MADManagedObjectView
    <UIGestureRecognizerDelegate>

    @property (assign, getter=isWobbling) bool displayWobbling;
    @property (assign) bool displayHighlighted;

    @property (nonatomic, strong) NSAttributedString *displayStringAttributed;
    @property (nonatomic, strong) UIImage *displayImage;
    @property (nonatomic, strong) MTBarcode *displayBarcode;

    @property (nonatomic, assign, readwrite, getter=isResizingEnabled) BOOL enableResizing;

    - (instancetype)initWithDocumentObject:(RptqDocumentObject *)documentObject;

    + (instancetype)newDesignerElementViewForDocumentObject:(RptqDocumentObject *)documentObject
                                         tapGestureDelegate:(id<UIGestureRecognizerDelegate>)tapGestureDelegate
                                                tapSelector:(SEL)selector;

    - (void)setWobbleRunning:(BOOL)running;
    - (void)flash:(void (^)(BOOL finished))completion;

    - (void)updateForManagedObjectContent:(NSManagedObjectContext *)context;
    - (void)handleGesturePanResizeHandle:(UIPanGestureRecognizer *)gestureRecognizer;

@end

#endif
