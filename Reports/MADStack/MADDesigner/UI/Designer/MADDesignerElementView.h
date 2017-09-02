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
#import <MAD/MADDocumentObjectType.h>
#import "MADManagedObjectViewProtocol.h"
#import "MADViewAnimationProtocol.h"

@protocol UIGestureRecognizerDelegate;

@class UIPanGestureRecognizer, NSManagedObjectID, NSManagedObjectContext, MADDesignerElementView,
       MTBarcode, RptqDocumentElement;

@protocol MADDesignerElementViewDataSource <NSObject>
  @required
    - (MADPrintPageElementType)documentObjectTypeForElementView:(MADDesignerElementView *)elementView;
    - (id)documentObjectForElementView:(MADDesignerElementView *)elementView;
    - (CGSize)documentObjectSizeForElementView:(MADDesignerElementView *)elementView;
  @optional
@end

@protocol MADDesignerElementViewProtocol <NSObject>
  @required
    @property (nonatomic, readwrite, assign) BOOL displayWobbling;
    @property (nonatomic, readwrite, assign) BOOL enableResizing;
    @property (nonatomic, readwrite, assign) BOOL displayHighlighted;

@end

@interface MADDesignerElementView : UIView
    <MADDesignerElementViewProtocol, MADManagedObjectViewProtocol, MADViewAnimationProtocol>

    @property (nonatomic, readonly, weak) NSManagedObjectContext *managedObjectContext;

    @property (nonatomic, strong) id displayObject;
    @property (nonatomic, readonly, copy) NSString *textRepresentation;

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
