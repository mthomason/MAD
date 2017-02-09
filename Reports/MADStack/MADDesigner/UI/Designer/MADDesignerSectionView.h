//
//  MTDocumentSectionView.h
//  Reports
//
//  Created by Michael Thomason on 2/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDocumentSectionView_h
#define Reports_MTDocumentSectionView_h

#import "MADManagedObjectCollectionView.h"

@protocol MADDesignerSectionLayoutLiquidDelegate;

@class MADDesignerSectionLabel, MADReportSection;

typedef NS_ENUM(NSUInteger, MADBorderState) {
    MADBorderStateNormal,
    MADBorderStateSelected,
    MADBorderStateDisabled
};

@interface MADDesignerSectionView : MADManagedObjectCollectionView

    + (instancetype)newDesignerSectionView:(MADReportSection *)section
                                  delegate:(id <MADDesignerSectionLayoutLiquidDelegate, UICollectionViewDataSource>)layoutDelegate;

    @property (nonatomic, weak) MADDesignerSectionLabel *sectionLabel;

    @property (nonatomic, assign) BOOL visible;
    @property (nonatomic, assign) BOOL selected;

    - (void)removeItemAtIndex:(NSIndexPath *)deletePath
                       update:(void (^)())update
            animationComplete:(void (^)())animationComplete
                   completion:(void (^)())completion;
                       
    - (void)insertItemAtIndex:(NSIndexPath *)path
                       update:(void (^)())update
            animationComplete:(void (^)())animationComplete
                   completion:(void (^)())completion;

@end

#endif
