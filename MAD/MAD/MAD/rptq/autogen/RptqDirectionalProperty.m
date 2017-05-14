//
//  RptqDirectionalProperty+CoreDataClass.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDirectionalProperty.h"

@implementation RptqDirectionalProperty

@end

@implementation RptqDirectionalProperty (CoreDataProperties)

+ (NSFetchRequest<RptqDirectionalProperty *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDirectionalProperty"];
}

@dynamic top;
@dynamic bottom;
@dynamic left;
@dynamic right;
@dynamic inBorder;

@end
