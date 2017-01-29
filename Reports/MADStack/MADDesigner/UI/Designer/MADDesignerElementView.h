//
//  MTElementView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTElementView_h
#define Reports_MTElementView_h

#import <UIKit/UIView.h>
#import "MADManagedObjectViewProtocol.h"

@protocol UIGestureRecognizerDelegate;

@class UIPanGestureRecognizer;
@class NSManagedObjectID;
@class NSManagedObjectContext;
@class MADDesignerElementView;
@class MTBarcode;
@class RptqDocumentElement;

typedef id <UIGestureRecognizerDelegate> MADGestureDelegate;

@interface MADDesignerElementView : UIView
    <MADManagedObjectViewProtocol>

    @property (nonatomic, readwrite, assign) BOOL displayHighlighted;
    @property (nonatomic, readwrite, assign, getter=isWobbling) BOOL displayWobbling;
    @property (nonatomic, readwrite, assign, getter=isResizingEnabled) BOOL enableResizing;

    @property (nonatomic, readwrite, strong) NSAttributedString *displayStringAttributed;
    @property (nonatomic, readwrite, strong) UIImage *displayImage;
    @property (nonatomic, readwrite, strong) MTBarcode *displayBarcode;


    - (instancetype)initWithDocumentObject:(RptqDocumentElement *)documentObject;

    + (instancetype)newDesignerElementViewForDocumentObject:(RptqDocumentElement *)documentObject
                                         tapGestureDelegate:(MADGestureDelegate)tapGestureDelegate
                                                tapSelector:(SEL)selector;

    - (void)setWobbleRunning:(BOOL)running;
    - (void)flash:(void (^)(BOOL finished))completion;

    - (void)updateForManagedObjectContent:(NSManagedObjectContext *)context;
    - (void)handleGesturePanResizeHandle:(UIPanGestureRecognizer *)gestureRecognizer;

@end

#endif
