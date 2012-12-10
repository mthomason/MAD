//
//  RptqField.h
//  Reports
//
//  Created by Michael Thomason on 12/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObjectLabelDataField, RptqQuery, RptqQueryGroup, RptqQueryLinks, RptqQueryPredicate, RptqQuerySort, RptqRelationship, RptqTable;

@interface RptqField : NSManagedObject

@property (nonatomic, retain) NSString * datatype;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *inRelationships;
@property (nonatomic, retain) RptqTable *inTable;
@property (nonatomic, retain) NSSet *referenceedByDataObject;
@property (nonatomic, retain) NSSet *inQuery;
@property (nonatomic, retain) RptqQueryGroup *inQueryGroup;
@property (nonatomic, retain) RptqQueryLinks *inQueryLinkLeft;
@property (nonatomic, retain) RptqQueryLinks *inQueryLinkRight;
@property (nonatomic, retain) RptqQueryPredicate *inQueryPredicateLeft;
@property (nonatomic, retain) RptqQueryPredicate *inQueryPredicateRight;
@property (nonatomic, retain) RptqQuerySort *inQuerySort;
@end

@interface RptqField (CoreDataGeneratedAccessors)

- (void)addInRelationshipsObject:(RptqRelationship *)value;
- (void)removeInRelationshipsObject:(RptqRelationship *)value;
- (void)addInRelationships:(NSSet *)values;
- (void)removeInRelationships:(NSSet *)values;

- (void)addReferenceedByDataObjectObject:(RptqDocumentObjectLabelDataField *)value;
- (void)removeReferenceedByDataObjectObject:(RptqDocumentObjectLabelDataField *)value;
- (void)addReferenceedByDataObject:(NSSet *)values;
- (void)removeReferenceedByDataObject:(NSSet *)values;

- (void)addInQueryObject:(RptqQuery *)value;
- (void)removeInQueryObject:(RptqQuery *)value;
- (void)addInQuery:(NSSet *)values;
- (void)removeInQuery:(NSSet *)values;

@end
