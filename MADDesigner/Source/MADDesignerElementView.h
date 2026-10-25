//
//  MTElementView.h
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTElementView_h
#define Reports_MTElementView_h

#import "MADManagedObjectViewProtocol.h"
#import <MAD/MADDocumentObjectType.h>
#import <MAD/RptqStoreContext.h>
#import <UIKit/UIView.h>


@protocol UIGestureRecognizerDelegate;
@class UIPanGestureRecognizer, MADDesignerElementView, RptqDocumentElement;

@protocol MADDesignerElementViewDataSource <NSObject>
@required
- (MADPrintPageElementType)documentObjectTypeForElementView:(MADDesignerElementView *)elementView;
- (id)documentObjectForElementView:(MADDesignerElementView *)elementView;
- (CGSize)documentObjectSizeForElementView:(MADDesignerElementView *)elementView;
@optional
@end

@protocol MADViewAnimationProtocol <NSObject>
- (void)flash:(void (^)(BOOL finished))completion;
@end

@protocol MADDesignerElementViewProtocol <NSObject>
@required
@property (nonatomic, readwrite, assign) BOOL displayWobbling;
@property (nonatomic, readwrite, assign) BOOL enableResizing;
@property (nonatomic, readwrite, assign) BOOL displayHighlighted;
@end

@interface MADDesignerElementView : UIView <MADDesignerElementViewProtocol, MADManagedObjectViewProtocol, MADViewAnimationProtocol>
@property (nonatomic, readonly, weak) RptqStoreContext *managedObjectContext;
@property (nonatomic, strong) id displayObject;
@property (nonatomic, readonly, copy) NSString *textRepresentation;

- (void)setWobbleRunning:(BOOL)running;
- (void)flash:(void (^)(BOOL finished))completion;

- (void)updateForManagedObjectContent:(RptqStoreContext *)context;
- (void)updateWithElement:(RptqDocumentElement *)element;
- (void)handleGesturePanResizeHandle:(UIPanGestureRecognizer *)gestureRecognizer;

- (void)applyBorder;
- (void)removeBorder;

@end

#endif
