//
//  MTCollectionViewFlowLayout.m
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerSectionLayoutLine.h"
#import "MADDesignerSectionControl.h"
#import <UIKit/UITableView.h>

@interface MADDesignerSectionLayoutLine ()

    @property (assign) CGSize contentSize;
    @property (assign) NSUInteger numberOfSections;

    @property (nonatomic, strong) NSMutableArray *itemAttributesBySection;
    @property (nonatomic, strong) NSMutableArray *decorationAttributesBySection;
    @property (nonatomic, strong) NSMutableArray *invalidatedLayoutArray;

@end

@implementation MADDesignerSectionLayoutLine


- (instancetype)init {
    self = [super init];
    if (self) {
        
        NSMutableArray *rectArray = [[NSMutableArray alloc] init];
        self.itemAttributesBySection = rectArray;

        [self registerClass: [MADDesignerSectionControl class]
    forDecorationViewOfKind: NSStringFromClass([MADDesignerSectionControl class])];

    }
    return self;
}

- (CGFloat)sectionHeight {
    CGFloat collectionViewHeight = [self.delegate heightOfCollectionView:self.collectionView];
    return collectionViewHeight / (CGFloat)_numberOfSections;
}

- (void)prepareLayout {
    [super prepareLayout];
    
    id <MADDesignerSectionLayoutLineDelegate, UICollectionViewDataSource> delegate;
    UICollectionView *collectionView;
    NSUInteger numberOfSections;
    delegate = _delegate;
    collectionView = self.collectionView;
    if (collectionView == nil) return;

    numberOfSections = (NSUInteger)[delegate numberOfSectionsInCollectionView:collectionView];

    NSMutableArray *itemAttributesBySection, *decorationAttributesBySection;
    itemAttributesBySection         = [[NSMutableArray alloc] initWithCapacity: numberOfSections];
    decorationAttributesBySection   = [[NSMutableArray alloc] initWithCapacity: numberOfSections];

    CGSize contentSize = CGSizeZero;
    
    CGFloat sectionHeight = [self sectionHeight];
    
    NSUInteger numberOfItems;
    CGFloat maxWidthForSection, maxHeightForSection;
    NSMutableArray *layoutAttributesForSection;
    CGFloat sectionY;
    NSUInteger section, item;
    for (section = 0; section < numberOfSections; section++) {
        
        numberOfItems = [delegate numberOfItemsInSection:section ofCollectionView:collectionView];
        maxWidthForSection = CGSizeZero.width, maxHeightForSection = CGSizeZero.height;
        layoutAttributesForSection = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
        
        sectionY = CGPointZero.y + sectionHeight * section;
        
        UICollectionViewLayoutAttributes *itemAttributes;
        for (item = 0; item < numberOfItems; item++) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem: (NSInteger)item
                                                         inSection: (NSInteger)section];
            CGSize itemSize = [delegate collectionView: collectionView
                                                layout: self
                                sizeForItemAtIndexPath: indexPath];

            itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            
            itemAttributes.frame = CGRectMake(maxWidthForSection, sectionY,
                                              itemSize.width, itemSize.height);
            if (itemSize.height > maxHeightForSection) {
                maxHeightForSection = itemSize.height;
            }
            itemAttributes.zIndex = (NSInteger)section;

            [layoutAttributesForSection addObject: itemAttributes];

            maxWidthForSection += itemSize.width;
        }
                
        [itemAttributesBySection addObject:layoutAttributesForSection];

        if (maxWidthForSection > contentSize.width) {
            contentSize.width = maxWidthForSection;
        }
    
        contentSize.height += maxHeightForSection;
    }
    
    contentSize.height = [delegate heightOfCollectionView: collectionView];

    _numberOfSections = numberOfSections;
    _contentSize = contentSize;
    _itemAttributesBySection = itemAttributesBySection;
    _decorationAttributesBySection = decorationAttributesBySection;
    
}

