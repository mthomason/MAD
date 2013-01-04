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

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0
#define kAnimationTranslateX 2.0
#define kAnimationTranslateY 2.0

@interface MTElementView ()

@property (nonatomic, retain) UIView *marginView;
@property (nonatomic, retain) UIView *visibleView;
@property (nonatomic, retain) UIView *paddingView;
@property (nonatomic, retain) UILabel *displayLabel;

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

- (id)initWithFrame:(CGRect)frame andObjectId:(NSManagedObjectID *)objectId inObjectContext:(NSManagedObjectContext *)managedObjectContext {
    self = [super initWithFrame:frame];
    if (self) {
        [self setObjectIdTag:objectId];
        [self setManagedObjectContext:managedObjectContext];

        [self setDisplayWobbling: NO];
        [self setDisplayHighlighted: NO];
        
        UIView *marginView = [self retain];
        [self setMarginView: marginView];
        [marginView release];
        
        UIView *visibleView = [[UIView alloc] initWithFrame:frame];
        [[self marginView] addSubview: visibleView];
        [self setVisibleView:visibleView];
        [visibleView release];
        
        UIView *labelBackground = [[UIView alloc] initWithFrame:frame];
        [labelBackground setClipsToBounds:YES];
        [labelBackground setBackgroundColor:[UIColor greenColor]];
        [[self visibleView] addSubview:labelBackground];
        [self setPaddingView:labelBackground];
        [labelBackground release];
        
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        [label setUserInteractionEnabled:NO];
        [label setBackgroundColor:[UIColor yellowColor]];
        [[self paddingView] addSubview:label];
        [self setDisplayLabel:label];
        [label release];

        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(managedObjectContextDidSave:)
                              name:NSManagedObjectContextDidSaveNotification
                            object:managedObjectContext];
    }
    return self;
}

- (CGRect)marginViewRect {
    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[self objectIdTag] fromObjectContext:[self managedObjectContext]];

    CGFloat marginOriginX = self.frame.origin.x - [[documentObject marginLeft] floatValue];
    CGFloat marginOriginY = self.frame.origin.y - [[documentObject marginTop] floatValue];
    CGFloat marginSizeWidth = self.frame.size.width + [[documentObject marginLeft] floatValue] + [[documentObject marginRight] floatValue];
    CGFloat marginSizeHeight = self.frame.size.width + [[documentObject marginTop] floatValue] + [[documentObject marginBottom] floatValue];
    return CGRectMake(marginOriginX, marginOriginY, marginSizeWidth, marginSizeHeight);
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
                                    NSUnderlineStyleAttributeName : underlineStyle
    };
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
            //[[self displayLabel] verticalAlignTop];
            [[self displayLabel] sizeToFit];
            CGFloat originX = [[self paddingView] frame].origin.x;
            CGFloat originY = [[self paddingView] frame].origin.y;
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
            
            CGFloat originX = [[self paddingView] frame].origin.x;
            CGFloat originY = [[self paddingView] frame].origin.y + [[self paddingView] frame].size.height - [[self displayLabel] bounds].size.height;
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

- (void)drawRect:(CGRect)rect {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextAddPath(currentContext, path);
    [[UIColor whiteColor] setFill];
    [[UIColor blackColor] setStroke];
    if ([self highlight] || [self isSelected]) {
        [[UIColor redColor] setStroke];
    } else {
        [[UIColor blackColor] setStroke];
    }
    float dashPhase = 0.0;
    float dashLengths[] = { 7, 3, 7, 3, 7, 3 };
    CGContextSetLineDash(currentContext,
                         dashPhase, dashLengths,
                         sizeof( dashLengths ) / sizeof( float ) );
    CGContextSetLineWidth(currentContext, 5.0000f);
    CGContextDrawPath(currentContext, kCGPathFillStroke);
    if ([self highlight] || [self isSelected]) {
        [[UIColor redColor] set];
    } else {
        [[UIColor blackColor] set];
    }

    CGPathRelease(path);
    
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

- (void)setSelected:(BOOL)selected {
    [self setDisplaySelected:selected];
    [self setNeedsDisplay];
}

- (BOOL)isSelected {
    return [self displaySelected];
}

- (void)setHighlight:(BOOL)selected {
    [self setDisplayHighlighted:selected];
    [self setNeedsDisplay];
}

- (BOOL)highlight {
    return [self displayHighlighted];
}

@end