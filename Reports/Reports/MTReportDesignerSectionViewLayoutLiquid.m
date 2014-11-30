
//
//  MTCollectionViewFlowLayout.m
//  Reports
//
//  Created by Michael Thomason on 1/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerSectionViewLayoutLiquid.h"
#import "SectionEnumerator.h"
#import "MTReportDesignerSectionDecorationView.h"
#import "MTCollectionViewLayoutLiquidAttributes.h"
#import "CGGeometry+Extras.h"

@interface MTReportDesignerSectionViewLayoutLiquid ()

@property (nonatomic, assign) NSInteger numberOfSections;
@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, strong) NSMutableArray *itemAttributesBySection;

@end

@implementation MTReportDesignerSectionViewLayoutLiquid


- (instancetype)init {
    self = [super init];
    if (self) {
        
        if (self.collectionView.tag == 1) {
            NSLog(@"%s", __PRETTY_FUNCTION__);
        }

        NSMutableArray *itemAttributesBySection = [[NSMutableArray alloc] init];
        self.itemAttributesBySection = itemAttributesBySection;

        NSString *decorationViewKind = NSStringFromClass([MTReportDesignerSectionDecorationView class]);
        [self registerClass: [MTReportDesignerSectionDecorationView class]
    forDecorationViewOfKind: decorationViewKind];

    }
    return self;
}

- (MTCollectionViewLayoutLiquidAttributes *)placeLayouts:(NSArray *)layoutAttributesForSection
                                               forLayout:(MTCollectionViewLayoutLiquidAttributes *)layout {
    /*
    CGFloat distanceFromDropPoint = -1.0000f;   //Represents an invalid distance
    CGRect nearestRect = CGRectZero;
    
    CGFloat x1, x2, y1, y2;
    CGRect placement0, placement1, placement2, placement3;
    NSValue *placement0Value, *placement1Value, *placement2Value, *placement3Value;
    NSArray *potentialPlacements;
    CGRect potentialPlacement;
    CGFloat potentialPlacementDistanceFromDropPoint;
    id placementValue;
    MTCollectionViewLayoutLiquidAttributes *placedLayout;
    for (placedLayout in layoutAttributesForSection) {
        
        //There exist four potental placement spots for each alredy placed rect
        x1 = placedLayout.frame.origin.x;
        x2 = placedLayout.frame.origin.x + placedLayout.frame.size.width;
        y1 = placedLayout.frame.origin.y;
        y2 = placedLayout.frame.origin.y + placedLayout.frame.size.height;
        
        placement0 = CGRectMake(x1, y1, layout.frame.size.width, layout.frame.size.height);
        placement1 = CGRectMake(x2, y1, layout.frame.size.width, layout.frame.size.height);
        placement2 = CGRectMake(x2, y2, layout.frame.size.width, layout.frame.size.height);
        placement3 = CGRectMake(x1, y2, layout.frame.size.width, layout.frame.size.height);

        placement0Value = [NSValue valueWithCGRect: placement0];
        placement1Value = [NSValue valueWithCGRect: placement1];
        placement2Value = [NSValue valueWithCGRect: placement2];
        placement3Value = [NSValue valueWithCGRect: placement3];
        
        potentialPlacements = @[placement0Value,
                                placement1Value,
                                placement2Value,
                                placement3Value];
        
        for (placementValue in potentialPlacements) {
            
            potentialPlacement = ((NSValue *)placementValue).CGRectValue;
            
            potentialPlacementDistanceFromDropPoint = CGDistance(potentialPlacement.origin, layout.frame.origin);
            BOOL dropPointIsOrigin = CGPointEqualToPoint(potentialPlacement.origin, layout.frame.origin);
            
            if (((potentialPlacementDistanceFromDropPoint < distanceFromDropPoint && dropPointIsOrigin == NO) ||
                 dropPointIsOrigin ||
                 distanceFromDropPoint < 0)) {
                
                distanceFromDropPoint = potentialPlacementDistanceFromDropPoint;
                nearestRect = potentialPlacement;
            }
            
        }
    }
    
    layout.frame = nearestRect;
    
    [self.delegate collectionView: self.collectionView
                           layout: self
                     setDropPoint: layout.frame.origin
               forItemAtIndexPath: layout.indexPath];
    
    return layout;*/
    return nil;
}

