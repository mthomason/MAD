//
//  RptqDocumentObject.h
//  MAD
//
//  Created by Michael Thomason on 11/19/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqDocumentObject_h
#define MAD_AutoGen_RptqDocumentObject_h

#import <CoreData/NSManagedObject.h>

@class RptqDocumentObjectAggregate, RptqDocumentObjectBarcode, RptqDocumentObjectChart, RptqDocumentObjectFormula, RptqDocumentObjectGroupKey, RptqDocumentObjectImage, RptqDocumentObjectLabel, RptqDocumentObjectLabelDataField, RptqDocumentObjectLabelLink, RptqDocumentSectionRows;

@interface RptqDocumentObject : NSManagedObject

@property (nonatomic, strong) NSData * binary;
@property (nonatomic, strong) NSNumber * bold;
@property (nonatomic, strong) id color;
@property (nonatomic, strong) NSNumber * dropIndex;
@property (nonatomic, strong) NSNumber * dropPointX;
@property (nonatomic, strong) NSNumber * dropPointY;
@property (nonatomic, strong) NSString * fontname;
@property (nonatomic, strong) NSNumber * fontsize;
@property (nonatomic, strong) NSNumber * formatNumericCurrency;
@property (nonatomic, strong) NSString * formatNumericCurrencyLocal;
@property (nonatomic, strong) NSNumber * formatNumericDecimals;
@property (nonatomic, strong) NSNumber * horizontalAlignment;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSNumber * italic;
@property (nonatomic, strong) NSString * label;
@property (nonatomic, strong) NSNumber * marginBottom;
@property (nonatomic, strong) NSNumber * marginLeft;
@property (nonatomic, strong) NSNumber * marginRight;
@property (nonatomic, strong) NSNumber * marginTop;
@property (nonatomic, strong) NSNumber * originx;
@property (nonatomic, strong) NSNumber * originy;
@property (nonatomic, strong) NSNumber * paddingBottom;
@property (nonatomic, strong) NSNumber * paddingLeft;
@property (nonatomic, strong) NSNumber * paddingRight;
@property (nonatomic, strong) NSNumber * paddingTop;
@property (nonatomic, strong) NSNumber * sectionIndexItem;
@property (nonatomic, strong) NSNumber * sectionIndexRow;
@property (nonatomic, strong) NSNumber * sectionRowNumber;
@property (nonatomic, strong) NSNumber * sizeheight;
@property (nonatomic, strong) NSNumber * sizewidth;
@property (nonatomic, strong) NSNumber * strike;
@property (nonatomic, strong) NSNumber * touchPointX;
@property (nonatomic, strong) NSNumber * touchPointY;
@property (nonatomic, strong) NSNumber * type;
@property (nonatomic, strong) NSNumber * underline;
@property (nonatomic, strong) NSNumber * verticalAlignment;
@property (nonatomic, strong) NSNumber * wrappingStyle;
@property (nonatomic, strong) NSNumber * borderWidthLeft;
@property (nonatomic, strong) NSNumber * borderWidthRight;
@property (nonatomic, strong) NSData * colorBackground;
@property (nonatomic, strong) NSData * colorBorder;
@property (nonatomic, strong) NSData * colorForeground;
@property (nonatomic, strong) NSNumber * borderStyleTop;
@property (nonatomic, strong) NSNumber * borderStyleBottom;
@property (nonatomic, strong) NSNumber * borderStyleLeft;
@property (nonatomic, strong) NSNumber * borderStyleRight;
@property (nonatomic, strong) NSNumber * borderHeightBottom;
@property (nonatomic, strong) NSNumber * borderHeightTop;
@property (nonatomic, strong) RptqDocumentSectionRows *inSectionRow;
@property (nonatomic, strong) RptqDocumentObjectAggregate *isAggregate;
@property (nonatomic, strong) RptqDocumentObjectBarcode *isBarcode;
@property (nonatomic, strong) RptqDocumentObjectChart *isChart;
@property (nonatomic, strong) RptqDocumentObjectFormula *isFormula;
@property (nonatomic, strong) RptqDocumentObjectGroupKey *isGroupKey;
@property (nonatomic, strong) RptqDocumentObjectImage *isImage;
@property (nonatomic, strong) RptqDocumentObjectLabel *isLabel;
@property (nonatomic, strong) RptqDocumentObjectLabelDataField *isLabelDataField;
@property (nonatomic, strong) RptqDocumentObjectLabelLink *isLabelLink;

@end

#endif
