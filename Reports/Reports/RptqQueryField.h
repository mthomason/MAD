//
//  RptqQueryField.h
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaField, RptqDocumentObjectAggregate, RptqDocumentObjectLabelDataField, RptqQueryGroup, RptqQueryLinks, RptqQueryPredicate, RptqQuerySort, RptqQueryTable;

@interface RptqQueryField : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) RptqQueryTable *inQueryTable;
@property (nonatomic, retain) RptqDatabaseSchemaField *databaseSchemaField;
@property (nonatomic, retain) NSSet *inDataObject;
@property (nonatomic, retain) NSSet *inAggregateObject;
@property (nonatomic, retain) NSSet *inQueryGroup;
@property (nonatomic, retain) NSSet *inQueryLinkLeft;
@property (nonatomic, retain) NSSet *inQueryLinkRight;
@property (nonatomic, retain) NSSet *inQueryPredicateLeft;
@property (nonatomic, retain) NSSet *inQueryPredicateRight;
@property (nonatomic, retain) NSSet *inQuerySort;
@end

@interface RptqQueryField (CoreDataGeneratedAccessors)

- (void)addInDataObjectObject:(RptqDocumentObjectLabelDataField *)value;
- (void)removeInDataObjectObject:(RptqDocumentObjectLabelDataField *)value;
- (void)addInDataObject:(NSSet *)values;
- (void)removeInDataObject:(NSSet *)values;

- (void)addInAggregateObjectObject:(RptqDocumentObjectAggregate *)value;
- (void)removeInAggregateObjectObject:(RptqDocumentObjectAggregate *)value;
- (void)addInAggregateObject:(NSSet *)values;
- (void)removeInAggregateObject:(NSSet *)values;

- (void)addInQueryGroupObject:(RptqQueryGroup *)value;
- (void)removeInQueryGroupObject:(RptqQueryGroup *)value;
- (void)addInQueryGroup:(NSSet *)values;
- (void)removeInQueryGroup:(NSSet *)values;

- (void)addInQueryLinkLeftObject:(RptqQueryLinks *)value;
- (void)removeInQueryLinkLeftObject:(RptqQueryLinks *)value;
- (void)addInQueryLinkLeft:(NSSet *)values;
- (void)removeInQueryLinkLeft:(NSSet *)values;

- (void)addInQueryLinkRightObject:(RptqQueryLinks *)value;
- (void)removeInQueryLinkRightObject:(RptqQueryLinks *)value;
- (void)addInQueryLinkRight:(NSSet *)values;
- (void)removeInQueryLinkRight:(NSSet *)values;

- (void)addInQueryPredicateLeftObject:(RptqQueryPredicate *)value;
- (void)removeInQueryPredicateLeftObject:(RptqQueryPredicate *)value;
- (void)addInQueryPredicateLeft:(NSSet *)values;
- (void)removeInQueryPredicateLeft:(NSSet *)values;

- (void)addInQueryPredicateRightObject:(RptqQueryPredicate *)value;
- (void)removeInQueryPredicateRightObject:(RptqQueryPredicate *)value;
- (void)addInQueryPredicateRight:(NSSet *)values;
- (void)removeInQueryPredicateRight:(NSSet *)values;

- (void)addInQuerySortObject:(RptqQuerySort *)value;
- (void)removeInQuerySortObject:(RptqQuerySort *)value;
- (void)addInQuerySort:(NSSet *)values;
- (void)removeInQuerySort:(NSSet *)values;

@end
