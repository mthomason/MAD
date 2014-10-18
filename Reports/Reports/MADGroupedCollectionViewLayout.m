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
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];

    if (attributes == nil) {
        attributes = [NSArray array];
    }
    
    NSMutableArray *elementAttributes = [NSMutableArray arrayWithCapacity:attributes.count];
    for (UICollectionViewLayoutAttributes *attribute in attributes) {
        if ((attribute.frame.origin.x + attribute.frame.size.width <= self.collectionViewContentSize.width) &&
            (attribute.frame.origin.y + attribute.frame.size.height <= self.collectionViewContentSize.height)) {
            [elementAttributes addObject:attribute];
        }
    }
    
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:elementAttributes.count];
    [results addObjectsFromArray:elementAttributes];

    BOOL gotHeader1 = NO;
    BOOL gotHeader2 = NO;
    BOOL displayHeaders = [MACloudManager sharedManager].cloudAvailble;
    BOOL displayHeaderOne = NO, displayHeaderTwo = NO;

    UICollectionViewLayoutAttributes *attributesHeader1;
    UICollectionViewLayoutAttributes *attributesHeader2;

    CGPoint sectionTwoOrigin;
    for (UICollectionViewLayoutAttributes *attributes in results) {
        
        switch (attributes.representedElementCategory) {

            case UICollectionElementCategorySupplementaryView:
                if (attributes.indexPath.section == 0) {
                    gotHeader1 = YES;
                    attributesHeader1 = attributes;
                } else if (attributes.indexPath.section == 1) {
                    gotHeader2 = YES;
                    attributesHeader2 = attributes;
                    sectionTwoOrigin = CGPointMake(attributes.frame.origin.x,
                                                   (CGFloat)MIN(sectionTwoOrigin.y, attributes.frame.origin.y));
                }
                break;
                
            case UICollectionElementCategoryCell:
                switch (attributes.indexPath.section) {
                    case 0:
                        displayHeaderOne = YES;
                        break;

                    case 1:
                        displayHeaderTwo = YES;
                        sectionTwoOrigin = CGPointMake(attributes.frame.origin.x,
                                                       (CGFloat)MIN(sectionTwoOrigin.y, attributes.frame.origin.y - self.headerReferenceSize.height));
                        break;

                    default:
                        break;
                }
                
                break;
                
            default:
                break;
        
        }
        
    }
    
    if (displayHeaderOne == NO) {
        displayHeaderOne = [self.collectionView numberOfItemsInSection:0] == 0;
    }
    
    
    if (displayHeaders) {
        
        if (gotHeader1 == NO) {
            NSIndexPath *header1 = [NSIndexPath indexPathForItem: 0
                                                       inSection: 0];
            attributesHeader1 = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                                                                                               withIndexPath: header1];
        }
        
        if (gotHeader2 == NO) {
            NSIndexPath *header2 = [NSIndexPath indexPathForItem: 0
                                                       inSection: 1];
            attributesHeader2 = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                                                                                               withIndexPath: header2];
            attributesHeader2.frame = CGRectMake(attributesHeader2.frame.origin.x,
                                                 sectionTwoOrigin.y,
                                                 attributesHeader2.frame.size.width,
                                                 attributesHeader2.frame.size.height);
        }
        
        if (displayHeaderOne == NO) {
            attributesHeader1.hidden = YES;
        }

        if (displayHeaderTwo == NO) {
            attributesHeader2.hidden = YES;
        }

        [self updateAttributes:&attributesHeader1];
        [self updateAttributes:&attributesHeader2];
        
        if (CGRectIntersectsRect(attributesHeader1.frame, attributesHeader2.frame) && displayHeaderOne && displayHeaderTwo) {
            attributesHeader1.frame = CGRectMake(attributesHeader2.frame.origin.x,
                                                 attributesHeader2.frame.origin.y - attributesHeader1.frame.size.height,
                                                 attributesHeader1.frame.size.width,
                                                 attributesHeader1.frame.size.height);
        }
        
        if (gotHeader1 == NO) {
            [results addObject:attributesHeader1];
        }
        if (gotHeader2 == NO) {
            [results addObject:attributesHeader2];
        }
    }
    
    return results;
}


- (void)updateAttributes:(UICollectionViewLayoutAttributes **)attributes {
    (*attributes).alpha = MADAlpha;
    (*attributes).zIndex = MADzIndexOffset + (*attributes).indexPath.section;
    
    CGFloat y = (*attributes).frame.origin.y;
    CGFloat border = self.collectionView.contentOffset.y + self.collectionView.contentInset.top;
    if (y < border)
        y = border;
    CGSize size = [((id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate) collectionView: self.collectionView
                                                                                                  layout: self.collectionView.collectionViewLayout
                                                                         referenceSizeForHeaderInSection: (*attributes).indexPath.section];
    (*attributes).frame = CGRectMake(CGPointZero.x, y, size.width, size.height);
}

@end
