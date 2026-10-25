//
//  MADDocumentObjectDataReferenceImageTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADDocumentObjectDataReferenceImage: the handle over an
//  image element.  It simply hands back the element's `image`.
//
//  This file also pins the image's journey through the portable store.  The element
//  declares `UIImage *image` (RptqDocumentElementImage.h) and the designer assigns a
//  UIImage (RptqDocument+Extras.m, addDocumentObject:...), while the store's Blob column
//  holds PNG bytes (MADStore.m's binder and reader; the legacy converter writes the same
//  form).  RptqDocumentElementImage (Extras) converts between the two at the attribute
//  boundary, so the picture set in memory is the picture read back after a reopen.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/UIColor.h>
#import <CoreGraphics/CGContext.h>

#import "MADDocumentObjectDataReference.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocumentElementImage.h"
#import "RptqDocumentElement+Extras.h"

@interface MADDocumentObjectDataReferenceImageTests : XCTestCase
@property (nonatomic, strong) NSURL *directory;
@end

@implementation MADDocumentObjectDataReferenceImageTests

- (void)setUp {
	[super setUp];
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:NULL];
	self.directory = [NSURL fileURLWithPath:directory isDirectory:YES];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:self.directory error:NULL];
	[super tearDown];
}

#pragma mark - Fixture

- (RptqStoreContext *)openContextAtPath:(NSString *)name {
	NSURL *url = [self.directory URLByAppendingPathComponent:name];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	return [RptqStoreContext contextWithStore:store];
}

- (UIImage *)onePixelImage {
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 1);
	[[UIColor redColor] setFill];
	UIRectFill(CGRectMake(0, 0, 1, 1));
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

// The two images are the same picture when both redraw to the same pixels in one
// common format.  PNG bytes are not stable across a decode/re-encode, so comparing
// the encodings would fail on the encoding, not the picture.
- (NSData *)redrawnPixelsOfImage:(UIImage *)image {
	CGImageRef cgImage = image.CGImage;
	if (!cgImage) return nil;
	size_t width = CGImageGetWidth(cgImage), height = CGImageGetHeight(cgImage);
	if (width == 0 || height == 0) return nil;
	NSMutableData *pixels = [NSMutableData dataWithLength:width * height * 4];
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(pixels.mutableBytes, width, height, 8, width * 4, space,
												 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(space);
	if (!context) return nil;
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
	CGContextRelease(context);
	return pixels;
}

- (MADDocumentObjectDataReferenceImage *)referenceForElement:(RptqDocumentElementImage *)element {
	return (MADDocumentObjectDataReferenceImage *)[MADDocumentObjectDataReference newDocumentObjectDataReference:nil
																										 delegate:nil
																											 page:1
																											 item:element
																										   itemID:3];
}

#pragma mark - Tests

- (void)testFactoryReturnsImageReference {
	RptqStoreContext *context = [self openContextAtPath:@"factory.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;

	MADDocumentObjectDataReferenceImage *reference = [self referenceForElement:element];

	XCTAssertEqualObjects(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceImage");
	XCTAssertEqual(reference.type, MADPrintPageElementTypeImage);
}

- (void)testImageIsNilWhenTheElementHasNone {
	RptqStoreContext *context = [self openContextAtPath:@"unset.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;

	MADDocumentObjectDataReferenceImage *reference = [self referenceForElement:element];

	XCTAssertNil(reference.image);
}

- (void)testImageIsTheElementImageWhileInMemory {
	RptqStoreContext *context = [self openContextAtPath:@"memory.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);
	UIImage *image = [self onePixelImage];
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;
	element.image = image;

	MADDocumentObjectDataReferenceImage *reference = [self referenceForElement:element];

	// The setter stores the picture as PNG bytes and the getter decodes them, so the
	// element hands back the same picture, not the same object.
	XCTAssertTrue([reference.image isKindOfClass:[UIImage class]]);
	XCTAssertEqualObjects([self redrawnPixelsOfImage:reference.image], [self redrawnPixelsOfImage:image]);
}

- (void)testTheStoredBlobIsTheImagesPNGData {
	RptqStoreContext *context = [self openContextAtPath:@"wireformat.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);
	UIImage *image = [self onePixelImage];
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;
	element.image = image;

	// The store's wire format for the attribute: what a save would bind and a read
	// would hand back is the PNG encoding of the image, not the image or NULL.
	NSData *stored = [element.backingObject attributeValue:@"image"];
	XCTAssertTrue([stored isKindOfClass:[NSData class]]);
	XCTAssertEqualObjects(stored, UIImagePNGRepresentation(image));
}

- (void)testImageSurvivesSaveAndReopen {
	RptqStoreContext *context = [self openContextAtPath:@"persistence.sqlite"];
	XCTAssertTrue([context loadAllWithError:NULL]);
	UIImage *image = [self onePixelImage];
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;
	element.image = image;
	int64_t elementIdentifier = element.identifier;

	NSError *error = nil;
	XCTAssertTrue([context save:&error], @"save failed: %@", error);

	RptqStoreContext *reread = [self openContextAtPath:@"persistence.sqlite"];
	XCTAssertTrue([reread loadAllWithError:&error], @"load failed: %@", error);
	RptqDocumentElementImage *readElement = (RptqDocumentElementImage *)[reread objectForEntity:@"RptqDocumentElementImage"
																					  identifier:elementIdentifier];

	XCTAssertNotNil(readElement);
	// The picture set before the save is the picture the reopened document hands back.
	XCTAssertTrue([readElement.image isKindOfClass:[UIImage class]]);
	XCTAssertEqualObjects([self redrawnPixelsOfImage:readElement.image], [self redrawnPixelsOfImage:image]);
}

@end
