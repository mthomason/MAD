//
//  DataObject.m
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerElementView.h"
#import "MTElementCanvas.h"
#import "MADResizeHandles.h"
#import "MTResizeHandleView.h"
#import "UITapGestureRecognizer+Designer.h"
#import <MAD/RptqDocumentObject.h>
#import <MAD/RptqDocumentObject+Extras.h>
#import <MAD/RptqDocumentObjectImage.h>
#import <MAD/RptqDocumentObjectBarcode.h>
#import <MAD/RptqDocumentObjectBarcode+Extras.h>

#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>

#import <MADCocoaExtensions/UIView+Animations.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0
#define kAnimationTranslateX 2.0
#define kAnimationTranslateY 2.0

static const UIViewAnimationOptions MADViewAnimationOptionsWobble = (UIViewAnimationOptions)
                                                    (UIViewAnimationOptionAllowUserInteraction |
                                                        UIViewAnimationOptionRepeat |
                                                        UIViewAnimationOptionAutoreverse);

#pragma mark - MTElementView

@interface MADDesignerElementView ()
    <MTElementCanvasDelegate, UIGestureRecognizerDelegate>

    @property (nonatomic, strong) MTElementCanvas *canvasView;
    @property (nonatomic, strong) MADResizeHandles *resizeHandles;

    @property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

@end

@implementation MADDesignerElementView

+ (instancetype)newDesignerElementViewForDocumentObject:(RptqDocumentObject *)documentObject
                                     tapGestureDelegate:(id<UIGestureRecognizerDelegate>)tapGestureDelegate
                                            tapSelector:(SEL)selector {

    id elementView = [[self alloc] initWithDocumentObject: documentObject];
    [elementView updateForManagedObjectContent:documentObject.managedObjectContext];
    
    UIGestureRecognizer *tapGestureRecognizer;
    tapGestureRecognizer = [MADTapGestureRecognizer newTapGestureRecognizerElementTouchWithTarget: tapGestureDelegate
                                                                                           action: selector
                                                                                         delegate: tapGestureDelegate];
    [elementView addGestureRecognizer:tapGestureRecognizer];
    elementView = elementView;
    return elementView;
}

#pragma mark - NSObject

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [gestureRecognizer respondsToSelector:@selector(handleGesturePanResizeHandle:)] ||
        [otherGestureRecognizer respondsToSelector:@selector(handleGesturePanResizeHandle:)] ?
            YES : NO;
}

- (BOOL)gestureRecognizer: (UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch: (UITouch *)touch {
    return YES;
}

- (void)dealloc {
    for (UIView *view in _resizeHandles.resizeHandles) {
        [view removeFromSuperview];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.resizeHandles positionAroundRect:self.frame];
}

#pragma mark - UIView

- (id)displayObject {
    if (self.displayImage != nil) {
        return self.displayImage;
    } else if (self.displayBarcode != nil) {
        return self.displayBarcode;
    } else {
        return self.displayStringAttributed;
    }
}

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor {
    [self.canvasView setContentScaleFactor:contentScaleFactor];
    [super setContentScaleFactor:contentScaleFactor];
}

- (void)setNeedsDisplay {
    [self.canvasView  setNeedsDisplay];
    [super setNeedsDisplay];
}

- (void)setTransform:(CGAffineTransform)transform {
    self.canvasView.transform = transform;
    [super setTransform:transform];
}

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    
    UIColor *labelBackgroundColor = [UIColor colorWithRed:1.0000f green:1.0000f
                                                     blue:1.0000f alpha:alpha];
    self.backgroundColor = labelBackgroundColor;
}

