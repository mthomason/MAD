//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADImageElementTests.m
//  Linux/Tests
//
//  The image element's headless render path.  The element is already stored as
//  PNG bytes; off Apple the model type is those bytes (MADElementImage), so a
//  picture set on the element reaches the data reference unchanged, the drawing
//  object answers it as -renderedImageData, and the line representation -- the
//  seam every exporter reads -- carries it to the formats.
//

#import "MADTestSupport.h"

#import <MAD/MADDocumentObjectDataReference.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/MADPrintPageElement.h>
#import <MAD/MADPrintPageElement+Constructor.h>
#import <MAD/MADReportLineRepresentation.h>
#import <MAD/MADStore.h>
#import <MAD/RptqDocumentElementImage.h>
#import <MAD/RptqStoreContext.h>

/// A real 1x1 transparent PNG -- the wire format the image column carries.
static NSData *MADImageOnePixelPNG(void) {
	static NSData *data = nil;
	if (data == nil) {
		data = [[NSData alloc] initWithBase64EncodedString:
				@"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
												   options: 0];
	}
	return data;
}

static NSURL *makeTempDirectory(void) {
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	NSURL *directory = [NSURL fileURLWithPath:path isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:directory
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:nil];
	return directory;
}

static RptqStoreContext *openContextAtPath(NSURL *directory, NSString *name) {
	MADStore *store = [MADStore storeWithURL:[directory URLByAppendingPathComponent:name]];
	MAD_PASS([store openWithError:NULL], "the store opens");
	return [RptqStoreContext contextWithStore:store];
}

static RptqDocumentElementImage *imageElement(RptqStoreContext *context, NSData *png) {
	RptqDocumentElementImage *element = (RptqDocumentElementImage *)[context insertObjectForEntity:@"RptqDocumentElementImage" identifier:0];
	element.type = MADPrintPageElementTypeImage;
	element.image = png;
	return element;
}

static MADDocumentObjectDataReference *referenceFor(RptqDocumentElementImage *element) {
	return [MADDocumentObjectDataReference newDocumentObjectDataReference:nil
																 delegate:nil
																	 page:1
																	 item:element
																   itemID:7];
}

#pragma mark - Tests

static void testTheReferenceHandsBackTheStoredPNG(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"reference.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");
	NSData *png = MADImageOnePixelPNG();
	MAD_PASS(png.length > 0, "the fixture decodes to PNG bytes");

	MADDocumentObjectDataReference *reference = referenceFor(imageElement(context, png));

	MAD_PASS_EQUAL(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceImage",
				   "the factory returns the image reference");
	MAD_PASS_EQUAL(((MADDocumentObjectDataReferenceImage *)reference).image, png,
				   "the reference hands back the element's PNG bytes");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static void testTheDrawingObjectAnswersTheStoredPNG(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"drawing.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");
	NSData *png = MADImageOnePixelPNG();

	MADDocumentObjectDataReference *reference = referenceFor(imageElement(context, png));
	MADPrintPageElement *drawingObject = [MADPrintPageElement newDocumentObject:reference];

	MAD_PASS_EQUAL(NSStringFromClass([drawingObject class]), @"MADPrintPageElementImage",
				   "the constructor builds the image drawing object");
	MAD_PASS_EQUAL([(MADPrintPageElementImage *)drawingObject renderedImageData], png,
				   "the drawing object answers the stored PNG as its rendered image data");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static void testTheDrawingObjectAnswersNilWithoutAnImage(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"empty.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");

	MADDocumentObjectDataReference *reference = referenceFor(imageElement(context, nil));
	MADPrintPageElement *drawingObject = [MADPrintPageElement newDocumentObject:reference];

	MAD_PASS([(MADPrintPageElementImage *)drawingObject renderedImageData] == nil,
			 "an element without a picture has no rendered image data");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static void testTheLineRepresentationCarriesTheImage(void) {
	NSURL *directory = makeTempDirectory();
	RptqStoreContext *context = openContextAtPath(directory, @"line.sqlite");
	MAD_PASS([context loadAllWithError:NULL], "the context loads");
	NSData *png = MADImageOnePixelPNG();

	MADDocumentObjectDataReference *reference = referenceFor(imageElement(context, png));
	MADPrintPageElement *drawingObject = [MADPrintPageElement newDocumentObject:reference];
	MADReportLineRepresentation *line = [[MADReportLineRepresentation alloc]
										 initWithObject:drawingObject
												   type:MADPrintPageElementTypeImage
												  frame:CGRectMake(0.0, 0.0, 96.0, 64.0)];

	MAD_PASS([line text] == nil, "an image line has no text");
	MAD_PASS_EQUAL([line imageData], png, "the line representation carries the PNG for the exporters");

	[[NSFileManager defaultManager] removeItemAtURL:directory error:nil];
}

static void testATextLineHasNoImageData(void) {
	MADReportLineRepresentation *line = [[MADReportLineRepresentation alloc]
										 initWithObject:@"Hello"
												   type:MADPrintPageElementTypeLabelStatic
												  frame:CGRectMake(0.0, 0.0, 120.0, 20.0)];
	MAD_PASS([line imageData] == nil, "a text line has no image data");
}

MAD_TEST_MAIN("MADImageElementTests",
	MAD_TEST(testTheReferenceHandsBackTheStoredPNG),
	MAD_TEST(testTheDrawingObjectAnswersTheStoredPNG),
	MAD_TEST(testTheDrawingObjectAnswersNilWithoutAnImage),
	MAD_TEST(testTheLineRepresentationCarriesTheImage),
	MAD_TEST(testATextLineHasNoImageData));
