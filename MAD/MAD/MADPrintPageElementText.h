//
//  MADPrintPageElementText.h
//  MAD
//
//  Created by Michael on 1/17/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//


#ifndef Reports_MAD_MADDocumentObjectText_h
#define Reports_MAD_MADDocumentObjectText_h

#import "MADPrintPageElement.h"

@interface MADPrintPageElementText : MADPrintPageElement

    - (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition;

    @property (readwrite, nonatomic, copy) NSString *text;

@end

#endif
