
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

@property (nonatomic, strong) NSMutableArray *itemAttributesBySection;
@property (nonatomic, strong) NSMutableArray *decorationAttributesBySection;
@property (nonatomic, strong) NSMutableArray *invalidatedLayoutArray;

@property (nonatomic, strong) NSMutableArray *placedItemDropPoint;
@property (nonatomic, strong) NSMutableArray *placedItemFrame;
@property (nonatomic, assign) NSUInteger totalNumberOfItems;

@property (nonatomic, assign) BOOL firstTime;

@end

@implementation MTReportDesignerSectionViewLayoutLiquid


- (id)init {
    self = [super init];
    if (self) {
        
        NSMutableArray *itemAttributesBySection = [[NSMutableArray alloc] init];
        [self setItemAttributesBySection:itemAttributesBySection];
        
        NSMutableArray *placedItemDropPoint = [[NSMutableArray alloc] init];
        [self setPlacedItemDropPoint:placedItemDropPoint];

        NSMutableArray *placedItemFrame = [[NSMutableArray alloc] init];
        [self setPlacedItemFrame:placedItemFrame];

        [self registerClass: [MTReportDesignerSectionDecorationView class]
    forDecorationViewOfKind: NSStringFromClass([MTReportDesignerSectionDecorationView class])];

        [self setFirstTime:YES];
    }
    return self;
}

- (MTCollectionViewLayoutLiquidAttributes *)placeLayouts:(NSArray *)layoutAttributesForSection forLayout:(MTCollectionViewLayoutLiquidAttributes *)layout {
    CGFloat distanceFromDropPoint = -1.0000f;   //Represents an invalid distance
    CGRect nearestRect = CGRectZero;
    
    for (MTCollectionViewLayoutLiquidAttributes *placedLayout in layoutAttributesForSection) {
        
        //There exist four potental placement spots for each alredy placed rect
        CGFloat x1 = placedLayout.frame.origin.x;
        CGFloat x2 = placedLayout.frame.origin.x + placedLayout.frame.size.width;
        CGFloat y1 = placedLayout.frame.origin.y;
        CGFloat y2 = placedLayout.frame.origin.y + placedLayout.frame.size.height;
        
        CGRect placement0, placement1, placement2, placement3;
        
        placement0 = CGRectMake(x1, y1, layout.frame.size.width, layout.frame.size.height);
        placement1 = CGRectMake(x2, y1, layout.frame.size.width, layout.frame.size.height);
        placement2 = CGRectMake(x2, y2, layout.frame.size.width, layout.frame.size.height);
        placement3 = CGRectMake(x1, y2, layout.frame.size.width, layout.frame.size.height);
        
        NSArray *potentialPlacements = @[[NSValue valueWithCGRect: placement0],
                                         [NSValue valueWithCGRect: placement1],
                                         [NSValue valueWithCGRect: placement2],
                                         [NSValue valueWithCGRect: placement3]];
        
        for (NSValue *placementValue in potentialPlacements) {
            
            CGRect potentialPlacement = [placementValue CGRectValue];
            
                CGFloat potentialPlacementDistanceFromDropPoint = CGDistance(potentialPlacement.origin, layout.frame.origin);
                BOOL dropPointIsOrigin = CGPointEqualToPoint(potentialPlacement.origin, layout.frame.origin);
                
                if (((potentialPlacementDistanceFromDropPoint < distanceFromDropPoint && dropPointIsOrigin == NO) ||
                     dropPointIsOrigin ||
                     distanceFromDropPoint < 0)) {
                    
                    distanceFromDropPoint = potentialPlacementDistanceFromDropPoint;
                    nearestRect = potentialPlacement;
                }
            
        }
    }
    [layout setFrame: nearestRect];

    [[self delegate] collectionView: [self collectionView]
                             layout: self
                       setDropPoint: [layout frame].origin
                 forItemAtIndexPath: [layout indexPath]];

    return layout;
}

