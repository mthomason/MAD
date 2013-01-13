//
//  DataObject.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTElementView.h"
#import <QuartzCore/QuartzCore.h>
#import "CGGeometry+Extras.h"
#import "UIViewResizeHandle.h"
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

@property (nonatomic, retain) UILabel *displayLabel;    //Display label floats in the padding
@property (nonatomic, retain) UIView *paddingView;      //Padding is inside the visible view
@property (nonatomic, retain) UIView *visibleView;      //View floats inside the margin
@property (nonatomic, retain) UIView *marginView;       //[self view]

@property (assign) BOOL displayWobbling;
@property (assign) BOOL displayHighlighted;
@property (assign) BOOL displaySelected;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@end

@implementation MTElementView

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:_managedObjectContext];
    [_marginView release];
    [_visibleView release];
    [_displayLabel release];
    [_paddingView release];
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

- (id)initWithObjectId:(NSManagedObjectID *)objectId inObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
    CGSize viewSize = [documentObject viewSize];
    CGRect frame = CGRectMake(CGPointZero.x, CGPointZero.y, viewSize.width, viewSize.height);
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setDisplaySelected:NO];
        [self setDisplayHighlighted:NO];
        [self setObjectIdTag:objectId];
        [self setManagedObjectContext:managedObjectContext];
        
        //CGRect frame = [self marginViewBounds];

        [self setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self setDisplayWobbling: NO];
        [self setDisplayHighlighted: NO];
        
        UIView *marginView = [self retain];
        //[marginView setFrame: frame];
        [marginView setBackgroundColor:[UIColor edaBlackFiftyPercent]];
        [marginView setClipsToBounds:YES];
        [self setMarginView: marginView];
        [marginView release];
        
        //CGRect visibleFrame = [self visibleFrame];
        
        UIView *visibleView = [[UIView alloc] initWithFrame:CGRectZero];
        [visibleView setClipsToBounds:YES];
        [visibleView setBackgroundColor:[UIColor yellowColor]];
        [visibleView setAutoresizingMask:UIViewAutoresizingNone];
        [[self marginView] addSubview: visibleView];
        [self setVisibleView:visibleView];
        [visibleView release];
        
        UIView *labelBackground = [[UIView alloc] initWithFrame:CGRectZero];
        [labelBackground setClipsToBounds:YES];
        [labelBackground setBackgroundColor:[UIColor whiteColor]];
        [labelBackground setAutoresizingMask:UIViewAutoresizingNone];
        [[self visibleView] addSubview:labelBackground];
        [self setPaddingView:labelBackground];
        [labelBackground release];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        //[label setUserInteractionEnabled:NO];
        [label setBackgroundColor:[UIColor whiteColor]];
        [label setAutoresizingMask:UIViewAutoresizingNone];
        [[self paddingView] addSubview:label];
        [self setDisplayLabel:label];
        [label release];

        [self updateDisplayLabel];
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(managedObjectContextDidSave:)
                              name:NSManagedObjectContextDidSaveNotification
                            object:managedObjectContext];
    }
    return self;
}

- (CGRect)marginViewBounds {
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[self objectIdTag] fromObjectContext:[self managedObjectContext]];
    CGRect elementBounds = CGRectMake(CGPointZero.x, CGPointZero.y, [[documentObject sizewidth] floatValue], [[documentObject sizeheight] floatValue]);
    
    CGRect paddingBounds = CGRectMake(CGPointZero.x, CGPointZero.y,
                                      elementBounds.size.width + [[documentObject paddingLeft] floatValue] + [[documentObject paddingRight] floatValue],
                                      elementBounds.size.height + [[documentObject paddingTop] floatValue] + [[documentObject paddingBottom] floatValue]);
    
    CGFloat marginBoundsSizeWidth = [[documentObject marginLeft] floatValue] + [[documentObject marginRight] floatValue] + paddingBounds.size.width;
    CGFloat marginBoundsSizeHeight = [[documentObject marginTop] floatValue] + [[documentObject marginBottom] floatValue] + paddingBounds.size.height;
    CGRect marginBounds = CGRectMake(CGPointZero.x, CGPointZero.y, marginBoundsSizeWidth, marginBoundsSizeHeight);
    
    return marginBounds;
}

