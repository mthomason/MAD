//
//  MADDocumentObjectStaticLabel.h
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_MADDocumentObjectLabelStatic_h
#define Reports_MAD_MADDocumentObjectLabelStatic_h

#import "MADDocumentObjectText.h"

@class MADDocumentObjectDataReferenceLabelStatic;

@interface MADDocumentObjectLabelStatic : MADDocumentObjectText

    - (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceLabelStatic *)definition;

@end

#endif
