//
//  MADColorTransformer.m
//  MAD Designer
//
//  Created by Michael on 5/21/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "MADColorTransformer.h"
#import <UIKit/UIColor.h>

@implementation MADColorTransformer

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
