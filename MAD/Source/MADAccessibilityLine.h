//
//  MADAccessibilityLine.h
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADAccessibilityLine_h
#define MAD_MADAccessibilityLine_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>
#import "MADDocumentObjectType.h"

@interface MADAccessibilityLine : NSObject

- (instancetype)initWithValue:(id)value type:(MADPrintPageElementType)type
					 andFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

/// The value's text when it carries one -- a drawing object does -- and otherwise
/// its debug description.
@property (readonly) NSString *label;
@property (readonly) CGRect frame;
@property (nonatomic, assign, readonly) MADPrintPageElementType type;

@end

#endif
