//
//  MADReportDesignerSectionElementLayoutManager.m
//  MAD
//
//  Created by Michael Thomason on 11/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADSectionLayoutManager.h"
#import "MADSectionLayoutAttributes.h"
#import "CGGeometry+Extras.h"
#import "MTPair.h"

#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSectionRows.h"

@interface MADSectionLayoutManager ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *items;
@property (nonatomic, weak) MADSectionLayoutAttributes *lastItem;
@property (nonatomic, assign) BOOL lastOpperationWasAdditon;
@property (nonatomic, assign) BOOL visibility;

@end

@implementation MADSectionLayoutManager

- (instancetype)initWithDocumentSection:(RptqDocumentSection *)section {

    if (self = [super init]) {
        NSMutableDictionary *items = [NSMutableDictionary dictionary];
        self.items = items;
        self.visibility = section.visibility.boolValue;
        
        RptqDocumentSectionRows *rows = section.hasRows.firstObject;
        RptqDocumentObject *object;
        MADSectionLayoutAttributes *layout;
        NSInteger itemCounter = 0;
        for (object in rows.hasObjects) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:itemCounter inSection:0];
            layout = [MADSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
            layout.objectID = object.objectID;
            CGSize size = object.size;
            layout.frame = CGRectMake(object.originx.floatValue, object.originy.floatValue,
                                      size.width, size.height);
            [self addItem:layout];
            itemCounter++;
        }

    }
    
    return self;
}

- (void)addItem:(MADSectionLayoutAttributes *)item {

    [self appendItemToItems:item];
    self.lastOpperationWasAdditon = YES;

}

- (void)removeItemWithID:(NSManagedObjectID *)objectID {
    
    MADSectionLayoutAttributes *item = [self.items objectForKey:objectID];
    NSIndexPath *pathToRemvoe = item.indexPath;
    
    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, MADSectionLayoutAttributes *obj, BOOL *stop) {
        if (obj.indexPath.item >= pathToRemvoe.item) {
            obj.indexPath = [NSIndexPath indexPathForItem: obj.indexPath.item - 1
                                                inSection: obj.indexPath.section];
        }
    }];
    
    [self.items removeObjectForKey:objectID];
    self.lastOpperationWasAdditon = NO;
}

- (void)positionItem:(MADSectionLayoutAttributes *)placedItem {
    NSArray *allValues = self.items.allValues;
    NSMutableArray *placedItems = [[NSMutableArray alloc] initWithCapacity:allValues.count];
    NSArray *allPotentalDropPoints = [MADSectionLayoutManager allValidLocationsForAttributes: placedItem
                                                                              withAttributes: allValues];
    BOOL anchored = [self moveItem:placedItem toNearestPointInGroup:allPotentalDropPoints dropTolerance:24.0000f];
    if (!anchored) {
        anchored = [placedItem moveOnScreen];
    }
    if ([placedItem intersectsAnItemInArray: allValues]) {
        [placedItem placeItemGivenAttributes: allValues];
    }
    [placedItems addObject:placedItem];
    
    NSPredicate *unplaced = [NSPredicate predicateWithFormat:@"objectID != %@.objectID", placedItem];
    NSArray *unplacedItems = [allValues filteredArrayUsingPredicate:unplaced];
    
    BOOL positionItems = YES;
    while (positionItems) {
        NSArray *placedNow = [self positionUnplacedItems:unplacedItems aroundPlacedItems:placedItems];
        [placedItems setArray:placedNow];
        positionItems = NO;
        NSPredicate *filterPlacedItems = [NSPredicate predicateWithFormat:@"NOT objectID IN %@.objectID", placedItems];
        NSArray *unplacedItems = [allValues filteredArrayUsingPredicate:filterPlacedItems];
        for (MADSectionLayoutAttributes *item in placedItems) {
            if ([item intersectsAnItemInArray:unplacedItems]) {
                positionItems = YES;
                break;
            }
        }
    }
}

