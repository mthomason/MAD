//
//  MADReportDesignerSectionLayoutAttributes.h
//  MAD
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADSectionLayoutAttributes_h
#define Reports_MADSectionLayoutAttributes_h

#import <UIKit/UICollectionViewLayout.h>

@class MADSectionLayoutManager, NSArray <__covariant ObjectType>;

@interface MADSectionLayoutAttributes : UICollectionViewLayoutAttributes
	<NSCopying>

	@property (nonatomic, assign) int64_t objectID;

	+ (instancetype)newSectionLayoutAttributesWithIndex:(NSIndexPath *)indexPath
											   objectID:(int64_t)objectID
												andRect:(CGRect)rect;

	- (void)placeItemGivenAttributes:(NSArray <MADSectionLayoutAttributes *> *)attributes;
	- (BOOL)intersectsAnItemInArray:(NSArray <MADSectionLayoutAttributes *> *)items;
	- (BOOL)validDropPoint:(CGPoint)dropPoint
		  givenPlacedItems:(NSArray <MADSectionLayoutAttributes *> *)placedItems;
	- (BOOL)moveOnScreen;
	- (NSArray <NSValue *> *)copyDropPointsHorizontal;
	- (NSArray <NSValue *> *)copyDropPoints;

@end

#endif
