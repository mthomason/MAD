//
//  MTCollectionViewFlowLayout.m
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerSectionViewLayout.h"

@interface MTReportDesignerSectionViewLayout ()

@property (assign) CGSize contentSize;
@property (assign) NSInteger numberOfSections;

@property (nonatomic, retain) NSMutableArray *layoutArray;
@property (nonatomic, retain) NSMutableArray *invalidatedLayoutArray;

@property (nonatomic, retain) NSMutableArray *disappearingAttributes;

@end

@implementation MTReportDesignerSectionViewLayout

- (void)dealloc {
    [_invalidatedLayoutArray release];
    [_layoutArray release];
    [_disappearingAttributes release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        
        NSMutableArray *rectArray = [[NSMutableArray alloc] init];
        [self setLayoutArray:rectArray];
        [rectArray release];

        NSMutableArray *disappearingAttributes = [[NSMutableArray alloc] init];
        [self setDisappearingAttributes:disappearingAttributes];
        [disappearingAttributes release];

    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
    //NSLog(@"%@Prepare layout", self);

    NSUInteger numberOfSections = [[self collectionView] numberOfSections];
    [self setNumberOfSections:numberOfSections];
    NSMutableArray *layoutAttributesArray = [[NSMutableArray alloc] initWithCapacity: numberOfSections];

    CGSize contentSize = CGSizeZero;

    for (NSInteger section = 0; section < self.numberOfSections; section++) {

        NSInteger numberOfItems = [[self collectionView] numberOfItemsInSection:section];
        CGFloat maxWidthForSection = 0.0000f, maxHeightForSection = 0.0000f;
        NSMutableArray *layoutAttributesForSection = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
        
        for (NSInteger item = 0; item < numberOfItems; item++) {

            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            CGSize itemSize = [[self delegate] collectionView:[self collectionView] layout:self sizeForItemAtIndexPath:indexPath];
            UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

            layoutAttributes.frame = CGRectMake(maxWidthForSection, CGPointZero.y, itemSize.width, itemSize.height);

            [layoutAttributesForSection addObject: layoutAttributes];
            if (itemSize.height > maxHeightForSection) {
                maxHeightForSection = itemSize.height;
            }
            maxWidthForSection += itemSize.width;
        }
        
        [layoutAttributesArray addObject:layoutAttributesForSection];
        [layoutAttributesForSection release];
        
        if (maxWidthForSection > contentSize.width) {
            contentSize.width = maxWidthForSection;
        }
    
        contentSize.height += maxHeightForSection;

    }

    [self setContentSize:contentSize];
    [self setLayoutArray:layoutAttributesArray];
    [layoutAttributesArray release];
}

- (CGSize)collectionViewContentSize {
    return [self contentSize];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
    
    for (NSInteger section = 0; section < [self.layoutArray count]; section++) {
        NSArray *items = [[self layoutArray] objectAtIndex:section];
        for (NSInteger item = 0; item < items.count; item++) {
            UICollectionViewLayoutAttributes *layoutAttribute = [items objectAtIndex:item];
            if (CGRectIntersectsRect(rect, layoutAttribute.frame)) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                [layoutAttributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
            }
        }
    }
    
    return [layoutAttributes autorelease];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger sectionIndex = [indexPath section];
    NSUInteger itemIndex = [indexPath item];
    NSArray *rectsForSection = [[self layoutArray] objectAtIndex:sectionIndex];
    UICollectionViewLayoutAttributes *layoutAttributes = [rectsForSection objectAtIndex:itemIndex];
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)invalidatedLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger sectionIndex = [indexPath section];
    NSUInteger itemIndex = [indexPath item];
    NSArray *rectsForSection = [[self invalidatedLayoutArray] objectAtIndex:sectionIndex];
    UICollectionViewLayoutAttributes *layoutAttributes = [rectsForSection objectAtIndex:itemIndex];
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    //NSLog(@"Appearing %@", itemIndexPath);
    UICollectionViewLayoutAttributes *layoutAttributes = [[[[self layoutArray] objectAtIndex:itemIndexPath.section] objectAtIndex:itemIndexPath.item] copy];
    return [layoutAttributes autorelease];
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    //NSLog(@"Disappearing %@", itemIndexPath);
    [super layoutAttributesForItemAtIndexPath:itemIndexPath];
    UICollectionViewLayoutAttributes *layoutAttributes = [[[self invalidatedLayoutArray] objectAtIndex:itemIndexPath.section] objectAtIndex: itemIndexPath.item];
    return layoutAttributes;
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];
    
    NSMutableArray *disappearingAttributes = [[NSMutableArray alloc] initWithArray:[self invalidatedLayoutArray]];
    //NSMutableArray *appearingAttributes = [[NSMutableArray alloc] initWithArray:[self layoutArray]];
    
    //NSMutableArray *invalidatedLayoutArray = [[NSMutableArray alloc] initWithArray:[self layoutArray]];
    /*
    // MARK: Update attribute array for colleciton view.
    for (UICollectionViewUpdateItem *updateItem in updateItems) {
        switch ([updateItem updateAction]) {
            case UICollectionUpdateActionNone:
                NSLog(@"%@%@%@", @"UICollectionUpdateActionNone", [updateItem indexPathBeforeUpdate], [updateItem indexPathAfterUpdate]);
                break;
            case UICollectionUpdateActionInsert:
                NSLog(@"%@%@%@", @"UICollectionUpdateActionInsert", [updateItem indexPathBeforeUpdate], [updateItem indexPathAfterUpdate]);
                UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:updateItem.indexPathAfterUpdate];
                layoutAttributes.size = [[self delegate] collectionView:[self collectionView] layout:self sizeForItemAtIndexPath:updateItem.indexPathAfterUpdate];
                layoutAttributes.center = [[self delegate] collectionView:[self collectionView] layout:self initialLayoutCenterPointForIndexPath:updateItem.indexPathAfterUpdate];
                [[disappearingAttributes objectAtIndex:updateItem.indexPathAfterUpdate.section] insertObject:layoutAttributes atIndex:updateItem.indexPathAfterUpdate.item];
                break;
            case UICollectionUpdateActionDelete:
                NSLog(@"%@%@%@", @"UICollectionUpdateActionDelete", [updateItem indexPathBeforeUpdate], [updateItem indexPathAfterUpdate]);
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:updateItem.indexPathBeforeUpdate.item];
                [[disappearingAttributes objectAtIndex:updateItem.indexPathBeforeUpdate.section] removeObjectsAtIndexes:indexSet];
                break;
            case UICollectionUpdateActionReload:
                NSLog(@"%@%@%@", @"UICollectionUpdateActionReload", [updateItem indexPathBeforeUpdate], [updateItem indexPathAfterUpdate]);
                break;
            case UICollectionUpdateActionMove:
                NSLog(@"%@%@%@", @"UICollectionUpdateActionMove", [updateItem indexPathBeforeUpdate], [updateItem indexPathAfterUpdate]);
                break;
            default:
                break;
        }
    }
    */
    [self setDisappearingAttributes:disappearingAttributes];
    [disappearingAttributes release];
    //[appearingAttributes release];
    
    
    // MARK: Recalculate updated attributes.
    CGSize contentSize = CGSizeZero;
    NSUInteger sectionCounter = 0, itemCounter = 0;
    for (NSArray *sectionAttributes in [self invalidatedLayoutArray]) {

        CGFloat maxWidthForSection = 0.0000f, maxHeightForSection = 0.0000f;

        for (UICollectionViewLayoutAttributes *layoutAttributes in sectionAttributes) {
            layoutAttributes.indexPath = [NSIndexPath indexPathForItem:itemCounter inSection:sectionCounter];
            if (CGSizeEqualToSize(layoutAttributes.size, CGSizeZero)) {
                layoutAttributes.size = [[self delegate] collectionView:[self collectionView] layout:self sizeForItemAtIndexPath:layoutAttributes.indexPath];
            }
            layoutAttributes.frame = CGRectMake(maxWidthForSection, CGPointZero.y, layoutAttributes.size.width, layoutAttributes.size.height);
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
    NSMutableArray *invalidatedLayoutArray = [[self layoutArray] copy];
    [self setInvalidatedLayoutArray:invalidatedLayoutArray];
    [invalidatedLayoutArray release];
    [super invalidateLayout];
}

@end
