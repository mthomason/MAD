//
//  RptqDocumentObjectImage+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectImage_Extras_h
#define Reports_RptqDocumentObjectImage_Extras_h

#import "RptqDocumentObjectImage.h"
#import <MADFoundation/MTDataType.h>

@interface RptqDocumentObjectImage (Extras)

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;

@end

#endif
