//
//  MADDocumentObjectAggregate.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_MADDocumentObjectAggregate_h
#define Reports_MAD_MADDocumentObjectAggregate_h

#import "MADDocumentObjectText.h"

@class MADDocumentObjectDataReference;

@interface MADDocumentObjectAggregate : MADDocumentObjectText

    - (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition;

@end

#endif
