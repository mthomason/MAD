//
//  RptqDocumentElementFormula+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/18/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentElementFormula_Extras_h
#define Reports_RptqDocumentElementFormula_Extras_h

#import "RptqDocumentElementFormula.h"
#import "RptqDocumentElementFactory.h"
#import <MADDataStructures/MTProtocolLog.h>
#import <MADFoundation/MADDataType.h>

@interface RptqDocumentElementFormula (Extras)
        <RptqDocumentElementFactory, MTProtocolLog>

@end

#endif