- (NSArray *)positionUnplacedItems:(NSArray *)unplacedItems aroundPlacedItems:(NSArray *)placedItems {
    NSMutableArray *unplacedOverlapping = [[NSMutableArray alloc] initWithCapacity:unplacedItems.count];
    NSMutableArray *placedItemsTracker = [[NSMutableArray alloc] initWithArray:placedItems];
    for (MADSectionLayoutAttributes *unplacedItem in unplacedItems) {
        if ([unplacedItem intersectsAnItemInArray:placedItemsTracker]) {
            [unplacedOverlapping addObject:unplacedItem];
        }
    }
    
    BOOL stillPlacing = YES;
    while (stillPlacing) {
        if ((stillPlacing = (unplacedOverlapping.count > 0))) {
            [unplacedOverlapping sortUsingComparator:^NSComparisonResult(MADSectionLayoutAttributes *attr1, MADSectionLayoutAttributes *attr2) {
                CGFloat d1 = [MADSectionLayoutManager distanceToBestDropPoint:attr1 placedItems:placedItems],
                        d2 = [MADSectionLayoutManager distanceToBestDropPoint:attr2 placedItems:placedItems];
                if (d1 == d2) {
                    return NSOrderedSame;
                } else if (d1 > d2) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedDescending;
                }
            }];
            
            MADSectionLayoutAttributes *attribute = unplacedOverlapping[0];
            [self placeItem:attribute givenAlreadyPlacedItems:placedItems];
            placedItems = [placedItems arrayByAddingObject:attribute];
            [placedItemsTracker addObject:attribute];
            [unplacedOverlapping removeObjectAtIndex:0];
            
        }
    }
    return placedItems;
}

+ (NSArray *)allHorizontallyValidLocations:(MADSectionLayoutAttributes *)attribute
                            withAttributes:(NSArray *)placedItems {
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity: 4 * placedItems.count];
    for (MADSectionLayoutAttributes *placedItem in placedItems) {
        if (placedItem.objectID != attribute.objectID) {
            NSArray * dropPoints = [placedItem dropPoints];
            [results addObjectsFromArray:dropPoints];
        }
    }
    return results;
}

+ (NSArray *)allValidLocationsForAttributes: (MADSectionLayoutAttributes *)attribute
                             withAttributes: (NSArray *)placedItems {
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity: 4 * placedItems.count];
    for (MADSectionLayoutAttributes *placedItem in placedItems) {
        if (placedItem.objectID != attribute.objectID) {
            NSArray * dropPoints = [placedItem dropPoints];
            [results addObjectsFromArray:dropPoints];
        }
    }
    return results;
}

- (void)placeItem:(MADSectionLayoutAttributes *)item givenAlreadyPlacedItems:(NSArray *)alreadyPlacedItems {
    [MADSectionLayoutManager moveItem:item alreadyPlacedItems:alreadyPlacedItems];
}

+ (BOOL)isPointGoodLocation:(CGPoint )point forItem:(MADSectionLayoutAttributes *)attr1 givenPlacedItems:(NSArray *)placedItems {
    return attr1.frame.origin.y >= point.y - 0.5f && [attr1 validDropPoint:point givenPlacedItems:placedItems];
}
+ (void)moveItem:(MADSectionLayoutAttributes *)itemToPlace alreadyPlacedItems:(NSArray *)alreadyPlacedItems {
    CGPoint dropPoint = CGPointZero;
    CGFloat distance = 0.00000000f, tmpDistance;//CGDistance(itemToPlace.frame.origin, dropPoint), tmpDistance;
    BOOL distanceSet = NO;
    for (MADSectionLayoutAttributes *alreadyPlacedItem in alreadyPlacedItems) {
        if (itemToPlace.objectID != alreadyPlacedItem.objectID) {
            NSArray *alreadyPlacedItemDropPoints = [alreadyPlacedItem dropPoints];
            for (NSValue *v in alreadyPlacedItemDropPoints) {
                if ([self isPointGoodLocation:v.CGPointValue forItem:itemToPlace givenPlacedItems:alreadyPlacedItems]) {
                    if (distanceSet == NO) {
                        dropPoint = v.CGPointValue;
                        distance = CGDistance(itemToPlace.frame.origin, v.CGPointValue);
                        distanceSet = YES;
                    } else if ((tmpDistance = CGDistance(itemToPlace.frame.origin, v.CGPointValue)) < distance) {
                        dropPoint = v.CGPointValue;
                        distance = tmpDistance;
                    }
                }
            }
        }
    }
    itemToPlace.frame = CGRectMake(dropPoint.x, dropPoint.y, itemToPlace.frame.size.width, itemToPlace.frame.size.height);
}