- (NSSet *)positionsOfRects: (CGRect)rect
                 aroundRect: (CGRect)centerRect {
    
    //There exist four potental placement spots for each alredy placed rect
    CGFloat x1 = centerRect.origin.x;
    CGFloat x2 = centerRect.origin.x + centerRect.size.width;
    CGFloat y1 = centerRect.origin.y;
    CGFloat y2 = centerRect.origin.y + centerRect.size.height;
    
    CGRect placement0, placement1, placement2, placement3;
    
    placement0 = CGRectMake(x1, y1, rect.size.width, rect.size.height);
    placement1 = CGRectMake(x2, y1, rect.size.width, rect.size.height);
    placement2 = CGRectMake(x2, y2, rect.size.width, rect.size.height);
    placement3 = CGRectMake(x1, y2, rect.size.width, rect.size.height);
    
    
    return [NSSet setWithObjects:
            [NSValue valueWithCGRect: placement0],
            [NSValue valueWithCGRect: placement1],
            [NSValue valueWithCGRect: placement2],
            [NSValue valueWithCGRect: placement3], nil];
}

- (NSSet *)availablePositionsOfRect: (CGRect)rect
                         aroundRect: (CGRect)centerRect {
    
    //There exist two potental placement spots around a rect to put another rect.
    
    CGRect placement1 = CGRectMake(centerRect.origin.x + centerRect.size.width,
                                   centerRect.origin.y,
                                   rect.size.width,
                                   rect.size.height);
    
    CGRect placement3 = CGRectMake(centerRect.origin.x,
                                   centerRect.origin.y + centerRect.size.height,
                                   rect.size.width,
                                   rect.size.height);
    
    NSValue *value1 = [NSValue valueWithCGRect: placement1];
    NSValue *value2 = [NSValue valueWithCGRect: placement3];
    return [NSSet setWithObjects:
            value1,
            value2, nil];
}

- (NSArray *)layout: (MTCollectionViewLayoutLiquidAttributes *)layout
  overlapWithLayout: (NSArray *)layouts {
    
    NSMutableArray *layoutsToReposition = [[NSMutableArray alloc] init];
    MTCollectionViewLayoutLiquidAttributes *layoutForSection;
    for (layoutForSection in layouts) {
        if (layoutForSection != layout && CGRectIntersectsRect(layoutForSection.frame, layout.frame)) {
            [layoutsToReposition addObject:layoutForSection];
        }
    }
    return layoutsToReposition;
}

