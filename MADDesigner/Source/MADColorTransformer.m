//
//  MADColorTransformer.m
//  MAD Designer
//
//  Created by Michael on 5/21/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADColorTransformer.h"
#import <UIKit/UIColor.h>

@implementation MADColorTransformer

+ (void)load {
	if (self == [MADColorTransformer class]) {
		MADColorTransformer *t = [MADColorTransformer new];
		[NSValueTransformer setValueTransformer:t forName:NSStringFromClass([MADColorTransformer class])];
	}
}

+ (Class)transformedValueClass {
	return [UIColor class];
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

+ (NSSet<Class> *)allowedTopLevelClasses {
	return [NSSet setWithObjects:[UIColor class], nil];
}

@end
