//
//  RptqDocumentElementAggregate+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
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
