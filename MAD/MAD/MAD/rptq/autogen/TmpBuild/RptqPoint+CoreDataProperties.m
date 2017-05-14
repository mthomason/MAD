//
//  RptqPoint+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqPoint+CoreDataProperties.h"

@implementation RptqPoint (CoreDataProperties)

+ (NSFetchRequest<RptqPoint *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqPoint"];
}

@dynamic x;
@dynamic y;

@end
