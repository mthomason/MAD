//
//  RptqDocumentElement+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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

@dynamic backgroundColor;
@dynamic dropIndex;
@dynamic fontname;
@dynamic fontsize;
@dynamic foregroundColor;
@dynamic identifier;
@dynamic type;
@dynamic inSectionRow;
@dynamic dropPoint;
@dynamic padding;
@dynamic rect;
@dynamic margin;
@dynamic border;
@dynamic textStyle;
@dynamic alignment;
@dynamic numericFormat;

@end
