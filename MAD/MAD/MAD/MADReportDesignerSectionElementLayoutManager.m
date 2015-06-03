//
//  MADReportDesignerSectionElementLayoutManager.m
//  MAD
//
//  Created by Michael Thomason on 11/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADReportDesignerSectionElementLayoutManager.h"
#import "CGGeometry+Extras.h"
#import "MTPair.h"

#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSectionRows.h"

@implementation MADReportDesignerSectionLayoutAttributes

@end

@interface MADReportDesignerSectionElementLayoutManager ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *items;
@property (nonatomic, weak) MADReportDesignerSectionLayoutAttributes *lastItem;
@property (nonatomic, assign) BOOL lastOpperationWasAdditon;
@property (nonatomic, assign) BOOL visibility;
@end

@implementation MADReportDesignerSectionElementLayoutManager

- (instancetype)initWithDocumentSection:(RptqDocumentSection *)section {

    if (self = [super init]) {
        
        NSMutableDictionary *items = [NSMutableDictionary dictionary];
        self.items = items;
        self.visibility = section.visibility.boolValue;
        RptqDocumentSectionRows *rows = section.hasRows.firstObject;
        NSOrderedSet *objects = rows.hasObjects;
        NSInteger itemCounter = 0;
        RptqDocumentObject *object;
        MADReportDesignerSectionLayoutAttributes *layout;
        for (object in objects) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:itemCounter inSection:0];
            layout = [MADReportDesignerSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
            layout.objectID = object.objectID;
            CGSize size = object.size;
            layout.frame = CGRectMake(object.originx.floatValue,
                                      object.originy.floatValue,
                                      size.width,
                                      size.height);
            [self addItem:layout];
            itemCounter++;
        }

    }
    
    return self;

}


- (instancetype)init {
    
    if (self = [super init]) {
        NSMutableDictionary *items = [NSMutableDictionary dictionary];
        self.items = items;
    }
    
    return self;
    
}

- (void)addItem:(MADReportDesignerSectionLayoutAttributes *)item {

    [self appendItemToItems:item];
    
    self.lastOpperationWasAdditon = YES;

}

- (void)positionItem:(MADReportDesignerSectionLayoutAttributes *)item {
    NSArray *allValues = self.items.allValues;
    NSArray *allPotentalDropPoints = [MADReportDesignerSectionElementLayoutManager allValidLocationsForAttributes: item
                                                                                                   withAttributes: allValues
                                                                                                   excludingItems: @[]];
    [self moveItem:item toNearestPointInGroup:allPotentalDropPoints];
    
    // FIXME: May need this...
    //[self.delegate layoutManager:self itemNeedsUpdate:item];
    
}

- (void)moveItem:(MADReportDesignerSectionLayoutAttributes *)item toNearestPointInGroup:(NSArray *)dropPoints {
    CGPoint nearestPoint = CGPointZero;
    static CGFloat minDistanceToInvoikeAutoLayout = 18.0000f;
    CGFloat distanceToLastDropPoint = minDistanceToInvoikeAutoLayout;
    BOOL foundNearDropPoint = NO;
    for (NSValue *pointObj in dropPoints) {
        CGPoint dropPoint = pointObj.CGPointValue;
        CGFloat distanceToDropPoint = CGDistance(dropPoint, item.frame.origin);
        if ((distanceToDropPoint <= minDistanceToInvoikeAutoLayout &&
                distanceToDropPoint <= distanceToLastDropPoint &&
                distanceToLastDropPoint > CGSizeZero.width))                                       //Not yet found
        {
            
            nearestPoint = dropPoint;
            foundNearDropPoint = YES;
            distanceToLastDropPoint = distanceToDropPoint;
        }
    }
    if (foundNearDropPoint) {
        item.frame = CGRectMake(nearestPoint.x, nearestPoint.y, item.frame.size.width, item.frame.size.height);
    }
}

- (void)addItemWithObjectID:(NSManagedObjectID *)objectID andFrame:(CGRect)frame {
    
    NSIndexPath *path = [NSIndexPath indexPathForItem:self.items.count
                                            inSection:0];
    
    MADReportDesignerSectionLayoutAttributes *layout = [MADReportDesignerSectionLayoutAttributes layoutAttributesForCellWithIndexPath:path];
    layout.objectID = objectID;
    layout.frame = frame;
    [self.items setObject: layout
                   forKey: objectID];
}

- (void)layout {

    if (self.lastOpperationWasAdditon) {
        id lastItemDropped = self.lastItem;
        [self positionItem:lastItemDropped];
    }

}

