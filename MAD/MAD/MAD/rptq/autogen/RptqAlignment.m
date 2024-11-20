//
//  RptqAlignment+CoreDataClass.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqAlignment.h"

@implementation RptqAlignment

@end

@implementation RptqAlignment (CoreDataProperties)

+ (NSFetchRequest<RptqAlignment *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqAlignment"];
}

@dynamic horizontal;
@dynamic vertical;
@dynamic inElement;

@end
