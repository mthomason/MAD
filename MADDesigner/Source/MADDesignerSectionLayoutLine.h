//
//  MTCollectionViewFlowLayout.h
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTReportDesignerSectionViewLayout_h
#define Reports_MTReportDesignerSectionViewLayout_h

#import <UIKit/UICollectionView.h>
#import <UIKit/UICollectionViewLayout.h>

@class MADDesignerSectionLayoutLine;

@protocol MADDesignerSectionLayoutLineDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightOfCollectionView:(UICollectionView *)collectionView;
- (NSUInteger)numberOfItemsInSection:(NSUInteger)section ofCollectionView:(UICollectionView *)collectionView;
@end

@interface MADDesignerSectionLayoutLine : UICollectionViewLayout

@property (nonatomic, weak) id <MADDesignerSectionLayoutLineDelegate, UICollectionViewDataSource> delegate;

- (NSIndexPath *)indexOfAlienViewWithCenterPoint:(CGPoint)alienCenter;

@end

#endif