- (void)repositionLayouts: (NSArray *)layouts
                forLayout: (MTCollectionViewLayoutLiquidAttributes *)layoutToReposition {
    /*
    NSArray *overlap = [self layout: layoutToReposition
                  overlapWithLayout: layouts];
    NSMutableArray *layoutsToReposition = [[NSMutableArray alloc] initWithArray: overlap];
    
    if (layoutsToReposition.count) {
        
        //Sort layouts by distance from layoutToReposition
        CGPoint layoutToRepositionOrigin = layoutToReposition.frame.origin;
        NSComparator comparator = ^NSComparisonResult(MTCollectionViewLayoutLiquidAttributes *layout1, MTCollectionViewLayoutLiquidAttributes *layout2) {
            return CGDistance(layoutToRepositionOrigin, layout1.frame.origin) >
                        CGDistance(layoutToRepositionOrigin, layout2.frame.origin) ?
                                                                        NSOrderedDescending : NSOrderedAscending;
        };
        [layoutsToReposition sortUsingComparator:comparator];
        
        // FIXME: Order by distance from layoutToReposition
        NSUInteger ctr = 0;
        
        for (MTCollectionViewLayoutLiquidAttributes *layoutToChange in layoutsToReposition) {
            
            if (ctr == 0) {
                
                NSSet *availablePositions = [self availablePositionsOfRect: layoutToChange.frame
                                                                aroundRect: layoutToReposition.frame];
                
                NSArray *availablePositionsOrdered = availablePositions.allObjects;
                NSUInteger indexOfNearestPosition = -1, indexOfFurtheristPosition = -1;
                CGFloat distanceToNearest = 0.0000f, distanceToFurtherist = 0.0000f;
                NSUInteger positionCounter = 0;
                
                for (NSValue *availablePositionsValue in availablePositionsOrdered) {
                    CGRect availableRect = availablePositionsValue.CGRectValue;
                    
                    CGFloat d = CGDistance(availableRect.origin, layoutToReposition.frame.origin);
                    if (indexOfNearestPosition == -1 || d > distanceToNearest) {
                        distanceToNearest = d;
                        indexOfNearestPosition = positionCounter;
                    }
                    if (d > distanceToFurtherist) {
                        distanceToFurtherist = d;
                        indexOfFurtheristPosition = positionCounter;
                    }
                    positionCounter++;
                }
                
                NSValue *position = availablePositionsOrdered[indexOfNearestPosition];
                layoutToChange.frame = [position CGRectValue];
                layoutToChange.dropIndex = [self.delegate collectionView: self.collectionView
                                                                  layout: self
                                       updateDropIndexForItemAtIndexPath: layoutToChange.indexPath];
                layoutToChange.dropPoint = layoutToChange.frame.origin;
                
                [self.delegate collectionView: self.collectionView
                                       layout: self
                                 setDropPoint: layoutToChange.frame.origin
                           forItemAtIndexPath: layoutToChange.indexPath];
                layoutToChange.lastTouchPointValid = NO;
                
            } else {
                
                NSArray *layoutToRepositionLocked = [[NSArray alloc] initWithArray:layoutsToReposition];
                if (ctr < [layoutToRepositionLocked count] - 1) {
                    NSRange range = NSMakeRange(ctr, [layoutToRepositionLocked count] - ctr);
                    NSArray *lb = [[NSArray alloc] initWithArray:[layoutToRepositionLocked subarrayWithRange:range]];
                    [self repositionLayouts: lb
                                  forLayout: layoutToRepositionLocked[ctr - 1]];
                }
            }
            ctr++;
        }
    }*/
}

- (void)prepareLayout {
    [super prepareLayout];
    if (self.collectionView.tag == 1) {
        NSLog(@"%s", __PRETTY_FUNCTION__);
    }
    
    [self.delegate collectionView:self.collectionView prepareLayout:self];
    
    self.numberOfSections = 1;
    self.numberOfItems = [self.delegate numberOfItemsInSection: 0
                                              ofCollectionView: self.collectionView];
/*
    NSInteger numberOfSections = 1;
    
    NSMutableArray *itemAttributesBySection = [[NSMutableArray alloc] initWithCapacity: numberOfSections];
    
    for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
        
        NSInteger numberOfItems = [self.delegate numberOfItemsInSection: sectionIndex
                                                       ofCollectionView: self.collectionView];
        
        NSMutableArray *itemLayouts = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
        
        for (NSInteger itemIndex = 0; itemIndex < numberOfItems; itemIndex++) {

            NSIndexPath *path = [NSIndexPath indexPathForItem: itemIndex
                                                    inSection: sectionIndex];
            
            MTCollectionViewLayoutLiquidAttributes *itemAttributes = [self.delegate collectionView: self.collectionView
                                                                                            layout: self
                                                                layoutAttributesForItemAtIndexPath: path];
            [itemLayouts addObject:itemAttributes];
            
        }
        
        NSComparator comparator = ^NSComparisonResult(MTCollectionViewLayoutLiquidAttributes *layout1, MTCollectionViewLayoutLiquidAttributes *layout2) {
            return (layout1.dropIndex > layout2.dropIndex) ?
                                                    NSOrderedDescending : NSOrderedAscending;
        };
        
        [itemLayouts sortUsingComparator:comparator];
        [itemAttributesBySection addObject:itemLayouts];
    }
    
    for (NSArray *sectionItemLayouts in itemAttributesBySection) {
        
        @autoreleasepool {

            NSUInteger itemCounter = 0;
            NSMutableArray *layoutAttributesForSection = [[NSMutableArray alloc] initWithCapacity:sectionItemLayouts.count];
            
            for (MTCollectionViewLayoutLiquidAttributes *itemAttributes in sectionItemLayouts) {
                @autoreleasepool {
                    
                    if (itemCounter == 0) {
                        
                        CGRect zeroPointRect = CGRectMake(CGPointZero.x,
                                                          CGPointZero.y,
                                                          itemAttributes.frame.size.width,
                                                          itemAttributes.frame.size.height);
                        itemAttributes.frame = zeroPointRect;
                        
                        [self.delegate collectionView: self.collectionView
                                               layout: self
                                         setDropPoint: itemAttributes.frame.origin
                                   forItemAtIndexPath: itemAttributes.indexPath];
                        
                        [layoutAttributesForSection addObject:itemAttributes];
                        
                    } else {
                        
                        //Try every placement option to the bottom-right of existing items, while
                        //  checking for overlap with every already placed item.  The shortest
                        //  path to the drop path wins.
                        
                        MTCollectionViewLayoutLiquidAttributes *updatedLayout = [self placeLayouts:layoutAttributesForSection forLayout:itemAttributes];
                        [layoutAttributesForSection addObject:updatedLayout];
                        
                    }
                    itemCounter++;
                }
            }
            
        }
    }
    
    [self repositionLayouts:itemAttributesBySection[0]
                  forLayout:[itemAttributesBySection[0] lastObject]];
    
    
    for (id ly in itemAttributesBySection[0]) {
        @autoreleasepool {
            [self repositionLayouts: itemAttributesBySection[0]
                          forLayout: ly];
        }
    }
    
    self.itemAttributesBySection = itemAttributesBySection;
 */
}