- (CGRect)elementFrame {
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[self objectIdTag] fromObjectContext:[self managedObjectContext]];
    CGRect elementBounds = CGRectMake(CGPointZero.x, CGPointZero.y, [[documentObject sizewidth] floatValue], [[documentObject sizeheight] floatValue]);
    CGFloat elementFrameOriginX =  CGPointZero.x + [[documentObject marginLeft] floatValue];
    CGFloat elementFrameOriginY = CGPointZero.y + [[documentObject marginTop] floatValue];
    CGRect elementFrame = CGRectMake(elementFrameOriginX, elementFrameOriginY,
                                     elementBounds.size.width, elementBounds.size.height);
    return elementFrame;
}

- (CGRect)visibleFrame {
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[self objectIdTag] fromObjectContext:[self managedObjectContext]];
    CGRect elementBounds = CGRectMake(CGPointZero.x, CGPointZero.y, [[documentObject sizewidth] floatValue], [[documentObject sizeheight] floatValue]);
    
    return CGRectMake(CGPointZero.x + [[documentObject marginLeft] floatValue],
                      CGPointZero.y + [[documentObject marginTop] floatValue],
                      elementBounds.size.width + [[documentObject paddingLeft] floatValue] + [[documentObject paddingRight] floatValue],
                      elementBounds.size.height + [[documentObject paddingTop] floatValue] + [[documentObject paddingBottom] floatValue]);
}


- (void)managedObjectContextDidSave:(NSNotification *)notification {
    NSArray *updatedObjects = [[notification userInfo] objectForKey: NSUpdatedObjectsKey];

    for (id updatedObject in updatedObjects) {
        if ([updatedObject isKindOfClass:[RptqDocumentObject class]]) {
            if ([[self objectIdTag] isEqual:[updatedObject objectID]]) {
                [self updateDisplayLabel];
                [self setNeedsDisplay];
                break;
            }
        }
    }

}

- (void)updateDisplayLabel {
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[self objectIdTag] fromObjectContext:[self managedObjectContext]];
    
    [[self marginView] setFrame:[self marginViewBounds]];
    [[self visibleView] setFrame:[self elementFrame]];
    
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
    }
    
    NSString *string = [[documentObject isLabelDataField] text];
    NSNumber *underlineStyle = [[documentObject underline] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
    NSNumber *strikeThroughStyle = [[documentObject strike] boolValue] ? @(NSUnderlineStyleSingle) : @(NSUnderlineStyleNone);
    
    NSDictionary *attributes = @{NSFontAttributeName : displayFont,
                                    NSStrikethroughStyleAttributeName : strikeThroughStyle,
                                    NSUnderlineStyleAttributeName : underlineStyle};

    NSAttributedString *attributtedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    
    
    CGFloat paddingLeft = [[documentObject paddingLeft] floatValue];
    CGFloat paddingTop = [[documentObject paddingTop] floatValue];
    CGFloat paddingBottom = [[documentObject paddingBottom] floatValue];
    CGFloat paddingRight = [[documentObject paddingRight] floatValue];
    CGFloat originX = CGPointZero.x + paddingLeft;
    CGFloat originY = CGPointZero.y + paddingTop;
    CGFloat sizeWidth = [self bounds].size.width - paddingLeft - paddingRight;
    CGFloat sizeHeight =  [self bounds].size.height - paddingTop - paddingBottom;
    CGRect newBoundsAfterPadding = CGRectMake(originX, originY, sizeWidth, sizeHeight);
    [[self paddingView] setFrame:newBoundsAfterPadding];
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
            textAlignment = NSTextAlignmentNatural;
            break;
    }
    [[self displayLabel] setTextAlignment:textAlignment];
    
    MTVerticalAlignment verticalAlignment = [[documentObject verticalAlignment] integerValue];
    UIBaselineAdjustment baselineAdjustment;
    switch (verticalAlignment) {
        case MTVerticalAlignmentTop: {
            
            [[self displayLabel] sizeToFit];
            CGFloat originX = [[self paddingView] bounds].origin.x;
            CGFloat originY = [[self paddingView] bounds].origin.y;
            CGFloat sizeWidth = [[self paddingView] bounds].size.width;
            CGFloat sizeHeight = [[self displayLabel] bounds].size.height;

            [[self displayLabel] setFrame:CGRectMake(originX, originY, sizeWidth, sizeHeight)];
            baselineAdjustment = UIBaselineAdjustmentNone;
            break;
        }
        case MTVerticalAlignmentCenter: {
            [[self displayLabel] setFrame:[[self paddingView] bounds]];
            baselineAdjustment = UIBaselineAdjustmentAlignCenters;
            break;
        }
        case MTVerticalAlignmentBottom: {
            [[self displayLabel] sizeToFit];
            
            CGFloat originX = [[self paddingView] bounds].origin.x;
            CGFloat originY = [[self paddingView] bounds].origin.y + [[self paddingView] frame].size.height - [[self displayLabel] bounds].size.height;
            CGFloat sizeWidth = [[self paddingView] bounds].size.width;
            CGFloat sizeHeight = [[self displayLabel] bounds].size.height;
            [[self displayLabel] setFrame:CGRectMake(originX, originY, sizeWidth, sizeHeight)];
            baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
            break;
        }
        default:
            baselineAdjustment = UIBaselineAdjustmentNone;
            break;
    }
    [[self displayLabel] setNeedsDisplay];
    [attributtedString release];
}
/*
- (void)drawRect:(CGRect)rect {
    if ([self isSelected]) {
        
        [[self displayLabel] setBackgroundColor:[UIColor redColor]];
        [[self paddingView] setBackgroundColor:[UIColor redColor]];
        [[self visibleView] setBackgroundColor:[UIColor redColor]];
        [[self marginView] setBackgroundColor:[UIColor redColor]];
        
        //[[UIColor redColor] setFill];
        //[[self paddingView] setBackgroundColor:[UIColor redColor]];
//    } else if ([self highlight]) {
//        [[UIColor yellowColor] setFill];
    } else {
        [[self displayLabel] setBackgroundColor:[UIColor whiteColor]];
        [[self paddingView] setBackgroundColor:[UIColor whiteColor]];
        [[self visibleView] setBackgroundColor:[UIColor whiteColor]];
        [[self marginView] setBackgroundColor:[UIColor whiteColor]];
        //[[self paddingView] setBackgroundColor:[UIColor clearColor]];
        //[[UIColor whiteColor] setFill];
    }
    //UIRectFill(rect);
}
*/
#pragma mark - Members

