//
//  MADDocumentObjectStaticLabel.h
//  MAD
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADDocumentObject.h"

@class MADocumentObjectAttributesText;

@interface MADDocumentObjectLabelStatic : MADDocumentObject

    - (void)drawInRect:(CGRect)rect
        withAttributes:(__kindof MADocumentObjectAttributesText *)attributes;

@end
