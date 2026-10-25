//
//  MADReportDesignerSectionLayoutAttributes.m
//  MAD
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADSectionLayoutAttributes.h"
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
	return [[NSArray alloc] initWithObjects:bottomRight, topRight, nil];
}

+ (NSArray <NSValue *> *)newArrayOfdropPointsOnAttribute:(MADSectionLayoutAttributes *)item {
	MADCorners corners = MTCornersMake(item.frame);
	NSValue *topLeft = [[NSValue alloc] initWithBytes: &corners.topLeft objCType: @encode(CGPoint)];
	NSValue *topRight = [[NSValue alloc] initWithBytes: &corners.topRight objCType: @encode(CGPoint)];
	NSValue *bottomLeft = [[NSValue alloc] initWithBytes: &corners.bottomLeft objCType: @encode(CGPoint)];
	NSValue *bottomRight = [[NSValue alloc] initWithBytes: &corners.bottomRight objCType: @encode(CGPoint)];
	return [[NSArray alloc] initWithObjects:topLeft, topRight, bottomLeft, bottomRight, nil];
}

+ (BOOL)item:(MADSectionLayoutAttributes *)item
		intersectsAnItem:(NSArray <MADSectionLayoutAttributes *> *)items {
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
	 intersectingItems:(NSArray <MADSectionLayoutAttributes *> *)allItems {

	CGPoint dropPoint = CGPointZero;
	double distance = MADDistance(placedItem.frame.origin, dropPoint);
	BOOL hasOtherItem = NO;
	for (MADSectionLayoutAttributes *item in allItems) {
		if (placedItem.objectID != item.objectID) {
			hasOtherItem = YES;

			NSArray *array = [item copyDropPoints];
			for (NSValue *v in array) {
				double tmpDistance = MADDistance(placedItem.frame.origin, v.CGPointValue);
				if (tmpDistance < distance) {
					dropPoint = v.CGPointValue;
					distance = tmpDistance;
				}

			}
		}
	}
	// With no other item to snap against, the origin is not a drop point: the item
	// stays where it was placed.
	if (!hasOtherItem) return;
	placedItem.frame = CGRectMake(dropPoint.x, dropPoint.y, placedItem.frame.size.width, placedItem.frame.size.height);
}

#pragma mark -
#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone {
	MADSectionLayoutAttributes *copy = [super copyWithZone:zone];
	copy.objectID = self.objectID;
	copy.frame = self.frame;
	return copy;
}

#pragma mark -
#pragma mark Convience Constructor

+ (instancetype)newSectionLayoutAttributesWithIndex:(NSIndexPath *)indexPath
										   objectID:(int64_t)objectID
											andRect:(CGRect)rect {
	MADSectionLayoutAttributes *instance = [self layoutAttributesForCellWithIndexPath:indexPath];
	instance.objectID = objectID;
	instance.frame = rect;
	return instance;
}

- (BOOL)intersectsAnItemInArray:(NSArray <MADSectionLayoutAttributes *> *)items {
	return [MADSectionLayoutAttributes item:self intersectsAnItem:items];
}

- (BOOL)moveOnScreen {
	return [MADSectionLayoutAttributes moveItemOnScreen:self];
}

- (void)placeItemGivenAttributes:(NSArray <MADSectionLayoutAttributes *> *)layoutAttributes {
	[MADSectionLayoutAttributes movePlacedItem:self intersectingItems:layoutAttributes];
}

- (BOOL)validDropPoint:(CGPoint)dropPoint
	  givenPlacedItems:(NSArray <MADSectionLayoutAttributes *> *)placedItems {

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
	return [NSString stringWithFormat:@"%lld\t\t%@", self.objectID, NSStringFromCGRect(self.frame)];
}

@end
