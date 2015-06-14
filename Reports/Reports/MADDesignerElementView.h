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

@class RptqDocumentObject, MADDesignerElementView, MTBarcode, NSManagedObjectID, NSManagedObjectContext;

@interface MADDesignerElementView : UIView
    <UIGestureRecognizerDelegate>

@property (assign) BOOL displayWobbling;
@property (assign) BOOL displayHighlighted;

@property (nonatomic, strong) NSAttributedString *displayStringAttributed;
@property (nonatomic, strong) UIImage *displayImage;
@property (nonatomic, strong) MTBarcode *displayBarcode;

@property (nonatomic, assign, readwrite, getter=isResizingEnabled) BOOL enableResizing;

+ (NSStringDrawingOptions)drawingOptions;

- (void)setWobbleRunning:(BOOL)running;
- (BOOL)isWobbleRunning;
- (void)flash:(void (^)(BOOL finished))completion;

- (instancetype)initWithDocumentObject:(RptqDocumentObject *)documentObject NS_DESIGNATED_INITIALIZER;

- (void)updateForManagedObjectContent:(NSManagedObjectContext *)context;
- (void)handleGesturePanResizeHandle:(UIPanGestureRecognizer *)gestureRecognizer;

@end

#endif
