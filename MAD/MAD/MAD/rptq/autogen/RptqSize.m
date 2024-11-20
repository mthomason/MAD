//
//  RptqSize+CoreDataClass.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqSize.h"

@implementation RptqSize

@end

@implementation RptqSize (CoreDataProperties)

+ (NSFetchRequest<RptqSize *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqSize"];
}

@dynamic width;
@dynamic height;
@dynamic inRect;

@end
