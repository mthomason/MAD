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

@implementation MTElementView

#pragma mark - NSObject


#pragma mark - UIView

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

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    UIColor *labelBackgroundColor = [UIColor colorWithRed:1.0000f green:1.0000f blue:1.0000f alpha:alpha];
    [self setBackgroundColor:labelBackgroundColor];
}

- (instancetype)initWithObjectId:(NSManagedObjectID *)objectId inObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    CGSize viewSize = [[RptqDocumentObject documentObjectForObjectID:objectId managedObjectContext:managedObjectContext] size];
    self = [super initWithFrame: CGRectMake(CGPointZero.x, CGPointZero.y, viewSize.width, viewSize.height)];

    if (self) {
        
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
        
        if ([UIDevice isLagacyOS]) {
            [self setBackgroundColor:[UIColor whiteColor]];
        } else {
            [self setBackgroundColor:[UIColor clearColor]];
        }
        [self setClipsToBounds:YES];

    }
    return self;
}

static CGFloat const kDashedBorderWidth     = (0.5f);
static CGFloat const kDashedPhase           = (0.0f);
static CGFloat const kDashedLinesLength[]   = {4.0f, 2.0f};
static size_t const kDashedCount            = (2.0f);

- (void)drawRect:(CGRect)rect {

    if (self.displayImage) {
        [[self displayImage] drawInRect:rect];
    } else if (self.displayBarcode) {
        [self.displayBarcode initSampleData];
        [self.displayBarcode setForgroundColor:[UIColor lightGrayColor]];
        [self.displayBarcode drawInRect:rect];
    } else {
        [self.displayStringAttributed drawWithRect:rect options:self.drawingOptions context:nil];
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, kDashedBorderWidth);
    UIColor *tintColor = [UIColor tintColorGold2];
    CGContextSetStrokeColorWithColor(context, tintColor.CGColor);
    CGContextSetLineDash(context, kDashedPhase, kDashedLinesLength, kDashedCount) ;
    CGContextAddRect(context, rect);
    CGContextStrokePath(context);
}

#pragma mark - Members

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
        [[self delegate] didTouchElementView:self];
    }
}

- (id)debugQuickLookObject {
    return self;
}

@end