- (void)layoutAfterItemRemoval {
    
    MADReportDesignerSectionLayoutAttributes *opp;
    while ((opp = [self getAnOutOfPositionItem]) != nil) {
        [self layoutOutOfPlaceItem:opp];
    }
    
}

- (MADReportDesignerSectionLayoutAttributes *)getAnOutOfPositionItem {

    __block MADReportDesignerSectionLayoutAttributes *opp = nil;
    MADReportDesignerSectionLayoutAttributes *layout;
    __weak MADReportDesignerSectionElementLayoutManager *weakself = self;
    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([weakself isItemMisplaced:layout]) {
            opp = layout;
            *stop = YES;
        }
    }];
    return opp;
}

- (BOOL)isItemMisplaced:(MADReportDesignerSectionLayoutAttributes *)item {
    
    __block BOOL originFound = NO;
    __block CGFloat x1, x2, y1, y2;
    __block CGPoint p0, p1, p2, p3;

    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, MADReportDesignerSectionLayoutAttributes *layout, BOOL *stop) {
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
}

- (void)layoutOutOfPlaceItem:(MADReportDesignerSectionLayoutAttributes *)opp {
    
}

- (void)removeItemWithID:(NSManagedObjectID *)objectID {
    
    MADReportDesignerSectionLayoutAttributes *item = [self.items objectForKey:objectID];
    NSIndexPath *pathToRemvoe = item.indexPath;
    
    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, MADReportDesignerSectionLayoutAttributes *obj, BOOL *stop) {
        if (obj.indexPath.item >= pathToRemvoe.item) {
            obj.indexPath = [NSIndexPath indexPathForItem: obj.indexPath.item - 1
                                                inSection: obj.indexPath.section];
        }
    }];

    [self.items removeObjectForKey:objectID];
    self.lastOpperationWasAdditon = NO;
}

- (void)removeItem:(MADReportDesignerSectionLayoutAttributes *)itemToRemove {
    
    NSIndexPath *pathToRemvoe = itemToRemove.indexPath;
    
    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, MADReportDesignerSectionLayoutAttributes *obj, BOOL *stop) {
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
        [self.items enumerateKeysAndObjectsUsingBlock:^(id key, MADReportDesignerSectionLayoutAttributes *layout, BOOL *stop) {
            size.width = MAX(size.width, layout.frame.origin.x + layout.frame.size.width);
            size.height = MAX(size.height, layout.frame.origin.y + layout.frame.size.height);
        }];
    }
    return size;
}

#pragma mark - Helpers

- (void)appendItemToItems:(MADReportDesignerSectionLayoutAttributes *)item {
    [self.items setObject:item forKey:item.objectID];
    self.lastItem = item;
}

- (void)positionLastItem {
    MADReportDesignerSectionLayoutAttributes *attributes = self.lastItem;
    NSArray *validLocations = [self allValidLocationsForLastItem];
    CGPoint newLocation = [self pointNearestDropPoint: attributes.frame.origin
                                      fromValidPoints: validLocations];
    attributes.frame = CGRectMake(newLocation.x,
                                  newLocation.y,
                                  attributes.frame.size.width,
                                  attributes.frame.size.height);
    [self.delegate layoutManager: self
                 itemNeedsUpdate: attributes];
}

/*
 
 Assumes that all items are pushed to the proper place.
 
 */

