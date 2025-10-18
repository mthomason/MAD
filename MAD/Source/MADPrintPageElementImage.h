//
//  MADPrintPageElementImage.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MAD_MADDocumentObjectImage_h
#define Reports_MAD_MADDocumentObjectImage_h

#import "MADPrintPageElement.h"

@class MADDocumentObjectDataReferenceImage;

@interface MADPrintPageElementImage : MADPrintPageElement

- (instancetype)initWithDefinition:(MADDocumentObjectDataReferenceImage *)definition;

@end

#endif
