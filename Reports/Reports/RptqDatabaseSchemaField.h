//
//  RptqDatabaseSchemaField.h
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDatabaseSchemaTable, RptqDocumentObjectLabelDataField, RptqQuery, RptqQueryGroup, RptqQueryLinks, RptqQueryPredicate, RptqQuerySort, RptqRelationship;

@interface RptqDatabaseSchemaField : NSManagedObject

@property (nonatomic, retain) NSNumber *dataType;
@property (nonatomic, retain) NSNumber *identifier;
@property (nonatomic, retain) NSNumber *dataTypeNative;

@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *dataTypeNativeDescription;

@property (nonatomic, retain) NSSet *inQuery;
@property (nonatomic, retain) NSSet *inQueryGroup;
@property (nonatomic, retain) NSSet *inQueryLinkLeft;
@property (nonatomic, retain) NSSet *inQueryLinkRight;
@property (nonatomic, retain) NSSet *inQueryPredicateLeft;
@property (nonatomic, retain) NSSet *inQueryPredicateRight;
@property (nonatomic, retain) NSSet *inQuerySort;
@property (nonatomic, retain) NSSet *inRelationships;
@property (nonatomic, retain) NSSet *referenceedByDataObject;

@property (nonatomic, retain) RptqDatabaseSchemaTable *inTable;

@end

@interface RptqDatabaseSchemaField (CoreDataGeneratedAccessors)

- (void)addInQueryObject:(RptqQuery *)value;
- (void)removeInQueryObject:(RptqQuery *)value;
- (void)addInQuery:(NSSet *)values;
- (void)removeInQuery:(NSSet *)values;

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

- (void)addInRelationshipsObject:(RptqRelationship *)value;
- (void)removeInRelationshipsObject:(RptqRelationship *)value;
- (void)addInRelationships:(NSSet *)values;
- (void)removeInRelationships:(NSSet *)values;

- (void)addReferenceedByDataObjectObject:(RptqDocumentObjectLabelDataField *)value;
- (void)removeReferenceedByDataObjectObject:(RptqDocumentObjectLabelDataField *)value;
- (void)addReferenceedByDataObject:(NSSet *)values;
- (void)removeReferenceedByDataObject:(NSSet *)values;

@end
