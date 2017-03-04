//
//  MADDocumentObjectImage.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_MADDocumentObjectImage_h
#define Reports_MAD_MADDocumentObjectImage_h

#import "MADDocumentObject.h"

@class RptqDocumentElementImage;

@interface MADDocumentObjectImage : MADDocumentObject

- (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition;

@end

#endif
