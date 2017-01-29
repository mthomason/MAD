//
//  RptqDocumentObjectImage+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectImage_Extras_h
#define Reports_RptqDocumentObjectImage_Extras_h

#import "RptqDocumentObjectImage+CoreDataClass.h"
#import <MADFoundation/MADDataType.h>

@interface RptqDocumentObjectImage (Extras)

    - (NSString *)formattedString:(MADDataType)dataType forValue:(id)value;

@end

#endif
