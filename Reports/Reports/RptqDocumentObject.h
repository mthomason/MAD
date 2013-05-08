//
//  RptqDocumentObject.h
//  Reports
//
//  Created by Michael Thomason on 5/7/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObjectAggregate, RptqDocumentObjectChart, RptqDocumentObjectFormula, RptqDocumentObjectGroupKey, RptqDocumentObjectImage, RptqDocumentObjectLabel, RptqDocumentObjectLabelDataField, RptqDocumentObjectLabelLink, RptqDocumentSectionRows;

@interface RptqDocumentObject : NSManagedObject

@property (nonatomic, retain) NSData * binary;
@property (nonatomic, retain) NSNumber * bold;
@property (nonatomic, retain) id color;
@property (nonatomic, retain) NSNumber * dropPointX;
@property (nonatomic, retain) NSNumber * dropPointY;
@property (nonatomic, retain) NSString * fontname;
@property (nonatomic, retain) NSNumber * fontsize;
@property (nonatomic, retain) NSNumber * formatNumericCurrency;
@property (nonatomic, retain) NSString * formatNumericCurrencyLocal;
@property (nonatomic, retain) NSNumber * formatNumericDecimals;
@property (nonatomic, retain) NSNumber * horizontalAlignment;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * italic;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSNumber * marginBottom;
@property (nonatomic, retain) NSNumber * marginLeft;
@property (nonatomic, retain) NSNumber * marginRight;
@property (nonatomic, retain) NSNumber * marginTop;
@property (nonatomic, retain) NSNumber * originx;
@property (nonatomic, retain) NSNumber * originy;
@property (nonatomic, retain) NSNumber * paddingBottom;
@property (nonatomic, retain) NSNumber * paddingLeft;
@property (nonatomic, retain) NSNumber * paddingRight;
@property (nonatomic, retain) NSNumber * paddingTop;
@property (nonatomic, retain) NSNumber * sectionIndexItem;
@property (nonatomic, retain) NSNumber * sectionIndexRow;
@property (nonatomic, retain) NSNumber * sectionRowNumber;
@property (nonatomic, retain) NSNumber * sizeheight;
@property (nonatomic, retain) NSNumber * sizewidth;
@property (nonatomic, retain) NSNumber * strike;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * underline;
@property (nonatomic, retain) NSNumber * verticalAlignment;
@property (nonatomic, retain) NSNumber * wrappingStyle;
@property (nonatomic, retain) NSNumber * dropIndex;
@property (nonatomic, retain) NSNumber * touchPointX;
@property (nonatomic, retain) NSNumber * touchPointY;
@property (nonatomic, retain) RptqDocumentSectionRows *inSectionRow;
@property (nonatomic, retain) RptqDocumentObjectAggregate *isAggregate;
@property (nonatomic, retain) RptqDocumentObjectChart *isChart;
@property (nonatomic, retain) RptqDocumentObjectFormula *isFormula;
@property (nonatomic, retain) RptqDocumentObjectGroupKey *isGroupKey;
@property (nonatomic, retain) RptqDocumentObjectImage *isImage;
@property (nonatomic, retain) RptqDocumentObjectLabel *isLabel;
@property (nonatomic, retain) RptqDocumentObjectLabelDataField *isLabelDataField;
@property (nonatomic, retain) RptqDocumentObjectLabelLink *isLabelLink;

@end
