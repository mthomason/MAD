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

@class MTReportDesignerSectionViewLayoutLiquid, MTCollectionViewLayoutLiquidAttributes;

@protocol MTReportDesignerSectionViewLayoutLiquidDelegate

- (MTCollectionViewLayoutLiquidAttributes *)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
                        layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
          setDropPoint:(CGPoint)dropPoint forItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
                                     updateDropIndexForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section ofCollectionView:(UICollectionView *)collectionView;

- (void)collectionViewDidFinishUpdates:(UICollectionView *)collectionView;

@end

@interface MTReportDesignerSectionViewLayoutLiquid : UICollectionViewLayout

@property (nonatomic, weak) id <MTReportDesignerSectionViewLayoutLiquidDelegate, UICollectionViewDataSource> delegate;

@property (nonatomic, assign) CGSize contentSize;

@end

#endif
