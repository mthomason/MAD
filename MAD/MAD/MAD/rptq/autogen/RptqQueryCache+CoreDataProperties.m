//
//  RptqQueryCache+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryCache+CoreDataProperties.h"

@implementation RptqQueryCache (CoreDataProperties)

+ (NSFetchRequest<RptqQueryCache *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqQueryCache"];
}

@dynamic cacheDate;
@dynamic data;
@dynamic filename;
@dynamic identifier;
@dynamic hasQuery;

@end
