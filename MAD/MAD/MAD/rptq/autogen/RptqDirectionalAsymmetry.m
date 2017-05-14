//
//  RptqDirectionalAsymmetry+CoreDataClass.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDirectionalAsymmetry.h"

@implementation RptqDirectionalAsymmetry

@end

@implementation RptqDirectionalAsymmetry (CoreDataProperties)

+ (NSFetchRequest<RptqDirectionalAsymmetry *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDirectionalAsymmetry"];
}

@dynamic top;
@dynamic bottom;
@dynamic left;
@dynamic right;

@end
