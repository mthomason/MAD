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

@end

@implementation MTReportDesignerSectionViewLayout

- (void)dealloc {
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
        
    }
    return self;
}

- (CGFloat)sectionHeight {
    CGFloat collectionViewHeight = [[self delegate] heightOfCollectionView:[self collectionView]];
    return collectionViewHeight / [self numberOfSections];
}

- (void)prepareLayout {
    [super prepareLayout];
    NSUInteger numberOfSections = [[self delegate] numberOfSectionsInCollectionView:[self collectionView]];
    [self setNumberOfSections:numberOfSections];
    NSMutableArray *layoutAttributesArray = [[NSMutableArray alloc] initWithCapacity: numberOfSections];

    CGSize contentSize = CGSizeZero;
    
    CGFloat sectionHeight = [self sectionHeight];
    
    for (NSInteger section = 0; section < self.numberOfSections; section++) {

        NSInteger numberOfItems = [[self collectionView] numberOfItemsInSection:section];
        
        NSLog(@"Number of items in section %d: %d", section, numberOfItems);

        
        //CGSize supplementryViewSize = CGSizeMake(50.0000f, 50.0000f);
        //CGFloat maxWidthForSection = 50.0000f, maxHeightForSection = 0.0000f;
        
        CGFloat maxWidthForSection = CGSizeZero.width, maxHeightForSection = CGSizeZero.height;
        NSMutableArray *layoutAttributesForSection = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
        
        //NSIndexPath *firstIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        //UICollectionViewLayoutAttributes *layoutAttributesForHeader = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind: UICollectionElementKindSectionHeader
        //                                                                                                                             withIndexPath: firstIndexPath];
        //[layoutAttributesForHeader setFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 50.0000f, 50.0000f)];
        
        CGFloat sectionY = CGPointZero.y + sectionHeight * section;
        
        for (NSInteger item = 0; item < numberOfItems; item++) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            CGSize itemSize = [[self delegate] collectionView:[self collectionView] layout:self sizeForItemAtIndexPath:indexPath];
            UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            
//            layoutAttributes.frame = CGRectMake(maxWidthForSection, CGPointZero.y, itemSize.width, itemSize.height);
            
            layoutAttributes.frame = CGRectMake(maxWidthForSection, sectionY, itemSize.width, itemSize.height);

            NSLog(@"Layout frame: %@", NSStringFromCGRect(layoutAttributes.frame));
            
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
    
    for (NSInteger section = 0; section < [[self layoutArray] count]; section++) {
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

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *result;
    result = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    return result;
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

    // MARK: Recalculate updated attributes.
    CGSize contentSize = CGSizeZero;
    NSUInteger sectionCounter = 0, itemCounter = 0;
    CGFloat sectionHeight = [self sectionHeight];

    for (NSArray *sectionAttributes in [self invalidatedLayoutArray]) {

        CGFloat maxWidthForSection = 0.0000f, maxHeightForSection = 0.0000f;

        for (UICollectionViewLayoutAttributes *layoutAttributes in sectionAttributes) {

            layoutAttributes.indexPath = [NSIndexPath indexPathForItem:itemCounter inSection:sectionCounter];

            if (CGSizeEqualToSize(layoutAttributes.size, CGSizeZero)) {
                layoutAttributes.size = [[self delegate] collectionView:[self collectionView] layout:self sizeForItemAtIndexPath:layoutAttributes.indexPath];
            }
            CGFloat sectionY = CGPointZero.y + sectionHeight * layoutAttributes.indexPath.section;
            //CGFloat sectionY = CGPointZero.y;
            layoutAttributes.frame = CGRectMake(maxWidthForSection, sectionY, layoutAttributes.size.width, layoutAttributes.size.height);

            NSLog(@"Update frame: %@", NSStringFromCGRect(layoutAttributes.frame));

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
