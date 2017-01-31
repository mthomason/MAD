//
//  RptqDocumentElementLabelLink+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementLabelLink+CoreDataProperties.h"

@implementation RptqDocumentElementLabelLink (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabelLink *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementLabelLink"];
}

@dynamic text;
@dynamic url;

@end
