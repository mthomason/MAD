//
//  RptqDocumentObjectLabelDataField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectLabelDataField_Extras_h
#define Reports_RptqDocumentObjectLabelDataField_Extras_h

#import "RptqDocumentObjectLabelDataField.h"
#import <MADDataStructures/MADDataStructures.h>
#import <MADFoundation/MADDataType.h>

@interface RptqDocumentObjectLabelDataField (Extras) <MTProtocolCompare>

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;

@end

#endif
