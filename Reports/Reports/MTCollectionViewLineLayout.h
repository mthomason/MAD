//
//  MTCollectionViewFlowLayout.h
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "UIView+NSObjectIdTag.h"

@class MTCollectionViewLineLayout;

@protocol MTCollectionViewLineLayoutDelegate
- (CGPoint)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout initialLayoutCenterPointForIndexPath:(NSIndexPath *)indexPath;
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface MTCollectionViewLineLayout : UICollectionViewLayout

@property (assign, nonatomic) id <MTCollectionViewLineLayoutDelegate> delegate;

@end