//
//  RptqDocumentElementImage+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentElementImage_Extras_h
#define Reports_RptqDocumentElementImage_Extras_h

#import "RptqDocumentElementImage+CoreDataClass.h"
#import <MADFoundation/MADDataType.h>

@interface RptqDocumentElementImage (Extras)

    - (NSString *)formattedString:(MADDataType)dataType forValue:(id)value;

@end

#endif
