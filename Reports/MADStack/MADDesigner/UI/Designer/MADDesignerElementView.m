//
//  DataObject.m
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerElementView.h"

#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>

#import <QuartzCore/CALayer.h>

#import <UIKit/NSParagraphStyle.h>
#import <UIKit/UIGraphics.h>

#import <MADCocoaExtensions/UIView+Animations.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADTextStyle.h>

#import <MAD/RptqRect+Extras.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqTextStyle.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementImage.h>
#import <MAD/RptqDocumentElementBarcode.h>
#import <MAD/RptqDocumentElementBarcode+Extras.h>

#import <MAD/MADElementStylizedText.h>
#import <MAD/MADAlignment.h>

#import "MADDesignerElementTextView.h"
#import "MADDesignerElementBarcodeView.h"
#import "MADDesignerElementImageView.h"

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

    @property (nonatomic, strong)   MADResizeHandles *resizeHandles;
    @property (nonatomic, weak)     NSManagedObjectContext *managedObjectContext;
    @property (nonatomic, copy)     NSManagedObjectID *objectID;
    @property (nonatomic, readwrite, copy) NSString *textRepresentation;

@end

@implementation MADDesignerElementView

@synthesize identifier = _identifier;

- (void)dealloc {
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
    
    switch (documentObject.documentObjectType) {
        case MTDocumentObjectTypeImage:
            self = [[MADDesignerElementImageView alloc] initWithFrame:rect];
            break;
        case MTDocumentObjectTypeBarcode:
            self = [[MADDesignerElementBarcodeView alloc] initWithFrame:rect];
            break;
        default:
            self = [[MADDesignerElementTextView alloc] initWithFrame:rect];
            break;
    }
    
    if (self) {
        
        self.identifier = documentObject.identifier;
        self.objectID = documentObject.objectID.copy;
        
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

#pragma mark -
#pragma mark NSObject

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

#pragma mark -
#pragma mark UIView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    id displayObject = [self displayObject];
    
    if ([displayObject isKindOfClass: [NSAttributedString class]]) {
        [displayObject drawWithRect: rect
                            options: NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                            context: nil];
    } else if ([displayObject isKindOfClass: [MTBarcode class]]) {
        [displayObject loadSampleData];
        MADColor *color = [[MADColor alloc] initWithColor:[UIColor lightGrayColor]];
        ((MTBarcode *)displayObject).forgroundColor = color;
    } else {
        [displayObject drawInRect:rect];
    }
    
    static const CGFloat kDashedBorderWidth     = (0.5000f);
    static const CGFloat kDashedPhase           = (0.0000f);
    static const CGFloat kDashedLinesLength[]   = {4.0000f, 2.0000f};
    static size_t const kDashedCount            = (2.0000f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, kDashedBorderWidth);
    UIColor *tintColor = [UIColor blackColor];
    CGContextSetStrokeColorWithColor(context, tintColor.CGColor);
    CGContextSetLineDash(context, kDashedPhase, kDashedLinesLength, kDashedCount) ;
    CGContextAddRect(context, rect);
    CGContextStrokePath(context);
}

- (void)layoutSubviews {
    [super layoutSubviews];

    //
    RptqDocumentElement *element;
    element = [_managedObjectContext objectWithID: _objectID];
    
    //self.frame = element.rect.frame;
    
    // Position handles
    [self.resizeHandles positionAroundRect:self.frame];
}

- (void)setAlpha:(CGFloat)alpha {
    super.alpha = alpha;
    
    UIColor *labelBackgroundColor = [[UIColor alloc] initWithRed: 1.0000f
                                                           green: 1.0000f
                                                            blue: 1.0000f
                                                           alpha: alpha];
    self.backgroundColor = labelBackgroundColor;
}

#pragma mark -
#pragma mark Accessors

- (void)showResizeHandles { }

- (void)hideResizeHandles {
    id resizeView;
    for (resizeView in self.resizeHandles.resizeHandles) {
        ((UIView *)resizeView).hidden = YES;
    }
}

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

- (void)setEnableResizing:(BOOL)enableResizing {
    if (_enableResizing != enableResizing) {
        _enableResizing = enableResizing;
        if (enableResizing) [self showResizeHandles];
        else [self hideResizeHandles];
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

#pragma mark -
#pragma mark Update model

- (void)updateWithElement:(RptqDocumentElement *)element {
    if (element != nil) {
        
        CGRect marginViewFrame = [element boundsContentView];
        self.frame = marginViewFrame;
        
        NSString *textRepresentation = [element designerRepresentationText];
        self.textRepresentation = textRepresentation.copy;
        
    }
}

- (void)updateSetMarginTop:(float)value {
    
}
- (void)updateSetMarginBottom:(float)value {
    
}
- (void)updateSetMarginLeft:(float)value {
    
}
- (void)updateSetMarginRight:(float)value {
    
}

#pragma mark -
#pragma mark Event Handlers

- (void)updateForManagedObjectContent:(NSManagedObjectContext *)context {
    RptqDocumentElement *element = (RptqDocumentElement *)[context objectWithID:self.objectID];
    [self updateWithElement:element];
    self.managedObjectContext = context;
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

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint locationInView = [gestureRecognizer locationInView:gestureRecognizer.view];
        gestureRecognizer.view.layer.anchorPoint =
                CGPointMake(locationInView.x / gestureRecognizer.view.bounds.size.width,
                            locationInView.y / gestureRecognizer.view.bounds.size.height);
        gestureRecognizer.view.center =
                [gestureRecognizer locationInView:gestureRecognizer.view.superview];
    }
}

#pragma mark -
#pragma mark Standard

- (id)debugQuickLookObject {
    return self;
}

@end