- (CGSize)collectionViewContentSize {
    if (self.collectionView.tag == 1) {
        NSLog(@"%s", __PRETTY_FUNCTION__);
    }

/*    CGFloat width = CGSizeZero.width, height = CGSizeZero.height;
    for (NSArray *items in self.itemAttributesBySection) {
        for (MTCollectionViewLayoutLiquidAttributes *itemAttribute in items) {
            
            CGFloat w = itemAttribute.frame.origin.x + itemAttribute.frame.size.width;
            width = width > w ? width : w;
            CGFloat h = itemAttribute.frame.origin.y + itemAttribute.frame.size.height;
            height = height > h ? height : h;
            
        }
    }
    self.contentSize = CGSizeMake(width, height);
    return self.contentSize;*/
    
    return [self.delegate collectionView:self.collectionView sizeForLayout:self];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    if (self.collectionView.tag == 1) {
        NSLog(@"%s", __PRETTY_FUNCTION__);
    }

    NSArray *layoutAttributes = [self.delegate collectionView:self.collectionView attributesForLayout:self];
    NSArray *results = @[];
    UICollectionViewLayoutAttributes *itemAttributes;
    for (itemAttributes in layoutAttributes) {
        if (CGRectIntersectsRect(rect, itemAttributes.frame)) {
            results = [results arrayByAddingObject:itemAttributes];
        }
        
    }
    return results;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.collectionView.tag == 1) {
        NSLog(@"%s", __PRETTY_FUNCTION__);
    }

    return [self.delegate collectionView:self.collectionView layout:self layoutAttributesForItemAtIndexPath:indexPath];

}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.collectionView.tag == 1) {
        NSLog(@"%s", __PRETTY_FUNCTION__);
    }

    return [self.delegate collectionView:self.collectionView layout:self layoutAttributesForItemAtIndexPath:indexPath];

}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];
    if (self.collectionView.tag == 1) {
        NSLog(@"%s", __PRETTY_FUNCTION__);
    }

}

- (void)finalizeCollectionViewUpdates {
    [self.delegate collectionViewDidFinishUpdates:self.collectionView];
    [super finalizeCollectionViewUpdates];
    if (self.collectionView.tag == 1) {
        NSLog(@"%s", __PRETTY_FUNCTION__);
    }

}

- (void)invalidateLayout {
    [super invalidateLayout];
    if (self.collectionView.tag == 1) {
        NSLog(@"%s", __PRETTY_FUNCTION__);
    }
}

@end
