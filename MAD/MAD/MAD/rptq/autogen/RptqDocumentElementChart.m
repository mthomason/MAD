//
//  RptqDocumentElementChart+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementChart.h"

@implementation RptqDocumentElementChart

@end

@implementation RptqDocumentElementChart (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementChart *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementChart"];
}


@end
