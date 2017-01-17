//
//  MADDocumentObjectText.h
//  MAD
//
//  Created by Michael on 1/17/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//


#ifndef Reports_MAD_MADDocumentObjectText_h
#define Reports_MAD_MADDocumentObjectText_h

#import "MADDocumentObject.h"

@interface MADDocumentObjectText : MADDocumentObject

    - (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition;

    @property (readwrite, nonatomic, copy) NSString *text;

@end

#endif
