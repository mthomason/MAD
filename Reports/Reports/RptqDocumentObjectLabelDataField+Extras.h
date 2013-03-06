//
//  RptqDocumentObjectLabelDataField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectLabelDataField_Extras_h
#define Reports_RptqDocumentObjectLabelDataField_Extras_h

#import "RptqDocumentObjectLabelDataField.h"
#import "MTProtocolCompare.h"
#import "RptqDocument.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqField.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentObjectFactory.h"

@interface RptqDocumentObjectLabelDataField (Extras) <MTProtocolCompare, RptqDocumentObjectFactory>

@end

#endif
