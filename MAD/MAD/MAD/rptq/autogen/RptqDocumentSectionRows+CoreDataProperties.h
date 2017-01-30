//
//  RptqDocumentSectionRows+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentSectionRows_CoreDataProperties_h
#define MAD_RptqDocumentSectionRows_CoreDataProperties_h

#import "RptqDocumentSectionRows+CoreDataClass.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentSectionRows (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentSectionRows *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *layoutHeight;
@property (nullable, nonatomic, copy) NSNumber *rowNumber;
@property (nullable, nonatomic, retain) NSOrderedSet<RptqDocumentElement *> *hasObjects;
@property (nullable, nonatomic, retain) RptqDocumentSection *inSection;

@end

@interface RptqDocumentSectionRows (CoreDataGeneratedAccessors)

- (void)insertObject:(RptqDocumentElement *)value inHasObjectsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasObjectsAtIndex:(NSUInteger)idx;
- (void)insertHasObjects:(NSArray<RptqDocumentElement *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHasObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasObjectsAtIndex:(NSUInteger)idx withObject:(RptqDocumentElement *)value;
- (void)replaceHasObjectsAtIndexes:(NSIndexSet *)indexes withHasObjects:(NSArray<RptqDocumentElement *> *)values;
- (void)addHasObjectsObject:(RptqDocumentElement *)value;
- (void)removeHasObjectsObject:(RptqDocumentElement *)value;
- (void)addHasObjects:(NSOrderedSet<RptqDocumentElement *> *)values;
- (void)removeHasObjects:(NSOrderedSet<RptqDocumentElement *> *)values;

@end

NS_ASSUME_NONNULL_END

#endif
