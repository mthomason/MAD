//
//  MADAccessibilityLine.h
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADAccessibilityLine_h
#define MAD_MADAccessibilityLine_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>
#import "MADDocumentObjectType.h"

@interface MADAccessibilityLine : NSObject

    - (instancetype)initWithValue:(id)value type:(MTDocumentObjectType)type andFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

    @property (readonly) NSString *label;
    @property (readonly) CGRect frame;
    @property (nonatomic, assign, readonly) MTDocumentObjectType type;

@end

#endif
