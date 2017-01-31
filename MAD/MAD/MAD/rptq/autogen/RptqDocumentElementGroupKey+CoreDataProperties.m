//
//  RptqDocumentElementGroupKey+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElementGroupKey+CoreDataProperties.h"

@implementation RptqDocumentElementGroupKey (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementGroupKey *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElementGroupKey"];
}

@dynamic groupNumber;

@end