+ (CGFloat)distanceToBestDropPoint:(MADSectionLayoutAttributes *)attr1 placedItems:(NSArray *)placedItems {
    CGFloat d = 0.0000f;
    CGPoint nearestPoint = CGPointZero;
    NSArray *dropPoints = [MADSectionLayoutManager allValidLocationsForAttributes: attr1
                                                                   withAttributes: placedItems];
    BOOL foundNearDropPoint = NO;
    BOOL firstTime = YES;
    
    for (NSValue *pointObj in dropPoints) {
        
        if ([self isPointGoodLocation:pointObj.CGPointValue forItem:attr1 givenPlacedItems:placedItems]) {
            
            CGFloat distanceToDropPoint = CGDistance(pointObj.CGPointValue, attr1.frame.origin);
            
            if (firstTime) {
                firstTime = NO;
                nearestPoint = pointObj.CGPointValue;
                foundNearDropPoint = YES;
                d = distanceToDropPoint;
            } else if (distanceToDropPoint <= d && d > 0.00000000f) {
                nearestPoint = pointObj.CGPointValue;
                foundNearDropPoint = YES;
                d = distanceToDropPoint;
            }
        }
    }
    return d;
}

+ (NSArray *)nonOverlappingDropPointsForItem:(MADSectionLayoutAttributes *)attr1 givenDropPoints:(NSArray *)dropPoints andPlacedItems:(NSArray *)placedItems {
    
    NSMutableArray *nonOverlappingDropPoints = [[NSMutableArray alloc] initWithCapacity:dropPoints.count];
    for (NSValue *pointObj in dropPoints) {
        // Is drop point valid... doesn't it overlap a placed item?
        if ([attr1 validDropPoint:pointObj.CGPointValue givenPlacedItems:placedItems]) {
            [nonOverlappingDropPoints addObject: pointObj];
        }
    }
    return nonOverlappingDropPoints;
}

- (BOOL)moveItem:(MADSectionLayoutAttributes *)item toNearestPointInGroup:(NSArray *)dropPoints dropTolerance:(CGFloat)tolerance {
    return [MADSectionLayoutManager moveItem:item toNearestPointInGroup:dropPoints dropTolerance:tolerance];
}

+ (BOOL)moveItem:(MADSectionLayoutAttributes *)item toNearestPointInGroup:(NSArray *)dropPoints dropTolerance:(CGFloat)tolerance {
    CGPoint nearestPoint = CGPointZero;
    CGFloat distanceToLastDropPoint = tolerance;
    BOOL foundNearDropPoint = NO;
    for (NSValue *pointObj in dropPoints) {
        CGPoint dropPoint = pointObj.CGPointValue;
        CGFloat distanceToDropPoint = CGDistance(dropPoint, item.frame.origin);
        if ((distanceToDropPoint <= tolerance && distanceToDropPoint <= distanceToLastDropPoint &&
             distanceToLastDropPoint > CGSizeZero.width))                                        //Not yet found
        {
            
            nearestPoint = dropPoint;
            foundNearDropPoint = YES;
            distanceToLastDropPoint = distanceToDropPoint;
        }
    }
    if (foundNearDropPoint) {
        item.frame = CGRectMake(nearestPoint.x, nearestPoint.y, item.frame.size.width, item.frame.size.height);
    }
    return foundNearDropPoint;
}

- (void)addItemWithObjectID:(NSManagedObjectID *)objectID andFrame:(CGRect)frame {
    NSIndexPath *path = [NSIndexPath indexPathForItem:self.items.count inSection:0];
    MADSectionLayoutAttributes *layout = [MADSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
    layout.objectID = objectID;
    layout.frame = frame;
    [self.items setObject: layout forKey: objectID];
}

- (void)layout {
    if (self.lastOpperationWasAdditon) {
        [self positionItem:self.lastItem];
    }
}

- (void)removeItem:(MADSectionLayoutAttributes *)itemToRemove {
    
    NSIndexPath *pathToRemvoe = itemToRemove.indexPath;
    
    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, MADSectionLayoutAttributes *obj, BOOL *stop) {
        if (obj.indexPath.item >= pathToRemvoe.item) {
            obj.indexPath = [NSIndexPath indexPathForItem: obj.indexPath.item - 1
                                                inSection: obj.indexPath.section];
        }
    }];
    
    [self.items removeObjectForKey:itemToRemove.objectID];
    self.lastOpperationWasAdditon = NO;
}

