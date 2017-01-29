//
//  RptqDocumentObjectImage+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectImage+CoreDataProperties.h"

@implementation RptqDocumentObjectImage (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectImage *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentObjectImage"];
}

@dynamic image;
@dynamic parentObject;

@end
