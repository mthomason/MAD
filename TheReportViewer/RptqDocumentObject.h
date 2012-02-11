//
//  RptqDocumentObject.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqDocumentObjectFormula, RptqDocumentObjectLabel, RptqDocumentObjectLabelDataField, RptqDocumentObjectLabelLink, RptqDocumentSection;

@interface RptqDocumentObject : NSManagedObject

@property (nonatomic, retain) NSNumber * sizewidth;
@property (nonatomic, retain) NSNumber * originy;
@property (nonatomic, retain) NSNumber * sizeheight;
@property (nonatomic, retain) NSNumber * originx;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSData * binary;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) RptqDocumentSection *inSection;
@property (nonatomic, retain) RptqDocumentObjectFormula *isFormula;
@property (nonatomic, retain) RptqDocumentObjectLabel *isLabel;
@property (nonatomic, retain) RptqDocumentObjectLabelLink *isLabelLink;
@property (nonatomic, retain) RptqDocumentObjectLabelDataField *isLabelDataField;

@end
