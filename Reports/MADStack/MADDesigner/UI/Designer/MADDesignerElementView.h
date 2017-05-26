//
//  MTElementView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTElementView_h
#define Reports_MTElementView_h

#import <UIKit/UIView.h>
#import <MAD/MADVerticalAlignmentType.h>
#import <MAD/MADHorizontalAlignmentType.h>
#import "MADManagedObjectViewProtocol.h"

@protocol UIGestureRecognizerDelegate;

@class UIPanGestureRecognizer, NSManagedObjectID, NSManagedObjectContext, MADDesignerElementView,
       MTBarcode, RptqDocumentElement;

@interface MADDesignerElementView : UIView
    <MADManagedObjectViewProtocol>

    @property (nonatomic, readwrite, assign) BOOL displayHighlighted;
    @property (nonatomic, readwrite, assign, getter=isWobbling) BOOL displayWobbling;
    @property (nonatomic, readwrite, assign, getter=isResizingEnabled) BOOL enableResizing;

    @property (nonatomic, readonly, weak) NSManagedObjectContext *managedObjectContext;
    @property (nonatomic, readonly, copy) NSManagedObjectID *objectID;

    @property (nonatomic, strong) id displayObject;
    @property (nonatomic, readonly, copy) NSString *textRepresentation;

    - (instancetype)initWithDocumentObject:(RptqDocumentElement *)documentObject
                        tapGestureDelegate:(id <UIGestureRecognizerDelegate>)tapGestureDelegate
                               tapSelector:(SEL)selector;
    + (instancetype)newDesignerElementViewForDocumentObject:(RptqDocumentElement *)documentObject
                                         tapGestureDelegate:(id <UIGestureRecognizerDelegate>)tapGestureDelegate
                                                tapSelector:(SEL)selector;

    - (void)setWobbleRunning:(BOOL)running;
    - (void)flash:(void (^)(BOOL finished))completion;

    - (void)updateForManagedObjectContent:(NSManagedObjectContext *)context;
    - (void)updateWithElement:(RptqDocumentElement *)element;
    - (void)handleGesturePanResizeHandle:(UIPanGestureRecognizer *)gestureRecognizer;

    - (void)applyBorder;
    - (void)removeBorder;

@end

#endif
