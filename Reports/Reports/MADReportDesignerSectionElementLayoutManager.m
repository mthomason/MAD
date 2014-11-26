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

@implementation MADReportDesignerSectionLayoutAttributes

@end

@interface MADReportDesignerSectionElementLayoutManager ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *items;
@property (nonatomic, weak) MADReportDesignerSectionLayoutAttributes *lastItem;
@property (nonatomic, assign) BOOL lastOpperationWasAdditon;

@end

@implementation MADReportDesignerSectionElementLayoutManager

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
        [self positionLastItem];
        [self positionAllItemsAroundLastItem];
    } else {
        //[self layoutAfterItemRemoval];
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
    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, MADReportDesignerSectionLayoutAttributes *layout, BOOL *stop) {
        size.width = MAX(size.width, layout.frame.origin.x + layout.frame.size.width);
        size.height = MAX(size.height, layout.frame.origin.y + layout.frame.size.height);
    }];
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

- (void)positionAllItemsAroundLastItem {
    NSArray *overlappingItems = [self itemsThatOverlapLastItem];
    MADReportDesignerSectionLayoutAttributes *attributes = self.lastItem;
    CGPoint origin = attributes.frame.origin;

    MTPair *sepratedItems = [self seperateByDestionationDirection:overlappingItems];
    NSComparator sortBydistanceAsc = ^NSComparisonResult(MADReportDesignerSectionLayoutAttributes *obj1, MADReportDesignerSectionLayoutAttributes *obj2) {
        NSNumber *distance1 = @(CGDistance(origin, obj1.frame.origin));
        NSNumber *distance2 = @(CGDistance(origin, obj2.frame.origin));
        return [distance1 compare:distance2];
    };
    NSArray *itemsToPushDown = [sepratedItems.left sortedArrayUsingComparator:sortBydistanceAsc];
    NSArray *itemsToPushRigth = [sepratedItems.right sortedArrayUsingComparator:sortBydistanceAsc];
    
    [self pushItems:itemsToPushDown directon:down];
    [self pushItems:itemsToPushRigth directon:right];
    
    [self slideItems: overlappingItems
           direction: right
            distance: attributes.frame.size.width];
    
}

- (void)pushItems: (NSArray *)items
         directon: (MADDirection)direction {
    MADReportDesignerSectionLayoutAttributes *attributes;
    NSArray *overlappingItems = items;
    NSObject *lastItem = self.lastItem;
    for (attributes in overlappingItems) {
        if (lastItem != attributes) {
            [self pushItem:attributes directon:direction];
        }
    }
}

- (void)pushItem: (MADReportDesignerSectionLayoutAttributes *)pushItem
        directon: (MADDirection)direction {

    MADReportDesignerSectionLayoutAttributes *lastItem = self.lastItem;
    CGPoint newOrigin;
    CGFloat distance;
    switch (direction) {
        case right:
            newOrigin = CGPointMake(lastItem.frame.origin.x + lastItem.frame.size.width, pushItem.frame.origin.y);
            distance = CGDistance(pushItem.frame.origin, newOrigin);
            break;
        case down:
            newOrigin = CGPointMake(pushItem.frame.origin.x, lastItem.frame.origin.y + lastItem.frame.size.height);
            distance = CGDistance(pushItem.frame.origin, newOrigin);
            break;
        default:
            break;
    }
    pushItem.frame = CGRectMake(newOrigin.x, newOrigin.y, pushItem.size.width, pushItem.size.height);
    
    [self.delegate layoutManager: self
                 itemNeedsUpdate: pushItem];
    
    MADReportDesignerSectionLayoutAttributes *attributes;
    __weak MADReportDesignerSectionElementLayoutManager *weakself = self;
    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (lastItem != attributes && attributes != pushItem && CGRectIntersectsRect(pushItem.frame, attributes.frame)) {
            [weakself pushItem: attributes
                      directon: direction];
        }
    }];
    
    // Now make sure each item is at an anchor point...
    //  if not at anchor point, move to nearest anchor point in same direction as current move...
    //  oherwise nearest anchorpoint in opposate direction...
    //  otherwise nearest anchorpoint, yo
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
    CGRect placement0, placement1, placement2, placement3;
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
            
            allValidLocations = [allValidLocations arrayByAddingObjectsFromArray:potentialPlacements];
        }
    }
    return allValidLocations;
}

- (NSArray *)allValidLocations {
    CGFloat x1, x2, y1, y2;
    CGRect placement0, placement1, placement2, placement3;
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
        
        allValidLocations = [allValidLocations arrayByAddingObjectsFromArray:potentialPlacements];
        
    }
    return allValidLocations;
}

- (NSArray *)itemsNotAtDropPoints:(NSArray *)allValidLocations {
    
}

- (CGPoint)pointNearestDropPoint: (CGPoint)dropPoint
                 fromValidPoints: (NSArray *)validLocations {
    CGPoint nearestPoint = dropPoint;
    CGFloat distance = CGSizeZero.width;
    CGFloat d2;
    NSValue *value;
    CGRect frame;
    for (value in validLocations) {
        frame = [value CGRectValue];
        d2 = CGDistance(dropPoint, frame.origin);
        if (d2 < distance) {
            distance = d2;
            nearestPoint = dropPoint;
        }
    }
    return nearestPoint;
}

@end
