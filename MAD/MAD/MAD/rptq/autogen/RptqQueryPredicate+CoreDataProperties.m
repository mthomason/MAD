//
//  RptqQueryPredicate+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryPredicate+CoreDataProperties.h"

@implementation RptqQueryPredicate (CoreDataProperties)

+ (NSFetchRequest<RptqQueryPredicate *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqQueryPredicate"];
}

@dynamic comparson;
@dynamic leftFieldID;
@dynamic rightFieldID;
@dynamic identifier;
@dynamic hasLeftField;
@dynamic hasRightField;
@dynamic inQuery;

@end
