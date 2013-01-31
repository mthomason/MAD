//
//  RptqDocumentSection.h
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqDocumentObject, RptqQueryGroup;

@interface RptqDocumentSection : NSManagedObject

@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * marginBottom;
@property (nonatomic, retain) NSNumber * marginLeft;
@property (nonatomic, retain) NSNumber * marginRight;
@property (nonatomic, retain) NSNumber * marginTop;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * paddingBottom;
@property (nonatomic, retain) NSNumber * paddingLeft;
@property (nonatomic, retain) NSNumber * paddingRight;
@property (nonatomic, retain) NSNumber * paddingTop;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * visibility;
@property (nonatomic, retain) NSNumber * wrappingStyle;
@property (nonatomic, retain) NSOrderedSet *hasObjects;
@property (nonatomic, retain) RptqQueryGroup *inGroup;
@property (nonatomic, retain) RptqDocument *inReport;
@end

@interface RptqDocumentSection (CoreDataGeneratedAccessors)

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
