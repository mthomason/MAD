//
//  RptqField.m
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqField.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqQuery.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqQueryPredicate.h"
#import "RptqQuerySort.h"
#import "RptqRelationship.h"
#import "RptqTable.h"


@implementation RptqField

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
