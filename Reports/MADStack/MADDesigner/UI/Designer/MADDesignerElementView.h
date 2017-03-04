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

@protocol UIGestureRecognizerDelegate;

@class UIPanGestureRecognizer, NSManagedObjectID, NSManagedObjectContext, MADDesignerElementView,
       MTBarcode, RptqDocumentElement;

@interface MADDesignerElementView : UIView
    <MADManagedObjectViewProtocol>

    @property (nonatomic, readwrite, assign) BOOL displayHighlighted;
    @property (nonatomic, readwrite, assign, getter=isWobbling) BOOL displayWobbling;
    @property (nonatomic, readwrite, assign, getter=isResizingEnabled) BOOL enableResizing;

    @property (nonatomic, readwrite, strong) NSAttributedString *displayStringAttributed;
    @property (nonatomic, readwrite, strong) UIImage *displayImage;
    @property (nonatomic, readwrite, strong) MTBarcode *displayBarcode;


    - (instancetype)initWithDocumentObject:(RptqDocumentElement *)documentObject
                        tapGestureDelegate:(id <UIGestureRecognizerDelegate>)tapGestureDelegate
                               tapSelector:(SEL)selector;
    + (instancetype)newDesignerElementViewForDocumentObject:(RptqDocumentElement *)documentObject
                                         tapGestureDelegate:(id <UIGestureRecognizerDelegate>)tapGestureDelegate
                                                tapSelector:(SEL)selector;

    - (void)setWobbleRunning:(BOOL)running;
    - (void)flash:(void (^)(BOOL finished))completion;

    - (void)updateForManagedObjectContent:(NSManagedObjectContext *)context;
    - (void)handleGesturePanResizeHandle:(UIPanGestureRecognizer *)gestureRecognizer;

@end

#endif