- (void)prepareLayout {
    [super prepareLayout];
    
        NSInteger numberOfSections = 1;
        
        NSMutableArray *itemAttributesBySection = [[NSMutableArray alloc] initWithCapacity: numberOfSections];
        
        for (NSInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
            
            NSInteger numberOfItems = [[self delegate] numberOfItemsInSection:sectionIndex ofCollectionView:[self collectionView]];
            
            NSMutableArray *itemLayouts = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
            
            for (NSInteger itemIndex = 0; itemIndex < numberOfItems; itemIndex++) {
                
                MTCollectionViewLayoutLiquidAttributes *itemAttributes = [[self delegate] collectionView: [self collectionView]
                                                                                                  layout: self
                                                                      layoutAttributesForItemAtIndexPath: [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex]];
                [itemLayouts addObject:itemAttributes];
                
            }
            
            [itemLayouts sortUsingComparator:^NSComparisonResult(MTCollectionViewLayoutLiquidAttributes *layout1, MTCollectionViewLayoutLiquidAttributes *layout2) {
                return (layout1.dropIndex > layout2.dropIndex) ? NSOrderedDescending : NSOrderedAscending;
            }];
            
            [itemAttributesBySection addObject:itemLayouts];
        }
        
        for (NSArray *sectionItemLayouts in itemAttributesBySection) {
            @autoreleasepool {
                NSUInteger itemCounter = 0;
                //NSUInteger indexOfPotentiallyDroppedItem = [[sectionItemLayouts lastObject] dropIndex];
                
                NSMutableArray *layoutAttributesForSection = [[NSMutableArray alloc] initWithCapacity:[sectionItemLayouts count]];
                
                for (MTCollectionViewLayoutLiquidAttributes *itemAttributes in sectionItemLayouts) {
                    @autoreleasepool {
                        if (itemCounter == 0) {
                            CGRect zeroPointRect = CGRectMake(CGPointZero.x, CGPointZero.y, itemAttributes.frame.size.width, itemAttributes.frame.size.height);
                            [itemAttributes setFrame: zeroPointRect];
                            CGPoint dropPoint = [itemAttributes frame].origin;
                            NSIndexPath *indexPath = [itemAttributes indexPath];
                            
                            [[self delegate] collectionView: [self collectionView]
                                                     layout: self
                                               setDropPoint: dropPoint
                                         forItemAtIndexPath: indexPath];
                            
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
    
        [self repositionLayouts:[itemAttributesBySection objectAtIndex:0] forLayout:[[itemAttributesBySection objectAtIndex:0] lastObject]];
        

        for (id ly in [itemAttributesBySection objectAtIndex:0]) {
            @autoreleasepool {
                [self repositionLayouts:[itemAttributesBySection objectAtIndex:0] forLayout:ly];
            }
        }

        [self setItemAttributesBySection: itemAttributesBySection];
    
    


}

- (NSSet *)positionsOfRects:(CGRect)rect aroundRect:(CGRect)centerRect {
    
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

- (NSSet *)availablePositionsOfRect:(CGRect)rect aroundRect:(CGRect)centerRect {
    
    //There exist two potental placement spots around a rect to put another rect.
    CGFloat x1 = centerRect.origin.x;
    CGFloat x2 = centerRect.origin.x + centerRect.size.width;
    CGFloat y1 = centerRect.origin.y;
    CGFloat y2 = centerRect.origin.y + centerRect.size.height;
    
    CGRect placement1, placement3;
    
    placement1 = CGRectMake(x2, y1, rect.size.width, rect.size.height);
    placement3 = CGRectMake(x1, y2, rect.size.width, rect.size.height);
    
    
    return [NSSet setWithObjects:
              [NSValue valueWithCGRect: placement1],
              [NSValue valueWithCGRect: placement3], nil];
}

- (NSArray *)layout:(MTCollectionViewLayoutLiquidAttributes *)layout overlapWithLayout:(NSArray *)layouts {

//    BOOL overlapWithAnother = NO;
    NSMutableArray *layoutsToReposition = [[NSMutableArray alloc] init];
    
    for (MTCollectionViewLayoutLiquidAttributes *layoutForSection in layouts) {
        
        if (layoutForSection != layout && CGRectIntersectsRect([layoutForSection frame], [layout frame])) {
            
            [layoutsToReposition addObject:layoutForSection];
            //overlapWithAnother = YES;
        }
        
    }
    return layoutsToReposition;
}


- (void)repositionLayouts:(NSArray *)layouts forLayout:(MTCollectionViewLayoutLiquidAttributes *)layoutToReposition {

    NSMutableArray *layoutsToReposition = [[NSMutableArray alloc] initWithArray:[self layout:layoutToReposition overlapWithLayout:layouts]];
    
    if ([layoutsToReposition count]) {
        
        //Sort layouts by distance from layoutToReposition
        CGPoint layoutToRepositionOrigin = layoutToReposition.frame.origin;
        [layoutsToReposition sortUsingComparator:^NSComparisonResult(MTCollectionViewLayoutLiquidAttributes *layout1, MTCollectionViewLayoutLiquidAttributes *layout2) {
            return (CGDistance(layoutToRepositionOrigin, layout1.frame.origin) > CGDistance(layoutToRepositionOrigin, layout2.frame.origin)) ? NSOrderedDescending : NSOrderedAscending;
        }];

        
        
        // FIXME: Order by distance from layoutToReposition
        NSUInteger ctr = 0;
        for (MTCollectionViewLayoutLiquidAttributes *layoutToChange in layoutsToReposition) {

            
            if (ctr == 0) {

                NSSet *availablePositions = [self availablePositionsOfRect:[layoutToChange frame]
                                                                 aroundRect:[layoutToReposition frame]];
                NSArray *availablePositionsOrdered = [availablePositions allObjects];
                NSUInteger indexOfNearestPosition = -1, indexOfFurtheristPosition = -1;
                CGFloat distanceToNearest = 0.0000f, distanceToFurtherist = 0.0000f;
                NSUInteger positionCounter = 0;

                for (NSValue *availablePositionsValue in availablePositionsOrdered) {
                    CGRect availableRect = [availablePositionsValue CGRectValue];

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
                
                [layoutToChange setFrame: [[availablePositionsOrdered objectAtIndex:indexOfNearestPosition] CGRectValue]];
                [layoutToChange setDropIndex: [[self delegate] collectionView: [self collectionView]
                                                                       layout: self
                                            updateDropIndexForItemAtIndexPath: [layoutToChange indexPath]]];
                [layoutToChange setDropPoint: [layoutToChange frame].origin];
                [[self delegate] collectionView:[self collectionView] layout:self
                                   setDropPoint:[layoutToChange frame].origin
                             forItemAtIndexPath:[layoutToChange indexPath]];
                [layoutToChange setLastTouchPointValid: NO];
                

            
            } else {
            
                NSArray *layoutToRepositionLocked = [[NSArray alloc] initWithArray:layoutsToReposition];
                if (ctr < [layoutToRepositionLocked count] - 1) {
                    NSRange range = NSMakeRange(ctr, [layoutToRepositionLocked count] - ctr);
                    NSArray *lb = [[NSArray alloc] initWithArray:[layoutToRepositionLocked subarrayWithRange:range]];
                    [self repositionLayouts:lb forLayout:[layoutToRepositionLocked objectAtIndex:ctr - 1]];
                }
            }
            ctr++;
        }
    }
    
}

- (CGSize)collectionViewContentSize {
    CGFloat width = CGSizeZero.width, height = CGSizeZero.height;
    for (NSArray *items in [self itemAttributesBySection]) {
        
        for (MTCollectionViewLayoutLiquidAttributes *itemAttribute in items) {
            CGFloat w = itemAttribute.frame.origin.x + itemAttribute.frame.size.width;
            width = width > w ? width : w;
            CGFloat h = itemAttribute.frame.origin.y + itemAttribute.frame.size.height;
            height = height > h ? height : h;
        }
    }
    [self setContentSize:CGSizeMake(width, height)];
    return [self contentSize];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
    
    for (NSArray *items in [self itemAttributesBySection]) {
        
        for (MTCollectionViewLayoutLiquidAttributes *itemAttribute in items) {
            if (CGRectIntersectsRect(rect, itemAttribute.frame)) {
                [layoutAttributes addObject:itemAttribute];
            }

        }
    }
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    MTCollectionViewLayoutLiquidAttributes *resultLayout = nil;
    BOOL found = NO;
    for (NSArray *section in [self itemAttributesBySection]) {
        for (MTCollectionViewLayoutLiquidAttributes *layoutAttributes in section) {
            if (layoutAttributes.indexPath.item == indexPath.item && layoutAttributes.indexPath.section == indexPath.section) {
                resultLayout = layoutAttributes;
                found = YES;
                break;
            }
        }
        if (found) {
            break;
        }
    }

    return resultLayout;

}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MTCollectionViewLayoutLiquidAttributes *resultLayout = nil;
    BOOL found = NO;
    for (NSArray *section in [self itemAttributesBySection]) {
        for (MTCollectionViewLayoutLiquidAttributes *layoutAttributes in section) {
            if (layoutAttributes.indexPath.item == indexPath.item && layoutAttributes.indexPath.section == indexPath.section) {
                resultLayout = layoutAttributes;
                found = YES;
                break;
            }
        }
        if (found) {
            break;
        }
    }
    return resultLayout;

}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];
}

- (void)finalizeCollectionViewUpdates {
    [[self delegate] collectionViewDidFinishUpdates:[self collectionView]];
    [super finalizeCollectionViewUpdates];
}

- (void)invalidateLayout {
    NSMutableArray *invalidatedLayoutArray = [[self itemAttributesBySection] copy];
    [self setInvalidatedLayoutArray:invalidatedLayoutArray];

    [super invalidateLayout];

}

@end
