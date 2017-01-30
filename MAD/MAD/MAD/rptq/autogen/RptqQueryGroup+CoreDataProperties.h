//
//  RptqQueryGroup+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MAD.RptqQueryGroup+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryGroup (CoreDataProperties)

+ (NSFetchRequest<RptqQueryGroup *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, copy) NSNumber *sort;
@property (nullable, nonatomic, copy) NSNumber *weight;
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