- (CGSize)collectionViewContentSize {
    //NSLog(@"collectionViewContentSize");
    return self.contentSize;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
    NSUInteger section = 0;
    for (NSArray *items in _itemAttributesBySection) {
        
        for (UICollectionViewLayoutAttributes *itemAttribute in items) {
            if (CGRectIntersectsRect(rect, itemAttribute.frame)) {
                [layoutAttributes addObject:itemAttribute];
            }
        }
        
        section++;
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind
                                                                     atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *result;
    result = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];

    return result;

}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *rectsForSection = _itemAttributesBySection[(NSUInteger)indexPath.section];
    UICollectionViewLayoutAttributes *layoutAttributes = rectsForSection[(NSUInteger)indexPath.item];

    return layoutAttributes;

}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind
                                                                  atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes;
    attributes = _decorationAttributesBySection[(NSUInteger)indexPath.section];
    attributes.frame = CGRectMake(attributes.frame.origin.x,
                                  attributes.frame.origin.y,
                                  self.collectionView.contentSize.width,
                                  attributes.frame.size.height);
    return  attributes;

}

- (UICollectionViewLayoutAttributes *)invalidatedLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *rectsForSection = _invalidatedLayoutArray[(NSUInteger)indexPath.section];
    UICollectionViewLayoutAttributes *attributes = rectsForSection[(NSUInteger)indexPath.item];
    return attributes;

}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes;
    attributes = _itemAttributesBySection[(NSUInteger)indexPath.section][(NSUInteger)indexPath.item];
    return attributes;

}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)indexPath {
    [super layoutAttributesForItemAtIndexPath:indexPath];
    UICollectionViewLayoutAttributes *attributes;
    attributes = _invalidatedLayoutArray[(NSUInteger)indexPath.section][(NSUInteger)indexPath.item];
    return attributes;

}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];

    // MARK: Recalculate updated attributes.
    CGSize contentSize = CGSizeZero;
    NSUInteger sectionCounter = 0, itemCounter = 0;
    CGFloat sectionHeight = [self sectionHeight];

    for (NSArray *sectionAttributes in self.invalidatedLayoutArray) {

        CGFloat maxWidthForSection = 0.0000f, maxHeightForSection = 0.0000f;

        for (UICollectionViewLayoutAttributes *layoutAttributes in sectionAttributes) {

            layoutAttributes.indexPath = [NSIndexPath indexPathForItem:(NSInteger)itemCounter
                                                             inSection:(NSInteger)sectionCounter];

            if (CGSizeEqualToSize(layoutAttributes.size, CGSizeZero)) {
                layoutAttributes.size = [self.delegate collectionView: self.collectionView
                                                               layout: self
                                               sizeForItemAtIndexPath: layoutAttributes.indexPath];
            }
            
            CGFloat sectionY = CGPointZero.y + sectionHeight * layoutAttributes.indexPath.section;
            layoutAttributes.frame = CGRectMake(maxWidthForSection, sectionY,
                                                layoutAttributes.size.width,
                                                layoutAttributes.size.height);

            if (layoutAttributes.size.height > maxHeightForSection) {
                maxHeightForSection = layoutAttributes.size.height;
            }

            maxWidthForSection += layoutAttributes.size.width;

            itemCounter++;
        }
        if (maxWidthForSection > contentSize.width) {
            contentSize.width = maxWidthForSection;
        }
        contentSize.height += maxHeightForSection;

        sectionCounter++;
    }
     
}

- (void)finalizeCollectionViewUpdates {
    [super finalizeCollectionViewUpdates];
}

- (void)invalidateLayout {
    NSMutableArray *invalidatedLayoutArray = [_itemAttributesBySection copy];
    self.invalidatedLayoutArray = invalidatedLayoutArray;

    [super invalidateLayout];

}

- (NSIndexPath *)indexOfAlienViewWithCenterPoint:(CGPoint)alienCenter {
    NSUInteger item = 0;
    NSInteger counter = 0;
    BOOL valueSet = NO;
    NSArray *indexPathsForItems = [self.collectionView indexPathsForVisibleItems];
    CGFloat sectionHeight = ((self.collectionView).frame.size.height / [self.collectionView numberOfSections]);
    NSUInteger section = alienCenter.y / sectionHeight;
    NSUInteger numberOfItemsInSameSection = 0;
    
    for (NSIndexPath *indexPath in indexPathsForItems) {
        
        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath: indexPath];
        
        if (indexPath.section == section) {
            
            if (alienCenter.x < layoutAttributes.center.x && valueSet == NO) {
                item = indexPath.item;
                //section = indexPath.section;
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
