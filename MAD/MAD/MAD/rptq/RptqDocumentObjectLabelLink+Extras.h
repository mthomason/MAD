//
//  RptqDocumentElementLabelLink+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentElementLabelLink_Extras_h
#define Reports_RptqDocumentElementLabelLink_Extras_h

#import "RptqDocumentElementLabelLink+CoreDataClass.h"
#import <MADFoundation/MADDataType.h>

@interface RptqDocumentElementLabelLink (Extras)

    - (NSString *)formattedString:(MADDataType)dataType forValue:(id)value;

@end

#endif
