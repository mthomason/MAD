//
//  MADDocumentObjectLabelDynamic.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_UMADDocumentObjectLabelDynamic_h
#define Reports_MAD_UMADDocumentObjectLabelDynamic_h

#import "MADDocumentObjectText.h"

@class MADDocumentObjectDataReferenceLabelDynamic;

@interface MADPrintPageElementTextDynamic : MADDocumentObjectText

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceLabelDynamic *)definition;

@end

#endif
