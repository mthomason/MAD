//
//  RptqDocumentElementLabelDataField+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementLabelDataField+CoreDataProperties.h"

@implementation RptqDocumentElementLabelDataField (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabelDataField *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementLabelDataField"];
}

@dynamic field;
@dynamic table;
@dynamic text;
@dynamic referencesQueryField;

@end
