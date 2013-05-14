//
//  RptqQueryField.m
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryField.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDocumentObjectAggregate.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqQueryPredicate.h"
#import "RptqQuerySort.h"
#import "RptqQueryTable.h"


@implementation RptqQueryField

@dynamic identifier;
@dynamic inQueryTable;
@dynamic databaseSchemaField;
@dynamic inDataObject;
@dynamic inAggregateObject;
@dynamic inQueryGroup;
@dynamic inQueryLinkLeft;
@dynamic inQueryLinkRight;
@dynamic inQueryPredicateLeft;
@dynamic inQueryPredicateRight;
@dynamic inQuerySort;

@end
