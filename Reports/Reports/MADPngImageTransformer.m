//
//  MADPngImageTransformer.m
//  MAD Designer
//
//  Created by Michael on 7/9/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "MADPngImageTransformer.h"
#import <UIKit/UIImage.h>

@implementation MADPngImageTransformer

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
