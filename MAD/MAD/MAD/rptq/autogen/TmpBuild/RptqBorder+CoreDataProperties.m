//
//  RptqBorder+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqBorder+CoreDataProperties.h"

@implementation RptqBorder (CoreDataProperties)

+ (NSFetchRequest<RptqBorder *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqBorder"];
}

@dynamic width;
@dynamic style;

@end
