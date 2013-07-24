//
//  MTDocumentSectionView.m
//  Reports
//
//  Created by Michael Thomason on 2/11/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTDocumentSectionView.h"

@interface MTDocumentSectionView ()

@property (nonatomic, assign) CGFloat resizeHeightDifferenceInital;
@property (nonatomic, assign) CGFloat resizeHeightBoundsHeightInital;

@end

@implementation MTDocumentSectionView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupGestures];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self setupGestures];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupGestures];
    }
    return self;
}

- (void)setupGestures {
    //UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(resizeHeight:)];
    //[pinchGesture setDelegate:self];
    //[self addGestureRecognizer:pinchGesture];
    //[pinchGesture release];
}

- (void)resizeHeight:(UIPinchGestureRecognizer *)gestureRecognizer {
    //NSLog(@"pinchView");
    //gestureRecognizer.view.transform  = CGAffineTransformMakeScale(gestureRecognizer.scale, gestureRecognizer.scale);
    //gestureRecognizer.scale = 1.0f;
    
    switch ([gestureRecognizer state]) {
        case UIGestureRecognizerStatePossible: {    // MARK: UIPinchGestureRecognizer UIGestureRecognizerStatePossible
            break;
        }
        case UIGestureRecognizerStateBegan: {       // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateBegan
            if ([gestureRecognizer numberOfTouches] >= 2) {
                CGPoint locationStart0 = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
                CGPoint locationStart1 = [gestureRecognizer locationOfTouch:1 inView:[gestureRecognizer view]];
                CGFloat differenceY = fabsf(locationStart1.y - locationStart0.y);
                [self setResizeHeightDifferenceInital:differenceY];
                [self setResizeHeightBoundsHeightInital:[self bounds].size.width];
                //NSLog(@"Start difference y = %f", differenceY);
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {     // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateChanged
            if ([gestureRecognizer numberOfTouches] >= 2) {
                CGPoint locationStart0 = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
                CGPoint locationStart1 = [gestureRecognizer locationOfTouch:1 inView:[gestureRecognizer view]];
                CGFloat differenceY = locationStart0.y - locationStart1.y;
                //NSLog(@"Change difference y = %f", differenceY);
                CGFloat newHeight = [self resizeHeightDifferenceInital] + differenceY - [self resizeHeightDifferenceInital];
                CGRect newBounds = CGRectMake(CGPointZero.x, CGPointZero.y, [self bounds].size.width, newHeight);
                [self setBounds: newBounds];
                //NSLog(@"New bounds %@", NSStringFromCGRect(newBounds));
                [[self sectionDelegate] didUpdateLayout:self];
            }
            break;
        }
        case UIGestureRecognizerStateCancelled: {   // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateCancelled
            break;
        }
        case UIGestureRecognizerStateFailed: {      // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateFailed
            break;
        }
        case UIGestureRecognizerStateEnded: {       // MARK: UIPinchGestureRecognizer UIGestureRecognizerStateEnded
            //CGPoint locationEnd0 = [gestureRecognizer locationOfTouch:0 inView:[gestureRecognizer view]];
            //CGPoint locationEnd1 = [gestureRecognizer locationOfTouch:1 inView:[gestureRecognizer view]];
            //CGFloat distance = CGDistance(locationEnd0, locationEnd1);
            //NSLog(@"End distance %f", distance);
            break;
        }
    }
}

@end