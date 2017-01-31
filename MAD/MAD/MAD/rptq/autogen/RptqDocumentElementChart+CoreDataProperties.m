//
//  RptqDocumentElementChart+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementChart+CoreDataProperties.h"

@implementation RptqDocumentElementChart (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementChart *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementChart"];
}


@end
