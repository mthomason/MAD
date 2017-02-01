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

@dynamic fieldLeftID;
@dynamic type;
@dynamic identifier;
@dynamic fieldRightID;
@dynamic tableleft;
@dynamic tableright;
@dynamic hasLeftField;
@dynamic hasRightField;
@dynamic inQuery;

@end
