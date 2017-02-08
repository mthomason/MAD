//
//  RptqDocumentElementImage+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementImage.h"

@implementation RptqDocumentElementImage

@end

@implementation RptqDocumentElementImage (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementImage *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementImage"];
}

@dynamic image;

@end
