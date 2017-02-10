//
//  DataObject.m
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerElementView.h"

#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>

#import <QuartzCore/CALayer.h>

#import <MADCocoaExtensions/UIView+Animations.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADTextStyle.h>

#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementImage.h>
#import <MAD/RptqDocumentElementBarcode.h>
#import <MAD/RptqDocumentElementBarcode+Extras.h>

#import <MAD/MADElementStylizedText.h>
#import <MAD/MADAlignment.h>

#import "MADElementCanvas.h"
#import "MADResizeHandles.h"
#import "MADResizeHandleView.h"
#import "UITapGestureRecognizer+Designer.h"

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
    <MADElementCanvasDelegate, UIGestureRecognizerDelegate>

    @property (nonatomic, weak)     MADElementCanvas *canvasView;
    @property (nonatomic, strong)   MADResizeHandles *resizeHandles;

    @property (nonatomic, weak)     NSManagedObjectContext *managedObjectContext;

    @property (nonatomic, copy)     NSManagedObjectID *objectID;

@end

@implementation MADDesignerElementView

@synthesize identifier = _identifier;

- (void)dealloc {
    [_canvasView removeFromSuperview];
    if (_resizeHandles) {
        UIView *view;
        for (view in _resizeHandles.resizeHandles) {
            [view removeFromSuperview];
        }
    }
}

+ (instancetype)newDesignerElementViewForDocumentObject:(RptqDocumentElement *)documentObject
                                     tapGestureDelegate:(id <UIGestureRecognizerDelegate>)tapGestureDelegate
                                            tapSelector:(SEL)selector {
    id elementView = [[self alloc] initWithDocumentObject: documentObject
                                       tapGestureDelegate: tapGestureDelegate
                                              tapSelector: selector];
    return elementView;
}

- (instancetype)initWithDocumentObject:(RptqDocumentElement *)documentObject
                    tapGestureDelegate:(id <UIGestureRecognizerDelegate>)tapGestureDelegate
                           tapSelector:(SEL)selector {
    
    CGRect rect = MADRectOfSize([documentObject sizeCalculated]);
    if (self = [self initWithFrame: rect]) {
        
        self.identifier = documentObject.identifier;
        self.objectID = documentObject.objectID.copy;
        
        MADElementCanvas *canvasView;
        canvasView = [[MADElementCanvas alloc] initWithFrame:rect];
        canvasView.autoresizingMask = MADViewAutoresizingFlexable();
        canvasView.backgroundColor = [UIColor clearColor];
        canvasView.canvasDelegate = self;
        [self addSubview:canvasView];
        self.canvasView = canvasView;
        

        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.displayWobbling = NO;
        self.displayHighlighted = NO;
        
        self.backgroundColor = [UIColor clearColor];
        
        
        MADResizeHandles *resizeHandles = [[MADResizeHandles alloc] init];
        for (UIView *view in resizeHandles.resizeHandles) {
            [self addSubview:view];
        }
        self.resizeHandles = resizeHandles;
        
        self.clipsToBounds = NO;
        
        self.autoresizingMask = MADViewAutoresizingFlexable();
        
        [self updateWithElement:documentObject];
        
        self.managedObjectContext = documentObject.managedObjectContext;
        UIGestureRecognizer *tap;
        tap = [MADTapGestureRecognizer newTapGestureRecognizerTapWithTarget: tapGestureDelegate
                                                                     action: selector
                                                                   delegate: tapGestureDelegate];
        [self addGestureRecognizer:tap];
    }
    return self;
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
    _canvasView.contentScaleFactor = contentScaleFactor;
    super.contentScaleFactor = contentScaleFactor;
}

- (void)setNeedsDisplay {
    [_canvasView  setNeedsDisplay];
    [super setNeedsDisplay];
}

- (void)setTransform:(CGAffineTransform)transform {
    _canvasView.transform = transform;
    super.transform = transform;
}

- (void)setAlpha:(CGFloat)alpha {
    super.alpha = alpha;
    
    UIColor *labelBackgroundColor = [[UIColor alloc] initWithRed: 1.0000f
                                                           green: 1.0000f
                                                            blue: 1.0000f
                                                           alpha: alpha];
    self.backgroundColor = labelBackgroundColor;
}

