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

typedef NSMutableDictionary <NSManagedObjectID *, MADSectionLayoutAttributes *>
                                                        MADSectionLayoutAttributesMutableMap;

@class MADSectionLayoutManager, RptqDocumentSection, NSManagedObjectID;

@interface MADSectionLayoutManager : NSObject

    @property (nonatomic, strong, readonly) MADSectionLayoutAttributesMutableMap *items;
    @property (readonly) CGSize size;

    - (instancetype)initWithDocumentSection:(RptqDocumentSection *)section;
    - (void)addItem:(MADSectionLayoutAttributes *)item;
    - (void)removeItemWithID:(NSManagedObjectID *)objectID;
    - (void)layout;
    - (void)positionItem:(MADSectionLayoutAttributes *)placedItem;

@end

#endif
