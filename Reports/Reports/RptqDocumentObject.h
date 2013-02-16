//
//  RptqDocumentObject.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObjectFormula, RptqDocumentObjectLabel, RptqDocumentObjectLabelDataField, RptqDocumentObjectLabelLink, RptqDocumentSection;

@interface RptqDocumentObject : NSManagedObject

@property (nonatomic, retain) NSData * binary;
@property (nonatomic, retain) NSNumber * bold;
@property (nonatomic, retain) id color;
@property (nonatomic, retain) NSString * fontname;
@property (nonatomic, retain) NSNumber * fontsize;
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
@property (nonatomic, retain) NSNumber * sizeheight;
@property (nonatomic, retain) NSNumber * sizewidth;
@property (nonatomic, retain) NSNumber * strike;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * underline;
@property (nonatomic, retain) NSNumber * verticalAlignment;
@property (nonatomic, retain) NSNumber * wrappingStyle;
@property (nonatomic, retain) RptqDocumentSection *inSection;
@property (nonatomic, retain) RptqDocumentObjectFormula *isFormula;
@property (nonatomic, retain) RptqDocumentObjectLabel *isLabel;
@property (nonatomic, retain) RptqDocumentObjectLabelDataField *isLabelDataField;
@property (nonatomic, retain) RptqDocumentObjectLabelLink *isLabelLink;

@end
