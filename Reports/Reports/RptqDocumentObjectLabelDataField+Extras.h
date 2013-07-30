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
#import "RptqDatabaseSchemaField.h"
#import "RptqDocumentSection+Extras.h"

@interface RptqDocumentObjectLabelDataField (Extras) <MTProtocolCompare>

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;

@end

#endif
