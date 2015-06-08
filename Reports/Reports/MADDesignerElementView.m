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

#pragma mark - MTElementCanvas

@protocol MTElementCanvasDelegate <NSObject>

- (id)displayObject;

@end

@interface MTElementCanvas : UIView

@property (nonatomic, weak) id <MTElementCanvasDelegate>canvasDelegate;
@property (nonatomic, strong) UIFont *displayFont;
@property (nonatomic, strong) NSParagraphStyle *paragraphStyle;
@property (nonatomic, strong) NSNumber *underlineStyle;
@property (nonatomic, strong) NSNumber *strikeThroughStyle;
@property (nonatomic, assign) CGRect drawingRect;

@end

@implementation MTElementCanvas

static CGFloat const kDashedBorderWidth     = (0.5f);
static CGFloat const kDashedPhase           = (0.0f);
static CGFloat const kDashedLinesLength[]   = {4.0f, 2.0f};
static size_t const kDashedCount            = (2.0f);

- (void)drawRect:(CGRect)rect {
    
    id displayObject = [self.canvasDelegate displayObject];
    if ([displayObject isKindOfClass: [MTBarcode class]]) {
        [displayObject initSampleData];
        [displayObject setForgroundColor:[UIColor lightGrayColor]];
    }
    
    if ([displayObject isKindOfClass: [NSAttributedString class]]) {
        [displayObject drawWithRect: rect
                            options: [MADDesignerElementView drawingOptions]
                            context: nil];
    } else {
        [displayObject drawInRect:rect];
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, kDashedBorderWidth);
    UIColor *tintColor = [UIColor blackColor];
    CGContextSetStrokeColorWithColor(context, tintColor.CGColor);
    CGContextSetLineDash(context, kDashedPhase, kDashedLinesLength, kDashedCount) ;
    CGContextAddRect(context, rect);
    CGContextStrokePath(context);
}

@end

#pragma mark - MTElementView

@interface MADDesignerElementView ()
    <MTElementCanvasDelegate>

@property (nonatomic, strong) MTElementCanvas *canvasView;

@property (nonatomic, strong) MTResizeHandleView *handleEdgeRight;
@property (nonatomic, strong) MTResizeHandleView *handleEdgeLeft;
@property (nonatomic, strong) MTResizeHandleView *handleEdgeTop;
@property (nonatomic, strong) MTResizeHandleView *handleEdgeBottom;
@property (nonatomic, strong) MTResizeHandleView *handleCornerTopRight;
@property (nonatomic, strong) MTResizeHandleView *handleCornerTopLeft;
@property (nonatomic, strong) MTResizeHandleView *handleCornerBottomRight;
@property (nonatomic, strong) MTResizeHandleView *handleCornerBottomLeft;

@property (nonatomic, strong) NSArray *resizeHandles;

@end

@implementation MADDesignerElementView

#pragma mark - NSObject

- (void)dealloc {
    [_handleEdgeRight removeFromSuperview];
    [_handleEdgeLeft removeFromSuperview];
    [_handleEdgeTop removeFromSuperview];
    [_handleEdgeBottom removeFromSuperview];
    [_handleCornerTopRight removeFromSuperview];
    [_handleCornerTopLeft removeFromSuperview];
    [_handleCornerBottomRight removeFromSuperview];
    [_handleCornerBottomLeft removeFromSuperview];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.handleEdgeLeft.center = CGEdgeLeftPointInRect(self.frame);
    self.handleEdgeRight.center = CGEdgeRightPointInRect(self.frame);
    self.handleEdgeBottom.center = CGEdgeBottomPointInRect(self.frame);
    self.handleEdgeTop.center = CGEdgeTopPointInRect(self.frame);
    self.handleCornerBottomLeft.center = CGCornerBottomLeftPointInRect(self.frame);
    self.handleCornerBottomRight.center = CGCornerBottomRightPointInRect(self.frame);
    self.handleCornerTopRight.center = CGCornerTopRightPointInRect(self.frame);
    self.handleCornerTopLeft.center = CGCornerTopLeftPointInRect(self.frame);
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

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    
    UIColor *labelBackgroundColor = [UIColor colorWithRed:1.0000f green:1.0000f blue:1.0000f alpha:alpha];
    self.backgroundColor = labelBackgroundColor;
}

