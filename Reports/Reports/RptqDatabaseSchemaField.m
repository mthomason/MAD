//
//  RptqDatabaseSchemaField.m
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqQuery.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqQueryPredicate.h"
#import "RptqQuerySort.h"
#import "RptqRelationship.h"


@implementation RptqDatabaseSchemaField

@dynamic datatype;
@dynamic identifier;
@dynamic label;
@dynamic name;
@dynamic inQuery;
@dynamic inQueryGroup;
@dynamic inQueryLinkLeft;
@dynamic inQueryLinkRight;
@dynamic inQueryPredicateLeft;
@dynamic inQueryPredicateRight;
@dynamic inQuerySort;
@dynamic inRelationships;
@dynamic inTable;
@dynamic referenceedByDataObject;

@end
