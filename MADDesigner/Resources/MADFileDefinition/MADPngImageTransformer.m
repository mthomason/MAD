//
//  MADPngImageTransformer.m
//  MAD Designer
//
//  Created by Michael on 7/9/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADPngImageTransformer.h"
#import <UIKit/UIImage.h>

@implementation MADPngImageTransformer

+ (void)load {
	if (self == [MADPngImageTransformer class]) {
		MADPngImageTransformer *t = [MADPngImageTransformer new];
		[NSValueTransformer setValueTransformer:t forName:NSStringFromClass([MADPngImageTransformer class])];
	}
}

+ (Class)transformedValueClass {
	return [NSData class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (nullable id)transformedValue:(nullable id)value {
	if (!value || ![value isKindOfClass:[UIImage class]]) return nil;
	return UIImagePNGRepresentation((UIImage *)value);
}

- (nullable id)reverseTransformedValue:(nullable id)value {
	if (!value || ![value isKindOfClass:[NSData class]]) return nil;
	return [UIImage imageWithData:(NSData *)value];
}

@end