- (void)positionAllItemsAroundItem:(MADReportDesignerSectionLayoutAttributes *)lastItemDropped {
    NSArray *overlappingItems = [self itemsThatOverlapItem:lastItemDropped];
    CGPoint origin = lastItemDropped.frame.origin;
    MTPair *sepratedItems = [MADReportDesignerSectionElementLayoutManager seperateByDestionationDirection: overlappingItems
                                                                                   inRelationToAttributes: lastItemDropped];
    NSComparator sortBydistanceAsc = ^NSComparisonResult(MADReportDesignerSectionLayoutAttributes *obj1, MADReportDesignerSectionLayoutAttributes *obj2) {
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
    
}

- (void)pushingItem: (MADReportDesignerSectionLayoutAttributes *)pushingItem
         pushesItem: (MADReportDesignerSectionLayoutAttributes *)pushedItem
        inDirection: (MADDirection)direction {
    
    NSArray *allPotentalDropPoints = [self allValidLocationsForPushedItem: pushedItem
                                                          withPushingItem: pushingItem
                                                                direction: direction];
    
    [self moveItem:pushedItem toNearestPointInGroup:allPotentalDropPoints
         direction:direction];
    
    [self.delegate layoutManager: self
                 itemNeedsUpdate: pushedItem];
    
}

- (NSArray *)allValidLocationsForPushedItem: (MADReportDesignerSectionLayoutAttributes *)pushedItem
                            withPushingItem: (MADReportDesignerSectionLayoutAttributes *)pushingItem
                                  direction: (MADDirection)direction {
    
    __block CGFloat x1, x2, y1, y2;
    __block CGPoint placement0, placement1, placement2, placement3;
    __block NSValue *placement0Value, *placement1Value, *placement2Value, *placement3Value;
    placement0Value = [NSValue valueWithCGPoint:CGPointZero];
    __block NSArray *allValidLocations = @[placement0Value];
    BOOL directionIsHorizontal = MADDirectionIsHorizontal(direction);
    NSMutableArray *placemntValues = [[NSMutableArray alloc] initWithCapacity:4];
    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, MADReportDesignerSectionLayoutAttributes *layout, BOOL *stop) {
        
        BOOL isPushedItem = layout == pushedItem;
        
        if (isPushedItem == NO) {
            x1 = layout.frame.origin.x;
            x2 = layout.frame.origin.x + layout.frame.size.width;
            y1 = layout.frame.origin.y;
            y2 = layout.frame.origin.y + layout.frame.size.height;
            
            placement0 = CGPointMake(x1, y1);
            placement1 = CGPointMake(x2, y1);
            placement2 = CGPointMake(x2, y2);
            placement3 = CGPointMake(x1, y2);
            
            if (directionIsHorizontal) {
                
                if (direction == MADDirectionHorizontalDirectionOfPoint(placement0, pushedItem.frame.origin)) {
                    placement0Value = [NSValue valueWithCGPoint: placement0];
                    [placemntValues addObject:placement0Value];
                }
                
                if (direction == MADDirectionHorizontalDirectionOfPoint(placement1, pushedItem.frame.origin)) {
                    placement1Value = [NSValue valueWithCGPoint: placement1];
                    [placemntValues addObject:placement1Value];
                }
                
                if (direction == MADDirectionHorizontalDirectionOfPoint(placement2, pushedItem.frame.origin)) {
                    placement2Value = [NSValue valueWithCGPoint: placement2];
                    [placemntValues addObject:placement2Value];
                }
                
                if (direction == MADDirectionHorizontalDirectionOfPoint(placement3, pushedItem.frame.origin)) {
                    placement3Value = [NSValue valueWithCGPoint: placement3];
                    [placemntValues addObject:placement3Value];
                }
                
            } else {
                
                if (direction == MADDirectionVerticalDirectionOfPoint(placement0, pushedItem.frame.origin)) {
                    placement0Value = [NSValue valueWithCGPoint: placement0];
                    [placemntValues addObject:placement0Value];
                }
                
                if (direction == MADDirectionVerticalDirectionOfPoint(placement1, pushedItem.frame.origin)) {
                    placement1Value = [NSValue valueWithCGPoint: placement1];
                    [placemntValues addObject:placement1Value];
                }
                
                if (direction == MADDirectionVerticalDirectionOfPoint(placement2, pushedItem.frame.origin)) {
                    placement2Value = [NSValue valueWithCGPoint: placement2];
                    [placemntValues addObject:placement2Value];
                }
                
                if (direction == MADDirectionVerticalDirectionOfPoint(placement3, pushedItem.frame.origin)) {
                    placement3Value = [NSValue valueWithCGPoint: placement3];
                    [placemntValues addObject:placement3Value];
                }
                
                
            }
            
            allValidLocations = [allValidLocations arrayByAddingObjectsFromArray:placemntValues];
            
            [placemntValues removeAllObjects];
        }
        
    }];
    
    return allValidLocations;
    
}

- (void)moveItem:(MADReportDesignerSectionLayoutAttributes *)item toNearestPointInGroup:(NSArray *)dropPoints
       direction:(MADDirection)direction {
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
}

+ (MTPair *)seperateByDestionationDirection: (NSArray *)overlappingItems
                     inRelationToAttributes: (MADReportDesignerSectionLayoutAttributes *)droppedAttributes {
    CGFloat x = droppedAttributes.frame.origin.x + droppedAttributes.frame.size.width;
    CGFloat y = droppedAttributes.frame.origin.y + droppedAttributes.frame.size.height;
    CGPoint bottomLeft, topRight;
    
    MADReportDesignerSectionLayoutAttributes *attributes;
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
    MADReportDesignerSectionLayoutAttributes *droppedAttributes = self.lastItem;
    CGFloat x = droppedAttributes.frame.origin.x + droppedAttributes.frame.size.width;
    CGFloat y = droppedAttributes.frame.origin.y + droppedAttributes.frame.size.height;
    CGPoint bottomLeft, topRight;
    
    MADReportDesignerSectionLayoutAttributes *attributes;
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
}

