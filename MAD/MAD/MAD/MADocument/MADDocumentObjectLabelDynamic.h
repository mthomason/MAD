//
//  MADDocumentObjectLabelDynamic.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_UMADDocumentObjectLabelDynamic_h
#define Reports_MAD_UMADDocumentObjectLabelDynamic_h

#import "MADDocumentObjectText.h"

@class MADDocumentObjectDataReference;

@interface MADDocumentObjectLabelDynamic : MADDocumentObjectText

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition;

@end

#endif
