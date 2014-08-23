//
//  DataObject.m
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTElementView.h"
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>
#import "UIView+NSObjectIdTag.h"
#import "RptqDocumentObjectImage+Extras.h"
#import "Constants.h"
#import "MTTextView.h"
#import "UIDevice+Hack.h"
#import "UIColor+EverydayApps.h"
#import "MTBarcode.h"
#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"

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
                            options: [MTElementView drawingOptions]
                            context: nil];
    } else {
        [displayObject drawRect:rect];
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, kDashedBorderWidth);
    UIColor *tintColor = [UIColor tintColorGold2];
    CGContextSetStrokeColorWithColor(context, tintColor.CGColor);
    CGContextSetLineDash(context, kDashedPhase, kDashedLinesLength, kDashedCount) ;
    CGContextAddRect(context, rect);
    CGContextStrokePath(context);
}


@end

#pragma mark - MTElementView

@interface MTElementView ()
    <MTElementCanvasDelegate>

@property (nonatomic, strong) MTElementCanvas *canvasView;

@end

@implementation MTElementView

#pragma mark - NSObject


#pragma mark - UIView

+ (NSStringDrawingOptions)drawingOptions {
    return NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
}

- (instancetype)init {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Use initWithFrame: andObjectId:.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (instancetype)initWithFrame:(CGRect)frame {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Use initWithFrame: andObjectId:.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
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

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    [self.canvasView  setNeedsDisplay];
}

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    
    UIColor *labelBackgroundColor = [UIColor colorWithRed:1.0000f green:1.0000f blue:1.0000f alpha:alpha];
    [self setBackgroundColor:labelBackgroundColor];
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
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSelection:)];
        [tapGestureRecognizer setNumberOfTapsRequired:1];
        [tapGestureRecognizer setNumberOfTouchesRequired:1];
        [tapGestureRecognizer setDelegate: self];
        [self addGestureRecognizer:tapGestureRecognizer];
        
        [self setDisplayHighlighted:NO];
        [self setObjectIdTag:objectId];

        [self setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self setDisplayWobbling: NO];
        [self setDisplayHighlighted: NO];
        
        [self setBackgroundColor:[UIColor clearColor]];
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

- (void)toggleSelection:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self.delegate didTouchElementView:self];
    }
}

- (id)debugQuickLookObject {
    return self;
}

@end
