//
//  MTCollectionViewFlowLayoutDesignerSection.m
//  Reports
//
//  Created by Michael Thomason on 12/25/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTCollectionViewFlowLayoutDesignerSection.h"
#import "Constants.h"

@implementation MTCollectionViewFlowLayoutDesignerSection

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {

    NSMutableArray *results = [[NSMutableArray alloc] initWithArray: [super layoutAttributesForElementsInRect:rect]];

    /*
    CGRect collectionViewFrame = [[self collectionView] frame];
    CGRect floatingAttributeFrame = CGRectMake(collectionViewFrame.size.width - 100.0000f, collectionViewFrame.size.height - 22.0000f, 100.0000f, 22.0000f);

    if (!CGRectIsNull(CGRectIntersection(collectionViewFrame, floatingAttributeFrame))) {
        UICollectionViewLayoutAttributes *newAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:MTCollectionElementKindSectionLabel
                                                                                                                         withIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        [newAttributes setZIndex: NSIntegerMax];
        [newAttributes setFrame:floatingAttributeFrame];
        [results addObject:newAttributes];
    }
    */

    return results;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *result = [super layoutAttributesForItemAtIndexPath:indexPath];
    return [self processForReportDesigner:result];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *result;
    
    result = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    if ([kind isEqualToString:MTCollectionElementKindSectionLabel]) {
        CGRect collectionViewFrame = [[self collectionView] frame];
        CGPoint newCenter = CGPointMake(collectionViewFrame.size.width - result.size.width, collectionViewFrame.size.width - result.size.height);
        [result setCenter: newCenter];
    }
    
    return result;
}

- (UICollectionViewLayoutAttributes *)processForReportDesigner:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if ([layoutAttributes representedElementCategory] == UICollectionElementCategorySupplementaryView) {
        if ([[layoutAttributes representedElementKind] isEqualToString:MTCollectionElementKindSectionLabel]) {
            CGRect collectionViewFrame = [[self collectionView] frame];
            CGRect floatingAttributeFrame = CGRectMake(collectionViewFrame.size.width - 100.0000f, collectionViewFrame.size.height - 22.0000f, 100.0000f, 22.0000f);
            [layoutAttributes setFrame: floatingAttributeFrame];
        }
    }
    return layoutAttributes;
}

@end