//
//  RptqDocumentElementLabelDataField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentElementLabelDataField_Extras_h
#define Reports_RptqDocumentElementLabelDataField_Extras_h

#import "RptqDocumentElementLabelDataField+CoreDataClass.h"
#import <MADFoundation/MADDataType.h>

@interface RptqDocumentElementLabelDataField (Extras)

    - (NSString *)formattedString:(MADDataType)dataType forValue:(id)value;

@end

#endif