- (CGSize)size {
    __block CGSize size = CGSizeZero;
    if (self.visibility) {
        [self.items enumerateKeysAndObjectsUsingBlock:^(id key, MADSectionLayoutAttributes *layout, BOOL *stop) {
            size.width = MAX(size.width, layout.frame.origin.x + layout.frame.size.width);
            size.height = MAX(size.height, layout.frame.origin.y + layout.frame.size.height);
        }];
    }
    return size;
}

#pragma mark - Helpers

- (NSArray *)allValidLocations {
    NSValue *placement0Value, *placement1Value, *placement2Value, *placement3Value;
    NSArray *allValidLocations = @[];
    NSArray *potentialPlacements = @[];
    NSArray *allItems = self.items.allValues;
    MADSectionLayoutAttributes *layout;
    for (layout in allItems) {
        
        MTCorners corners = MTCornersMake(layout.frame);
        
        placement0Value = [NSValue valueWithCGPoint: corners.topLeft];
        placement1Value = [NSValue valueWithCGPoint: corners.topRight];
        placement2Value = [NSValue valueWithCGPoint: corners.bottomLeft];
        placement3Value = [NSValue valueWithCGPoint: corners.bottomRight];
        
        potentialPlacements = @[placement0Value, placement1Value,
                                placement2Value, placement3Value];
        
        allValidLocations = [allValidLocations arrayByAddingObjectsFromArray:potentialPlacements];
        
    }
    return allValidLocations;
}

- (void)appendItemToItems:(MADSectionLayoutAttributes *)item {
    [self.items setObject:item forKey:item.objectID];
    self.lastItem = item;
}

            /*
            NSMutableArray *unplacedItemsA = [[NSMutableArray alloc] init];
            for (MADSectionLayoutAttributes *a in self.items.allValues) {
                BOOL aIsP = NO;
                for (MADSectionLayoutAttributes *p in placedItems) {
                    if (a.objectID != p.objectID) {
                        aIsP = YES;
                        break;
                    }
                }
                if (aIsP) {
                    [unplacedItemsA addObject:a];
                }
            }
            
            [unplacedOverlapping removeAllObjects];
            for (MADSectionLayoutAttributes *a in unplacedItemsA) {
                if ([a intersectsAnItemInArray:placedItemsTracker]) {
                    [unplacedOverlapping addObject:a];
                }
            }*/

    //Sort the unplaced overlapping by distance from best drop point.
    /*for (MADSectionLayoutAttributes *unplacedItem in unplacedItems) {
        NSArray *dropPoints = [MADSectionLayoutManager allValidLocationsForAttributes: unplacedItem
                                                                       withAttributes: placedItemsTracker];
        CGFloat distanceToNearestDropPoint = 0.00000000f;
        CGPoint nearestPoint = CGPointZero;
        BOOL foundNearDropPoint = NO;
        for (NSValue *pointObj in dropPoints) {
            CGPoint dropPoint = pointObj.CGPointValue;
            CGFloat distanceToDropPoint = CGDistance(dropPoint, unplacedItem.frame.origin);
            if (distanceToDropPoint <= distanceToNearestDropPoint && distanceToNearestDropPoint > 0.00000000f)                                        //Not yet found
            {
                
                nearestPoint = dropPoint;
                foundNearDropPoint = YES;
                distanceToNearestDropPoint = distanceToDropPoint;
            }
        }
    }*/
    /*
    NSArray *unplacedOverlapping =
    
    NSArray *unplacedItemsSorted = [unplacedItems sortedArrayUsingComparator:^NSComparisonResult(MADSectionLayoutAttributes *obj1, MADSectionLayoutAttributes *obj2) {
        NSNumber *distance1 = @(CGDistance(origin, obj1.frame.origin));
        NSNumber *distance2 = @(CGDistance(origin, obj2.frame.origin));
        return [distance1 compare:distance2];
*/