- (NSArray *)sortOverlappingItems: (NSArray *)overlappingItems
                distanctFromPoint: (CGPoint)origin {

    NSArray *sortedArray = [overlappingItems sortedArrayUsingComparator:^NSComparisonResult(MADReportDesignerSectionLayoutAttributes *obj1, MADReportDesignerSectionLayoutAttributes *obj2) {
        NSNumber *distance1 = @(CGDistance(origin, obj1.frame.origin));
        NSNumber *distance2 = @(CGDistance(origin, obj2.frame.origin));
        return [distance1 compare:distance2];
    }];
    
    return sortedArray;
}

- (NSArray *)itemsThatOverlapItem:(MADReportDesignerSectionLayoutAttributes *)lastItem {
    MADReportDesignerSectionLayoutAttributes *layout;
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
}

- (NSArray *)itemsThatOverlapLastItem {
    
    MADReportDesignerSectionLayoutAttributes *layout;
    NSArray *allItems = self.items.allValues;
    MADReportDesignerSectionLayoutAttributes *lastItem = self.lastItem;
    NSArray *results = @[];
    for (layout in allItems) {
        if (lastItem != layout) {
            if (CGRectIntersectsRect(layout.frame, lastItem.frame)) {
                results = [results arrayByAddingObject:layout];
            }
        }
    }
    return results;
}

- (void)slideItems: (NSArray *)itemsToSlide
         direction: (MADDirection)direction
          distance: (CGFloat)distance {
    
    MADReportDesignerSectionLayoutAttributes *attributes;

    switch (direction) {
    
        case left:
            
            for (attributes in itemsToSlide) {
                
                attributes.frame = CGRectMake(attributes.frame.origin.x - distance,
                                              attributes.frame.origin.y,
                                              attributes.frame.size.width,
                                              attributes.frame.size.height);
                
                [self.delegate layoutManager: self
                             itemNeedsUpdate: attributes];

            }
            
            break;
            
        case right:
            
            for (attributes in itemsToSlide) {
                
                attributes.frame = CGRectMake(attributes.frame.origin.x + distance,
                                              attributes.frame.origin.y,
                                              attributes.frame.size.width,
                                              attributes.frame.size.height);
                
                [self.delegate layoutManager: self
                             itemNeedsUpdate: attributes];

            }
            
            break;
            
        case up:
            
            for (attributes in itemsToSlide) {
                attributes.frame = CGRectMake(attributes.frame.origin.x,
                                              attributes.frame.origin.y + distance,
                                              attributes.frame.size.width,
                                              attributes.frame.size.height);
                
                [self.delegate layoutManager: self
                             itemNeedsUpdate: attributes];
                
            }
            
            break;
            
        case down:
            
            for (attributes in itemsToSlide) {
                attributes.frame = CGRectMake(attributes.frame.origin.x,
                                              attributes.frame.origin.y - distance,
                                              attributes.frame.size.width,
                                              attributes.frame.size.height);
                
                [self.delegate layoutManager: self
                             itemNeedsUpdate: attributes];

            }
            
            break;
            
        default:
            break;
    }
    
}

- (NSArray *)allValidLocationsForLastItem {
    CGFloat x1, x2, y1, y2;
    CGPoint placement0, placement1, placement2, placement3;
    NSValue *placement0Value, *placement1Value, *placement2Value, *placement3Value;
    NSArray *allValidLocations = @[];
    NSArray *potentialPlacements = @[];
    id lastItem = self.lastItem;
    NSArray *allItems = self.items.allValues;
    MADReportDesignerSectionLayoutAttributes *layout;
    for (layout in allItems) {
        if (lastItem != layout) {
            
            //There exist four potental placement spots for each alredy placed rect
            x1 = layout.frame.origin.x;
            x2 = layout.frame.origin.x + layout.frame.size.width;
            y1 = layout.frame.origin.y;
            y2 = layout.frame.origin.y + layout.frame.size.height;
            
            placement0 = CGPointMake(x1, y1);
            placement1 = CGPointMake(x2, y1);
            placement2 = CGPointMake(x2, y2);
            placement3 = CGPointMake(x1, y2);
            
            placement0Value = [NSValue valueWithCGPoint: placement0];
            placement1Value = [NSValue valueWithCGPoint: placement1];
            placement2Value = [NSValue valueWithCGPoint: placement2];
            placement3Value = [NSValue valueWithCGPoint: placement3];
            
            potentialPlacements = @[placement0Value,
                                    placement1Value,
                                    placement2Value,
                                    placement3Value];
            
            allValidLocations = [allValidLocations arrayByAddingObjectsFromArray:potentialPlacements];
        }
    }
    return allValidLocations;
}

