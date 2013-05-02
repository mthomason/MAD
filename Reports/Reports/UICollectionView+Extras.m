//
//  UICollectionView+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UICollectionView+Extras.h"

@implementation UICollectionView (Extras)
/*
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
*/
- (NSIndexPath *)indexOfAlienViewWithCenterPoint:(CGPoint)alienCenter {
    NSUInteger item = 0;
    NSInteger counter = 0;
    BOOL valueSet = NO;
    NSArray *indexPathsForItems = [self indexPathsForVisibleItems];
    CGFloat sectionHeight = ([self frame].size.height / [self numberOfSections]);
    NSUInteger section = alienCenter.y / sectionHeight;
    NSUInteger numberOfItemsInSameSection = 0;

    for (NSIndexPath *indexPath in indexPathsForItems) {
        
        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath: indexPath];
        
        if ([indexPath section] == section) {

            if (alienCenter.x < [layoutAttributes center].x && valueSet == NO) {
                item = [indexPath item];
                //section = [indexPath section];
                valueSet = YES;
                //break;
            }
            numberOfItemsInSameSection++;

        }
        counter++;
    }
    
    if (counter == 0) {
        item = 0;
        valueSet = YES;
    }
    if (!valueSet) {
        item = numberOfItemsInSameSection;
    }
    return  [NSIndexPath indexPathForItem:item inSection:section];
}

@end
