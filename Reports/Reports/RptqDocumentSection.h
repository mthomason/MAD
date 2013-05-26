//
//  RptqDocumentSection.h
//  Reports
//
//  Created by Michael Thomason on 5/26/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocument, RptqDocumentSectionRows, RptqQueryGroup;

@interface RptqDocumentSection : NSManagedObject

@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * marginBottom;
@property (nonatomic, retain) NSNumber * marginLeft;
@property (nonatomic, retain) NSNumber * marginRight;
@property (nonatomic, retain) NSNumber * marginTop;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * numberOfRows;
@property (nonatomic, retain) NSNumber * paddingBottom;
@property (nonatomic, retain) NSNumber * paddingLeft;
@property (nonatomic, retain) NSNumber * paddingRight;
@property (nonatomic, retain) NSNumber * paddingTop;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * visibility;
@property (nonatomic, retain) NSNumber * wrappingStyle;
@property (nonatomic, retain) NSNumber * layoutHeight;
@property (nonatomic, retain) NSOrderedSet *hasRows;
@property (nonatomic, retain) RptqQueryGroup *inGroup;
@property (nonatomic, retain) RptqDocument *inReport;
@end

@interface RptqDocumentSection (CoreDataGeneratedAccessors)

- (void)insertObject:(RptqDocumentSectionRows *)value inHasRowsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromHasRowsAtIndex:(NSUInteger)idx;
- (void)insertHasRows:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeHasRowsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInHasRowsAtIndex:(NSUInteger)idx withObject:(RptqDocumentSectionRows *)value;
- (void)replaceHasRowsAtIndexes:(NSIndexSet *)indexes withHasRows:(NSArray *)values;
- (void)addHasRowsObject:(RptqDocumentSectionRows *)value;
- (void)removeHasRowsObject:(RptqDocumentSectionRows *)value;
- (void)addHasRows:(NSOrderedSet *)values;
- (void)removeHasRows:(NSOrderedSet *)values;
@end
