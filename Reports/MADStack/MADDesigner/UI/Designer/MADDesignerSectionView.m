//
//  MTDocumentSectionView.m
//  Reports
//
//  Created by Michael Thomason on 2/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerSectionView.h"

#import <QuartzCore/CALayer.h>

#import <UIKit/UIAccessibilityCustomAction.h>
#import <UIKit/UICollectionViewFlowLayout.h>
#import <UIKit/UIAccessibilityConstants.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

#import "MTReportDesignerSectionViewLayoutLiquid.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"
#import "MTCollectionViewCellElement.h"
#import "MTReportDesignerSectionBackgroundView.h"

static inline UIColor *backgroundColor(BOOL selected, BOOL visible) {
    if (!selected && !visible) {
        return [MADColorEverydayApps newColorDisabledColor];
    } else if (selected && !visible) {
        return [MADColorEverydayApps newColorDisabledColor];
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
@property (nonatomic, assign) bool accessibile;

@end

@implementation MADDesignerSectionView

- (id)initWithFrame:(CGRect)frame {
    
    MTReportDesignerSectionViewLayoutLiquid *layout = [[MTReportDesignerSectionViewLayoutLiquid alloc] init];

    if (self = [super initWithFrame:frame collectionViewLayout:layout]) {

        UIColor *borderColor = [MADColorEverydayApps newColorBorderColor];
        UIColor *clearColor = [UIColor clearColor];
        
        self.accessibile = true;
        
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
        self.layer.borderColor = borderColor.CGColor;
        self.backgroundView = nil;
        self.backgroundColor = clearColor;
        
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

- (void)removeItemAtIndex:(NSIndexPath *)deletePath update:(void (^)())update animationComplete:(void (^)())animationComplete completion:(void (^)())completion {
    [self performBatchUpdates:^{
        if (update != nil) update();
        NSArray *indexPaths = @[deletePath];
        [self deleteItemsAtIndexPaths: indexPaths];
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.6666f animations:^{
                [self invalidateIntrinsicContentSize];
            } completion:^(BOOL animateFinished) {
                if (animateFinished) {
                    if (animationComplete != nil) animationComplete(animateFinished);
                }
            }];
            if (completion != nil) { completion(); }
        }
    }];
}

- (void)insertItemAtIndex:(NSIndexPath *)path update:(void (^)())update animationComplete:(void (^)())animationComplete completion:(void (^)())completion {
    [self performBatchUpdates:^(void) {
        
        if (update != nil) update();
        NSArray *indexPathsInserted = @[path];
        [self insertItemsAtIndexPaths: indexPathsInserted];
        
    } completion:^(BOOL finished) {
    
        if (finished) {
            [UIView animateWithDuration:0.6666f animations:^{
                [self invalidateIntrinsicContentSize];
            } completion:^(BOOL animateFinished) {
                if (animateFinished) {
                    if (animationComplete != nil) animationComplete();
                }
            }];
            
            if (completion != nil) { completion(); }
        }
        
    }];
}

- (void)setBorderState:(MADBorderState)borderState {
    UIColor *color;
    switch (borderState) {
        case MADBorderStateDisabled:
            color = [UIColor blackColor];
            self.layer.borderColor = color.CGColor;
            self.layer.borderWidth = 1.0000f;
            break;
        case MADBorderStateNormal:
            color = [UIColor blackColor];
            self.layer.borderColor = color.CGColor;
            self.layer.borderWidth = 1.0000f;
            break;
        case MADBorderStateSelected:
            color = [MADColorEverydayApps newColorAnalogous4];
            self.layer.borderColor = color.CGColor;
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

#pragma mark - Accessibility

- (NSArray <__kindof UIAccessibilityCustomAction *> *)accessibilityCustomActions {
    NSString *toggleAccessibilityName = NSLocalizedString(@"Access section elements.", @"Access section elements.");
    UIAccessibilityCustomAction *toggleAccessibility;
    toggleAccessibility = [[UIAccessibilityCustomAction alloc] initWithName:toggleAccessibilityName target:self selector:@selector(toggleAccessibility:)];
    return @[toggleAccessibility];
}

- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSInteger)accessibilityElementCount {
    return [self.dataSource collectionView:self numberOfItemsInSection:0] + 1;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    return [element isKindOfClass:[UICollectionViewCell class]] ? [self indexPathForCell:element].item + 1 : 0;
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    if (index == 0) {
        return self.sectionLabel;
    } else {
        NSIndexPath *path = [NSIndexPath indexPathForItem:index + 1 inSection:0];
        return [self cellForItemAtIndexPath:path];
    }
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitButton;
}


@end
