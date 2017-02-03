//
//  RptqQueryField+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryField.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqDocumentElementBarcode.h"
#import "RptqDocumentElementLabelDataField.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqQueryPredicate.h"
#import "RptqQuerySort.h"
#import "RptqQueryTable.h"
@implementation RptqQueryField

@end

@implementation RptqQueryField (CoreDataProperties)

+ (NSFetchRequest<RptqQueryField *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqQueryField"];
}

@dynamic identifier;
@dynamic databaseSchemaField;
@dynamic inAggregateObject;
@dynamic inBarcodeField1;
@dynamic inBarcodeField2;
@dynamic inDataObject;
@dynamic inQueryGroup;
@dynamic inQueryLinkLeft;
@dynamic inQueryLinkRight;
@dynamic inQueryPredicateLeft;
@dynamic inQueryPredicateRight;
@dynamic inQuerySort;
@dynamic inQueryTable;

@end
