//
//  RptqSize+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqSize+CoreDataProperties.h"

@implementation RptqSize (CoreDataProperties)

+ (NSFetchRequest<RptqSize *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqSize"];
}

@dynamic width;
@dynamic height;

@end
