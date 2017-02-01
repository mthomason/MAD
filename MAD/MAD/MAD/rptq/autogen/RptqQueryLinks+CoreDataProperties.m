//
//  RptqQueryLinks+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryLinks+CoreDataProperties.h"

@implementation RptqQueryLinks (CoreDataProperties)

+ (NSFetchRequest<RptqQueryLinks *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqQueryLinks"];
}

@dynamic identifier;
@dynamic type;
@dynamic fieldLeftID;
@dynamic tableLeftID;
@dynamic fieldRightID;
@dynamic tableRightID;
@dynamic hasLeftField;
@dynamic hasRightField;
@dynamic inQuery;

@end
