//
//  MADDocumentObject.h
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentObject_h
#define MAD_MADDocumentObject_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>
#import "MADDocumentObjectType.h"

@class MADDocumentObjectDataReference;

@interface MADDocumentObject : NSObject

    + (instancetype)newDocumentObject:(MADDocumentObjectDataReference *)definition;

    - (void)drawInRect:(CGRect)rect;

@end

#endif
