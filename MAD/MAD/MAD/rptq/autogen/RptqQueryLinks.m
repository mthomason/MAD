//
//  RptqQueryLinks+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryLinks.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"
@implementation RptqQueryLinks

@end

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