- (instancetype)initWithDocumentObject:(RptqDocumentObject *)documentObject {
    
    if (self = [self initWithFrame: MADRectOfSize(documentObject.size)]) {
        
        MTElementCanvas *canvasView = [[MTElementCanvas alloc] initWithFrame:MADRectOfSize(documentObject.size)];
        canvasView.autoresizingMask = MADViewAutoresizingFlexable();
        canvasView.backgroundColor = [UIColor clearColor];
        canvasView.canvasDelegate = self;
        [self addSubview:canvasView];
        self.canvasView = canvasView;
        
        NSManagedObjectID *objectIdTag = documentObject.objectID.copy;
        self.objectIdTag = objectIdTag;
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.displayWobbling = false;
        self.displayHighlighted = false;
        
        self.backgroundColor = [UIColor clearColor];
        

        MADResizeHandles *resizeHandles = [[MADResizeHandles alloc] init];
        for (UIView *view in resizeHandles.resizeHandles) {
            //UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesturePanResizeHandle:)];
            //[panGesture setDelegate:self];
            //[view addGestureRecognizer:panGesture];
            //view.userInteractionEnabled = YES;
            [self addSubview:view];
        }
        self.resizeHandles = resizeHandles;
        
        self.clipsToBounds = NO;
        
        self.autoresizingMask = MADViewAutoresizingFlexable();
        
        [self updateForManagedObjectContent:documentObject.managedObjectContext];
        
        self.managedObjectContext = documentObject.managedObjectContext;

    }
    return self;
}

- (void)setEnableResizing:(BOOL)enableResizing {
    if (_enableResizing != enableResizing) {
        _enableResizing = enableResizing;
        if (enableResizing) [self showResizeHandles];
        else [self hideResizeHandles];
    }
}

- (void)showResizeHandles {
    //id resizeView;
    //for (resizeView in self.resizeHandles.resizeHandles) {
    //    ((UIView *)resizeView).hidden = NO;
    //}
}

