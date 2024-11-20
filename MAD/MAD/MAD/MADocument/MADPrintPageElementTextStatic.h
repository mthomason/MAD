//
//  MADDocumentObjectStaticLabel.h
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MAD_MADDocumentObjectLabelStatic_h
#define Reports_MAD_MADDocumentObjectLabelStatic_h

#import "MADPrintPageElementText.h"

@class MADDocumentObjectDataReferenceLabelStatic;

@interface MADPrintPageElementTextStatic : MADPrintPageElementText

    - (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceLabelStatic *)definition;

@end

#endif
