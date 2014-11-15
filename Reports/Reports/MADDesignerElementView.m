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
    if ([displayObject isKindOfClass:[MTBarcode class]]) {
        [displayObject initSampleData];
        [displayObject setForgroundColor:[UIColor lightGrayColor]];
    }
    
    if ([displayObject isKindOfClass:[NSAttributedString class]]) {
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

@end

@implementation MADDesignerElementView

#pragma mark - NSObject


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

- (instancetype)initWithObjectId:(NSManagedObjectID *)objectId inObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    CGSize viewSize = [[RptqDocumentObject documentObjectForObjectID:objectId managedObjectContext:managedObjectContext] size];
    CGRect viewFrame = CGRectMake(CGPointZero.x, CGPointZero.y, viewSize.width, viewSize.height);
    self = [super initWithFrame: viewFrame];

    if (self) {
        
        MTElementCanvas *canvasView = [[MTElementCanvas alloc] initWithFrame:viewFrame];
        canvasView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        canvasView.backgroundColor = [UIColor clearColor];
        canvasView.canvasDelegate = self;
        
        [self addSubview:canvasView];
        self.canvasView = canvasView;
                
        [self setDisplayHighlighted:NO];
        [self setObjectIdTag:objectId];

        self.translatesAutoresizingMaskIntoConstraints = YES;
        [self setDisplayWobbling: NO];
        [self setDisplayHighlighted: NO];
        
        self.backgroundColor = [UIColor clearColor];
        [self setClipsToBounds:YES];

    }
    return self;
}

#pragma mark - Members

- (void)flash:(void (^)(BOOL finished))completion {
    __weak UIView *weakself = self;
    [UIView animateWithDuration: 0.6666f delay:0.3333f
                        options: UIViewAnimationOptionAutoreverse
                     animations: ^{
                         weakself.backgroundColor = [UIColor edaYellow];
                     } completion:^(BOOL finished) {
                         if (finished) {
                             weakself.backgroundColor = [UIColor clearColor];
                         }
                         completion(finished);
                     }];
}

- (void)setWobbleRunning:(BOOL)running {
    [self setDisplayWobbling:running];
    if (running) {
        NSInteger randomInt = arc4random() % 500;
        float r = (randomInt / 500.0000f) + 0.5000f;
        
        CGAffineTransform leftWobble = CGAffineTransformMakeRotation(degreesToRadians( (kAnimationRotateDeg * -1.0) - r ));
        CGAffineTransform rightWobble = CGAffineTransformMakeRotation(degreesToRadians( kAnimationRotateDeg + r ));
        
        [self setTransform: leftWobble];
        
        [[self layer] setAnchorPoint:CGPointMake(0.5000f, 0.5000f)];
        
        [UIView animateWithDuration:0.3500
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                         animations:^{
                             [UIView setAnimationRepeatCount:NSNotFound];
                             [self setTransform: rightWobble];
                         }
                         completion:nil];
        
    } else {
        [[self layer] removeAllAnimations];
        [self setTransform: CGAffineTransformIdentity];
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
        
        CGAffineTransform transformSpacing = CGAffineTransformMakeTranslation([documentObject spacingLeft],
                                                                              [documentObject spacingTop]);
        drawingBounds = CGRectApplyAffineTransform(drawingBounds, transformSpacing);
        [self setNeedsLayout];
        [self setNeedsDisplay];
    }
    
}