- (void)hideResizeHandles {
    id resizeView;
    for (resizeView in self.resizeHandles.resizeHandles) {
        ((UIView *)resizeView).hidden = YES;
    }
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

- (void)handleGesturePanResizeHandle:(UIPanGestureRecognizer *)gestureRecognizer {
    UIView *piece = nil;
    if ([piece isKindOfClass:[MTResizeHandleView class]]) {
        [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
        if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
            CGPoint translation = [gestureRecognizer translationInView:piece.superview];
            switch (((MTResizeHandleView *)piece).type) {
                case north:
                case south:
                    [self resize:CGSizeMake(self.frame.size.width, self.frame.size.width + translation.y)];
                    break;
                case east:
                case west:
                    [self resize:CGSizeMake(self.frame.size.width + translation.x, self.frame.size.width)];
                    break;
                case northWest:
                case northEast:
                case southEast:
                case southWest:
                default:
                    [self resize:CGSizeMake(self.frame.size.width + translation.x, self.frame.size.width + translation.y)];
                    break;
            }
            [gestureRecognizer setTranslation:CGPointZero inView:piece.superview];
        }
    }
}

- (void)resize:(CGSize)size {

    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    RptqDocumentObject *documentObject = [managedObjectContext objectWithID:self.objectIdTag];

    NSNumber *n = [[NSNumber alloc] initWithFloat:size.width];
    documentObject.sizewidth = n;
    
    n = [[NSNumber alloc] initWithFloat:size.height];
    documentObject.sizeheight = n;

    NSError * __autoreleasing *error = NULL;
    [managedObjectContext save:error];
    NSAssert(*error == nil, @"Error: %@", *error);
    
}
#pragma mark - Members

- (void)flash:(void (^)(BOOL finished))completion {
    [UIView animateWithDuration: 0.6666f delay: 0.3333f options: UIViewAnimationOptionAutoreverse
                     animations: ^{
                         self.backgroundColor = [[MADColorEverydayApps newColorBlue] colorWithAlphaComponent:0.33333333f];
                     } completion:^(BOOL finished) {
                         if (finished) self.backgroundColor = [UIColor clearColor];
                         completion(finished);
                     }];
}

- (void)setWobbleRunning:(BOOL)running {
    [self setDisplayWobbling:running ? true : false];
    if (running) {
        NSInteger randomInt = arc4random() % 500;
        float r = (randomInt / 500.0000f) + 0.5000f;
        
        self.transform = CGAffineTransformMakeRotation((CGFloat)degreesToRadians( (kAnimationRotateDeg * -1.0) - r ));
        CGAffineTransform rightWobble = CGAffineTransformMakeRotation((CGFloat)degreesToRadians( kAnimationRotateDeg + r ));
        
        self.layer.anchorPoint = CGPointMake(0.5000f, 0.5000f);

        [UIView animateWithDuration:0.3500 delay:0 options: MADViewAnimationOptionsWobble
                         animations: ^{
            [UIView setAnimationRepeatCount:NSNotFound];
            self.transform = rightWobble;
        } completion:nil];
        
    } else {
        [self.layer removeAllAnimations];
        self.transform = CGAffineTransformIdentity;
    }
}

- (id)debugQuickLookObject {
    return self;
}

- (void)updateForManagedObjectContent:(NSManagedObjectContext *)context {
    RptqDocumentObject *documentObject = (RptqDocumentObject *)[context objectWithID:self.objectIdTag];
    if (documentObject != nil) {
        
        CGRect marginViewFrame = [documentObject boundsContentView];
        
        self.frame = marginViewFrame;
        self.displayImage = nil;
        self.displayBarcode = nil;
        self.displayImage = nil;
        
        
        NSString *string = [documentObject copyDesignerRepresentationText];
        
        switch ([documentObject getType]) {
                
            case MTDocumentObjectTypeImage:
                self.displayImage = documentObject.isImage.image;
                break;
                
            case MTDocumentObjectTypeBarcode: {
                MTBarcode *displayBarcode = [RptqDocumentObjectBarcode newBarcodeWithDocumentObject:documentObject.isBarcode];
                self.displayBarcode = displayBarcode;
                break;
            }
                
            default:
                break;
        }
        
        UIFontDescriptor *fontDescriptor = [documentObject newFontDescriptor];
        NSDictionary *attributes = [documentObject newTextAttributesWithFontDescriptor:fontDescriptor];
        NSAttributedString *attributtedString = [[NSAttributedString alloc] initWithString: string
                                                                                attributes: attributes];
        self.displayStringAttributed = attributtedString;
        
        /*
        CGSize sizeContentView = [documentObject sizeContentView];
        CGRect boundsContentView = [documentObject boundsContentView]; //x1
        CGRect boundingRect = [[self displayStringAttributed] boundingRectWithSize: sizeContentView
                                                                           options: self.canvasView.drawingOptions
                                                                           context: nil];
        CGRect drawingBounds = CGRectIntersection(boundingRect, boundsContentView);
        
        switch ([documentObject.verticalAlignment integerValue]) {
            case MTVerticalAlignmentCenter: {
                CGFloat offsetY = (sizeContentView.height - drawingBounds.size.height) / 2.0000f;
                CGAffineTransform transform = CGAffineTransformMakeTranslation(CGSizeZero.width, offsetY);
                drawingBounds = CGRectApplyAffineTransform(drawingBounds, transform);
                break;
            }
            case MTVerticalAlignmentBottom: {
                CGFloat offsetY = sizeContentView.height - drawingBounds.size.height;
                CGAffineTransform transform = CGAffineTransformMakeTranslation(CGSizeZero.width, offsetY);
                drawingBounds = CGRectApplyAffineTransform(drawingBounds, transform);
                break;
            }
            case MTVerticalAlignmentTop:
            default:
                break;
        }*/
        
        //CGAffineTransform transformSpacing = CGAffineTransformMakeTranslation([documentObject spacingLeft],
        //                                                                      [documentObject spacingTop]);
        //drawingBounds = CGRectApplyAffineTransform(drawingBounds, transformSpacing);
        [self setNeedsLayout];
        [self setNeedsDisplay];
    }
    self.managedObjectContext = context;
}

@end
