//
//  RptqDocumentObjectLabelLink+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/15/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectLabelLink_Extras_h
#define Reports_RptqDocumentObjectLabelLink_Extras_h

#import "RptqDocumentObjectLabelLink.h"
#import <MADDataStructures/MADDataStructures.h>
#import <MADFoundation/MTDataType.h>

@interface RptqDocumentObjectLabelLink (Extras) <MTProtocolCompare>

- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;

@end

#endif