/*- (MADSectionLayoutAttributes *)getAnOutOfPositionItem {

    __block MADSectionLayoutAttributes *opp = nil;
    MADSectionLayoutAttributes *layout;
    __weak MADSectionLayoutManager *weakself = self;
    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([weakself isItemMisplaced:layout]) {
            opp = layout;
            *stop = YES;
        }
    }];
    return opp;
}*/
/*
- (BOOL)isItemMisplaced:(MADSectionLayoutAttributes *)item {
    
    __block BOOL originFound = NO;
    __block CGFloat x1, x2, y1, y2;
    __block CGPoint p0, p1, p2, p3;

    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, MADSectionLayoutAttributes *layout, BOOL *stop) {
        if (item != layout) {
            
            //There exist four potental placement spots for each alredy placed rect
            x1 = layout.frame.origin.x;
            x2 = layout.frame.origin.x + layout.frame.size.width;
            y1 = layout.frame.origin.y;
            y2 = layout.frame.origin.y + layout.frame.size.height;
            
            
            p0 = CGPointMake(x1, y1);
            if (CGPointEqualToPoint(item.frame.origin, p0)) {
                originFound = YES;
                *stop = YES;
            }
            
            p1 = CGPointMake(x2, y1);
            if (CGPointEqualToPoint(item.frame.origin, p1)) {
                originFound = YES;
                *stop = YES;
            }
            
            p2 = CGPointMake(x2, y2);
            if (CGPointEqualToPoint(item.frame.origin, p2)) {
                originFound = YES;
                *stop = YES;
            }
            
            p3 = CGPointMake(x1, y2);
            if (CGPointEqualToPoint(item.frame.origin, p3)) {
                originFound = YES;
                *stop = YES;
            }
        }
        
    }];
    return originFound == NO;
}*/
/*
- (void)layoutOutOfPlaceItem:(MADSectionLayoutAttributes *)opp {
    
}*/

/*
 - (void)layoutAfterItemRemoval {
    
    MADSectionLayoutAttributes *opp;
    while ((opp = [self getAnOutOfPositionItem]) != nil) {
        [self layoutOutOfPlaceItem:opp];
    }
    
}
 */

/*
 
 Assumes that all items are pushed to the proper place.
 
 */
