//
//  RptqDocumentSectionRows+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentSectionRows+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentSectionRows (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentSectionRows *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *layoutHeight;
@property (nullable, nonatomic, copy) NSNumber *rowNumber;
@property (nullable, nonatomic, retain) NSOrderedSet<RptqDocumentObject *> *hasObjects;
@property (nullable, nonatomic, retain) RptqDocumentSection *inSection;

@end

@interface RptqDocumentSectionRows (CoreDataGeneratedAccessors)

- (void)insertObject:(RptqDocumentObject *)value inHasObjectsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasObjectsAtIndex:(NSUInteger)idx;
- (void)insertHasObjects:(NSArray<RptqDocumentObject *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHasObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasObjectsAtIndex:(NSUInteger)idx withObject:(RptqDocumentObject *)value;
- (void)replaceHasObjectsAtIndexes:(NSIndexSet *)indexes withHasObjects:(NSArray<RptqDocumentObject *> *)values;
- (void)addHasObjectsObject:(RptqDocumentObject *)value;
- (void)removeHasObjectsObject:(RptqDocumentObject *)value;
- (void)addHasObjects:(NSOrderedSet<RptqDocumentObject *> *)values;
- (void)removeHasObjects:(NSOrderedSet<RptqDocumentObject *> *)values;

@end

NS_ASSUME_NONNULL_END
