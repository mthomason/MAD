//
//  DataObject.m
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTElementView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+NSObjectIdTag.h"
#import "RptqDocumentObjectImage+Extras.h"
#import "Constants.h"
#import "MTTextView.h"
#import "UIDevice+Hack.h"

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0
#define kAnimationTranslateX 2.0
#define kAnimationTranslateY 2.0

@interface MTElementView ()

@end

@implementation MTElementView

#pragma mark - NSObject

- (void)dealloc {
    [_displayBarcode release];
    [_displayImage release];
    [_underlineStyle release];
    [_strikeThroughStyle release];
    [_managedObjectContext release];
    [_displayFont release];
    [_displayText release];
    [_paragraphStyle release];
    [_displayStringAttributed release];
	[super dealloc];
}

#pragma mark - UIView

- (id)init {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Use initWithFrame: andObjectId:.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (id)initWithFrame:(CGRect)frame {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.  Use initWithFrame: andObjectId:.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    UIColor *labelBackgroundColor = [[UIColor alloc] initWithRed:1.0000f green:1.0000f blue:1.0000f alpha:alpha];
    [self setBackgroundColor:labelBackgroundColor];
    [labelBackgroundColor release];
}

- (id)initWithObjectId:(NSManagedObjectID *)objectId inObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
    CGSize viewSize = [documentObject size];
    CGRect frame = CGRectMake(CGPointZero.x, CGPointZero.y, viewSize.width, viewSize.height);
    self = [super initWithFrame:frame];

    if (self) {
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSelection:)];
        [tapGestureRecognizer setNumberOfTapsRequired:1];
        [tapGestureRecognizer setNumberOfTouchesRequired:1];
        [tapGestureRecognizer setDelegate: self];
        [self addGestureRecognizer:tapGestureRecognizer];
        [tapGestureRecognizer release];
        
        [self setDisplaySelected:NO];
        [self setDisplayHighlighted:NO];
        [self setObjectIdTag:objectId];
        [self setManagedObjectContext:managedObjectContext];

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

- (void)drawRect:(CGRect)rect {

    if ([self displayImage]) {
        [[self displayImage] drawInRect:rect];
    } else if ([self displayBarcode]) {
        [[self displayBarcode] initSampleData];
        [[self displayBarcode] setForgroundColor:[UIColor lightGrayColor]];
        [[self displayBarcode] drawInRect:rect];
    } else {
        CGAffineTransform transformPaddingBorderMargin = CGAffineTransformMakeTranslation(rect.origin.x, rect.origin.y);
        CGRect drawingBounds = CGRectApplyAffineTransform([self drawingRect], transformPaddingBorderMargin);
        [[self displayStringAttributed] drawWithRect:drawingBounds options:[self drawingOptions] context:nil];
    }
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

- (BOOL)toggleSelected {
    [self setDisplaySelected:[self displaySelected] == NO];
    return [self displaySelected];
}

- (BOOL)isSelected {
    return [self displaySelected];
}

- (void)toggleSelection:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        BOOL displaySelected = [self displaySelected] == NO;
        [self setDisplaySelected:displaySelected];
        if (displaySelected) {
            [[self delegate] didSelectElementView:self];
        } else {
            [[self delegate] didDeselectElementView:self animated:YES];
        }
    }
}

@end
