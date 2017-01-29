//
//  RptqDocumentElementAggregate+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentElementAggregate+CoreDataProperties.h"

@implementation RptqDocumentElementAggregate (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementAggregate *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementAggregate"];
}

@dynamic function;
@dynamic groupNumber;
@dynamic groupType;
@dynamic aggregateField;
@dynamic aggregateFunction;

@end
