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

@class MTReportDesignerSectionViewLayout;

@protocol MTReportDesignerSectionViewLayoutDelegate
- (CGPoint)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout initialLayoutCenterPointForIndexPath:(NSIndexPath *)indexPath;
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightOfCollectionView:(UICollectionView *)collectionView;
@end

@interface MTReportDesignerSectionViewLayout : UICollectionViewLayout

@property (assign, nonatomic) id <MTReportDesignerSectionViewLayoutDelegate, UICollectionViewDataSource> delegate;

@end

#endif
