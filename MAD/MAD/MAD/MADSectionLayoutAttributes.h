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
#import <CoreData/NSManagedObjectID.h>
#import <UIKit/UICollectionViewLayout.h>

@class MADSectionLayoutManager;

@interface MADSectionLayoutAttributes : UICollectionViewLayoutAttributes
    <NSCopying>
    
    + (instancetype)sectionLayoutAttributesWithIndex:(NSIndexPath *)indexPath objectID:(NSManagedObjectID *)objectID andRect:(CGRect)rect;
    @property (nonatomic, copy) NSManagedObjectID *objectID;

    - (BOOL)intersectsAnItemInArray:(NSArray *)items;
    - (BOOL)moveOnScreen;
    - (void)placeItemGivenAttributes:(NSArray *)layoutAttributes;
    - (BOOL)validDropPoint:(CGPoint)dropPoint givenPlacedItems:(NSArray *)placedItems;
    - (NSArray *)dropPointsHorizontal;
    - (NSArray *)dropPoints;

@end

#endif
