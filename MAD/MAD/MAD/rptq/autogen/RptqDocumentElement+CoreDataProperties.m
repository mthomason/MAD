//
//  RptqDocumentElement+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElement+CoreDataProperties.h"

@implementation RptqDocumentElement (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElement *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentElement"];
}

@dynamic dropIndex;
@dynamic fontname;
@dynamic fontsize;
@dynamic identifier;
@dynamic type;
@dynamic origin;
@dynamic dropPoint;
@dynamic margin;
@dynamic padding;
@dynamic border;
@dynamic alignment;
@dynamic size;
@dynamic style;
@dynamic backgroundColor;
@dynamic foregroundColor;
@dynamic numericFormat;
@dynamic inSectionRow;

@end
