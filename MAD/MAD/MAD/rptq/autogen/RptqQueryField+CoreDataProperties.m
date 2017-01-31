//
//  RptqQueryField+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryField+CoreDataProperties.h"

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
