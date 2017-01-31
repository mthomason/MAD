//
//  RptqQueryGroup+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
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
