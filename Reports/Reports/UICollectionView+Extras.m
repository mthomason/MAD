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
    NSUInteger item = 0;
    NSUInteger section = 0;
    NSInteger counter = 0;
    BOOL valueSet = NO;
    NSArray *indexPathsForItems = [self indexPathsForVisibleItems];
    for (NSIndexPath *indexPath in indexPathsForItems) {
        
        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath: indexPath];
        
        if (alienCenter.x < [layoutAttributes center].x) {
            item = [indexPath item];
            section = [indexPath section];
            valueSet = YES;
            break;
        }
        counter++;
    }
    if (counter == 0) {
        item = 0, section = 0;
        valueSet = YES;
    }
    if (!valueSet) {
        item = [indexPathsForItems count], section = 0;
    }
    return  [NSIndexPath indexPathForItem:item inSection:section];
}

@end