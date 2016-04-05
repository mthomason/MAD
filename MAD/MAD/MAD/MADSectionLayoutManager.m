//
//  MADReportDesignerSectionElementLayoutManager.m
//  MAD
//
//  Created by Michael Thomason on 11/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADSectionLayoutManager.h"
#import "MADSectionLayoutAttributes.h"

#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSectionRows.h"
#import <Foundation/NSIndexPath.h>
#import <UIKit/UICollectionView.h>
#import <UIKit/UITableView.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

@interface MADSectionLayoutManager ()

@property (nonatomic, strong, readwrite)    NSMutableDictionary *items;
@property (nonatomic, weak)                 MADSectionLayoutAttributes *lastItem;
@property (nonatomic, assign)               BOOL lastOpperationWasAdditon;
@property (nonatomic, assign)               BOOL visibility;

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
            layout.frame = CGRectMake(object.originx.floatValue, object.originy.floatValue, size.width, size.height);
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
    
    // If offscreen, move it onscreen.
    if (placedItem.frame.origin.x < CGPointZero.x) {
        placedItem.frame = CGRectMake(CGPointZero.x, placedItem.frame.origin.y, placedItem.frame.size.width, placedItem.frame.size.height);
    }
    if (placedItem.frame.origin.y < CGPointZero.y) {
        placedItem.frame = CGRectMake(placedItem.frame.origin.x, CGPointZero.y, placedItem.frame.size.width, placedItem.frame.size.height);
    }
    
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
    placedItem.frame = CGRectMake(roundf(placedItem.frame.origin.x),
                                  roundf(placedItem.frame.origin.y),
                                  placedItem.frame.size.width, placedItem.frame.size.height);
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
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity: 4 * placedItems.count + 1];
    NSValue *origin = [NSValue valueWithCGPoint:CGPointZero];
    [results addObject:origin];
    for (MADSectionLayoutAttributes *placedItem in placedItems) {
        if (placedItem.objectID != attribute.objectID) {
            NSArray *dropPoints = [placedItem dropPoints];
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
    NSIndexPath *path = [NSIndexPath indexPathForItem:(NSInteger)self.items.count inSection:0];
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

@end
