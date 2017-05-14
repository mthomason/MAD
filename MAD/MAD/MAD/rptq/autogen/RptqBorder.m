//
//  RptqBorder+CoreDataClass.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqBorder.h"
#import "RptqDirectionalAsymmetry.h"

#import "RptqDirectionalProperty.h"

@implementation RptqBorder

@end

@implementation RptqBorder (CoreDataProperties)

+ (NSFetchRequest<RptqBorder *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqBorder"];
}

@dynamic width;
@dynamic style;
@dynamic inElement;

@end
