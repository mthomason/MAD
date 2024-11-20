//
//  RptqDocumentSectionRows.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDocumentSectionRows_NSManagedObject_h
#define MAD_RptqDocumentSectionRows_NSManagedObject_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

@class RptqDocumentElement, RptqDocumentSection;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentSectionRows : NSManagedObject

@end

@interface RptqDocumentSectionRows (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentSectionRows *> *)fetchRequest;

@property (nonatomic) double layoutHeight;
@property (nonatomic) int32_t rowNumber;
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
