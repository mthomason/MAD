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
#import "MADManagedObjectViewProtocol.h"
#import "MADViewAnimationProtocol.h"
#import "MADDesignerElementViewProtocol.h"
#import "MADDesignerElementViewDataSource.h"

@protocol UIGestureRecognizerDelegate;

@class UIPanGestureRecognizer, NSManagedObjectID, NSManagedObjectContext, MADDesignerElementView,
       MTBarcode, RptqDocumentElement;

@interface MADDesignerElementView : UIView
    <MADDesignerElementViewProtocol, MADManagedObjectViewProtocol, MADViewAnimationProtocol>

    @property (nonatomic, readonly, weak) NSManagedObjectContext *managedObjectContext;

    @property (nonatomic, strong) id displayObject;
    @property (nonatomic, readonly, copy) NSString *textRepresentation;

    + (instancetype)newDesignerElementView:(RptqDocumentElement *)documentObject
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
