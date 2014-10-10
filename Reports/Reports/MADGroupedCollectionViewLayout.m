//
//  MADGroupedCollectionViewLayout.m
//  MAD
//
//  Created by Michael Thomason on 10/9/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADGroupedCollectionViewLayout.h"
#import "UIDevice+Hack.h"
#import "MACloudManager.h"

NSUInteger const MADzIndexOffset = 900;
CGFloat const MADAlpha = 0.9000f;

@interface MADGroupedCollectionViewLayout ()

@end

@implementation MADGroupedCollectionViewLayout

- (void)prepareLayout {
    [super prepareLayout];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *elementAttributes = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:elementAttributes.count];
    [results addObjectsFromArray:elementAttributes];

    BOOL gotHeader1 = NO;
    BOOL gotHeader2 = NO;
    BOOL displayHeaders = [MACloudManager sharedManager].cloudAvailble;
    
    UICollectionViewLayoutAttributes *attributesHeader1;
    UICollectionViewLayoutAttributes *attributesHeader2;
    
    for (UICollectionViewLayoutAttributes *attributes in results) {
        if (attributes.representedElementCategory == UICollectionElementCategorySupplementaryView) {
   
            if (attributes.indexPath.section == 0) {
                gotHeader1 = YES;
                attributesHeader1 = attributes;
            } else if (attributes.indexPath.section == 1) {
                gotHeader2 = YES;
                attributesHeader2 = attributes;
            }
            if (gotHeader1 && gotHeader2) {
                break;
            }
        }
    }
    
    if (displayHeaders) {
        if (gotHeader1 == NO) {
            NSIndexPath *header1 = [NSIndexPath indexPathForItem:0 inSection:0];
            attributesHeader1 = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                               withIndexPath:header1];
            [results addObject:attributesHeader1];
        }
        
        if (gotHeader2 == NO) {
            NSIndexPath *header2 = [NSIndexPath indexPathForItem:0 inSection:1];
            attributesHeader2 = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                               withIndexPath:header2];
            [results addObject:attributesHeader2];
        }
        
        [self updateAttributes:&attributesHeader1];
        [self updateAttributes:&attributesHeader2];
        
        if (CGRectIntersectsRect(attributesHeader1.frame, attributesHeader2.frame)) {
            attributesHeader1.frame = CGRectMake(attributesHeader2.frame.origin.x,
                                                 attributesHeader2.frame.origin.y - attributesHeader1.frame.size.height,
                                                 attributesHeader1.frame.size.width,
                                                 attributesHeader1.frame.size.height);
        }
    }
    
    return results;
}

- (void)updateAttributes:(UICollectionViewLayoutAttributes **)attributes {

    (*attributes).alpha = MADAlpha;
    (*attributes).zIndex = MADzIndexOffset + (*attributes).indexPath.section;
    
    CGFloat y = (*attributes).frame.origin.y;
    if (y < self.collectionView.contentOffset.y + self.collectionView.contentInset.top)
        y = self.collectionView.contentOffset.y + self.collectionView.contentInset.top;
    
    (*attributes).frame = CGRectMake(CGPointZero.x, y, (*attributes).frame.size.width, (*attributes).frame.size.height);
}

 @end
