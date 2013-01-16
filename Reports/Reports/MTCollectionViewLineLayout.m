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

@property (nonatomic, retain) NSArray *rectangleArray;
@property (nonatomic, retain) NSArray *invalidatedRectangleArray;

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
    [_invalidatedRectangleArray release];
    [_rectangleArray release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        
        NSArray *rectArray = [[NSArray alloc] init];
        [self setRectangleArray:rectArray];
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
    NSLog(@"Prepare layout");

    NSUInteger numberOfSections = [[self collectionView] numberOfSections];
    [self setNumberOfSections:numberOfSections];
    NSMutableArray *rectangleArray = [[NSMutableArray alloc] initWithCapacity: numberOfSections];
    //if (![self layoutValid]) {

    CGSize contentSize = CGSizeZero;
    
    for (NSInteger section = 0; section < self.numberOfSections; section++) {
        NSInteger numberOfItems = [[self collectionView] numberOfItemsInSection:section];
        
        CGFloat maxWidthForSection = 0.0000f;
        CGFloat maxHeightForSection = 0.0000f;
        
        NSMutableArray *rectsForSection = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
        
        for (NSInteger item = 0; item < numberOfItems; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            CGSize itemSize = [[self delegate] collectionView:[self collectionView] layout:self sizeForItemAtIndexPath:indexPath];
            
            UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            layoutAttributes.frame = CGRectMake(maxWidthForSection, CGPointZero.y, itemSize.width, itemSize.height);
            [rectsForSection addObject: layoutAttributes];
            if (itemSize.height > maxHeightForSection) {
                maxHeightForSection = itemSize.height;
            }
            maxWidthForSection += itemSize.width;
        }
        
        [rectangleArray addObject:rectsForSection];
        [rectsForSection release];
        
        if (maxWidthForSection > contentSize.width) {
            contentSize.width = maxWidthForSection;
        }
        contentSize.height += maxHeightForSection;
    }
    [self setContentSize:contentSize];
    
    [self setLayoutValid:YES];
    [self setRectangleArray:rectangleArray];
}

- (CGSize)collectionViewContentSize {
    return [self contentSize];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    //NSLog(@"layoutAttributesForElementsInRect");
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
    
    for (NSInteger section = 0; section < [self.rectangleArray count]; section++) {
        NSArray *items = [[self rectangleArray] objectAtIndex:section];
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
    if (sectionIndex >= [[self rectangleArray] count]) {
        NSLog(@"Crash");
    }
    NSArray *rectsForSection = [[self rectangleArray] objectAtIndex:sectionIndex];
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
    if (sectionIndex >= [[self invalidatedRectangleArray] count]) {
        NSLog(@"Crash");
    }
    NSArray *rectsForSection = [[self invalidatedRectangleArray] objectAtIndex:sectionIndex];
    if (itemIndex >= [rectsForSection count]) {
        NSLog(@"Crash");
    }
    UICollectionViewLayoutAttributes *layoutAttributes = [rectsForSection objectAtIndex:itemIndex];
    
    return layoutAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)oldBounds {
    NSLog(@"shouldInvalidateLayoutForBoundsChange");
    return NO;
}


- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    NSLog(@"initialLayoutAttributesForAppearingItemAtIndexPath: %@", itemIndexPath);
    UICollectionViewLayoutAttributes *result = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
    result.center = [[self delegate] collectionView:[self collectionView] layout:self initialLayoutCenterPointForIndexPath:itemIndexPath];
    return result;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:itemIndexPath];
    NSLog(@"finalLayoutAttributesForDisappearingItemAtIndexPath: %@", itemIndexPath);
    /*
    NSUInteger sectionIndex = [itemIndexPath section];
    NSUInteger itemIndex = [itemIndexPath item];
    if (sectionIndex >= [[self rectangleArray] count]) {
        NSLog(@"Crash");
    }
    NSArray *rectsForSection = [[self rectangleArray] objectAtIndex:sectionIndex];
    if (itemIndex >= [rectsForSection count]) {
        NSLog(@"Crash");
    }
    */
    //UICollectionViewLayoutAttributes *layoutAttributes = [[self updateItemsDeleted] objectForKey: itemIndexPath];
    
    [layoutAttributes setHidden:YES];
    return layoutAttributes;
}
/*
- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];
    NSLog(@"prepareForCollectionViewUpdates");
    for (UICollectionViewUpdateItem *updateItem in updateItems) {
        switch ([updateItem updateAction]) {
            case UICollectionUpdateActionNone:
                NSLog(@"%@%@%@", @"UICollectionUpdateActionNone", [updateItem indexPathBeforeUpdate], [updateItem indexPathAfterUpdate]);
                break;
            case UICollectionUpdateActionInsert:
                NSLog(@"%@%@%@", @"UICollectionUpdateActionInsert", [updateItem indexPathBeforeUpdate], [updateItem indexPathAfterUpdate]);
                break;
            case UICollectionUpdateActionDelete:
                NSLog(@"%@%@%@", @"UICollectionUpdateActionDelete", [updateItem indexPathBeforeUpdate], [updateItem indexPathAfterUpdate]);
//                [[self updateItemsDeleted] setObject:[self invalidatedLayoutAttributesForItemAtIndexPath:[updateItem indexPathBeforeUpdate]] forKey:[updateItem indexPathBeforeUpdate]];
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
}

- (void)finalizeCollectionViewUpdates {
    [super finalizeCollectionViewUpdates];
    NSLog(@"finalizeCollectionViewUpdates");
}
 */

- (void)invalidateLayout {
    NSLog(@"invalidateLayout");
    [super invalidateLayout];
    [self setInvalidatedRectangleArray:[self rectangleArray]];
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