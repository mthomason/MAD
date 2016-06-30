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

@class NSMutableDictionary <KeyType, ObjectType>;
@class NSManagedObjectID;
@class MADSectionLayoutManager;
@class MADSectionLayoutAttributes;
@class RptqDocumentSection;

typedef struct CGSize CGSize;
typedef NSMutableDictionary <NSManagedObjectID *, MADSectionLayoutAttributes *>
                                                            MADSectionLayoutAttributesMutableMap;

@interface MADSectionLayoutManager : NSObject

    - (instancetype)initWithDocumentSection:(RptqDocumentSection *)section;

    @property (nonatomic, strong, readonly) MADSectionLayoutAttributesMutableMap *items;
    @property (readonly) CGSize size;

    - (void)addItem:(MADSectionLayoutAttributes *)item;
    - (void)removeItemWithID:(NSManagedObjectID *)objectID;
    - (void)layout;
    - (void)positionItem:(MADSectionLayoutAttributes *)placedItem;

@end

#endif
