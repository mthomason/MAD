//
//  MADReportDesignerSectionLayoutAttributes.m
//  MAD
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADSectionLayoutAttributes.h"
#import <MADCocoaExtensions/CGGeometry+Extras.h>

@implementation MADSectionLayoutAttributes

- (id)copyWithZone:(nullable NSZone *)zone {
    NSIndexPath *path = [self.indexPath copyWithZone:zone];
    MADSectionLayoutAttributes *copy = [[self class] layoutAttributesForCellWithIndexPath:path];
    copy.objectID = [self.objectID copyWithZone:zone];
    copy.frame = self.frame;
    return copy;
}

+ (instancetype)sectionLayoutAttributesWithIndex:(NSIndexPath *)indexPath objectID:(NSManagedObjectID *)objectID andRect:(CGRect)rect {
    MADSectionLayoutAttributes *instance = [self layoutAttributesForCellWithIndexPath:indexPath];
    NSManagedObjectID *managedObjectID = objectID.copy;
    instance.objectID = managedObjectID;
    instance.frame = rect;
    return instance;
}

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

- (BOOL)validDropPoint:(CGPoint)dropPoint givenPlacedItems:(NSArray *)placedItems {
    BOOL valid = YES;
    for (MADSectionLayoutAttributes *placedItem in placedItems) {
    
        if (CGRectIntersectsRect(CGRectMake(dropPoint.x, dropPoint.y, self.frame.size.width, self.frame.size.height), placedItem.frame)) {
            valid = NO;
            break;
        }
    
    }
    return valid;
}

- (NSArray *)dropPoints {
    return [MADSectionLayoutAttributes dropPointsOnAttribute:self];
}

- (NSArray *)dropPointsHorizontal {
    return [MADSectionLayoutAttributes dropPointsHorizontalOnAttribute:self];
}

+ (NSArray *)dropPointsHorizontalOnAttribute:(MADSectionLayoutAttributes *)item {
    MTCorners corners = MTCornersMake(item.frame);
    NSArray *cornersArray = @[[NSValue valueWithCGPoint:corners.bottomRight] ,[NSValue valueWithCGPoint:corners.topRight]];
    return cornersArray;
}

+ (NSArray *)dropPointsOnAttribute:(MADSectionLayoutAttributes *)item {
    MTCorners corners = MTCornersMake(item.frame);
    NSArray *cornersArray = @[[NSValue valueWithCGPoint:corners.bottomLeft], [NSValue valueWithCGPoint:corners.topLeft], [NSValue valueWithCGPoint:corners.bottomRight] ,[NSValue valueWithCGPoint:corners.topRight]];
    return cornersArray;
}

- (id)debugQuickLookObject {
    return [NSString stringWithFormat:@"%@\t\t%@", self.objectID, NSStringFromCGRect(self.frame)];
}

@end
