//
//  MTCollectionViewFlowLayout.h
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerSectionViewLayout_h
#define Reports_MTReportDesignerSectionViewLayout_h

#import <UIKit/UIKit.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>

@class MTReportDesignerSectionViewLayoutLiquid, MTCollectionViewLayoutLiquidAttributes;

@protocol MTReportDesignerSectionViewLayoutLiquidDelegate

- (void)collectionView: (UICollectionView *)collectionView
         prepareLayout: (UICollectionViewLayout *)collectionViewLayout;

- (MTCollectionViewLayoutLiquidAttributes *)collectionView: (UICollectionView *)collectionView
                                                    layout: (UICollectionViewLayout *)collectionViewLayout
                        layoutAttributesForItemAtIndexPath: (NSIndexPath *)indexPath;

- (CGSize)collectionView: (UICollectionView *)collectionView
           sizeForLayout: (UICollectionViewLayout *)collectionViewLayout;

- (NSUInteger)numberOfItemsInSection: (NSUInteger)section
                    ofCollectionView: (UICollectionView *)collectionView;

- (NSArray *)collectionView: (UICollectionView *)collectionView
        attributesForLayout: (UICollectionViewLayout *)collectionViewLayout;

- (void)collectionViewDidFinishUpdates: (UICollectionView *)collectionView;

@end

@interface MTReportDesignerSectionViewLayoutLiquid : UICollectionViewLayout

@property (nonatomic, weak) id <MTReportDesignerSectionViewLayoutLiquidDelegate, UICollectionViewDataSource> delegate;

@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, assign) NSUInteger tag;

@end

#endif
