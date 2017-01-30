//
//  RptqDocumentElementFormula+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementFormula+CoreDataProperties.h"

@implementation RptqDocumentElementFormula (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementFormula *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementFormula"];
}

@dynamic functionScope;
@dynamic functionType;
@dynamic inputType;
@dynamic name;
@dynamic resultType;
@dynamic source;
@dynamic includedInAggregateObject;

@end
