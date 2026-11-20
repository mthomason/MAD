//
//  RptqDocumentElementImage+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/17/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqDocumentElementImage+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>

#include <TargetConditionals.h>
#if defined(__APPLE__) && TARGET_OS_IPHONE
#import <UIKit/UIImage.h>
#elif defined(__APPLE__) && TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

#import "RptqDocument.h"
#import "RptqDocumentElement+Extras.h"

#import "RptqDataHelper.h"

@implementation RptqDocumentElementImage (Extras)

#pragma mark - Overrides

#if defined(__APPLE__) && TARGET_OS_IPHONE

// The store's Blob column holds PNG bytes -- what the legacy converter writes
// (MADStorePNGData) and what MADPngImageTransformer produced before it -- while the
// declared property is a UIImage.  The accessors are where the two forms meet, so a
// picture set here survives the save and reads back as a picture.  Apple only:
// UIImage is UIKit's, and nothing builds an image element off Apple.

- (UIImage *)image {
	id value = [self valueForUndefinedKey:@"image"];
	if ([value isKindOfClass:[NSData class]]) return [UIImage imageWithData:value];
	return [value isKindOfClass:[UIImage class]] ? value : nil;
}

- (void)setImage:(UIImage *)image {
	// The attribute is optional, so an image with no representation clears the column.
	[self setValue:(image ? UIImagePNGRepresentation(image) : nil) forUndefinedKey:@"image"];
}

#elif defined(__APPLE__) && TARGET_OS_OSX

- (NSImage *)image {
	id value = [self valueForUndefinedKey:@"image"];
	if ([value isKindOfClass:[NSData class]]) return [[NSImage alloc] initWithData:value];
	return [value isKindOfClass:[NSImage class]] ? value : nil;
}

- (void)setImage:(NSImage *)image {
	NSData *pngData = nil;
	if (image != nil) {
		CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
		if (cgImage != NULL) {
			NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
			pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
		}
	}
	[self setValue:pngData forUndefinedKey:@"image"];
}

#endif

// The store's wire format, portable: the column always carries PNG bytes.  Off
// Apple those bytes are the picture (no decoding exists); where UIKit or AppKit
// exists, a picture set through -image is encoded on the way into the column and
// this accessor codes it back out for the formats and the designer's snapshot.
- (NSData *)pngData {
	id value = [self valueForUndefinedKey:@"image"];
	if ([value isKindOfClass:[NSData class]]) return value;
#if defined(__APPLE__) && TARGET_OS_IPHONE
	UIImage *image = [self image];
	return image != nil ? UIImagePNGRepresentation(image) : nil;
#elif defined(__APPLE__) && TARGET_OS_OSX
	NSImage *image = [self image];
	if (image == nil) return nil;
	CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
	if (cgImage == NULL) return nil;
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
	return [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
#else
	return nil;
#endif
}

// Stores the bytes verbatim rather than decoding and re-encoding them, so a PNG
// set by the designer round-trips through the engine unchanged on every platform.
- (void)setPngData:(NSData *)pngData {
	[self setValue:pngData forUndefinedKey:@"image"];
}

- (NSString *)designerRepresentationText {
	return @"image";
}

#pragma mark - RptqDocumentElementFactory

+ (instancetype)getElementForObjectID:(int64_t)objectId
					fromObjectContext:(RptqStoreContext *)managedObjectContext {
	RptqObject *result = [managedObjectContext objectForEntity:NSStringFromClass([RptqDocumentElement class]) identifier:objectId];
	return (RptqDocumentElementImage *)result;
}

- (id)debugQuickLookObject {
	return self.image;
}

@end
