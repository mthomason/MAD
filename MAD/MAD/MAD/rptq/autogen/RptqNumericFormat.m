//
//  RptqNumericFormat+CoreDataClass.m
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
@dynamic inElement;

@end
