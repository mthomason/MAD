//
//  MADSectionsLayout.h
//  MAD
//
//  Created by Michael on 5/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADSectionsLayout_h
#define MAD_MADSectionsLayout_h

#import <objc/NSObject.h>

@class MADSectionLayout, MADSectionGroupLayout, NSSortDescriptor, NSManagedObjectContext, NSNumber,
    NSArray<__covariant ObjectType>, NSDictionary<__covariant KeyType, __covariant ObjectType>;

@interface MADSectionsLayout : NSObject

    @property (nonatomic, strong) MADSectionLayout *reportHeader;
    @property (nonatomic, strong) MADSectionLayout *pageHeader;
    @property (nonatomic, strong) NSArray <MADSectionGroupLayout *> *groupHeaders;
    @property (nonatomic, strong) MADSectionLayout *detail;
    @property (nonatomic, strong) NSArray <MADSectionGroupLayout *> *groupFooters;
    @property (nonatomic, strong) MADSectionLayout *pageFooter;
    @property (nonatomic, strong) MADSectionLayout *reportFooter;
    @property (nonatomic, strong) NSDictionary <NSNumber *, NSNumber *> *heightForSectionID;
    @property (nonatomic, readonly, strong) NSArray <NSSortDescriptor *> *groupSortDescriptors;
    @property (nonatomic, readonly, assign) NSUInteger count;

    - (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                   databaseClass:(Class)databaseClass;
    - (MADSectionLayout *)sectionLayoutAtIndex:(NSUInteger)index;

@end

#endif
