//
//  MTDocumentSectionView.m
//  Reports
//
//  Created by Michael Thomason on 2/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerSectionView.h"
#import "MTReportDesignerSectionViewLayoutLiquid.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"
#import "MTCollectionViewCellElement.h"
#import "MTReportDesignerSectionBackgroundView.h"
#import "CGGeometry+Extras.h"
#import "UIColor+EverydayApps.h"

@interface MADDesignerSectionView ()

@property (nonatomic, assign) CGFloat resizeHeightDifferenceInital;
@property (nonatomic, assign) CGFloat resizeHeightBoundsHeightInital;

@end

@implementation MADDesignerSectionView

- (id)initWithFrame:(CGRect)frame {
    
    MTReportDesignerSectionViewLayoutLiquid *layout = [[MTReportDesignerSectionViewLayoutLiquid alloc] init];

    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        
        MTReportDesignerSectionBackgroundView *backgroundView = [[MTReportDesignerSectionBackgroundView alloc] initWithFrame:CGRectZero];
        [backgroundView setNumberOfRowsInBackground:1];
        backgroundView.backgroundColor = [UIColor clearColor];
        self.backgroundView = backgroundView;
        
        NSString *supplmentaryViewReuseIdHeader = [MTCollectionReuseableViewDefault reuseIdentifier];
        NSString *documentElementReuseIdentifier = [MTCollectionViewCellElement reuseIdentifier];
        
        [self registerClass: [MTCollectionViewCellElement class]
 forCellWithReuseIdentifier: documentElementReuseIdentifier];
        
        [self registerClass: [MTCollectionReuseableViewDefault class]
 forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
        withReuseIdentifier: supplmentaryViewReuseIdHeader];
        
        [self registerClass: [MTCollectionReuseableViewDefault class]
 forSupplementaryViewOfKind: UICollectionElementKindSectionFooter
        withReuseIdentifier: supplmentaryViewReuseIdHeader];
        
        self.clipsToBounds = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.allowsSelection = YES;
        self.allowsMultipleSelection = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layer.borderColor = [UIColor borderColor].CGColor;
        
        [self setContentHuggingPriority: UILayoutPriorityDefaultLow
                                forAxis: UILayoutConstraintAxisVertical];
        
        [self setContentCompressionResistancePriority: UILayoutPriorityDefaultHigh
                                              forAxis: UILayoutConstraintAxisVertical];
        
        
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

@end
