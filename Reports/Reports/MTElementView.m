//
//  DataObject.m
//  Reports
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTElementView.h"
#import <QuartzCore/QuartzCore.h>
#import "CGGeometry+Extras.h"
#import "MTResizeHandleView.h"
#import "UIView+NSObjectIdTag.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "Constants.h"
#import "MTFont.h"
#import "MTTextView.h"
#import "UIColor+EverydayApps.h"

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0
#define kAnimationTranslateX 2.0
#define kAnimationTranslateY 2.0

@interface MTElementView ()

// This element view is made of four total views.
@property (nonatomic, retain) UIImageView *imageView;   //Display image preview for image objects
@property (nonatomic, retain) UILabel *displayLabel;    //Display label floats in the padding
@property (nonatomic, retain) UIView *paddingView;      //Padding is inside the visible view
@property (nonatomic, retain) UIView *visibleView;      //View floats inside the margin
//@property (nonatomic, retain) UIView *marginView;       //[self view]

@property (assign) BOOL displayWobbling;
@property (assign) BOOL displayHighlighted;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end

@implementation MTElementView

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:_managedObjectContext];
    [_visibleView release];
    [_displayLabel release];
    [_paddingView release];
    [_imageView release];
    [_managedObjectContext release];
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

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    [[self paddingView] setNeedsDisplay];
    [[self displayLabel] setNeedsDisplay];
    [[self visibleView] setNeedsDisplay];
}

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    UIColor *labelBackgroundColor = [[UIColor alloc] initWithRed:1.0000f green:1.0000f blue:1.0000f alpha:alpha];
    [self setBackgroundColor:labelBackgroundColor];
    [labelBackgroundColor release];
    [[self visibleView] setAlpha:alpha];
    [[self paddingView] setAlpha:alpha];
}

- (id)initWithObjectId:(NSManagedObjectID *)objectId inObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
    CGSize viewSize = [documentObject viewSize];
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
        
        //CGRect frame = [self marginViewBounds];

        [self setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self setDisplayWobbling: NO];
        [self setDisplayHighlighted: NO];
        
        if ([UIDevice isLagacyOS]) {
            [self setBackgroundColor:[UIColor whiteColor]];
        } else {
            [self setBackgroundColor:[UIColor clearColor]];
        }
        [self setClipsToBounds:YES];
        
        UIView *visibleView = [[UIView alloc] initWithFrame:CGRectZero];
        [visibleView setClipsToBounds:YES];
        if ([UIDevice isLagacyOS]) {
            [[visibleView layer] setBorderWidth:1.0000f];
            [[visibleView layer] setBorderColor:[[UIColor greenColor] CGColor]];
            [visibleView setBackgroundColor:[UIColor whiteColor]];
        } else {
            [visibleView setBackgroundColor:[UIColor clearColor]];
        }
        [visibleView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [self addSubview: visibleView];
        [self setVisibleView:visibleView];
        [visibleView release];
        
        UIView *labelBackground = [[UIView alloc] initWithFrame:CGRectZero];
        [labelBackground setClipsToBounds:YES];
        if ([UIDevice isLagacyOS]) {
            [[labelBackground layer] setBorderColor:[[UIColor blackColor] CGColor]];
            [[labelBackground layer] setBorderWidth:1.0000f];
            [labelBackground setBackgroundColor:[UIColor whiteColor]];
        } else {
            [labelBackground setBackgroundColor:[UIColor clearColor]];
        }
        [labelBackground setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [[self visibleView] addSubview:labelBackground];
        [self setPaddingView:labelBackground];
        [labelBackground release];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:[[self paddingView] frame]];
        [imageView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [[self paddingView] addSubview:imageView];
        [self setImageView:imageView];
        [imageView release];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        if ([UIDevice isLagacyOS]) {
            [label setBackgroundColor:[UIColor whiteColor]];
        } else {
            [label setBackgroundColor:[UIColor clearColor]];
        }
        [label setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [[self paddingView] addSubview:label];
        [self setDisplayLabel:label];
        [label release];

        [self initalDisplaySettings];
                
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(managedObjectContextDidSave:)
                              name:NSManagedObjectContextDidSaveNotification
                            object:managedObjectContext];
    }
    return self;
}

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    NSArray *updatedObjects = [[notification userInfo] objectForKey: NSUpdatedObjectsKey];

    for (id updatedObject in updatedObjects) {
        if ([updatedObject isKindOfClass:[RptqDocumentObject class]]) {
            if ([[self objectIdTag] isEqual:[updatedObject objectID]]) {
                [self updateDisplayLabel];
                break;
            }
        }
    }

}

