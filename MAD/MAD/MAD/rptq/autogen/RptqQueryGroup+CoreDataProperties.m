//
//  RptqQueryGroup+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqQueryGroup+CoreDataProperties.h"

@implementation RptqQueryGroup (CoreDataProperties)

+ (NSFetchRequest<RptqQueryGroup *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqQueryGroup"];
}

@dynamic identifier;
@dynamic sort;
@dynamic weight;
@dynamic hasField;
@dynamic hasSection;
@dynamic inQuery;

@end
