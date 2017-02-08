//
//  MADReportDesignerSectionLayoutAttributes.m
//  MAD
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADSectionLayoutAttributes.h"
#import <CoreData/NSManagedObjectID.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

@implementation MADSectionLayoutAttributes

#pragma mark -
#pragma mark Static Functions

+ (NSArray <NSValue *> *)newArrayOfDropPointsHorizontalOnAttribute:(MADSectionLayoutAttributes *)item {
    MADCorners corners = MTCornersMake(item.frame);
    NSValue *bottomRight = [[NSValue alloc] initWithBytes: &corners.bottomRight
                                                 objCType: @encode(CGPoint)];
    NSValue *topRight = [[NSValue alloc] initWithBytes: &corners.topRight
                                              objCType: @encode(CGPoint)];
    NSArray *cornersArray = [[NSArray alloc] initWithObjects:bottomRight, topRight, nil];
    return cornersArray;
}

+ (NSArray <NSValue *> *)newArrayOfdropPointsOnAttribute:(MADSectionLayoutAttributes *)item {
    MADCorners corners = MTCornersMake(item.frame);
    
    NSValue *topLeft = [[NSValue alloc] initWithBytes: &corners.topLeft
                                             objCType: @encode(CGPoint)],
            *topRight = [[NSValue alloc] initWithBytes: &corners.topRight
                                              objCType: @encode(CGPoint)],
            *bottomLeft = [[NSValue alloc] initWithBytes: &corners.bottomLeft
                                                objCType: @encode(CGPoint)],
            *bottomRight = [[NSValue alloc] initWithBytes: &corners.bottomRight
                                                 objCType: @encode(CGPoint)];
    NSArray *result = [[NSArray alloc] initWithObjects:topLeft, topRight,
                                                       bottomLeft, bottomRight, nil];
    return result;
}

+ (BOOL)item:(MADSectionLayoutAttributes *)item
        intersectsAnItem:(NSArray <__kindof MADSectionLayoutAttributes *> *)items {
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

+ (void)movePlacedItem:(MADSectionLayoutAttributes *)placedItem
     intersectingItems:(NSArray <__kindof MADSectionLayoutAttributes *> *)allItems {
    
    CGPoint dropPoint = CGPointZero;
    double distance = MADDistance(placedItem.frame.origin, dropPoint),
           tmpDistance;
    for (MADSectionLayoutAttributes *item in allItems) {
        if (placedItem.objectID != item.objectID) {
            
            NSArray *array = [item copyDropPoints];
            for (NSValue *v in array) {
                tmpDistance = MADDistance(placedItem.frame.origin, v.CGPointValue);
                if (tmpDistance < distance) {
                    dropPoint = v.CGPointValue;
                    distance = tmpDistance;
                }
            
            }
        }
    }
    placedItem.frame = CGRectMake(dropPoint.x, dropPoint.y,
                                  placedItem.frame.size.width, placedItem.frame.size.height);
}

#pragma mark -
#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
    MADSectionLayoutAttributes *copy = [super copyWithZone:zone];
    copy.objectID = [self.objectID copyWithZone:zone];
    copy.frame = self.frame;
    return copy;
}

#pragma mark -
#pragma mark Convience Constructor

+ (instancetype)newSectionLayoutAttributesWithIndex:(NSIndexPath *)indexPath
                                           objectID:(NSNumber *)objectID
                                            andRect:(CGRect)rect {
    MADSectionLayoutAttributes *instance = [self layoutAttributesForCellWithIndexPath:indexPath];
    instance.objectID = objectID.copy;
    instance.frame = rect;
    return instance;
}

- (BOOL)intersectsAnItemInArray:(NSArray <__kindof MADSectionLayoutAttributes *> *)items {
    return [MADSectionLayoutAttributes item:self intersectsAnItem:items];
}

- (BOOL)moveOnScreen {
    return [MADSectionLayoutAttributes moveItemOnScreen:self];
}

- (void)placeItemGivenAttributes:(NSArray <__kindof MADSectionLayoutAttributes *> *)layoutAttributes {
    [MADSectionLayoutAttributes movePlacedItem:self intersectingItems:layoutAttributes];
}

- (BOOL)validDropPoint:(CGPoint)dropPoint
      givenPlacedItems:(NSArray <__kindof MADSectionLayoutAttributes *> *)placedItems {

    BOOL valid = YES;
    for (MADSectionLayoutAttributes *placedItem in placedItems) {
        CGRect drop = CGRectMake(dropPoint.x, dropPoint.y,
                              self.frame.size.width, self.frame.size.height);
        
        if (CGRectIntersectsRect(drop, placedItem.frame)) {
            valid = NO;
            break;
        }
        
    }
    return valid;
}

- (NSArray <NSValue *> *)copyDropPoints {
    return [MADSectionLayoutAttributes newArrayOfdropPointsOnAttribute:self];
}

- (NSArray <NSValue *> *)copyDropPointsHorizontal {
    return [MADSectionLayoutAttributes newArrayOfDropPointsHorizontalOnAttribute:self];
}

- (id)debugQuickLookObject {
    return [NSString stringWithFormat:@"%@\t\t%@", self.objectID, NSStringFromCGRect(self.frame)];
}

@end
