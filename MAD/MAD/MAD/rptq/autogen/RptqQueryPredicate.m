//
//  RptqQueryPredicate+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqQueryPredicate.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"
@implementation RptqQueryPredicate

@end

@implementation RptqQueryPredicate (CoreDataProperties)

+ (NSFetchRequest<RptqQueryPredicate *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqQueryPredicate"];
}

@dynamic comparson;
@dynamic leftFieldID;
@dynamic rigthFieldID;
@dynamic identifier;
@dynamic hasLeftField;
@dynamic hasRightField;
@dynamic inQuery;

@end
