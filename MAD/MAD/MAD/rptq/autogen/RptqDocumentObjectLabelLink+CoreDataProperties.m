//
//  RptqDocumentObjectLabelLink+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentObjectLabelLink+CoreDataProperties.h"

@implementation RptqDocumentObjectLabelLink (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentObjectLabelLink *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentObjectLabelLink"];
}

@dynamic text;
@dynamic url;
@dynamic parentObjectLinkLabel;

@end
