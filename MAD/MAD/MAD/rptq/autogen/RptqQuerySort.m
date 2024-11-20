//
//  RptqQuerySort+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqQuerySort.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"
@implementation RptqQuerySort

@end

@implementation RptqQuerySort (CoreDataProperties)

+ (NSFetchRequest<RptqQuerySort *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqQuerySort"];
}

@dynamic ascending;
@dynamic identifier;
@dynamic hasField;
@dynamic inQuery;

@end
