//
//  RptqDocumentObjectLabel+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentObjectLabel+CoreDataProperties.h"

@implementation RptqDocumentObjectLabel (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectLabel *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentObjectLabel"];
}

@dynamic text;
@dynamic parentObjectLabel;

@end
