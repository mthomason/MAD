//
//  RptqDocumentElementFormula+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/18/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_RptqDocumentElementFormula_Extras_h
#define Reports_RptqDocumentElementFormula_Extras_h

#import "RptqDocumentElementFormula.h"
#import "RptqDocumentElementFactory.h"
#import <MADDataStructures/MTProtocolLog.h>

@interface RptqDocumentElementFormula (Extras)
        <RptqDocumentElementFactory, MTProtocolLog>

@end

#endif