+ (NSArray *)allValidLocationsForAttributes: (MADReportDesignerSectionLayoutAttributes *)attribute
                             withAttributes: (NSArray *)attributes excludingItems:(NSArray *)excludingItems {
    CGFloat x1, x2, y1, y2;
    CGPoint placement0, placement1, placement2, placement3;
    NSValue *placement0Value, *placement1Value, *placement2Value, *placement3Value;
    placement0Value = [NSValue valueWithCGPoint:CGPointZero];
    NSArray *allValidLocations = @[placement0Value];
    NSArray *potentialPlacements = @[];
    MADReportDesignerSectionLayoutAttributes *layout, *layoutSubtest;
    BOOL excludedItem = NO;
    NSArray *attributesSubtest = [NSArray arrayWithArray:attributes];
    for (layout in attributes) {
        excludedItem = layout == attribute;
        if (excludedItem == NO) {
            for (MADReportDesignerSectionLayoutAttributes *excludingItem in excludingItems) {
                excludedItem = layout == excludingItem;
            }
        }
        /*
        if (excludedItem == NO) {
            for (layoutSubtest in attributesSubtest) {
                if (layout != layoutSubtest) {
                    if (CGRectIntersectsRect(layout.frame, layoutSubtest.frame)) {
                        excludedItem = YES;
                        break;
                    }
                }
            }
        }*/
        
        if (excludedItem == NO) {
            
            //There exist four potental placement spots for each alredy placed rect
            x1 = layout.frame.origin.x;
            x2 = layout.frame.origin.x + layout.frame.size.width;
            y1 = layout.frame.origin.y;
            y2 = layout.frame.origin.y + layout.frame.size.height;
            
            placement0 = CGPointMake(x1, y1);
            placement1 = CGPointMake(x2, y1);
            placement2 = CGPointMake(x2, y2);
            placement3 = CGPointMake(x1, y2);
            
            placement0Value = [NSValue valueWithCGPoint: placement0];
            placement1Value = [NSValue valueWithCGPoint: placement1];
            placement2Value = [NSValue valueWithCGPoint: placement2];
            placement3Value = [NSValue valueWithCGPoint: placement3];
            
            potentialPlacements = @[placement0Value,
                                    placement1Value,
                                    placement2Value,
                                    placement3Value];
            
            allValidLocations = [allValidLocations arrayByAddingObjectsFromArray:potentialPlacements];
        }
    }
    return allValidLocations;
}

- (NSArray *)allValidLocations {
    CGFloat x1, x2, y1, y2;
    CGPoint placement0, placement1, placement2, placement3;
    NSValue *placement0Value, *placement1Value, *placement2Value, *placement3Value;
    NSArray *allValidLocations = @[];
    NSArray *potentialPlacements = @[];
    NSArray *allItems = self.items.allValues;
    MADReportDesignerSectionLayoutAttributes *layout;
    for (layout in allItems) {
        
        //There exist four potental placement spots for each alredy placed rect
        x1 = layout.frame.origin.x;
        x2 = layout.frame.origin.x + layout.frame.size.width;
        y1 = layout.frame.origin.y;
        y2 = layout.frame.origin.y + layout.frame.size.height;
        
        placement0 = CGPointMake(x1, y1);
        placement1 = CGPointMake(x2, y1);
        placement2 = CGPointMake(x2, y2);
        placement3 = CGPointMake(x1, y2);
        
        placement0Value = [NSValue valueWithCGPoint: placement0];
        placement1Value = [NSValue valueWithCGPoint: placement1];
        placement2Value = [NSValue valueWithCGPoint: placement2];
        placement3Value = [NSValue valueWithCGPoint: placement3];
        
        potentialPlacements = @[placement0Value,
                                placement1Value,
                                placement2Value,
                                placement3Value];
        
        allValidLocations = [allValidLocations arrayByAddingObjectsFromArray:potentialPlacements];
        
    }
    return allValidLocations;
}

- (CGPoint)pointNearestDropPoint: (CGPoint)dropPoint
                 fromValidPoints: (NSArray *)validLocations {
    
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
    
}

@end
