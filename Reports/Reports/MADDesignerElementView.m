//
//  DataObject.m
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerElementView.h"
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>
#import "MTElementCanvas.h"
#import "MADResizeHandles.h"
#import "UIView+NSObjectIdTag.h"
#import "MTAlignment.h"
#import "UIColor+EverydayApps.h"
#import "MTBarcode.h"
#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentObjectBarcode.h"
#import "RptqDocumentObjectBarcode+Extras.h"
#import "RptqDocumentObjectImage.h"
#import "RptqDocumentObjectImage+Extras.h"

#import "MTResizeHandleView.h"
#import "CGGeometry+Extras.h"

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0
#define kAnimationTranslateX 2.0
#define kAnimationTranslateY 2.0


#pragma mark - MTElementView

@interface MADDesignerElementView ()
    <MTElementCanvasDelegate>

@property (nonatomic, strong) MTElementCanvas *canvasView;
@property (nonatomic, strong) MADResizeHandles *resizeHandles;

@end

@implementation MADDesignerElementView

#pragma mark - NSObject

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

+ (NSStringDrawingOptions)drawingOptions {
    return NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
}

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
    
    UIColor *labelBackgroundColor = [UIColor colorWithRed:1.0000f green:1.0000f blue:1.0000f alpha:alpha];
    self.backgroundColor = labelBackgroundColor;
}

- (instancetype)initWithDocumentObject:(RptqDocumentObject *)documentObject {
    
    CGRect viewFrame = CGRectMake(CGPointZero.x, CGPointZero.y, documentObject.size.width, documentObject.size.height);
    self = [super initWithFrame: viewFrame];

    if (self) {
        
        MTElementCanvas *canvasView = [[MTElementCanvas alloc] initWithFrame:viewFrame];
        canvasView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        canvasView.backgroundColor = [UIColor clearColor];
        canvasView.canvasDelegate = self;
        
        [self addSubview:canvasView];
        self.canvasView = canvasView;
                
        self.displayHighlighted = NO;
        self.objectIdTag = documentObject.objectID;
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
        
        self.tag = documentObject.objectID.hash;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self updateForManagedObjectContent:documentObject.managedObjectContext];

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
    id resizeView;
    for (resizeView in self.resizeHandles.resizeHandles) {
        ((UIView *)resizeView).hidden = NO;
    }
}

- (void)hideResizeHandles {
    id resizeView;
    for (resizeView in self.resizeHandles.resizeHandles) {
        ((UIView *)resizeView).hidden = YES;
    }
}

#pragma mark - Members

- (void)flash:(void (^)(BOOL finished))completion {
    [UIView animateWithDuration: 0.6666f delay: 0.3333f options: UIViewAnimationOptionAutoreverse
                     animations: ^{
                         self.backgroundColor = [[UIColor tintColorBlue] colorWithAlphaComponent:0.33333333];
                     } completion:^(BOOL finished) {
                         if (finished) self.backgroundColor = [UIColor clearColor];
                         completion(finished);
                     }];
}

- (void)setWobbleRunning:(BOOL)running {
    [self setDisplayWobbling:running];
    if (running) {
        NSInteger randomInt = arc4random() % 500;
        float r = (randomInt / 500.0000f) + 0.5000f;
        
        self.transform = CGAffineTransformMakeRotation(degreesToRadians( (kAnimationRotateDeg * -1.0) - r ));
        CGAffineTransform rightWobble = CGAffineTransformMakeRotation(degreesToRadians( kAnimationRotateDeg + r ));
        
        self.layer.anchorPoint = CGPointMake(0.5000f, 0.5000f);
        
        [UIView animateWithDuration:0.3500
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                         animations:^{
                             [UIView setAnimationRepeatCount:NSNotFound];
                             self.transform = rightWobble;
                         }
                         completion:nil];
        
    } else {
        [self.layer removeAllAnimations];
        self.transform = CGAffineTransformIdentity;
    }
}

- (BOOL)isWobbleRunning {
    return [self displayWobbling];
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
        
        
        NSString *string = [documentObject designerRepresentationText];
        
        switch ([documentObject getType]) {
                
            case MTDocumentObjectTypeImage:
                self.displayImage = documentObject.isImage.image;
                break;
                
            case MTDocumentObjectTypeBarcode: {
                MTBarcode *displayBarcode = [RptqDocumentObjectBarcode barcodeWithDocumentObject:documentObject.isBarcode];
                self.displayBarcode = displayBarcode;
                break;
            }
                
            default:
                break;
        }
        
        NSDictionary *attributes = [documentObject attributesForDrawingText];
        NSAttributedString *attributtedString = [[NSAttributedString alloc] initWithString:string
                                                                                attributes:attributes];
        self.displayStringAttributed = attributtedString;
        
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
        }
        
        //CGAffineTransform transformSpacing = CGAffineTransformMakeTranslation([documentObject spacingLeft],
        //                                                                      [documentObject spacingTop]);
        //drawingBounds = CGRectApplyAffineTransform(drawingBounds, transformSpacing);
        [self setNeedsLayout];
        [self setNeedsDisplay];
    }
    
}

@end
