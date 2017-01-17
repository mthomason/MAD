//
//  MADDocumentCachedDataReference.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_MADDocumentCachedDataReference_h
#define Reports_MAD_MADDocumentCachedDataReference_h

#import <Foundation/NSObject.h>

@class MADDocumentObjectDataReference;

@interface MADDocumentCachedDataReference : NSObject

    - (instancetype)initWithDefinition:(MADDocumentObjectDataReference *)definition;

@end

#endif
