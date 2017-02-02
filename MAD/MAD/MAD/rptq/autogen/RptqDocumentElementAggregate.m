//
//  RptqDocumentElementAggregate+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementAggregate.h"
#import "RptqDocumentElementFormula.h"
#import "RptqQueryField.h"
@implementation RptqDocumentElementAggregate

@end

@implementation RptqDocumentElementAggregate (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementAggregate *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementAggregate"];
}

@dynamic groupNumber;
@dynamic groupType;
@dynamic functionType;
@dynamic aggregateField;
@dynamic aggregateFunction;

@end
