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

    @property (nonatomic, strong, readwrite)    MADSectionLayoutAttributesMutableMap *items;
    @property (nonatomic, weak)                 MADSectionLayoutAttributes *lastItem;
    @property (nonatomic, assign)               bool lastOpperationWasAdditon;
    @property (nonatomic, assign)               bool visibility;

@end

@implementation MADSectionLayoutManager

#pragma mark - Static Helpers

+ (NSArray *)nonOverlappingDropPointsForItem:(MADSectionLayoutAttributes *)attr1
                             givenDropPoints:(NSArray *)dropPoints
                              andPlacedItems:(NSArray *)placedItems {
    
    NSMutableArray *nonOverlappingDropPoints = [[NSMutableArray alloc] initWithCapacity:dropPoints.count];
    for (NSValue *pointObj in dropPoints) {
        // Is drop point valid... doesn't it overlap a placed item?
        if ([attr1 validDropPoint:pointObj.CGPointValue givenPlacedItems:placedItems]) {
            [nonOverlappingDropPoints addObject: pointObj];
        }
    }
    return nonOverlappingDropPoints;
}

+ (bool)moveItem:(MADSectionLayoutAttributes *)item toNearestPointInGroup:(NSArray *)dropPoints
   dropTolerance:(CGFloat)tolerance {
    CGPoint nearestPoint = CGPointZero;
    CGFloat distanceToLastDropPoint = tolerance;
    bool foundNearDropPoint = false;
    for (NSValue *pointObj in dropPoints) {
        CGPoint dropPoint = pointObj.CGPointValue;
        CGFloat distanceToDropPoint = fCGDistance(dropPoint, item.frame.origin);
        if ((distanceToDropPoint <= tolerance && distanceToDropPoint <= distanceToLastDropPoint &&
             distanceToLastDropPoint > CGSizeZero.width)) { //Not yet found
            
            nearestPoint = dropPoint;
            foundNearDropPoint = true;
            distanceToLastDropPoint = distanceToDropPoint;
        }
    }
    if (foundNearDropPoint) {
        item.frame = CGRectMake(nearestPoint.x, nearestPoint.y, item.frame.size.width, item.frame.size.height);
    }
    return foundNearDropPoint;
}

+ (NSArray <NSValue *> *)allHorizontallyValidLocations:(MADSectionLayoutAttributes *)attribute
                                        withAttributes:(NSArray <__kindof MADSectionLayoutAttributes *> *)placedItems {
    NSMutableArray <NSValue *> *results = [[NSMutableArray alloc] initWithCapacity: 4 * placedItems.count];
    for (MADSectionLayoutAttributes *placedItem in placedItems) {
        if (placedItem.objectID != attribute.objectID) {
            NSArray <NSValue *> *dropPoints = [placedItem copyDropPoints];
            [results addObjectsFromArray:dropPoints];
        }
    }
    return results;
}

+ (NSArray <NSValue *> *)allValidLocationsForAttributes: (MADSectionLayoutAttributes *)attribute
                                                  withAttributes: (NSArray <__kindof MADSectionLayoutAttributes *> *)placedItems {
    
    NSMutableArray <NSValue *> *results = [[NSMutableArray alloc] initWithCapacity: 4 * placedItems.count + 1];
    NSValue *origin = [NSValue valueWithCGPoint:CGPointZero];
    [results addObject:origin];
    for (MADSectionLayoutAttributes *placedItem in placedItems) {
        if (placedItem.objectID != attribute.objectID) {
            NSArray <NSValue *> *dropPoints = [placedItem copyDropPoints];
            [results addObjectsFromArray:dropPoints];
        }
    }
    return results;
}

+ (bool)isPointGoodLocation:(CGPoint )point forItem:(MADSectionLayoutAttributes *)attr1 givenPlacedItems:(NSArray <__kindof MADSectionLayoutAttributes *> *)placedItems {
    return attr1.frame.origin.y >= point.y - 0.5f && [attr1 validDropPoint:point givenPlacedItems:placedItems];
}

+ (void)moveItem:(MADSectionLayoutAttributes *)itemToPlace
        alreadyPlacedItems:(NSArray <MADSectionLayoutAttributes *> *)alreadyPlacedItems {
    
    CGPoint dropPoint = CGPointZero;
    CGFloat distance = 0.00000000f, tmpDistance;
    bool distanceSet = false;
    
    for (MADSectionLayoutAttributes *alreadyPlacedItem in alreadyPlacedItems) {
        if (itemToPlace.objectID != alreadyPlacedItem.objectID) {
        
            NSArray <NSValue *> *alreadyPlacedItemDropPoints = [alreadyPlacedItem copyDropPoints];

            for (NSValue *v in alreadyPlacedItemDropPoints) {
                if ([self isPointGoodLocation: v.CGPointValue forItem: itemToPlace
                             givenPlacedItems: alreadyPlacedItems]) {
                    if (!distanceSet) {
                        dropPoint = v.CGPointValue;
                        distance = fCGDistance(itemToPlace.frame.origin, v.CGPointValue);
                        distanceSet = true;
                    } else if ((tmpDistance = fCGDistance(itemToPlace.frame.origin, v.CGPointValue)) < distance) {
                        dropPoint = v.CGPointValue;
                        distance = tmpDistance;
                    }
                }
            }
            
        }
    }
    itemToPlace.frame = CGRectMake(dropPoint.x, dropPoint.y, itemToPlace.frame.size.width, itemToPlace.frame.size.height);
}

