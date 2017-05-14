//
//  RptqNumericFormat+CoreDataClass.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqNumericFormat.h"

@implementation RptqNumericFormat

@end

@implementation RptqNumericFormat (CoreDataProperties)

+ (NSFetchRequest<RptqNumericFormat *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqNumericFormat"];
}

@dynamic locale;
@dynamic enabled;
@dynamic decimalCount;

@end
