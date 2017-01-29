//
//  RptqDocumentObjectAggregate+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentObjectAggregate+CoreDataProperties.h"

@implementation RptqDocumentObjectAggregate (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectAggregate *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentObjectAggregate"];
}

@dynamic function;
@dynamic groupNumber;
@dynamic groupType;
@dynamic aggregateField;
@dynamic aggregateFunction;
@dynamic parentObject;

@end
