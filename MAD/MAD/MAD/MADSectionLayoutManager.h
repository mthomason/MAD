//
//  MADReportDesignerSectionElementLayoutManager.h
//  MAD
//
//  Created by Michael Thomason on 11/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADReportDesignerSectionLayoutAttributes_h
#define Reports_MADReportDesignerSectionLayoutAttributes_h

#import <Foundation/NSObject.h>
#import <MAD/MADSectionLayoutAttributes.h>

@class MADSectionLayoutManager, RptqDocumentSection, NSManagedObjectID;

    @interface MADSectionLayoutManager : NSObject

    @property (nonatomic, strong, readonly) NSMutableDictionary <__kindof NSManagedObjectID *, __kindof MADSectionLayoutAttributes *> *items;

    - (instancetype)initWithDocumentSection:(RptqDocumentSection *)section;

    - (void)addItem:(MADSectionLayoutAttributes *)item;
    - (void)removeItemWithID:(NSManagedObjectID *)objectID;
    - (CGSize)size;
    - (void)layout;

    - (void)positionItem:(MADSectionLayoutAttributes *)placedItem;

@end

#endif
