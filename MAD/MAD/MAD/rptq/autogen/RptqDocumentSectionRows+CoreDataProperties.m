//
//  RptqDocumentSectionRows+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentSectionRows+CoreDataProperties.h"

@implementation RptqDocumentSectionRows (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentSectionRows *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentSectionRows"];
}

@dynamic layoutHeight;
@dynamic rowNumber;
@dynamic hasObjects;
@dynamic inSection;

@end
