//
//  RptqRect+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqRect+CoreDataProperties.h"

@implementation RptqRect (CoreDataProperties)

+ (NSFetchRequest<RptqRect *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqRect"];
}

@dynamic origin;
@dynamic size;

@end
