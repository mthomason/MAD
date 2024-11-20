//
//  MADPrintPageElementTextDynamic.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MAD_UMADDocumentObjectLabelDynamic_h
#define Reports_MAD_UMADDocumentObjectLabelDynamic_h

#import "MADPrintPageElementText.h"

@class MADDocumentObjectDataReferenceLabelDynamic;

@interface MADPrintPageElementTextDynamic : MADPrintPageElementText

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceLabelDynamic *)definition;

@end

#endif