- (instancetype)initWithObjectId:(NSManagedObjectID *)objectID inObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    CGSize viewSize = [[RptqDocumentObject documentObjectForObjectID:objectID managedObjectContext:managedObjectContext] size];
    CGRect viewFrame = CGRectMake(CGPointZero.x, CGPointZero.y, viewSize.width, viewSize.height);
    self = [super initWithFrame: viewFrame];

    if (self) {
        
        MTElementCanvas *canvasView = [[MTElementCanvas alloc] initWithFrame:viewFrame];
        canvasView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        canvasView.backgroundColor = [UIColor clearColor];
        canvasView.canvasDelegate = self;
        
        [self addSubview:canvasView];
        self.canvasView = canvasView;
                
        self.displayHighlighted = NO;
        self.objectIdTag = objectID;
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.displayWobbling = NO;
        self.displayHighlighted = NO;
        
        self.backgroundColor = [UIColor clearColor];
        
        CGSize handleSize = CGSizeMake(10.0000f, 10.0000f);
        CGRect handleBounds = CGRectMake(CGPointZero.x, CGPointZero.y, handleSize.width, handleSize.height);
        
        MTResizeHandleView *handleCornerTopLeft = [[MTResizeHandleView alloc] initWithFrame: handleBounds
                                                                                    andType: northWest];
        handleCornerTopLeft.hidden = YES;
        [self addSubview: handleCornerTopLeft];
        NSArray *resizeHandles = [NSArray arrayWithObject:handleCornerTopLeft];
        self.handleCornerTopLeft = handleCornerTopLeft;
        
        MTResizeHandleView *handleCornerTopRight = [[MTResizeHandleView alloc] initWithFrame: handleBounds
                                                                                     andType: northEast];
        handleCornerTopRight.hidden = YES;
        [self addSubview: handleCornerTopRight];
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerTopRight];
        self.handleCornerTopRight = handleCornerTopRight;
        
        MTResizeHandleView *handleCornerBottomRight = [[MTResizeHandleView alloc] initWithFrame: handleBounds
                                                                                        andType: southEast];
        handleCornerBottomRight.hidden = YES;
        [self addSubview: handleCornerBottomRight];
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerBottomRight];
        self.handleCornerBottomRight = handleCornerBottomRight;
        
        MTResizeHandleView *handleCornerBottomLeft = [[MTResizeHandleView alloc] initWithFrame: handleBounds
                                                                                       andType: southWest];
        handleCornerBottomLeft.hidden = YES;
        [self addSubview: handleCornerBottomLeft];
        resizeHandles = [resizeHandles arrayByAddingObject:handleCornerBottomLeft];
        self.handleCornerBottomLeft = handleCornerBottomLeft;
        
        MTResizeHandleView *handleEdgeTop = [[MTResizeHandleView alloc] initWithFrame: handleBounds
                                                                              andType: north];
        handleEdgeTop.hidden = YES;
        [self addSubview: handleEdgeTop];
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeTop];
        self.handleEdgeTop = handleEdgeTop;
        
        MTResizeHandleView *handleEdgeBottom = [[MTResizeHandleView alloc] initWithFrame: handleBounds
                                                                                 andType: south];
        handleEdgeBottom.hidden = YES;
        [self addSubview: handleEdgeBottom];
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeBottom];
        self.handleEdgeBottom = handleEdgeBottom;
        
        MTResizeHandleView *handleEdgeRight = [[MTResizeHandleView alloc] initWithFrame: handleBounds
                                                                                andType: east];
        handleEdgeRight.hidden = YES;
        [self addSubview: handleEdgeRight];
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeRight];
        self.handleEdgeRight = handleEdgeRight;
        
        MTResizeHandleView *handleEdgeLeft = [[MTResizeHandleView alloc] initWithFrame: handleBounds
                                                                               andType: west];
        handleEdgeLeft.hidden = YES;
        [self addSubview: handleEdgeLeft];
        resizeHandles = [resizeHandles arrayByAddingObject:handleEdgeLeft];
        self.handleEdgeLeft = handleEdgeLeft;
        
        self.resizeHandles = resizeHandles;
        self.clipsToBounds = NO;
        
        self.tag = objectID.hash;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    }
    return self;
}

- (void)setEnableResizing:(BOOL)enableResizing {
    if (_enableResizing != enableResizing) {
        _enableResizing = enableResizing;
        if (enableResizing) {
            [self showResizeHandles];
        } else {
            [self hideResizeHandles];
        }
    }
}

- (void)showResizeHandles {
    id resizeView;
    for (resizeView in self.resizeHandles) {
        ((UIView *)resizeView).hidden = NO;
    }
}

- (void)hideResizeHandles {
    id resizeView;
    for (resizeView in self.resizeHandles) {
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
                                                                                  options: [MADDesignerElementView drawingOptions]
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
