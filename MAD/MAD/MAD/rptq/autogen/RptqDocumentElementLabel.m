//
//  RptqDocumentElementLabel+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementLabel.h"

@implementation RptqDocumentElementLabel

@end

@implementation RptqDocumentElementLabel (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabel *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementLabel"];
}

@dynamic text;

@end
