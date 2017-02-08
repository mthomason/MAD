//
//  RptqDocumentElementGroupKey+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementGroupKey.h"

@implementation RptqDocumentElementGroupKey

@end

@implementation RptqDocumentElementGroupKey (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementGroupKey *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementGroupKey"];
}

@dynamic groupNumber;

@end
