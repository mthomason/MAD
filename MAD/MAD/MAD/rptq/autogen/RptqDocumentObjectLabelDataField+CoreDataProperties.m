//
//  RptqDocumentObjectLabelDataField+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentObjectLabelDataField+CoreDataProperties.h"

@implementation RptqDocumentObjectLabelDataField (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectLabelDataField *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentObjectLabelDataField"];
}

@dynamic field;
@dynamic table;
@dynamic text;
@dynamic parentObjectLabelDataField;
@dynamic referencesQueryField;

@end
