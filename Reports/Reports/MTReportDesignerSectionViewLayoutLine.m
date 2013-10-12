//
//  MTCollectionViewFlowLayout.m
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerSectionViewLayoutLine.h"
#import "MTLog.h"

@interface MTReportDesignerSectionViewLayoutLine ()

@property (assign) CGSize contentSize;
@property (assign) NSInteger numberOfSections;

@property (nonatomic, retain) NSMutableArray *itemAttributesBySection;
@property (nonatomic, retain) NSMutableArray *decorationAttributesBySection;
@property (nonatomic, retain) NSMutableArray *invalidatedLayoutArray;

@end

@implementation MTReportDesignerSectionViewLayoutLine

- (void)dealloc {
    [_itemAttributesBySection release];
    [_decorationAttributesBySection release];
    [_invalidatedLayoutArray release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        
        NSMutableArray *rectArray = [[NSMutableArray alloc] init];
        [self setItemAttributesBySection:rectArray];
        [rectArray release];

        [self registerClass: [MTReportDesignerSectionDecorationView class]
    forDecorationViewOfKind: NSStringFromClass([MTReportDesignerSectionDecorationView class])];

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

    NSMutableArray *itemAttributesBySection = [[NSMutableArray alloc] initWithCapacity: numberOfSections];
    NSMutableArray *decorationAttributesBySection = [[NSMutableArray alloc] initWithCapacity: numberOfSections];

    CGSize contentSize = CGSizeZero;
    
    CGFloat sectionHeight = [self sectionHeight];
    
    for (NSInteger section = 0; section < self.numberOfSections; section++) {
        
        NSInteger numberOfItems = [[self delegate] numberOfItemsInSection:section ofCollectionView:[self collectionView]];
        CGFloat maxWidthForSection = CGSizeZero.width, maxHeightForSection = CGSizeZero.height;
        NSMutableArray *layoutAttributesForSection = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
        
        CGFloat sectionY = CGPointZero.y + sectionHeight * section;
        
        for (NSInteger item = 0; item < numberOfItems; item++) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            CGSize itemSize = [[self delegate] collectionView:[self collectionView] layout:self sizeForItemAtIndexPath:indexPath];

            UICollectionViewLayoutAttributes *itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            [itemAttributes retain];
            
            itemAttributes.frame = CGRectMake(maxWidthForSection, sectionY, itemSize.width, itemSize.height);
            [layoutAttributesForSection addObject: itemAttributes];
            if (itemSize.height > maxHeightForSection) {
                maxHeightForSection = itemSize.height;
            }
            [itemAttributes setZIndex:section];
            maxWidthForSection += itemSize.width;
            [itemAttributes release];
        }
                
        [itemAttributesBySection addObject:layoutAttributesForSection];
        [layoutAttributesForSection release];

        if (maxWidthForSection > contentSize.width) {
            contentSize.width = maxWidthForSection;
        }
    
        contentSize.height += maxHeightForSection;
    }
    
    contentSize.height = [[self delegate] heightOfCollectionView:[self collectionView]];

    [self setContentSize:contentSize];
    [self setItemAttributesBySection:itemAttributesBySection];
    [self setDecorationAttributesBySection:decorationAttributesBySection];
    
    
    [itemAttributesBySection release];
    [decorationAttributesBySection release];
}

- (CGSize)collectionViewContentSize {
    //NSLog(@"collectionViewContentSize");
    return [self contentSize];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
    NSUInteger section = 0;
    for (NSArray *items in [self itemAttributesBySection]) {
        
        for (UICollectionViewLayoutAttributes *itemAttribute in items) {
            if (CGRectIntersectsRect(rect, itemAttribute.frame)) {
                [itemAttribute retain];
                [layoutAttributes addObject:itemAttribute];
                [itemAttribute release];
            }
        }
        
        section++;
    }
    
    return [layoutAttributes autorelease];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *result;
    result = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];

    return result;

}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *rectsForSection = [[self itemAttributesBySection] objectAtIndex:[indexPath section]];
    UICollectionViewLayoutAttributes *layoutAttributes = [rectsForSection objectAtIndex:[indexPath item]];

    return layoutAttributes;

}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = [[self decorationAttributesBySection] objectAtIndex:[indexPath section]];
    [layoutAttributes setFrame:CGRectMake(layoutAttributes.frame.origin.x, layoutAttributes.frame.origin.y, self.collectionView.contentSize.width, layoutAttributes.frame.size.height)];
    return  layoutAttributes;

}

- (UICollectionViewLayoutAttributes *)invalidatedLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *rectsForSection = [[self invalidatedLayoutArray] objectAtIndex:[indexPath section]];
    UICollectionViewLayoutAttributes *layoutAttributes = [rectsForSection objectAtIndex:[indexPath item]];

    return layoutAttributes;

}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = [[[[self itemAttributesBySection] objectAtIndex:indexPath.section] objectAtIndex:indexPath.item] copy];
    return [layoutAttributes autorelease];

}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)indexPath {
    [super layoutAttributesForItemAtIndexPath:indexPath];
    UICollectionViewLayoutAttributes *layoutAttributes = [[[self invalidatedLayoutArray] objectAtIndex:indexPath.section] objectAtIndex: indexPath.item];
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
            layoutAttributes.frame = CGRectMake(maxWidthForSection, sectionY, layoutAttributes.size.width, layoutAttributes.size.height);

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
    NSMutableArray *invalidatedLayoutArray = [[self itemAttributesBySection] copy];
    [self setInvalidatedLayoutArray:invalidatedLayoutArray];
    [invalidatedLayoutArray release];

    [super invalidateLayout];

}

- (NSIndexPath *)indexOfAlienViewWithCenterPoint:(CGPoint)alienCenter {
    NSUInteger item = 0;
    NSInteger counter = 0;
    BOOL valueSet = NO;
    NSArray *indexPathsForItems = [[self collectionView] indexPathsForVisibleItems];
    CGFloat sectionHeight = ([[self collectionView] frame].size.height / [[self collectionView] numberOfSections]);
    NSUInteger section = alienCenter.y / sectionHeight;
    NSUInteger numberOfItemsInSameSection = 0;
    
    for (NSIndexPath *indexPath in indexPathsForItems) {
        
        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath: indexPath];
        
        if ([indexPath section] == section) {
            
            if (alienCenter.x < [layoutAttributes center].x && valueSet == NO) {
                item = [indexPath item];
                //section = [indexPath section];
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
