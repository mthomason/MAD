//
//  RptqDocumentSectionRows.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject, RptqDocumentSection;

@interface RptqDocumentSectionRows : NSManagedObject

@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSNumber * layoutHeight;
@property (nonatomic, strong) NSNumber * rowNumber;
@property (nonatomic, strong) NSOrderedSet *hasObjects;
@property (nonatomic, strong) RptqDocumentSection *inSection;
@end

@interface RptqDocumentSectionRows (CoreDataGeneratedAccessors)

- (void)insertObject:(RptqDocumentObject *)value inHasObjectsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasObjectsAtIndex:(NSUInteger)idx;
- (void)insertHasObjects:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHasObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasObjectsAtIndex:(NSUInteger)idx withObject:(RptqDocumentObject *)value;
- (void)replaceHasObjectsAtIndexes:(NSIndexSet *)indexes withHasObjects:(NSArray *)values;
- (void)addHasObjectsObject:(RptqDocumentObject *)value;
- (void)removeHasObjectsObject:(RptqDocumentObject *)value;
- (void)addHasObjects:(NSOrderedSet *)values;
- (void)removeHasObjects:(NSOrderedSet *)values;
@end
