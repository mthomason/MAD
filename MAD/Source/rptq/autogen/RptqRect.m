//
//  RptqRect+CoreDataClass.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqRect.h"
#import "RptqPoint.h"

#import "RptqSize.h"

@implementation RptqRect

@end

@implementation RptqRect (CoreDataProperties)

+ (NSFetchRequest<RptqRect *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqRect"];
}

@dynamic origin;
@dynamic size;
@dynamic inElement;

@end
