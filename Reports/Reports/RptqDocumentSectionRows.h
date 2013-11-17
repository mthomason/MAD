//
//  RptqDocumentSectionRows.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObject, RptqDocumentSection;

@interface RptqDocumentSectionRows : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * layoutHeight;
@property (nonatomic, retain) NSNumber * rowNumber;
@property (nonatomic, retain) NSOrderedSet *hasObjects;
@property (nonatomic, retain) RptqDocumentSection *inSection;
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
