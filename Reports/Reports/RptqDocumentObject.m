//
//  RptqDocumentObject.m
//  Reports
//
//  Created by Michael Thomason on 12/31/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObject.h"
#import "RptqDocumentObjectFormula.h"
#import "RptqDocumentObjectLabel.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectLabelLink.h"
#import "RptqDocumentSection.h"


@implementation RptqDocumentObject

@dynamic binary;
@dynamic identifier;
@dynamic label;
@dynamic originx;
@dynamic originy;
@dynamic sectionIndexItem;
@dynamic sectionIndexRow;
@dynamic sizeheight;
@dynamic sizewidth;
@dynamic type;
@dynamic horizontalAlignment;
@dynamic verticalAlignment;
@dynamic marginTop;
@dynamic paddingTop;
@dynamic color;
@dynamic fontname;
@dynamic fontsize;
@dynamic marginBottom;
@dynamic marginLeft;
@dynamic marginRight;
@dynamic paddingBottom;
@dynamic paddingLeft;
@dynamic paddingRight;
@dynamic wrappingStyle;
@dynamic inSection;
@dynamic isFormula;
@dynamic isLabel;
@dynamic isLabelDataField;
@dynamic isLabelLink;

@end
