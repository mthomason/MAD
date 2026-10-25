//
//  MADImageTransformer.m
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADImageTransformer.h"
#import <UIKit/UIImage.h>
//#import <Foundation/NSKeyedUnarchiver.h> // For fallback unarchiving
#import <MADFoundation/madlog.h>

@implementation MADImageTransformer

// Specifies that the transformed value (what's stored in Core Data) is NSData.
+ (Class)transformedValueClass {
	return [NSData class];
}

// Allows conversion both ways (UIImage -> NSData and NSData -> UIImage).
+ (BOOL)allowsReverseTransformation {
	return YES;
}

// Converts UIImage to NSData for storage.
- (nullable id)transformedValue:(nullable id)value {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
	// Always convert UIImage to JPEG representation for storage.
	id result = value != nil ? UIImageJPEGRepresentation(value, 1.0) : nil;
#pragma clang diagnostic pop
	return result;
}

// Converts NSData back to UIImage. Handles both raw and old archived formats.
- (nullable id)reverseTransformedValue:(nullable id)value {
	if (value == nil) {
		return nil;
	}
	
	UIImage *decodedImage = nil;
	NSData *imageData = (NSData *)value;
	
	// 1. First, try to decode as raw image data (e.g., JPEG/PNG).
	// This is for images saved with the 'transformedValue' method or similar raw saves.
	decodedImage = [[UIImage alloc] initWithData:imageData];
	
	// 2. If raw decoding fails, attempt to unarchive using NSKeyedUnarchiver as a fallback.
	// This handles old documents where UIImages might have been implicitly archived by Core Data's default Transformable behavior.
	// WARNING: NSKeyedUnarchiver is deprecated and potentially insecure. Use this as a temporary compatibility solution.
	if (decodedImage == nil) {
		@try {
			if (@available(iOS 12.0, *)) {
				// Use the safer, class-specific unarchiving method for iOS 12 and later.
				decodedImage = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIImage class] fromData:imageData error:nil];
			} else {
				// Fallback for older iOS versions using the deprecated method.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
				decodedImage = [NSKeyedUnarchiver unarchiveObjectWithData:imageData];
#pragma clang diagnostic pop
			}
			if (decodedImage) {
				os_log_info(OS_LOG_DEFAULT, "MADImageTransformer: Successfully unarchived image using NSKeyedUnarchiver fallback.");
			} else {
				os_log_error(OS_LOG_DEFAULT, "MADImageTransformer: Failed to unarchive image with NSKeyedUnarchiver fallback (after trying raw).");
			}
		} @catch (NSException *exception) {
			os_log_error(OS_LOG_DEFAULT, "MADImageTransformer: Exception during NSKeyedUnarchiver fallback: %@", exception);
			decodedImage = nil;
		}
	}
	
	return decodedImage;
}

@end
