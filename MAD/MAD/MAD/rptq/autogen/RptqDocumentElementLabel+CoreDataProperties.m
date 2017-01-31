//
//  RptqDocumentElementLabel+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementLabel+CoreDataProperties.h"

@implementation RptqDocumentElementLabel (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabel *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementLabel"];
}

@dynamic text;

@end
