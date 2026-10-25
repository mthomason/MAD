//
//  MADSectionsLayout.h
//  MAD
//
//  Created by Michael on 5/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADSectionsLayout_h
#define MAD_MADSectionsLayout_h

#import <objc/NSObject.h>
#import <MAD/RptqStoreContext.h>

@class MADSectionLayout, MADSectionGroupLayout, NSSortDescriptor, NSNumber,
	NSArray<__covariant ObjectType>, NSDictionary;

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

	- (instancetype)initWithManagedObjectContext:(RptqStoreContext *)managedObjectContext
								   databaseClass:(Class)databaseClass;
	- (MADSectionLayout *)sectionLayoutAtIndex:(NSUInteger)index;

@end

#endif