/*


- (void)updateElementView:(MTElementView *)elementView forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (elementView) {
        
        // TODO: Only update specific properties when they change.
        
        RptqDocumentObject *documentObject = [self documentObjectForElementView:elementView inManagedObjectContext:managedObjectContext];
        
        if (documentObject != nil) {
            
            CGRect marginViewFrame = [documentObject boundsContentView];
            
            [elementView setFrame: marginViewFrame];
            
            NSString *fontName = [documentObject fontname];
            CGFloat pointSize = [[documentObject fontsize] floatValue];
            
            UIFont *displayFont = nil;
            if ([fontName length] == 0) {
                displayFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            } else {
                MTFont *stylizedDisplayFont = [[MTFont alloc] initWithFamilyName:fontName andPointSize:pointSize];
                if ([[documentObject bold] boolValue] && [[documentObject italic] boolValue]) {
                    displayFont = [stylizedDisplayFont boldItalicFont];
                } else if ([[documentObject bold] boolValue]) {
                    displayFont = [stylizedDisplayFont boldFont];
                } else if ([[documentObject italic] boolValue]) {
                    displayFont = [stylizedDisplayFont italicFont];
                } else {
                    displayFont = [stylizedDisplayFont font];
                }
            }
            
            if (displayFont == nil) {
                displayFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            }
            [self setDisplayFont:displayFont];
            
            NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            
            MTHorizontalAlignment horizontalAlignment = [[documentObject horizontalAlignment] integerValue];
            NSTextAlignment textAlignment;
            switch (horizontalAlignment) {
                case MTHorizontalAlignmentCenter:
                    textAlignment = NSTextAlignmentCenter;
                    break;
                case MTHorizontalAlignmentLeft:
                    textAlignment = NSTextAlignmentLeft;
                    break;
                case MTHorizontalAlignmentRight:
                    textAlignment = NSTextAlignmentRight;
                    break;
                case MTHorizontalAlignmentJustified:
                    textAlignment = NSTextAlignmentJustified;
                    break;
                default:
                    textAlignment = NSTextAlignmentLeft;
                    break;
            }
            [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
            [paragraphStyle setAlignment:textAlignment];
            [elementView setParagraphStyle:paragraphStyle];
            
            NSString *string = [documentObject designerRepresentationText];
            
            [elementView setDisplayImage:nil];
            [elementView setDisplayBarcode:nil];
            [elementView setDisplayImage:nil];
            
            if ([documentObject getType] == MTDocumentObjectTypeImage) {
                
                [elementView setDisplayImage:[[documentObject isImage] image]];
                
            } else if ([documentObject getType] == MTDocumentObjectTypeBarcode) {
                
                MTBarcode *displayBarcode = [RptqDocumentObjectBarcode barcodeWithDocumentObject:[documentObject isBarcode]];
                [elementView setDisplayBarcode:displayBarcode];
            }
            
            NSNumber *underlineStyle = [[documentObject underline] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
            [elementView setUnderlineStyle:underlineStyle];
            
            NSNumber *strikeThroughStyle = [[documentObject strike] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
            [elementView setStrikeThroughStyle:strikeThroughStyle];
            
            NSDictionary *attributes = @{
                                         NSParagraphStyleAttributeName : [elementView paragraphStyle],
                                         NSFontAttributeName : [elementView displayFont],
                                         NSStrikethroughStyleAttributeName : [elementView strikeThroughStyle],
                                         NSUnderlineStyleAttributeName : [elementView underlineStyle]
                                         };
            NSAttributedString *attributtedString = [[NSAttributedString alloc] initWithString:string
                                                                                    attributes:attributes];
            [elementView setDisplayStringAttributed:attributtedString];
            
            CGSize sizeContentView = [documentObject sizeContentView];
            CGRect boundsContentView = [documentObject boundsContentView]; //x1
            NSStringDrawingOptions drawingOptions = (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading);
            [elementView setDrawingOptions:drawingOptions];
            CGRect boundingRect = [[elementView displayStringAttributed] boundingRectWithSize:sizeContentView options:drawingOptions context:nil]; //x35
            CGRect drawingBounds = CGRectIntersection(boundingRect, boundsContentView);
            
            MTVerticalAlignment verticalAlignment = [[documentObject verticalAlignment] integerValue];
            
            switch (verticalAlignment) {
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
            
            CGFloat contentViewX = documentObject.marginLeft.floatValue + documentObject.borderWidthLeft.floatValue + documentObject.paddingLeft.floatValue;
            CGFloat contentViewY = documentObject.marginTop.floatValue + documentObject.borderHeightTop.floatValue + documentObject.paddingTop.floatValue;
            CGAffineTransform transformPaddingBorderMargin = CGAffineTransformMakeTranslation(contentViewX, contentViewY);
            drawingBounds = CGRectApplyAffineTransform(drawingBounds, transformPaddingBorderMargin);
            [elementView setDrawingRect:drawingBounds];
            
            [elementView setNeedsLayout];
            [elementView setNeedsDisplay];
        }
    }
}

*/

@end