+ (CGFloat)distanceToBestDropPoint:(MADSectionLayoutAttributes *)attr1 placedItems:(NSArray <__kindof MADSectionLayoutAttributes *> *)placedItems {
    CGFloat d = 0.0;
    CGPoint nearestPoint = CGPointZero;
    bool foundNearDropPoint = false;
    bool firstTime = true;
    
    NSArray <NSValue *> *dropPoints = [MADSectionLayoutManager allValidLocationsForAttributes: attr1 withAttributes: placedItems];
    for (NSValue *pointObj in dropPoints) {
        
        if ([self isPointGoodLocation:pointObj.CGPointValue forItem:attr1 givenPlacedItems:placedItems]) {
            
            CGFloat distanceToDropPoint = fCGDistance(pointObj.CGPointValue, attr1.frame.origin);
            
            if (firstTime) {
                firstTime = false;
                nearestPoint = pointObj.CGPointValue;
                foundNearDropPoint = true;
                d = distanceToDropPoint;
            } else if (distanceToDropPoint <= d && d > 0.00000000f) {
                nearestPoint = pointObj.CGPointValue;
                foundNearDropPoint = true;
                d = distanceToDropPoint;
            }
        }
    }
    return d;
}

#pragma mark - Creation

- (instancetype)initWithDocumentSection:(RptqDocumentSection *)section {

    if (self = [super init]) {
    
        NSMutableDictionary *items = [[NSMutableDictionary alloc] init];
        self.items = items;
        
        self.visibility = section.visibility.boolValue ? true : false;
        
        RptqDocumentSectionRows *rows = section.hasRows.firstObject;
        NSInteger itemCounter = 0;

        id layout, path;
        for (RptqDocumentObject *object in rows.hasObjects) {
            @autoreleasepool {
                path = [NSIndexPath indexPathForItem: itemCounter inSection: 0];
                layout = [MADSectionLayoutAttributes newSectionLayoutAttributesWithIndex: path
                                                                                objectID: object.objectID
                                                                                 andRect: object.frame];
                [self addItem:layout];
            }
            itemCounter++;
        }

    }
    
    return self;
}

#pragma mark - Methods

- (void)addItem:(MADSectionLayoutAttributes *)item {
    [self.items setObject:item forKey:item.objectID];
    self.lastItem = item;
    self.lastOpperationWasAdditon = true;
}

- (void)removeItem:(MADSectionLayoutAttributes *)itemToRemove {
    
    NSIndexPath *pathToRemvoe = itemToRemove.indexPath;
    
    [self.items enumerateKeysAndObjectsUsingBlock:
                                        ^(id key, MADSectionLayoutAttributes *obj, BOOL *stop) {
        if (obj.indexPath.item >= pathToRemvoe.item) {
            obj.indexPath = [NSIndexPath indexPathForItem: obj.indexPath.item - 1
                                                inSection: obj.indexPath.section];
        }
    }];
    
    [self.items removeObjectForKey:itemToRemove.objectID];
    self.lastOpperationWasAdditon = false;
}

