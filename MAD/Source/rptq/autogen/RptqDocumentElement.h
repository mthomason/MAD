//
//  RptqDocumentElement.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDocumentElement_NSManagedObject_h
#define MAD_RptqDocumentElement_NSManagedObject_h

#import "RptqObject.h"

@class RptqDocumentSectionRows, RptqPoint, RptqDirectionalAsymmetry, RptqRect,
       RptqBorder, RptqTextStyle, RptqAlignment, RptqNumericFormat, UIColor;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElement : RptqObject

@end

@interface RptqDocumentElement (CoreDataProperties)

@property (nonatomic) int64_t identifier;
@property (nonatomic) int16_t type;
@property (nonatomic) int64_t dropIndex;
@property (nonatomic) double fontsize;
@property (nullable, nonatomic, copy) NSString *fontname;
@property (nullable, nonatomic, retain) UIColor *backgroundColor;
@property (nullable, nonatomic, retain) UIColor *foregroundColor;
@property (nullable, nonatomic, retain) RptqDocumentSectionRows *inSectionRow;
@property (nullable, nonatomic, retain) RptqPoint *dropPoint;
@property (nullable, nonatomic, retain) RptqDirectionalAsymmetry *padding;
@property (nullable, nonatomic, retain) RptqRect *rect;
@property (nullable, nonatomic, retain) RptqDirectionalAsymmetry *margin;
@property (nullable, nonatomic, retain) RptqBorder *border;
@property (nullable, nonatomic, retain) RptqTextStyle *textStyle;
@property (nullable, nonatomic, retain) RptqAlignment *alignment;
@property (nullable, nonatomic, retain) RptqNumericFormat *numericFormat;

@end

NS_ASSUME_NONNULL_END

#endif
