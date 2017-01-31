//
//  RptqDocumentElementImage+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementImage+CoreDataProperties.h"

@implementation RptqDocumentElementImage (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementImage *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementImage"];
}

@dynamic image;

@end
