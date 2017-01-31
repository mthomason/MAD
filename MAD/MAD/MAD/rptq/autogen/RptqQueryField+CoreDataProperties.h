//
//  RptqQueryField+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryField+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqQueryField (CoreDataProperties)

+ (NSFetchRequest<RptqQueryField *> *)fetchRequest;

@property (nonatomic) int64_t identifier;
@property (nullable, nonatomic, retain) RptqDatabaseSchemaField *databaseSchemaField;
@property (nullable, nonatomic, retain) NSSet<RptqDocumentElementAggregate *> *inAggregateObject;
@property (nullable, nonatomic, retain) NSSet<RptqDocumentElementBarcode *> *inBarcodeField1;
@property (nullable, nonatomic, retain) NSSet<RptqDocumentElementBarcode *> *inBarcodeField2;
@property (nullable, nonatomic, retain) NSSet<RptqDocumentElementLabelDataField *> *inDataObject;
@property (nullable, nonatomic, retain) NSSet<RptqQueryGroup *> *inQueryGroup;
@property (nullable, nonatomic, retain) NSSet<RptqQueryLinks *> *inQueryLinkLeft;
@property (nullable, nonatomic, retain) NSSet<RptqQueryLinks *> *inQueryLinkRight;
@property (nullable, nonatomic, retain) NSSet<RptqQueryPredicate *> *inQueryPredicateLeft;
@property (nullable, nonatomic, retain) NSSet<RptqQueryPredicate *> *inQueryPredicateRight;
@property (nullable, nonatomic, retain) NSSet<RptqQuerySort *> *inQuerySort;
@property (nullable, nonatomic, retain) RptqQueryTable *inQueryTable;

@end

@interface RptqQueryField (CoreDataGeneratedAccessors)

- (void)addInAggregateObjectObject:(RptqDocumentElementAggregate *)value;
- (void)removeInAggregateObjectObject:(RptqDocumentElementAggregate *)value;
- (void)addInAggregateObject:(NSSet<RptqDocumentElementAggregate *> *)values;
- (void)removeInAggregateObject:(NSSet<RptqDocumentElementAggregate *> *)values;

- (void)addInBarcodeField1Object:(RptqDocumentElementBarcode *)value;
- (void)removeInBarcodeField1Object:(RptqDocumentElementBarcode *)value;
- (void)addInBarcodeField1:(NSSet<RptqDocumentElementBarcode *> *)values;
- (void)removeInBarcodeField1:(NSSet<RptqDocumentElementBarcode *> *)values;

- (void)addInBarcodeField2Object:(RptqDocumentElementBarcode *)value;
- (void)removeInBarcodeField2Object:(RptqDocumentElementBarcode *)value;
- (void)addInBarcodeField2:(NSSet<RptqDocumentElementBarcode *> *)values;
- (void)removeInBarcodeField2:(NSSet<RptqDocumentElementBarcode *> *)values;

- (void)addInDataObjectObject:(RptqDocumentElementLabelDataField *)value;
- (void)removeInDataObjectObject:(RptqDocumentElementLabelDataField *)value;
- (void)addInDataObject:(NSSet<RptqDocumentElementLabelDataField *> *)values;
- (void)removeInDataObject:(NSSet<RptqDocumentElementLabelDataField *> *)values;

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
