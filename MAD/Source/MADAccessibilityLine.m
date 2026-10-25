//
//  MADAccessibilityLine.m
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADAccessibilityLine.h"
#import <UIKit/UIGeometry.h>

// The one member the label reads off a text-carrying drawing object, declared here
// rather than imported: the line takes any object, and the element family's headers
// are not all visible to this file.
@protocol MADAccessibilityLineTextValue <NSObject>
@property (nonatomic, readonly, copy) NSString *text;
@end

@interface MADAccessibilityLine ()

@property (nonatomic, copy) NSValue *rect;
@property (nonatomic, strong) id value;
@property (nonatomic, assign, readwrite) MADPrintPageElementType type;

@end

@implementation MADAccessibilityLine

- (instancetype)init {
	return [self initWithValue:@"" type:MADPrintPageElementTypeLabelStatic andFrame:CGRectZero];
}

- (instancetype)initWithValue:(id)value type:(MADPrintPageElementType)type andFrame:(CGRect)frame {
	if (self = [super init]) {
		
		NSValue *r = [NSValue valueWithCGRect:frame];
		_rect = r.copy;
		
		// FIXME: :Maybe make weak or copy, ect
		self.value = value;
		self.type = type;
	}
	return self;
}

// A drawing object that carries text answers with it -- the label, aggregate and
// barcode elements do -- so the line reads the value the report shows rather than an
// object dump.  Anything else keeps the debug-description spelling.
- (NSString *)label {
	id value = self.value;
	if ([value respondsToSelector: @selector(text)]) {
		NSString *text = [(id <MADAccessibilityLineTextValue>)value text];
		if (text != nil) return text;
	}
	return [value debugDescription];
}

- (CGRect)frame { return self.rect.CGRectValue; }

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	[debug appendFormat:@"Text:\t%@\n", self.label];
	[debug appendFormat:@"Rect:\t%@", NSStringFromCGRect(self.frame)];
	return debug;
}

@end
