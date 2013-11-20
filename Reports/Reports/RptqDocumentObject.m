//
//  RptqDocumentObject.m
//  MAD
//
//  Created by Michael Thomason on 11/19/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObject.h"
#import "RptqDocumentObjectAggregate.h"
#import "RptqDocumentObjectBarcode.h"
#import "RptqDocumentObjectChart.h"
#import "RptqDocumentObjectFormula.h"
#import "RptqDocumentObjectGroupKey.h"
#import "RptqDocumentObjectImage.h"
#import "RptqDocumentObjectLabel.h"
#import "RptqDocumentObjectLabelDataField.h"
#import "RptqDocumentObjectLabelLink.h"
#import "RptqDocumentSectionRows.h"


@implementation RptqDocumentObject

@dynamic binary;
@dynamic bold;
@dynamic color;
@dynamic dropIndex;
@dynamic dropPointX;
@dynamic dropPointY;
@dynamic fontname;
@dynamic fontsize;
@dynamic formatNumericCurrency;
@dynamic formatNumericCurrencyLocal;
@dynamic formatNumericDecimals;
@dynamic horizontalAlignment;
@dynamic identifier;
@dynamic italic;
@dynamic label;
@dynamic marginBottom;
@dynamic marginLeft;
@dynamic marginRight;
@dynamic marginTop;
@dynamic originx;
@dynamic originy;
@dynamic paddingBottom;
@dynamic paddingLeft;
@dynamic paddingRight;
@dynamic paddingTop;
@dynamic sectionIndexItem;
@dynamic sectionIndexRow;
@dynamic sectionRowNumber;
@dynamic sizeheight;
@dynamic sizewidth;
@dynamic strike;
@dynamic touchPointX;
@dynamic touchPointY;
@dynamic type;
@dynamic underline;
@dynamic verticalAlignment;
@dynamic wrappingStyle;
@dynamic borderWidthLeft;
@dynamic borderWidthRight;
@dynamic colorBackground;
@dynamic colorBorder;
@dynamic colorForeground;
@dynamic borderStyleTop;
@dynamic borderStyleBottom;
@dynamic borderStyleLeft;
@dynamic borderStyleRight;
@dynamic borderHeightBottom;
@dynamic borderHeightTop;
@dynamic inSectionRow;
@dynamic isAggregate;
@dynamic isBarcode;
@dynamic isChart;
@dynamic isFormula;
@dynamic isGroupKey;
@dynamic isImage;
@dynamic isLabel;
@dynamic isLabelDataField;
@dynamic isLabelLink;

@end
