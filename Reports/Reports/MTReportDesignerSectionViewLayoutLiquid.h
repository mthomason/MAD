//
//  MTCollectionViewFlowLayout.h
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerSectionViewLayout_h
#define Reports_MTReportDesignerSectionViewLayout_h

#import <UIKit/UIKit.h>
#import "MTReportDesignerSectionDecorationView.h"
#import "CGGeometry+Extras.h"

@class MTReportDesignerSectionViewLayoutLiquid;

@protocol MTReportDesignerSectionViewLayoutLiquidDelegate

- (CGPoint)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout initialLayoutCenterPointForIndexPath:(NSIndexPath *)indexPath;

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

- (CGPoint)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout dropPointForItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout setDropPoint:(CGPoint)dropPoint forItemAtIndexPath:(NSIndexPath *)indexPath;

- (CGFloat)heightOfCollectionView:(UICollectionView *)collectionView;

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section ofCollectionView:(UICollectionView *)collectionView;

@end

@interface MTReportDesignerSectionViewLayoutLiquid : UICollectionViewLayout

@property (assign, nonatomic) id <MTReportDesignerSectionViewLayoutLiquidDelegate, UICollectionViewDataSource> delegate;

@end

#endif
