//
//  MTCollectionViewFlowLayout.h
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerSectionViewLayout_h
#define Reports_MTReportDesignerSectionViewLayout_h

#import <UIKit/UICollectionView.h>
#import <UIKit/UICollectionViewLayout.h>

@class MTReportDesignerSectionViewLayoutLine;

@protocol MTReportDesignerSectionViewLayoutDelegate
    - (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
    - (CGFloat)heightOfCollectionView:(UICollectionView *)collectionView;
    - (NSUInteger)numberOfItemsInSection:(NSUInteger)section ofCollectionView:(UICollectionView *)collectionView;
@end

@interface MTReportDesignerSectionViewLayoutLine : UICollectionViewLayout

    @property (weak, nonatomic) id <MTReportDesignerSectionViewLayoutDelegate, UICollectionViewDataSource> delegate;

    - (NSIndexPath *)indexOfAlienViewWithCenterPoint:(CGPoint)alienCenter;

@end

#endif
