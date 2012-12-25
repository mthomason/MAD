//
//  UICollectionView+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UICollectionView+Extras.h"

@implementation UICollectionView (Extras)

- (NSIndexPath *)indexOfAlienViewWithCenterPoint:(CGPoint)alienCenter {
    CGFloat minDistance = CGFLOAT_MAX;
    NSUInteger item = 0;
    NSUInteger section = 0;
    for (NSIndexPath *indexPath in [self indexPathsForVisibleItems]) {
        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath: indexPath];
        CGFloat distance = CGDistance([layoutAttributes center], alienCenter);
        if (distance < minDistance) {
            minDistance = distance;
            item = [indexPath item];
            section = [indexPath section];
        }
    }
    return  [NSIndexPath indexPathForItem:item inSection:section];
}

@end