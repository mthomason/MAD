//
//  MADColorTransformer.m
//  MAD Designer
//
//  Created by Michael on 5/21/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADColorTransformer.h"
#include <TargetConditionals.h>
#if defined(__APPLE__) && TARGET_OS_OSX
#import <AppKit/NSColor.h>
typedef NSColor MADTransformedColor;
#else
#import <UIKit/UIColor.h>
typedef UIColor MADTransformedColor;
#endif

@implementation MADColorTransformer

+ (void)load {
	if (self == [MADColorTransformer class]) {
		MADColorTransformer *t = [MADColorTransformer new];
		[NSValueTransformer setValueTransformer:t forName:NSStringFromClass([MADColorTransformer class])];
	}
}

+ (Class)transformedValueClass {
	return [MADTransformedColor class];
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

+ (NSSet<Class> *)allowedTopLevelClasses {
	return [NSSet setWithObjects:[MADTransformedColor class], nil];
}

@end
