//
//  MADLocaleTransformer.m
//  MAD Designer
//
//  Created by Michael on 5/21/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADLocaleTransformer.h"
#import <Foundation/NSLocale.h>
#import <Foundation/NSSet.h>

@implementation MADLocaleTransformer

+ (void)load {
	if (self == [MADLocaleTransformer class]) {
		MADLocaleTransformer *t = [MADLocaleTransformer new];
		[NSValueTransformer setValueTransformer:t forName:NSStringFromClass([MADLocaleTransformer class])];
	}
}

+ (Class)transformedValueClass {
	return [NSLocale class];
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

+ (NSSet<Class> *)allowedTopLevelClasses {
	return [NSSet setWithObjects:[NSLocale class], nil];
}

@end
