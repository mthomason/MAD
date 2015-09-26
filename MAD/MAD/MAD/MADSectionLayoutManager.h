//
//  MADReportDesignerSectionElementLayoutManager.h
//  MAD
//
//  Created by Michael Thomason on 11/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADReportDesignerSectionLayoutAttributes_h
#define Reports_MADReportDesignerSectionLayoutAttributes_h

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import <MAD/MADSectionLayoutAttributes.h>

@class MADSectionLayoutManager, RptqDocumentSection;

@interface MADSectionLayoutManager : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary *items;
@property (nonatomic, weak) id <MADReportDesignerSectionElementLayoutManagerDelegate>delegate;

- (instancetype)initWithDocumentSection:(RptqDocumentSection *)section;

- (void)addItem:(MADSectionLayoutAttributes *)item;
- (void)removeItemWithID:(NSManagedObjectID *)objectID;
- (CGSize)size;
- (void)layout;

- (void)positionItem:(MADSectionLayoutAttributes *)placedItem;

@end

#endif
