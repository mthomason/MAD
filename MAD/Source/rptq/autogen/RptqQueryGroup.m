//
//  RptqQueryGroup+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqQueryGroup.h"
#import "RptqDocumentSection.h"
#import "RptqQuery.h"
#import "RptqQueryField.h"
@implementation RptqQueryGroup

@end

@implementation RptqQueryGroup (CoreDataProperties)

+ (NSFetchRequest<RptqQueryGroup *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqQueryGroup"];
}

@dynamic identifier;
@dynamic sort;
@dynamic weight;
@dynamic hasField;
@dynamic hasSection;
@dynamic inQuery;

@end
