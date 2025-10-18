//
//  RptqPoint+CoreDataClass.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqPoint.h"

@implementation RptqPoint

@end

@implementation RptqPoint (CoreDataProperties)

+ (NSFetchRequest<RptqPoint *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqPoint"];
}

@dynamic x;
@dynamic y;
@dynamic inElement;
@dynamic inRect;

@end
