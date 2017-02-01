//
//  RptqQueryGroup+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqQueryGroup_CoreDataProperties_h
#define MAD_RptqQueryGroup_CoreDataProperties_h

#import "RptqQueryGroup.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryGroup (CoreDataProperties)

+ (NSFetchRequest<RptqQueryGroup *> *)fetchRequest;

@property (nonatomic) int64_t identifier;
@property (nonatomic) int32_t sort;
@property (nonatomic) int16_t weight;
@property (nullable, nonatomic, retain) RptqQueryField *hasField;
@property (nullable, nonatomic, retain) NSSet<RptqDocumentSection *> *hasSection;
@property (nullable, nonatomic, retain) RptqQuery *inQuery;

@end

@interface RptqQueryGroup (CoreDataGeneratedAccessors)

- (void)addHasSectionObject:(RptqDocumentSection *)value;
- (void)removeHasSectionObject:(RptqDocumentSection *)value;
- (void)addHasSection:(NSSet<RptqDocumentSection *> *)values;
- (void)removeHasSection:(NSSet<RptqDocumentSection *> *)values;

@end

NS_ASSUME_NONNULL_END

#endif
