//
//  RptqDocumentSection.h
//  Reports
//
//  Created by Michael Thomason on 3/29/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqQueryGroup;

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
@property (nonatomic, retain) NSNumber * numberOfRows;
@property (nonatomic, retain) RptqQueryGroup *inGroup;
@property (nonatomic, retain) RptqDocument *inReport;
@property (nonatomic, retain) NSOrderedSet *hasRows;
@end

@interface RptqDocumentSection (CoreDataGeneratedAccessors)

- (void)insertObject:(NSManagedObject *)value inHasRowsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasRowsAtIndex:(NSUInteger)idx;
- (void)insertHasRows:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHasRowsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasRowsAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceHasRowsAtIndexes:(NSIndexSet *)indexes withHasRows:(NSArray *)values;
- (void)addHasRowsObject:(NSManagedObject *)value;
- (void)removeHasRowsObject:(NSManagedObject *)value;
- (void)addHasRows:(NSOrderedSet *)values;
- (void)removeHasRows:(NSOrderedSet *)values;
@end
