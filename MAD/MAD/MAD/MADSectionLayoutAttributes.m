//
//  MADReportDesignerSectionLayoutAttributes.m
//  MAD
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADSectionLayoutAttributes.h"
#import "CGGeometry+extras.h"

@implementation MADSectionLayoutAttributes

- (BOOL)intersectsAnItemInArray:(NSArray *)items {
    return [MADSectionLayoutAttributes item:self intersectsAnItem:items];
}

+ (BOOL)item:(MADSectionLayoutAttributes *)item intersectsAnItem:(NSArray *)items {
    BOOL intersects = NO;
    for (MADSectionLayoutAttributes *existingItem in items) {
        if (item.objectID != existingItem.objectID) {
            if (CGRectIntersectsRect(item.frame, existingItem.frame)) {
                intersects = YES;
                break;
            }
        }
    }
    return intersects;
}

- (BOOL)moveToNearestPointInGroup:(NSArray *)dropPoints dropTolerance:(CGFloat)tolerance {
    return [MADSectionLayoutAttributes moveItem:self toNearestPointInGroup:dropPoints dropTolerance:tolerance];
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

- (BOOL)moveOnScreen {
    return [MADSectionLayoutAttributes moveItemOnScreen:self];
}

+ (BOOL)moveItemOnScreen:(MADSectionLayoutAttributes *)item {
    BOOL moved = NO;
    if (CGRectIsOffScreenWest(item.frame)) {
        item.frame = CGRectFlushLeft(item.frame);
        moved = YES;
    }
    if (CGRectIsOffScreenNorth(item.frame)) {
        item.frame = CGRectFlushTop(item.frame);
        moved = YES;
    }
    return moved;
}

- (void)placeItemGivenAttributes:(NSArray *)layoutAttributes {
    [MADSectionLayoutAttributes movePlacedItem:self intersectingItems:layoutAttributes];
}

+ (void)movePlacedItem:(MADSectionLayoutAttributes *)placedItem intersectingItems:(NSArray *)allItems {
    CGPoint dropPoint = CGPointZero;
    CGFloat distance = CGDistance(placedItem.frame.origin, dropPoint), tmpDistance;
    for (MADSectionLayoutAttributes *item in allItems) {
        if (placedItem.objectID != item.objectID) {
            NSArray *array = [item dropPoints];
            for (NSValue *v in array) {
                if ((tmpDistance = CGDistance(placedItem.frame.origin, v.CGPointValue)) < distance) {
                    dropPoint = v.CGPointValue;
                    distance = tmpDistance;
                }
            }
        }
    }
    placedItem.frame = CGRectMake(dropPoint.x, dropPoint.y, placedItem.frame.size.width, placedItem.frame.size.height);
}

- (NSArray *)dropPoints {
    return [MADSectionLayoutAttributes dropPointsOnAttribute:self];
}

+ (NSArray *)dropPointsOnAttribute:(MADSectionLayoutAttributes *)item {
    MTCorners corners = MTCornersMake(item.frame);
    NSArray *cornersArray = @[[NSValue valueWithCGPoint:corners.bottomLeft], [NSValue valueWithCGPoint:corners.topLeft], [NSValue valueWithCGPoint:corners.bottomRight] ,[NSValue valueWithCGPoint:corners.topRight]];
    return cornersArray;
}

/*
- (NSArray *)allValidLocationsInLayoutAttributes:(NSArray *)layoutAttributes {
    
}
*/
@end
