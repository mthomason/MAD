//
//  RptqDocumentObject.m
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
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
@dynamic rowid;
@dynamic sizeheight;
@dynamic sizewidth;
@dynamic type;
@dynamic inSection;
@dynamic isFormula;
@dynamic isLabel;
@dynamic isLabelDataField;
@dynamic isLabelLink;

@end
