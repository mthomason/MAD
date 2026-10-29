//
//  MADReportDesignerSectionLayoutAttributes.h
//  MAD
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADSectionLayoutAttributes_h
#define Reports_MADSectionLayoutAttributes_h

#include <TargetConditionals.h>
#if defined(__APPLE__) && TARGET_OS_OSX
#import <AppKit/NSCollectionViewLayout.h>
typedef NSCollectionViewLayoutAttributes MADPlatformCollectionViewLayoutAttributes;
#else
#import <UIKit/UICollectionViewLayout.h>
typedef UICollectionViewLayoutAttributes MADPlatformCollectionViewLayoutAttributes;
#endif

@class MADSectionLayoutManager, NSArray <__covariant ObjectType>;

@interface MADSectionLayoutAttributes : MADPlatformCollectionViewLayoutAttributes
	<NSCopying>

	@property (nonatomic, assign) int64_t objectID;

	+ (instancetype)newSectionLayoutAttributesWithIndex:(NSIndexPath *)indexPath
											   objectID:(int64_t)objectID
												andRect:(CGRect)rect;
#if defined(__APPLE__) && TARGET_OS_OSX
	+ (instancetype)layoutAttributesForCellWithIndexPath:(NSIndexPath *)indexPath;
#endif

	- (void)placeItemGivenAttributes:(NSArray <MADSectionLayoutAttributes *> *)attributes;
	- (BOOL)intersectsAnItemInArray:(NSArray <MADSectionLayoutAttributes *> *)items;
	- (BOOL)validDropPoint:(CGPoint)dropPoint
		  givenPlacedItems:(NSArray <MADSectionLayoutAttributes *> *)placedItems;
	- (BOOL)moveOnScreen;
	- (NSArray <NSValue *> *)copyDropPointsHorizontal;
	- (NSArray <NSValue *> *)copyDropPoints;

@end

#endif
