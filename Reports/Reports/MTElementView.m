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

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 1.0
#define kAnimationTranslateX 2.0
#define kAnimationTranslateY 2.0

@interface MTElementView ()

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
        [self setDisplayWobbling: NO];
        [self setDisplayHighlighted: NO];
        [self setManagedObjectContext:managedObjectContext];
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
    for (NSManagedObjectID *objectId in updatedObjects) {
        if ([[self objectIdTag] isEqual:objectId]) {
            [self setNeedsDisplay];
            break;
        }
    }
}

- (void)drawRect:(CGRect)rect {

    RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:[self objectIdTag] fromObjectContext:[self managedObjectContext]];
    MTLog(@"Object ID: %@\t\t Document Object: %@", [self objectIdTag], [[documentObject isLabelDataField] text]);
    
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
    [[[documentObject isLabelDataField] text] drawInRect:rect withFont:[UIFont systemFontOfSize:[UIFont systemFontSize]] lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentLeft];
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