//
//  RptqDocumentObjectFormula+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentObjectFormula+CoreDataProperties.h"

@implementation RptqDocumentObjectFormula (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectFormula *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentObjectFormula"];
}

@dynamic functionScope;
@dynamic functionType;
@dynamic inputType;
@dynamic name;
@dynamic resultType;
@dynamic source;
@dynamic includedInAggregateObject;
@dynamic parentObjectFormula;

@end