- (void)setEnableResizing:(BOOL)enableResizing {
    if (_enableResizing != enableResizing) {
        _enableResizing = enableResizing;
        if (enableResizing) [self showResizeHandles];
        else [self hideResizeHandles];
    }
}

- (void)showResizeHandles { }

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
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width,
                                              locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

- (void)handleGesturePanResizeHandle:(UIPanGestureRecognizer *)gestureRecognizer {
    UIView *piece = nil;
    if ([piece isKindOfClass:[MADResizeHandleView class]]) {
        [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan
                                || gestureRecognizer.state == UIGestureRecognizerStateChanged) {
            CGPoint translation = [gestureRecognizer translationInView:piece.superview];
            switch (((MADResizeHandleView *)piece).type) {
                case north:
                case south:
                    [self resize:CGSizeMake(self.frame.size.width,
                                            self.frame.size.width + translation.y)];
                    break;
                case east:
                case west:
                    [self resize:CGSizeMake(self.frame.size.width + translation.x,
                                            self.frame.size.width)];
                    break;
                case northWest:
                case northEast:
                case southEast:
                case southWest:
                default:
                    [self resize:CGSizeMake(self.frame.size.width + translation.x,
                                            self.frame.size.width + translation.y)];
                    break;
            }
            [gestureRecognizer setTranslation:CGPointZero inView:piece.superview];
        }
    }
}

- (void)resize:(CGSize)size {

    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    RptqDocumentElement *documentObject = [managedObjectContext objectWithID:self.objectID];
    [documentObject setSizeValue:size];

    NSError * __autoreleasing *error = NULL;
    [managedObjectContext save:error];
    NSAssert(error == NULL, @"Error: %@", *error);
    
}
#pragma mark - Members

- (void)flash:(void (^)(BOOL finished))completion {


    void (^animates)(void);
    animates = ^{
        self.backgroundColor = [[MADColorEverydayApps newColorBlue] colorWithAlphaComponent:0.33333333f];
    };
    void (^handleAnimatesCompletion)(BOOL);
    handleAnimatesCompletion = ^(BOOL finished) {
        if (finished) self.backgroundColor = [UIColor clearColor];
        completion(finished);
    };
    [UIView animateWithDuration: 0.6666f
                          delay: 0.3333f
                        options: UIViewAnimationOptionAutoreverse
                     animations: animates
                     completion: handleAnimatesCompletion];
}

- (void)setWobbleRunning:(BOOL)running {
    self.displayWobbling = running;
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
    RptqDocumentElement *element = (RptqDocumentElement *)[context objectWithID:self.objectID];
    [self updateWithElement:element];
    self.managedObjectContext = context;
}

- (void)updateWithElement:(RptqDocumentElement *)element {
    if (element != nil) {
        
        CGRect marginViewFrame = [element boundsContentView];
        
        self.frame = marginViewFrame;
        self.displayBarcode = nil;
        self.displayImage = nil;
        
        
        NSString *string = [element designerRepresentationText];
        
        switch (element.documentObjectType) {
                
            case MTDocumentObjectTypeImage:
                self.displayImage = ((RptqDocumentElementImage *)element).image;
                break;
                
            case MTDocumentObjectTypeBarcode: {
                MTBarcode *barcode;
                barcode = [RptqDocumentElementBarcode newBarcode:(RptqDocumentElementBarcode *)element];
                self.displayBarcode = barcode;
                break;
            }
                
            default:
                break;
        }
        
        MADElementStylizedText *attributesText;
        attributesText = [[MADElementStylizedText alloc] initWithFontName:element.fontname
                                                                 fontSize:element.fontsize
                                                                textStyle:element.style
                                                      horizontalAlignment:element.alignment.horizontal];
        
        NSAttributedString *attributtedString = [[NSAttributedString alloc] initWithString: string
                                                                                attributes: attributesText.fontAttributes];
        self.displayStringAttributed = attributtedString;
        [self setNeedsLayout];
        [self setNeedsDisplay];
    }
}

@end
