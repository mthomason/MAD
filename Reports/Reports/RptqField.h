//
//  RptqField.h
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObjectLabelDataField, RptqRelationship, RptqTable;

@interface RptqField : NSManagedObject

@property (nonatomic, retain) NSString * datatype;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *inRelationships;
@property (nonatomic, retain) RptqTable *inTable;
@property (nonatomic, retain) NSSet *referenceedByDataObject;
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

@end
