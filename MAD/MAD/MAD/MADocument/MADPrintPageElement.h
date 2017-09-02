//
//  MADPrintPageElement.h
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentObject_h
#define MAD_MADDocumentObject_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@class MADDocumentObjectDataReference;

@interface MADPrintPageElement : NSObject

    - (instancetype)initWithDefinition:(__kindof MADDocumentObjectDataReference *)definition;
    - (void)drawInRect:(CGRect)rect;

@end

#endif
