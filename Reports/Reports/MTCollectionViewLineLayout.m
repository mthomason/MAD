//
//  MTCollectionViewFlowLayout.m
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTCollectionViewLineLayout.h"

@interface MTCollectionViewLineLayout ()

@property (assign) CGSize contentSize;
@property (assign) NSInteger numberOfSections;

@property (assign) BOOL layoutValid;

@property (nonatomic, retain) NSMutableArray *layoutArray;
@property (nonatomic, retain) NSMutableArray *invalidatedLayoutArray;

@property (nonatomic, retain) NSMutableDictionary *updateItemsInserted;
@property (nonatomic, retain) NSMutableDictionary *updateItemsDeleted;
@property (nonatomic, retain) NSMutableDictionary *updateItemsMoved;
@property (nonatomic, retain) NSMutableDictionary *updateItemsReload;

@end

@implementation MTCollectionViewLineLayout

- (void)dealloc {
    [_updateItemsInserted release];
    [_updateItemsDeleted release];
    [_updateItemsMoved release];
    [_updateItemsReload release];
    [_invalidatedLayoutArray release];
    [_layoutArray release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        
        NSMutableArray *rectArray = [[NSMutableArray alloc] init];
        [self setLayoutArray:rectArray];
        [rectArray release];

        NSMutableDictionary *updateItemsInserted = [[NSMutableDictionary alloc] init];
        [self setUpdateItemsInserted:updateItemsInserted];
        [updateItemsInserted release];
        
        NSMutableDictionary *updateItemsDeleted = [[NSMutableDictionary alloc] init];
        [self setUpdateItemsDeleted:updateItemsDeleted];
        [updateItemsDeleted release];

        NSMutableDictionary *updateItemsMoved = [[NSMutableDictionary alloc] init];
        [self setUpdateItemsMoved:updateItemsMoved];
        [updateItemsMoved release];

        NSMutableDictionary *updateItemsReload = [[NSMutableDictionary alloc] init];
        [self setUpdateItemsReload:updateItemsReload];
        [updateItemsReload release];

    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];
    NSLog(@"%@Prepare layout", self);

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
    //NSLog(@"layoutAttributesForElementsInRect");
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
    //NSLog(@"layoutAttributesForItemAtIndexPath");
    NSUInteger sectionIndex = [indexPath section];
    NSUInteger itemIndex = [indexPath item];
    if (sectionIndex >= [[self layoutArray] count]) {
        NSLog(@"Crash");
    }
    NSArray *rectsForSection = [[self layoutArray] objectAtIndex:sectionIndex];
    if (itemIndex >= [rectsForSection count]) {
        NSLog(@"Crash");
    }
    UICollectionViewLayoutAttributes *layoutAttributes = [rectsForSection objectAtIndex:itemIndex];
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)invalidatedLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"layoutAttributesForItemAtIndexPath");
    NSUInteger sectionIndex = [indexPath section];
    NSUInteger itemIndex = [indexPath item];
    if (sectionIndex >= [[self invalidatedLayoutArray] count]) {
        NSLog(@"Crash");
    }
    NSArray *rectsForSection = [[self invalidatedLayoutArray] objectAtIndex:sectionIndex];
    if (itemIndex >= [rectsForSection count]) {
        NSLog(@"Crash");
    }
    UICollectionViewLayoutAttributes *layoutAttributes = [rectsForSection objectAtIndex:itemIndex];
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = [[[[self layoutArray] objectAtIndex:itemIndexPath.section] objectAtIndex:itemIndexPath.item] copy];
    //result.center = [[self delegate] collectionView:[self collectionView] layout:self initialLayoutCenterPointForIndexPath:itemIndexPath];
    NSLog(@"%@initial layout [%d, %d] %@", self, itemIndexPath.section, itemIndexPath.item, NSStringFromCGRect(layoutAttributes.frame));
    return [layoutAttributes autorelease];
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    [super layoutAttributesForItemAtIndexPath:itemIndexPath];
    UICollectionViewLayoutAttributes *layoutAttributes = [[[self invalidatedLayoutArray] objectAtIndex:itemIndexPath.section] objectAtIndex: itemIndexPath.item];
    NSLog(@"%@final layout [%d, %d] %@", self, itemIndexPath.section, itemIndexPath.item, NSStringFromCGRect(layoutAttributes.frame));
    return layoutAttributes;
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];
    NSLog(@"%@prepareForCollectionViewUpdates", self);
    
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
                NSIndexPath *insertedIndex = [updateItem indexPathAfterUpdate];
                UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:insertedIndex];
                [[invalidatedLayoutArray objectAtIndex:[insertedIndex section]] insertObject:layoutAttributes atIndex:[insertedIndex item]];
                break;
            case UICollectionUpdateActionDelete:
                NSLog(@"%@%@%@", @"UICollectionUpdateActionDelete", [updateItem indexPathBeforeUpdate], [updateItem indexPathAfterUpdate]);
                NSIndexPath *deletedIndex = [updateItem indexPathBeforeUpdate];
                [[invalidatedLayoutArray objectAtIndex:[deletedIndex section]] removeObjectsAtIndexes:[NSIndexSet indexSetWithIndex:[deletedIndex item]]];
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
    //[self setContentSize:contentSize];


    //[self setInvalidatedLayoutArray:invalidatedLayoutArray];
    
    //[invalidatedLayoutArray release];
}

- (void)finalizeCollectionViewUpdates {
    [super finalizeCollectionViewUpdates];
    NSLog(@"%@finalizeCollectionViewUpdates", self);
}

- (void)invalidateLayout {
    NSLog(@"%@invalidateLayout", self);
    NSMutableArray *invalidatedLayoutArray = [[self layoutArray] copy];
    [self setInvalidatedLayoutArray:invalidatedLayoutArray];
    [invalidatedLayoutArray release];
    [super invalidateLayout];
    //[self setInvalidatedLayoutArray:[self layoutArray]];
}

/*
-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray* array = [super layoutAttributesForElementsInRect:rect];
    CGRect visibleRect;
    visibleRect.origin = self.collectionView.contentOffset;
    visibleRect.size = self.collectionView.bounds.size;
 
    for (UICollectionViewLayoutAttributes *attributes in array) {
        if (CGRectIntersectsRect(attributes.frame, rect)) {
            [attributes setFrame:CGRectMake(attributes.frame.origin.x, CGPointZero.y, attributes.frame.size.width, attributes.frame.size.height)];
        }
    }
    return array;
}
 */
@end