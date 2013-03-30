//
//  MTCollectionViewFlowLayoutDesignerSection.m
//  Reports
//
//  Created by Michael Thomason on 12/25/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//
/*
#import "MTCollectionViewFlowLayoutDesignerSection.h"
#import "Constants.h"

@implementation MTCollectionViewFlowLayoutDesignerSection

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {

    NSMutableArray *results = [[NSMutableArray alloc] initWithArray: [super layoutAttributesForElementsInRect:rect]];

    return [results autorelease];
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
    } else if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
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

@end*/