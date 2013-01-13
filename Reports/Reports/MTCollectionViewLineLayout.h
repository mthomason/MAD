//
//  MTCollectionViewFlowLayout.h
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTCollectionViewLineLayout;

@protocol MTCollectionViewLineLayoutDelegate
- (CGPoint)centerPointForIndexPath:(NSIndexPath *)indexPath inCollectionView:(UICollectionView *)collectionView;
@end

@interface MTCollectionViewLineLayout : UICollectionViewLayout

@property (assign, nonatomic) id <MTCollectionViewLineLayoutDelegate> delegate;

@end