//
//  RptqDocumentObjectFormula+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/18/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObjectFormula_Extras_h
#define Reports_RptqDocumentObjectFormula_Extras_h

#import "RptqDocumentObjectFormula.h"
#import <MADDataStructures/MTProtocolLog.h>
#import "RptqDocumentObjectFactory.h"
#import <MADFoundation/MADDataType.h>

@interface RptqDocumentObjectFormula (Extras) <RptqDocumentObjectFactory, MTProtocolLog>

    - (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;

@end

#endif