/*
- (void)pushingItem: (MADSectionLayoutAttributes *)pushingItem
         pushesItem: (MADSectionLayoutAttributes *)pushedItem
        inDirection: (MADDirection)direction {
    
    NSArray *allPotentalDropPoints = [self allValidLocationsForPushedItem: pushedItem
                                                          withPushingItem: pushingItem
                                                                direction: direction];
    
    [self moveItem:pushedItem toNearestPointInGroup:allPotentalDropPoints direction:direction];
    
    [self.delegate layoutManager: self
                 itemNeedsUpdate: pushedItem];
    
}*/
/*
- (NSArray *)allValidLocationsForPushedItem: (MADSectionLayoutAttributes *)pushedItem
                            withPushingItem: (MADSectionLayoutAttributes *)pushingItem
                                  direction: (MADDirection)direction {
    
    NSValue *v = [NSValue valueWithCGPoint:CGPointZero];
    __block NSArray *allValidLocations = @[v];
    BOOL directionIsHorizontal = MADDirectionIsHorizontal(direction);
    NSMutableArray *placemntValues = [[NSMutableArray alloc] initWithCapacity:4];
    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, MADSectionLayoutAttributes *layout, BOOL *stop) {
        
        BOOL isPushedItem = layout == pushedItem;
        
        if (isPushedItem == NO) {
            MTCorners corners = MTCornersMake(layout.frame);
            
            if (directionIsHorizontal) {
                
                if (direction == MADDirectionHorizontalDirectionOfPoint(corners.topLeft, pushedItem.frame.origin)) {
                    NSValue *v = [NSValue valueWithCGPoint: corners.topLeft];
                    [placemntValues addObject:v];
                }
                
                if (direction == MADDirectionHorizontalDirectionOfPoint(corners.topRight, pushedItem.frame.origin)) {
                    NSValue *v = [NSValue valueWithCGPoint: corners.topRight];
                    [placemntValues addObject:v];
                }
                
                if (direction == MADDirectionHorizontalDirectionOfPoint(corners.bottomRight, pushedItem.frame.origin)) {
                    NSValue *v = [NSValue valueWithCGPoint: corners.bottomRight];
                    [placemntValues addObject:v];
                }
                
                if (direction == MADDirectionHorizontalDirectionOfPoint(corners.bottomLeft, pushedItem.frame.origin)) {
                    NSValue *v = [NSValue valueWithCGPoint: corners.bottomLeft];
                    [placemntValues addObject:v];
                }
                
            } else {
                
                if (direction == MADDirectionVerticalDirectionOfPoint(corners.topLeft, pushedItem.frame.origin)) {
                    NSValue *v = [NSValue valueWithCGPoint: corners.topLeft];
                    [placemntValues addObject:v];
                }
                
                if (direction == MADDirectionVerticalDirectionOfPoint(corners.topRight, pushedItem.frame.origin)) {
                    NSValue *v = [NSValue valueWithCGPoint: corners.topRight];
                    [placemntValues addObject:v];
                }
                
                if (direction == MADDirectionVerticalDirectionOfPoint(corners.bottomRight, pushedItem.frame.origin)) {
                    NSValue *v = [NSValue valueWithCGPoint: corners.bottomRight];
                    [placemntValues addObject:v];
                }
                
                if (direction == MADDirectionVerticalDirectionOfPoint(corners.bottomLeft, pushedItem.frame.origin)) {
                    NSValue *v = [NSValue valueWithCGPoint: corners.bottomLeft];
                    [placemntValues addObject:v];
                }
            }
            
            allValidLocations = [allValidLocations arrayByAddingObjectsFromArray:placemntValues];
            
            [placemntValues removeAllObjects];
        }
        
    }];
    
    return allValidLocations;
}*/
/*
- (void)moveItem:(MADSectionLayoutAttributes *)item toNearestPointInGroup:(NSArray *)dropPoints direction:(MADDirection)direction {
    CGPoint nearestPoint = CGPointZero;
    CGFloat distanceToLastDropPoint = -1.0000f;
    BOOL foundNearDropPoint = NO;
    CGPoint currentPointOrigin = item.frame.origin;
    for (NSValue *pointObj in dropPoints) {
        CGPoint dropPoint = pointObj.CGPointValue;
        CGFloat distanceToDropPoint = CGDistance(dropPoint, currentPointOrigin);
        MADDirection pointObjDirection = MADDirectionIsHorizontal(direction) ?
                                            MADDirectionHorizontalDirectionOfPoint(dropPoint, currentPointOrigin) :
                                            MADDirectionVerticalDirectionOfPoint(dropPoint, currentPointOrigin);
        
        if ((distanceToDropPoint <= distanceToLastDropPoint || foundNearDropPoint == NO) && direction == pointObjDirection)         //Not yet found
        {
            switch (pointObjDirection) {
                
                case left:
                    nearestPoint = CGPointMake(dropPoint.x, currentPointOrigin.y);
                    break;
                    
                case right:
                    nearestPoint = CGPointMake(dropPoint.x, currentPointOrigin.y);
                    break;

                case up:
                    nearestPoint = CGPointMake(currentPointOrigin.x, dropPoint.y);
                    break;

                case down:
                    nearestPoint = CGPointMake(currentPointOrigin.x, dropPoint.y);
                    break;

                default:
                    break;
            }
            foundNearDropPoint = YES;
            distanceToLastDropPoint = distanceToDropPoint;
        }
    }
    if (foundNearDropPoint) {
        item.frame = CGRectMake(nearestPoint.x, nearestPoint.y, item.frame.size.width, item.frame.size.height);
    }
}*/

/*
+ (MTPair *)seperateByDestionationDirection: (NSArray *)overlappingItems inRelationToAttributes: (MADSectionLayoutAttributes *)droppedAttributes {
    CGFloat x = droppedAttributes.frame.origin.x + droppedAttributes.frame.size.width;
    CGFloat y = droppedAttributes.frame.origin.y + droppedAttributes.frame.size.height;
    CGPoint bottomLeft, topRight;
    
    MADSectionLayoutAttributes *attributes;
    NSArray *itemsLeft = @[];
    NSArray *itemsRight = @[];
    CGFloat d1, d2;
    for (attributes in overlappingItems) {
        bottomLeft = CGPointMake(x, attributes.frame.origin.y);
        topRight = CGPointMake(attributes.frame.origin.x, y);
        d1 = CGDistance(attributes.frame.origin, bottomLeft);
        d2 = CGDistance(attributes.frame.origin, topRight);
        if (d1 >= d2) {
            itemsRight = [itemsRight arrayByAddingObject:attributes];
        } else {
            itemsLeft = [itemsLeft arrayByAddingObject:attributes];
        }
    }
    MTPair *result = [MTPair pairWithLeft:itemsLeft andRight:itemsRight];
    return result;
}

- (MTPair *)seperateByDestionationDirection:(NSArray *)overlappingItems {
    MADSectionLayoutAttributes *droppedAttributes = self.lastItem;
    CGFloat x = droppedAttributes.frame.origin.x + droppedAttributes.frame.size.width;
    CGFloat y = droppedAttributes.frame.origin.y + droppedAttributes.frame.size.height;
    CGPoint bottomLeft, topRight;
    
    MADSectionLayoutAttributes *attributes;
    NSArray *items = self.items.allValues;
    NSArray *itemsLeft = @[];
    NSArray *itemsRight = @[];
    CGFloat d1, d2;
    for (attributes in items) {
        bottomLeft = CGPointMake(x, attributes.frame.origin.y);
        topRight = CGPointMake(attributes.frame.origin.x, y);
        d1 = CGDistance(attributes.frame.origin, bottomLeft);
        d2 = CGDistance(attributes.frame.origin, topRight);
        if (d1 >= d2) {
            [itemsRight arrayByAddingObject:attributes];
        } else {
            [itemsLeft arrayByAddingObject:attributes];
        }
    }
    MTPair *result = [MTPair pairWithLeft:itemsLeft andRight:itemsRight];
    return result;
}*/

