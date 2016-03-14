//
//  RptqQueryField.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqQueryField_h
#define MAD_AutoGen_RptqQueryField_h

#import <CoreData/NSManagedObject.h>

@class RptqDatabaseSchemaField, RptqDocumentObjectAggregate, RptqDocumentObjectLabelDataField, RptqQueryGroup, RptqQueryLinks, RptqQueryPredicate, RptqQuerySort, RptqQueryTable;

@interface RptqQueryField : NSManagedObject

@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) RptqDatabaseSchemaField *databaseSchemaField;
@property (nonatomic, strong) NSSet *inAggregateObject;
@property (nonatomic, strong) NSManagedObject *inBarcodeField1;
@property (nonatomic, strong) NSManagedObject *inBarcodeField2;
@property (nonatomic, strong) NSSet *inDataObject;
@property (nonatomic, strong) NSSet *inQueryGroup;
@property (nonatomic, strong) NSSet *inQueryLinkLeft;
@property (nonatomic, strong) NSSet *inQueryLinkRight;
@property (nonatomic, strong) NSSet *inQueryPredicateLeft;
@property (nonatomic, strong) NSSet *inQueryPredicateRight;
@property (nonatomic, strong) NSSet *inQuerySort;
@property (nonatomic, strong) RptqQueryTable *inQueryTable;
@end

@interface RptqQueryField (CoreDataGeneratedAccessors)

- (void)addInAggregateObjectObject:(RptqDocumentObjectAggregate *)value;
- (void)removeInAggregateObjectObject:(RptqDocumentObjectAggregate *)value;
- (void)addInAggregateObject:(NSSet *)values;
- (void)removeInAggregateObject:(NSSet *)values;

- (void)addInDataObjectObject:(RptqDocumentObjectLabelDataField *)value;
- (void)removeInDataObjectObject:(RptqDocumentObjectLabelDataField *)value;
- (void)addInDataObject:(NSSet *)values;
- (void)removeInDataObject:(NSSet *)values;

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

#endif
