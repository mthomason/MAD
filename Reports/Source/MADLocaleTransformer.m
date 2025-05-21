//
//  MADLocaleTransformer.m
//  MAD Designer
//
//  Created by Michael on 5/21/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "MADLocaleTransformer.h"

@implementation MADLocaleTransformer

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
