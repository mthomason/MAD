//
//  MADReportDesignerSectionLayoutAttributes.h
//  MAD
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSArray.h>
#import <CoreGraphics/CGGeometry.h>
#import <CoreData/NSManagedObjectID.h>
#import <UIKit/UICollectionViewLayout.h>

@class MADSectionLayoutManager;

@interface MADSectionLayoutAttributes : UICollectionViewLayoutAttributes

    - (instancetype)initWithIndexPath:(NSIndexPath *)indexPath objectID:(NSManagedObjectID *)objectID
                              andRect:(CGRect)rect;
    @property (nonatomic, copy) NSManagedObjectID *objectID;

    - (BOOL)intersectsAnItemInArray:(NSArray *)items;
    - (BOOL)moveOnScreen;
    - (void)placeItemGivenAttributes:(NSArray *)layoutAttributes;
    - (BOOL)validDropPoint:(CGPoint)dropPoint givenPlacedItems:(NSArray *)placedItems;
    - (NSArray *)dropPointsHorizontal;
    - (NSArray *)dropPoints;

@end
