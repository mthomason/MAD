//
//  RptqDocumentElementFormula+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/18/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqDocumentElementFormula_Extras_h
#define Reports_RptqDocumentElementFormula_Extras_h

#import <MAD/RptqDocumentElementFormula.h>
#import <MAD/RptqDocumentElementFactory.h>
#import <MADDataStructures/MTProtocolLog.h>

@interface RptqDocumentElementFormula (Extras)
		<RptqDocumentElementFactory, MTProtocolLog>

@end

#endif
