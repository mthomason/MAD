//
//  RptqDatabaseSchemaField.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
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

@dynamic dataType;
@dynamic identifier;
@dynamic label;
@dynamic name;
@dynamic dataTypeNative;
@dynamic dataTypeNativeDescription;
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
