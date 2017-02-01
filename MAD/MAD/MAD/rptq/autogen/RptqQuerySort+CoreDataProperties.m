//
//  RptqQuerySort+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQuerySort+CoreDataProperties.h"

@implementation RptqQuerySort (CoreDataProperties)

+ (NSFetchRequest<RptqQuerySort *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqQuerySort"];
}

@dynamic ascending;
@dynamic identifier;
@dynamic hasField;
@dynamic inQuery;

@end
