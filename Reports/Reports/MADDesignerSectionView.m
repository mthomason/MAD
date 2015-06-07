//
//  MTDocumentSectionView.m
//  Reports
//
//  Created by Michael Thomason on 2/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerSectionView.h"
#import <QuartzCore/QuartzCore.h>
#import "MTReportDesignerSectionViewLayoutLiquid.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"
#import "MTCollectionViewCellElement.h"
#import "MTReportDesignerSectionBackgroundView.h"
#import "CGGeometry+Extras.h"
#import "UIColor+EverydayApps.h"


static const CGFloat selectedAlpha = 0.33333333f;
static inline UIColor *backgroundColor(BOOL selected, BOOL visible) {
    if (!selected && !visible) {
        return [[UIColor edaBlackFiftyPercent] colorWithAlphaComponent:selectedAlpha];
    } else if (selected && !visible) {
        return [[UIColor edaBlackFiftyPercent] colorWithAlphaComponent:selectedAlpha];
    } else if (selected && visible) {
        return [UIColor whiteColor];
    } else {
        return [UIColor whiteColor];
    }
}

static inline MADBorderState borderState(BOOL selected, BOOL visible) {
    if (selected) {
        return MADBorderStateSelected;
    } else if (visible) {
        return MADBorderStateNormal;
    } else {
        return MADBorderStateDisabled;
    }
}

@interface MADDesignerSectionView ()

@property (nonatomic, assign) CGFloat resizeHeightDifferenceInital;
@property (nonatomic, assign) CGFloat resizeHeightBoundsHeightInital;

@end

@implementation MADDesignerSectionView

- (id)initWithFrame:(CGRect)frame {
    
    MTReportDesignerSectionViewLayoutLiquid *layout = [[MTReportDesignerSectionViewLayoutLiquid alloc] init];

    if (self = [super initWithFrame:frame collectionViewLayout:layout]) {
        
        MTReportDesignerSectionBackgroundView *backgroundView = [[MTReportDesignerSectionBackgroundView alloc] initWithFrame:CGRectZero];
        [backgroundView setNumberOfRowsInBackground:1];
        backgroundView.backgroundColor = [UIColor clearColor];

        NSString *supplmentaryViewReuseIdHeader = [MTCollectionReuseableViewDefault reuseIdentifier];
        NSString *documentElementReuseIdentifier = [MTCollectionViewCellElement reuseIdentifier];
        
        [self registerClass: [MTCollectionViewCellElement class] forCellWithReuseIdentifier: documentElementReuseIdentifier];
        
        [self registerClass: [MTCollectionReuseableViewDefault class] forSupplementaryViewOfKind: UICollectionElementKindSectionHeader withReuseIdentifier: supplmentaryViewReuseIdHeader];
        
        [self registerClass: [MTCollectionReuseableViewDefault class] forSupplementaryViewOfKind: UICollectionElementKindSectionFooter withReuseIdentifier: supplmentaryViewReuseIdHeader];
        
        self.clipsToBounds = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.allowsSelection = YES;
        self.allowsMultipleSelection = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layer.borderColor = [UIColor borderColor].CGColor;
        self.backgroundView = nil;
        self.backgroundColor = [UIColor clearColor];
        
        [self setContentHuggingPriority: UILayoutPriorityDefaultLow forAxis: UILayoutConstraintAxisVertical];
        [self setContentCompressionResistancePriority: UILayoutPriorityDefaultHigh forAxis: UILayoutConstraintAxisVertical];
        _selected = NO;
        _visible = NO;
    }
    
    return self;
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;//[gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
}

- (CGSize)intrinsicContentSize {
    CGSize intrinsicContentSize = self.collectionViewLayout.collectionViewContentSize;
    return CGSizeMake(intrinsicContentSize.width, intrinsicContentSize.height + MTDefaultFingerSizeHeight);
}

- (void)removeItemAtIndex:(NSIndexPath *)deletePath update:(void (^)())update animationComplete:(void (^)(BOOL finished))animationComplete completion:(void (^)(BOOL finished))completion {
    [self performBatchUpdates:^{
        if (update != nil) update();
        NSArray *indexPaths = @[deletePath];
        [self deleteItemsAtIndexPaths: indexPaths];
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.6666f animations:^{
                [self invalidateIntrinsicContentSize];
            } completion:^(BOOL finished) {
                if (animationComplete != nil) animationComplete(finished);
            }];
        }
        if (completion != nil) { completion(YES); }
    }];
}

- (void)insertItemAtIndex:(NSIndexPath *)path update:(void (^)())update animationComplete:(void (^)(BOOL finished))animationComplete completion:(void (^)(BOOL finished))completion {
    
    [self performBatchUpdates:^(void) {
        if (update != nil) update();
        NSArray *indexPathsInserted = @[path];
        [self insertItemsAtIndexPaths: indexPathsInserted];
        
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.6666f animations:^{
                [self invalidateIntrinsicContentSize];
            } completion:^(BOOL finished) {
                if (finished) {
                    if (animationComplete != nil) animationComplete(finished);
                }
            }];
        }
        if (completion != nil) { completion(YES); }
    }];

}

- (void)setBorderState:(MADBorderState)borderState {
    switch (borderState) {
        case MADBorderStateDisabled:
            self.layer.borderColor = [UIColor blackColor].CGColor;
            self.layer.borderWidth = 1.0000f;
            break;
        case MADBorderStateNormal:
            self.layer.borderColor = [UIColor blackColor].CGColor;
            self.layer.borderWidth = 1.0000f;
            break;
        case MADBorderStateSelected:
            self.layer.borderColor = [UIColor tintColorAnalogous4].CGColor;
            self.layer.borderWidth = 1.0000f;
            break;
        default:
            break;
    }
}

#pragma mark - UIView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();

    UIColor *bgcolor = backgroundColor(self.selected, self.visible);
    CGContextSetFillColorWithColor(context, bgcolor.CGColor);
    CGContextFillRect(context, rect);
}

#pragma mark - Overrides

- (void)setVisible:(BOOL)visible {
    if (_visible != visible) {
        _visible = visible;
        [self setBorderState:borderState(_selected, _visible)];
        [self setNeedsDisplay];
    }
}

- (void)setSelected:(BOOL)selected {
    if (_selected != selected) {
        _selected = selected;
        [self setBorderState:borderState(_selected, _visible)];
        [self setNeedsDisplay];
    }
}

@end
