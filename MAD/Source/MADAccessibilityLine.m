//
//  MADAccessibilityLine.m
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADAccessibilityLine.h"
#import <UIKit/UIGeometry.h>

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

- (NSString *)label { return [self.value debugDescription]; }

- (CGRect)frame { return self.rect.CGRectValue; }

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	[debug appendFormat:@"Text:\t%@\n", self.label];
	[debug appendFormat:@"Rect:\t%@", NSStringFromCGRect(self.frame)];
	return debug;
}

@end