/*- (NSArray *)sortOverlappingItems: (NSArray *)overlappingItems distanctFromPoint: (CGPoint)origin {

    NSArray *sortedArray = [overlappingItems sortedArrayUsingComparator:^NSComparisonResult(MADSectionLayoutAttributes *obj1, MADSectionLayoutAttributes *obj2) {
        NSNumber *distance1 = @(CGDistance(origin, obj1.frame.origin));
        NSNumber *distance2 = @(CGDistance(origin, obj2.frame.origin));
        return [distance1 compare:distance2];
    }];
    
    return sortedArray;
}*/

/*- (NSArray *)itemsThatOverlapLastItem {
    
    MADSectionLayoutAttributes *layout;
    NSArray *allItems = self.items.allValues;
    MADSectionLayoutAttributes *lastItem = self.lastItem;
    NSArray *results = @[];
    for (layout in allItems) {
        if (lastItem != layout) {
            if (CGRectIntersectsRect(layout.frame, lastItem.frame)) {
                results = [results arrayByAddingObject:layout];
            }
        }
    }
    return results;
}*/
/*
- (void)slideItems: (NSArray *)itemsToSlide direction: (MADDirection)direction distance: (CGFloat)distance {
    
    MADSectionLayoutAttributes *attributes;

    switch (direction) {
    
        case left:
            
            for (attributes in itemsToSlide) {
                
                attributes.frame = CGRectMake(attributes.frame.origin.x - distance,
                                              attributes.frame.origin.y,
                                              attributes.frame.size.width,
                                              attributes.frame.size.height);
                
                [self.delegate layoutManager: self itemNeedsUpdate: attributes];

            }
            
            break;
            
        case right:
            
            for (attributes in itemsToSlide) {
                
                attributes.frame = CGRectMake(attributes.frame.origin.x + distance,
                                              attributes.frame.origin.y,
                                              attributes.frame.size.width,
                                              attributes.frame.size.height);
                
                [self.delegate layoutManager: self itemNeedsUpdate: attributes];

            }
            
            break;
            
        case up:
            
            for (attributes in itemsToSlide) {
                attributes.frame = CGRectMake(attributes.frame.origin.x,
                                              attributes.frame.origin.y + distance,
                                              attributes.frame.size.width,
                                              attributes.frame.size.height);
                
                [self.delegate layoutManager: self itemNeedsUpdate: attributes];
                
            }
            
            break;
            
        case down:
            
            for (attributes in itemsToSlide) {
                attributes.frame = CGRectMake(attributes.frame.origin.x,
                                              attributes.frame.origin.y - distance,
                                              attributes.frame.size.width,
                                              attributes.frame.size.height);
                
                [self.delegate layoutManager: self itemNeedsUpdate: attributes];

            }
            
            break;
            
        default:
            break;
    }
    
}
*/

/*- (CGPoint)pointNearestDropPoint: (CGPoint)dropPoint fromValidPoints: (NSArray *)validLocations {
    
    CGPoint nearestPoint = dropPoint, point;
    CGFloat distance = CGSizeZero.width, d2;
    NSValue *value;
    for (value in validLocations) {
        point = [value CGPointValue];
        d2 = CGDistance(dropPoint, point);
        if (d2 < distance) {
            distance = d2;
            nearestPoint = dropPoint;
        }
    }
    return nearestPoint;
    
}*/

