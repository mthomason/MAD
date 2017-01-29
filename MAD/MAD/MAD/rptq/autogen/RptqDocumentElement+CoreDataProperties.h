//
//  RptqDocumentElement+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "RptqDocumentElement+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElement (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElement *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSData *binary;
@property (nullable, nonatomic, copy) NSNumber *bold;
@property (nullable, nonatomic, copy) NSNumber *borderHeightBottom;
@property (nullable, nonatomic, copy) NSNumber *borderHeightTop;
@property (nullable, nonatomic, copy) NSNumber *borderStyleBottom;
@property (nullable, nonatomic, copy) NSNumber *borderStyleLeft;
@property (nullable, nonatomic, copy) NSNumber *borderStyleRight;
@property (nullable, nonatomic, copy) NSNumber *borderStyleTop;
@property (nullable, nonatomic, copy) NSNumber *borderWidthLeft;
@property (nullable, nonatomic, copy) NSNumber *borderWidthRight;
@property (nullable, nonatomic, retain) NSObject *color;
@property (nullable, nonatomic, retain) NSData *colorBackground;
@property (nullable, nonatomic, retain) NSData *colorBorder;
@property (nullable, nonatomic, retain) NSData *colorForeground;
@property (nullable, nonatomic, copy) NSNumber *dropIndex;
@property (nullable, nonatomic, copy) NSNumber *dropPointX;
@property (nullable, nonatomic, copy) NSNumber *dropPointY;
@property (nullable, nonatomic, copy) NSString *fontname;
@property (nullable, nonatomic, copy) NSNumber *fontsize;
@property (nullable, nonatomic, copy) NSNumber *formatNumericCurrency;
@property (nullable, nonatomic, copy) NSString *formatNumericCurrencyLocal;
@property (nullable, nonatomic, copy) NSNumber *formatNumericDecimals;
@property (nullable, nonatomic, copy) NSNumber *horizontalAlignment;
@property (nullable, nonatomic, copy) NSNumber *identifier;
@property (nullable, nonatomic, copy) NSNumber *italic;
@property (nullable, nonatomic, copy) NSString *label;
@property (nullable, nonatomic, copy) NSNumber *marginBottom;
@property (nullable, nonatomic, copy) NSNumber *marginLeft;
@property (nullable, nonatomic, copy) NSNumber *marginRight;
@property (nullable, nonatomic, copy) NSNumber *marginTop;
@property (nullable, nonatomic, copy) NSNumber *originx;
@property (nullable, nonatomic, copy) NSNumber *originy;
@property (nullable, nonatomic, copy) NSNumber *paddingBottom;
@property (nullable, nonatomic, copy) NSNumber *paddingLeft;
@property (nullable, nonatomic, copy) NSNumber *paddingRight;
@property (nullable, nonatomic, copy) NSNumber *paddingTop;
@property (nullable, nonatomic, copy) NSNumber *sectionIndexItem;
@property (nullable, nonatomic, copy) NSNumber *sectionIndexRow;
@property (nullable, nonatomic, copy) NSNumber *sectionRowNumber;
@property (nullable, nonatomic, copy) NSNumber *sizeheight;
@property (nullable, nonatomic, copy) NSNumber *sizewidth;
@property (nullable, nonatomic, copy) NSNumber *strike;
@property (nullable, nonatomic, copy) NSNumber *touchPointX;
@property (nullable, nonatomic, copy) NSNumber *touchPointY;
@property (nullable, nonatomic, copy) NSNumber *type;
@property (nullable, nonatomic, copy) NSNumber *underline;
@property (nullable, nonatomic, copy) NSNumber *verticalAlignment;
@property (nullable, nonatomic, copy) NSNumber *wrappingStyle;
@property (nullable, nonatomic, retain) RptqDocumentSectionRows *inSectionRow;

@end

NS_ASSUME_NONNULL_END
