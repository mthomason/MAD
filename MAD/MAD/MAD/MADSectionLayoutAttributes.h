//
//  MADReportDesignerSectionLayoutAttributes.h
//  MAD
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADSectionLayoutAttributes_h
#define Reports_MADSectionLayoutAttributes_h

#import <Foundation/NSArray.h>
#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UICollectionViewLayout.h>

@class MADSectionLayoutManager;
@class NSManagedObjectID;

@interface MADSectionLayoutAttributes : UICollectionViewLayoutAttributes
    <NSCopying>

    @property (nonatomic, copy) NSManagedObjectID *objectID;

    + (instancetype)newSectionLayoutAttributesWithIndex:(NSIndexPath *)indexPath
                                               objectID:(NSManagedObjectID *)objectID
                                                andRect:(CGRect)rect;

    - (void)placeItemGivenAttributes:(NSArray <__kindof MADSectionLayoutAttributes *> *)layoutAttributes;
    - (bool)intersectsAnItemInArray:(NSArray <__kindof MADSectionLayoutAttributes *> *)items;
    - (bool)validDropPoint:(CGPoint)dropPoint givenPlacedItems:(NSArray <__kindof MADSectionLayoutAttributes *> *)placedItems;
    - (bool)moveOnScreen;
    - (NSArray <NSValue *> *)copyDropPointsHorizontal;
    - (NSArray <NSValue *> *)copyDropPoints;

@end

#endif