/*- (NSArray *)allValidLocationsForLastItem {
    NSValue *placement0Value, *placement1Value, *placement2Value, *placement3Value;
    NSArray *allValidLocations = @[];
    NSArray *potentialPlacements = @[];
    id lastItem = self.lastItem;
    NSArray *allItems = self.items.allValues;
    MADSectionLayoutAttributes *layout;
    for (layout in allItems) {
        if (lastItem != layout) {
            
            MTCorners corners = MTCornersMake(layout.frame);
            
            placement0Value = [NSValue valueWithCGPoint: corners.topLeft];
            placement1Value = [NSValue valueWithCGPoint: corners.topRight];
            placement2Value = [NSValue valueWithCGPoint: corners.bottomLeft];
            placement3Value = [NSValue valueWithCGPoint: corners.bottomRight];
            
            potentialPlacements = @[placement0Value,
                                    placement1Value,
                                    placement2Value,
                                    placement3Value];
            
            allValidLocations = [allValidLocations arrayByAddingObjectsFromArray:potentialPlacements];
        }
    }
    return allValidLocations;
}*/


/*- (void)positionAllItemsAroundItem:(MADSectionLayoutAttributes *)lastItemDropped {
    NSArray *overlappingItems = [self itemsThatOverlapItem:lastItemDropped];
    CGPoint origin = lastItemDropped.frame.origin;
    MTPair *sepratedItems = [MADSectionLayoutManager seperateByDestionationDirection: overlappingItems
                                                                                   inRelationToAttributes: lastItemDropped];
    NSComparator sortBydistanceAsc = ^NSComparisonResult(MADSectionLayoutAttributes *obj1, MADSectionLayoutAttributes *obj2) {
        NSNumber *distance1 = @(CGDistance(origin, obj1.frame.origin));
        NSNumber *distance2 = @(CGDistance(origin, obj2.frame.origin));
        return [distance1 compare:distance2];
    };
    NSArray *itemsToPushDown = [sepratedItems.left sortedArrayUsingComparator:sortBydistanceAsc];
    NSArray *itemsToPushRigth = [sepratedItems.right sortedArrayUsingComparator:sortBydistanceAsc];
    
    if (itemsToPushDown.count > 0) {
        id firstItemsToPushDown = itemsToPushDown.firstObject;
        [self pushingItem:lastItemDropped pushesItem:firstItemsToPushDown inDirection:down];
    }
    
    if (itemsToPushRigth.count > 0) {
        id firstItemsToPushRight = itemsToPushRigth.firstObject;
        [self pushingItem:lastItemDropped pushesItem:firstItemsToPushRight inDirection:right];
    }
    
}*/

/*- (void)positionLastItem {
    MADSectionLayoutAttributes *attributes = self.lastItem;
    NSArray *validLocations = [self allValidLocationsForLastItem];
    CGPoint newLocation = [self pointNearestDropPoint: attributes.frame.origin
                                      fromValidPoints: validLocations];
    attributes.frame = CGRectMake(newLocation.x,
                                  newLocation.y,
                                  attributes.frame.size.width,
                                  attributes.frame.size.height);
    [self.delegate layoutManager: self
                 itemNeedsUpdate: attributes];
}*/

/*+ (NSSet *)itemsThatOverlapItem:(MADSectionLayoutAttributes *)item fromItems:(NSArray *)items {
    NSMutableSet *set = [[NSMutableSet alloc] initWithCapacity:items.count];
    for (MADSectionLayoutAttributes *existingItem in items) {
        if (item.objectID != existingItem.objectID) {
            if (CGRectIntersectsRect(item.frame, existingItem.frame)) {
                [set addObject:existingItem];
            }
        }
    }
    return set;
}*/

/*- (NSArray *)itemsThatOverlapItem:(MADSectionLayoutAttributes *)lastItem {
    MADSectionLayoutAttributes *layout;
    NSArray *allItems = self.items.allValues;
    NSArray *results = @[];
    for (layout in allItems) {
        if (lastItem != layout) {
            if (CGRectIntersectsRect(layout.frame, lastItem.frame)) {
                results = [results arrayByAddingObject:layout];
            }
        }
    }
    return results;
}*/

@end
