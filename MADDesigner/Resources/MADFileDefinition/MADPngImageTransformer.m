//
//  MADPngImageTransformer.m
//  MAD Designer
//
//  Created by Michael on 7/9/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADPngImageTransformer.h"
#include <TargetConditionals.h>
#if defined(__APPLE__) && TARGET_OS_OSX
#import <AppKit/NSImage.h>
#import <AppKit/NSBitmapImageRep.h>
#else
#import <UIKit/UIImage.h>
#endif

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
#if defined(__APPLE__) && TARGET_OS_OSX
	if (!value || ![value isKindOfClass:[NSImage class]]) return nil;
	NSImage *image = (NSImage *)value;
	CGImageRef cgRef = [image CGImageForProposedRect:NULL context:nil hints:nil];
	if (cgRef == NULL) return nil;
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
	return [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
#else
	if (!value || ![value isKindOfClass:[UIImage class]]) return nil;
	return UIImagePNGRepresentation((UIImage *)value);
#endif
}

- (nullable id)reverseTransformedValue:(nullable id)value {
	if (!value || ![value isKindOfClass:[NSData class]]) return nil;
#if defined(__APPLE__) && TARGET_OS_OSX
	return [[NSImage alloc] initWithData:(NSData *)value];
#else
	return [UIImage imageWithData:(NSData *)value];
#endif
}

@end