- (void)addItemWithObjectID:(NSManagedObjectID *)objectID andFrame:(CGRect)frame {
    NSIndexPath *path = [NSIndexPath indexPathForItem:(NSInteger)self.items.count inSection:0];
    MADSectionLayoutAttributes *layout;
    layout = [MADSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
    layout.objectID = objectID;
    layout.frame = frame;
    [self.items setObject: layout forKey: objectID];
}

- (void)removeItemWithID:(NSManagedObjectID *)objectID {
    
    MADSectionLayoutAttributes *item = [self.items objectForKey:objectID];
    NSIndexPath *pathToRemvoe = item.indexPath;
    
    [self.items enumerateKeysAndObjectsUsingBlock:
                                            ^(id key, MADSectionLayoutAttributes *obj, BOOL *stop) {
        if (obj.indexPath.item >= pathToRemvoe.item) {
            obj.indexPath = [NSIndexPath indexPathForItem: obj.indexPath.item - 1
                                                inSection: obj.indexPath.section];
        }
    }];
    
    [self.items removeObjectForKey:objectID];
    self.lastOpperationWasAdditon = false;
}

- (CGSize)size {
    CGSize size = CGSizeZero;
    NSArray *layouts = self.items.allValues;
    for (MADSectionLayoutAttributes *layout in layouts) {
        size.width = MAX(size.width, layout.frame.origin.x + layout.frame.size.width);
        size.height = MAX(size.height, layout.frame.origin.y + layout.frame.size.height);
    }
    return size;
}

- (void)layout {
    if (self.lastOpperationWasAdditon) {
        [self positionItem:self.lastItem];
    }
}

- (void)placeItem:(MADSectionLayoutAttributes *)item givenAlreadyPlacedItems:(NSArray *)placedItems {
    [MADSectionLayoutManager moveItem:item alreadyPlacedItems:placedItems];
}

- (bool)moveItem:(MADSectionLayoutAttributes *)item toNearestPointInGroup:(NSArray *)dropPoints
   dropTolerance:(CGFloat)tolerance {
    return [MADSectionLayoutManager moveItem: item toNearestPointInGroup: dropPoints
                               dropTolerance: tolerance];
}

- (void)positionItem:(MADSectionLayoutAttributes *)placedItem {

    NSArray <MADSectionLayoutAttributes *> *allValues = self.items.allValues;
    NSMutableArray <MADSectionLayoutAttributes *> *placedItems = [[NSMutableArray alloc] initWithCapacity:allValues.count];
    
    // If offscreen, move it onscreen.
    if (placedItem.frame.origin.x < CGPointZero.x) {
        placedItem.frame = CGRectMake(CGPointZero.x, placedItem.frame.origin.y, placedItem.frame.size.width, placedItem.frame.size.height);
    }
    if (placedItem.frame.origin.y < CGPointZero.y) {
        placedItem.frame = CGRectMake(placedItem.frame.origin.x, CGPointZero.y, placedItem.frame.size.width, placedItem.frame.size.height);
    }
    
    NSArray *allPotentalDropPoints = [MADSectionLayoutManager allValidLocationsForAttributes: placedItem withAttributes: allValues];
    bool anchored = [self moveItem:placedItem toNearestPointInGroup:allPotentalDropPoints dropTolerance:24.0000f];
    if (!anchored) {
        anchored = [placedItem moveOnScreen];
    }
    if ([placedItem intersectsAnItemInArray: allValues]) {
        [placedItem placeItemGivenAttributes: allValues];
    }
    [placedItems addObject:placedItem];
    
    static NSString * const formatString = @"objectID != %@.objectID";
    NSPredicate *unplaced = [NSPredicate predicateWithFormat:formatString, placedItem];
    NSArray *unplacedItems = [allValues filteredArrayUsingPredicate:unplaced];
    
    bool positionItems = true;
    while (positionItems) {
    
        NSArray *placedNow = [self positionUnplacedItems:unplacedItems aroundPlacedItems:placedItems];
        [placedItems setArray:placedNow];
        positionItems = false;
        
        static NSString * const format = @"NOT objectID IN %@.objectID";
        NSPredicate *filterPlacedItems = [NSPredicate predicateWithFormat:format, placedItems];
        NSArray *unplacedItems = [allValues filteredArrayUsingPredicate:filterPlacedItems];
        for (MADSectionLayoutAttributes *item in placedItems) {
            if ([item intersectsAnItemInArray:unplacedItems]) {
                positionItems = true;
                break;
            }
        }
    }
    placedItem.frame = CGRectMake(roundf(placedItem.frame.origin.x),
                                  roundf(placedItem.frame.origin.y),
                                  placedItem.frame.size.width, placedItem.frame.size.height);
}

- (NSArray *)positionUnplacedItems:(NSArray *)unplacedItems aroundPlacedItems:(NSArray *)placedItems {

    NSMutableArray <MADSectionLayoutAttributes *> *unplacedOverlapping = [[NSMutableArray alloc] initWithCapacity:unplacedItems.count];
    NSMutableArray *placedItemsTracker = [[NSMutableArray alloc] initWithArray:placedItems];
    
    for (MADSectionLayoutAttributes *unplacedItem in unplacedItems) {
        if ([unplacedItem intersectsAnItemInArray:placedItemsTracker]) {
            [unplacedOverlapping addObject:unplacedItem];
        }
    }
    
    bool stillPlacing = true;
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
    NSArray *newlyPlacedItems = [[NSArray alloc] initWithArray: placedItems];
    return newlyPlacedItems;
}

#pragma mark - Helpers

- (NSArray <__kindof NSValue *> *)allValidLocations {
    MADSectionLayoutAttributesMutableMap *items = self.items;
    NSValue *placement0Value;
    NSArray *allItems = items.allValues;
    NSMutableArray <__kindof NSValue *> *allValidLocations = [[NSMutableArray alloc] initWithCapacity:allItems.count * 4];
    for (MADSectionLayoutAttributes *layout in allItems) {
        @autoreleasepool {
            MTCorners corners = MTCornersMake(layout.frame);
            placement0Value = [[NSValue alloc] initWithBytes:&corners.topLeft objCType:@encode(CGPoint)];
            [allValidLocations addObject:placement0Value];
            
            placement0Value = [[NSValue alloc] initWithBytes:&corners.topRight objCType:@encode(CGPoint)];
            [allValidLocations addObject:placement0Value];
            
            placement0Value = [[NSValue alloc] initWithBytes:&corners.bottomLeft objCType:@encode(CGPoint)];
            [allValidLocations addObject:placement0Value];
            
            placement0Value = [[NSValue alloc] initWithBytes:&corners.bottomRight objCType:@encode(CGPoint)];
            [allValidLocations addObject:placement0Value];
        }
    }
    return allValidLocations;
}

@end
