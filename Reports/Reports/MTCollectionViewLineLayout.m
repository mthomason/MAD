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

@property (nonatomic, retain) NSMutableArray *rectangleArray;

@end

@implementation MTCollectionViewLineLayout

- (void)dealloc {
    [_rectangleArray release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        NSMutableArray *rectArray = [[NSMutableArray alloc] init];
        [self setRectangleArray:rectArray];
        [rectArray release];
        //[self prepareLayout];
    }
    return self;
}

- (void)prepareLayout {

    CGSize contentSize = CGSizeZero;
    self.numberOfSections = [[self collectionView] numberOfSections];

    [[self rectangleArray] removeAllObjects];

    for (NSInteger section = 0; section < self.numberOfSections; section++) {
        NSInteger numberOfItems = [[self collectionView] numberOfItemsInSection:section];
        
        CGFloat maxWidthForSection = 0.0000f;
        CGFloat maxHeightForSection = 0.0000f;
        
        NSMutableArray *rectsForSection = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
        
        for (NSInteger item = 0; item < numberOfItems; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewCell *cell = [[self collectionView] cellForItemAtIndexPath: indexPath];
            if (cell != nil) {
                CGRect itemRect = CGRectMake(maxWidthForSection, CGPointZero.y, cell.bounds.size.width, cell.bounds.size.height);
                NSValue *rect = [NSValue valueWithCGRect: itemRect];
                [rectsForSection addObject: rect];
                if ([cell bounds].size.height > maxHeightForSection) {
                    maxHeightForSection = [cell bounds].size.height;
                }
                maxWidthForSection += [cell bounds].size.width;
            }
        }
        [[self rectangleArray] addObject:rectsForSection];
        [rectsForSection release];
        
        if (maxWidthForSection > contentSize.width) {
            contentSize.width = maxWidthForSection;
        }
        contentSize.height += maxHeightForSection;
    }
    [self setContentSize:contentSize];
    [super prepareLayout];
}

- (CGSize)collectionViewContentSize {
    return [self contentSize];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
    
    for (NSInteger section = 0; section < self.rectangleArray.count; section++) {
        NSArray *items = [[self rectangleArray] objectAtIndex:section];
        for (NSInteger item = 0; item < items.count; item++) {
            NSValue *rectValue = [items objectAtIndex:item];
            CGRect itemRect = [rectValue CGRectValue];
            if (CGRectIntersectsRect(rect, itemRect)) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                [layoutAttributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
            }
        }
    }
    
    return [layoutAttributes autorelease];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *rectsForSection = [[self rectangleArray] objectAtIndex:[indexPath section]];
    NSValue *rectValue = [rectsForSection objectAtIndex:[indexPath item]];
    CGRect rect = [rectValue CGRectValue];

    UICollectionViewLayoutAttributes *layoutAttributes = [[UICollectionViewLayoutAttributes alloc] init];
    [layoutAttributes setIndexPath:indexPath];
    [layoutAttributes setFrame:rect];
    
    return [layoutAttributes autorelease];
}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)oldBounds {
    return YES;
}


- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    UICollectionViewLayoutAttributes *result = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
    result.center = [[self delegate] centerPointForIndexPath:itemIndexPath inCollectionView:[self collectionView]];
    return result;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    return [self layoutAttributesForItemAtIndexPath:itemIndexPath];
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    
}

- (void)finalizeCollectionViewUpdates {
    
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