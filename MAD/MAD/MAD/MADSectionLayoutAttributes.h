//
//  MADReportDesignerSectionLayoutAttributes.h
//  MAD
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class MADSectionLayoutManager;
@protocol MADReportDesignerSectionElementLayoutManagerDelegate;

@interface MADSectionLayoutAttributes : UICollectionViewLayoutAttributes

    @property (nonatomic, assign) NSManagedObjectID *objectID;

    - (BOOL)intersectsAnItemInArray:(NSArray *)items;
    - (BOOL)moveToNearestPointInGroup:(NSArray *)dropPoints dropTolerance:(CGFloat)tolerance;
    - (BOOL)moveOnScreen;
    - (void)placeItemGivenAttributes:(NSArray *)layoutAttributes;
    - (NSArray *)dropPoints;

@end

@protocol MADReportDesignerSectionElementLayoutManagerDelegate <NSObject>

    - (void)layoutManager:(MADSectionLayoutManager *)layoutManager itemNeedsUpdate:(MADSectionLayoutAttributes *)item;

@end
