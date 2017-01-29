//
//  RptqDocumentObjectLabel+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectLabel_Extras_h
#define Reports_RptqDocumentObjectLabel_Extras_h

#import "RptqDocumentObjectLabel+CoreDataClass.h"
#import <MADFoundation/MADDataType.h>

@interface RptqDocumentObjectLabel (Extras)

    - (NSString *)formattedString:(MADDataType)dataType forValue:(id)value;

@end

#endif
