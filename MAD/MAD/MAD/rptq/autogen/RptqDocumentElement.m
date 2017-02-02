//
//  RptqDocumentElement+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentElement.h"
#import "RptqDocumentSectionRows.h"
@implementation RptqDocumentElement

@end

NSString * const MTNullIdentifier = @"(null)";

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
