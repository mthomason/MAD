//
//  RptqQueryField+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqQueryField+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryField (CoreDataProperties)

+ (NSFetchRequest<RptqQueryField *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, retain) RptqDatabaseSchemaField *databaseSchemaField;
@property (nullable, nonatomic, retain) NSSet<RptqDocumentObjectAggregate *> *inAggregateObject;
@property (nullable, nonatomic, retain) NSSet<RptqDocumentObjectBarcode *> *inBarcodeField1;
@property (nullable, nonatomic, retain) NSSet<RptqDocumentObjectBarcode *> *inBarcodeField2;
@property (nullable, nonatomic, retain) NSSet<RptqDocumentObjectLabelDataField *> *inDataObject;
@property (nullable, nonatomic, retain) NSSet<RptqQueryGroup *> *inQueryGroup;
@property (nullable, nonatomic, retain) NSSet<RptqQueryLinks *> *inQueryLinkLeft;
@property (nullable, nonatomic, retain) NSSet<RptqQueryLinks *> *inQueryLinkRight;
@property (nullable, nonatomic, retain) NSSet<RptqQueryPredicate *> *inQueryPredicateLeft;
@property (nullable, nonatomic, retain) NSSet<RptqQueryPredicate *> *inQueryPredicateRight;
@property (nullable, nonatomic, retain) NSSet<RptqQuerySort *> *inQuerySort;
@property (nullable, nonatomic, retain) RptqQueryTable *inQueryTable;

@end

@interface RptqQueryField (CoreDataGeneratedAccessors)

- (void)addInAggregateObjectObject:(RptqDocumentObjectAggregate *)value;
- (void)removeInAggregateObjectObject:(RptqDocumentObjectAggregate *)value;
- (void)addInAggregateObject:(NSSet<RptqDocumentObjectAggregate *> *)values;
- (void)removeInAggregateObject:(NSSet<RptqDocumentObjectAggregate *> *)values;

- (void)addInBarcodeField1Object:(RptqDocumentObjectBarcode *)value;
- (void)removeInBarcodeField1Object:(RptqDocumentObjectBarcode *)value;
- (void)addInBarcodeField1:(NSSet<RptqDocumentObjectBarcode *> *)values;
- (void)removeInBarcodeField1:(NSSet<RptqDocumentObjectBarcode *> *)values;

- (void)addInBarcodeField2Object:(RptqDocumentObjectBarcode *)value;
- (void)removeInBarcodeField2Object:(RptqDocumentObjectBarcode *)value;
- (void)addInBarcodeField2:(NSSet<RptqDocumentObjectBarcode *> *)values;
- (void)removeInBarcodeField2:(NSSet<RptqDocumentObjectBarcode *> *)values;

- (void)addInDataObjectObject:(RptqDocumentObjectLabelDataField *)value;
- (void)removeInDataObjectObject:(RptqDocumentObjectLabelDataField *)value;
- (void)addInDataObject:(NSSet<RptqDocumentObjectLabelDataField *> *)values;
- (void)removeInDataObject:(NSSet<RptqDocumentObjectLabelDataField *> *)values;

- (void)addInQueryGroupObject:(RptqQueryGroup *)value;
- (void)removeInQueryGroupObject:(RptqQueryGroup *)value;
- (void)addInQueryGroup:(NSSet<RptqQueryGroup *> *)values;
- (void)removeInQueryGroup:(NSSet<RptqQueryGroup *> *)values;

- (void)addInQueryLinkLeftObject:(RptqQueryLinks *)value;
- (void)removeInQueryLinkLeftObject:(RptqQueryLinks *)value;
- (void)addInQueryLinkLeft:(NSSet<RptqQueryLinks *> *)values;
- (void)removeInQueryLinkLeft:(NSSet<RptqQueryLinks *> *)values;

- (void)addInQueryLinkRightObject:(RptqQueryLinks *)value;
- (void)removeInQueryLinkRightObject:(RptqQueryLinks *)value;
- (void)addInQueryLinkRight:(NSSet<RptqQueryLinks *> *)values;
- (void)removeInQueryLinkRight:(NSSet<RptqQueryLinks *> *)values;

- (void)addInQueryPredicateLeftObject:(RptqQueryPredicate *)value;
- (void)removeInQueryPredicateLeftObject:(RptqQueryPredicate *)value;
- (void)addInQueryPredicateLeft:(NSSet<RptqQueryPredicate *> *)values;
- (void)removeInQueryPredicateLeft:(NSSet<RptqQueryPredicate *> *)values;

- (void)addInQueryPredicateRightObject:(RptqQueryPredicate *)value;
- (void)removeInQueryPredicateRightObject:(RptqQueryPredicate *)value;
- (void)addInQueryPredicateRight:(NSSet<RptqQueryPredicate *> *)values;
- (void)removeInQueryPredicateRight:(NSSet<RptqQueryPredicate *> *)values;

- (void)addInQuerySortObject:(RptqQuerySort *)value;
- (void)removeInQuerySortObject:(RptqQuerySort *)value;
- (void)addInQuerySort:(NSSet<RptqQuerySort *> *)values;
- (void)removeInQuerySort:(NSSet<RptqQuerySort *> *)values;

@end

NS_ASSUME_NONNULL_END