- (void)setWobbleRunning:(BOOL)running {
    [self setDisplayWobbling:running];
    if (running) {
        NSInteger randomInt = arc4random() % 500;
        float r = (randomInt / 500.0000f) + 0.5000f;
        
        CGAffineTransform leftWobble = CGAffineTransformMakeRotation(degreesToRadians( (kAnimationRotateDeg * -1.0) - r ));
        CGAffineTransform rightWobble = CGAffineTransformMakeRotation(degreesToRadians( kAnimationRotateDeg + r ));
        
        [self setTransform: leftWobble];
        
        [[self layer] setAnchorPoint:CGPointMake(0.5, 0.5)];
        
        [UIView animateWithDuration:0.3500
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                         animations:^{
                             [UIView setAnimationRepeatCount:NSNotFound];
                             self.transform = rightWobble;
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
    [self setDisplaySelected:![self displaySelected]];
    return [self displaySelected];
}

- (void)setSelected:(BOOL)selected {
    /*
    NSLog(@"%@", selected ? @"Select" : @"Deselect");
    [self setDisplaySelected:selected];
    //[self setNeedsDisplay];
    
    if (selected) {
        [[self paddingView] setBackgroundColor:[UIColor yellowColor]];
        //[[UIColor redColor] setFill];
        //[[self paddingView] setBackgroundColor:[UIColor redColor]];
        //    } else if ([self highlight]) {
        //        [[UIColor yellowColor] setFill];
    } else {
        [[self paddingView] setBackgroundColor:[UIColor grayColor]];
        //[[self paddingView] setBackgroundColor:[UIColor clearColor]];
        //[[UIColor whiteColor] setFill];
    }
*/
}

- (BOOL)isSelected {
    return [self displaySelected];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self setDisplayHighlighted:YES];
    [[self delegate] didHighlightElementView:self];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self setDisplayHighlighted:NO];
    [[self delegate] didUnhighlightElementView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self setDisplayHighlighted:NO];
    [[self delegate] didUnhighlightElementView:self];
    if ([self toggleSelected]) {
        [[self delegate] didSelectElementView:self];
    } else {
        [[self delegate] didDeselectElementView:self];
    }
}


@end