- (void)initalDisplaySettings {
    
    // MARK: Display settings that should only run once.
    // This is a bit of a performance hack.  Right now, I'm redisplaying the whole label
    //   instead of only the changed parts.  That's cool, but should I reset the image, when
    //   there is currently no UI to change the image?  No!
    
    // TODO: Update image when changed.
    
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[self objectIdTag] fromObjectContext:[self managedObjectContext]];
    if (documentObject != nil) {
        [[self imageView] setImage:[[documentObject isImage] image]];
    }
    
    [self updateDisplayLabel];

}

- (void)updateDisplayLabel {
    
    // TODO: Only update specific properties when they change.
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[self objectIdTag] fromObjectContext:[self managedObjectContext]];
    
    if (documentObject != nil) {

        CGRect marginViewFrame = [documentObject marginViewFrame];
        CGRect paddingViewFrame = [documentObject paddingViewFrame];
        CGRect elementViewFrame = [documentObject elementViewFrame];
        
        [self setFrame: marginViewFrame];
        [[self visibleView] setFrame: paddingViewFrame];
        [[self paddingView] setFrame: elementViewFrame];

        NSString *fontName = [documentObject fontname];
        CGFloat pointSize = [[documentObject fontsize] floatValue];
        
        UIFont *displayFont;
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
            [stylizedDisplayFont release];
        }
        
        NSString *string = [documentObject designerRepresentationText];
        
        NSNumber *underlineStyle = [[documentObject underline] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
        NSNumber *strikeThroughStyle = [[documentObject strike] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
        
        [displayFont retain];
        NSDictionary *attributes = @{NSFontAttributeName : displayFont,
                                     NSStrikethroughStyleAttributeName : strikeThroughStyle,
                                     NSUnderlineStyleAttributeName : underlineStyle
                                     };
        [displayFont release];
        NSAttributedString *attributtedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
        
        [[self displayLabel] setAttributedText:attributtedString];
        
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
        [[self displayLabel] setTextAlignment:textAlignment];
        
        MTVerticalAlignment verticalAlignment = [[documentObject verticalAlignment] integerValue];
        UIBaselineAdjustment baselineAdjustment;
        switch (verticalAlignment) {
            case MTVerticalAlignmentTop: {
                
                [[self displayLabel] sizeToFit];
                CGFloat originX = [[self paddingView] frame].origin.x;
                CGFloat originY = [[self paddingView] frame].origin.y;
                CGFloat sizeWidth = [[self paddingView] frame].size.width;
                CGFloat sizeHeight = [[self displayLabel] frame].size.height;
                
                [[self displayLabel] setFrame:CGRectMake(originX, originY, sizeWidth, sizeHeight)];
                //baselineAdjustment = UIBaselineAdjustmentNone;
                break;
            }
            case MTVerticalAlignmentCenter: {
                [[self displayLabel] setFrame:[[self paddingView] frame]];
                //baselineAdjustment = UIBaselineAdjustmentAlignCenters;
                break;
            }
            case MTVerticalAlignmentBottom: {
                [[self displayLabel] sizeToFit];
                
                CGFloat originX = [[self paddingView] frame].origin.x;
                CGFloat originY = [[self paddingView] frame].origin.y + [[self paddingView] frame].size.height - [[self displayLabel] frame].size.height;
                CGFloat sizeWidth = [[self paddingView] frame].size.width;
                CGFloat sizeHeight = [[self displayLabel] frame].size.height;
                [[self displayLabel] setFrame:CGRectMake(originX, originY, sizeWidth, sizeHeight)];
                //baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
                break;
            }
            default:
                baselineAdjustment = UIBaselineAdjustmentNone;
                break;
        }
        [attributtedString release];
    

        [self setNeedsLayout];
        [self setNeedsDisplay];
//        [[self visibleView] setNeedsLayout];
//        [[self paddingView] setNeedsLayout];
//        [[self displayLabel] setNeedsLayout];
//        [[self displayLabel] setNeedsDisplay];
    }
//    [self setNeedsDisplay];
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
