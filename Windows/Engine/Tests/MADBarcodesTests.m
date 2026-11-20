//
//  MADBarcodesTests.m
//  Linux/Tests
//
//  The headless half of the MADBarcodes suite: the type-to-class factory and
//  name table, and the UIKit-free render core -- zint's bitmap through libpng
//  into PNG bytes.  The Apple XCTest suite (MADBarcodes/MADBarcodesTests) covers
//  the drawing and cache paths that need a UIkit.
//

#import "MADTestSupport.h"

#import <MADBarcodes/MADBarcode.h>
#import <MADBarcodes/MADBarcodeType.h>

static void testFactoryBuildsCode128(void) {
	MADBarcode *barcode = [MADBarcode newBarcodeWithType: MADBarcodeTypeCODE128];
	MAD_PASS(barcode != nil, "the factory builds Code 128");
	MAD_PASS_EQUAL(NSStringFromClass([barcode class]), @"MADBarcodeCode128Iso15417",
				   "the factory answers the Code 128 class");
	MAD_PASS_EQUAL(barcode.name, @"Code 128 (ISO 15417)", "the name table answers the type's name");
}

static void testNameTableAnswersASymbology(void) {
	MAD_PASS_EQUAL([MADBarcode newBarcodeNameForType: MADBarcodeTypeQrcode],
				   @"QR Code (ISO 18004)", "QR Code is in the name table");
}

static void testRenderedPNGDataIsAPNG(void) {
	MADBarcode *barcode = [MADBarcode newBarcodeWithType: MADBarcodeTypeCODE128];
	barcode.input = @"MAD-2026";
	barcode.humanReadable = YES;
	barcode.barcodeHeight = 40;

	NSData *png = [barcode renderedPNGData];
	MAD_NEED(png != nil, @"the Code 128 render produced no bytes");

	const uint8_t *bytes = png.bytes;
	MAD_PASS(png.length > 33, "the render is longer than the PNG signature and IHDR");
	MAD_PASS(bytes[0] == 0x89 && bytes[1] == 'P' && bytes[2] == 'N' && bytes[3] == 'G',
			 "the bytes carry the PNG signature");

	// The IHDR is the first chunk: width and height are big-endian 32-bit at 16 and 20.
	uint32_t width = ((uint32_t)bytes[16] << 24) | ((uint32_t)bytes[17] << 16) |
					 ((uint32_t)bytes[18] << 8) | (uint32_t)bytes[19];
	uint32_t height = ((uint32_t)bytes[20] << 24) | ((uint32_t)bytes[21] << 16) |
					  ((uint32_t)bytes[22] << 8) | (uint32_t)bytes[23];
	MAD_PASS(width > 0 && height > 0, "the PNG header carries a non-zero size (%u x %u)",
			 width, height);
}

static void testInvalidInputReportsTheMessage(void) {
	MADBarcode *barcode = [MADBarcode newBarcodeWithType: MADBarcodeTypeCODE128];
	barcode.input = @"";

	NSString *message = nil;
	NSData *png = [barcode renderedPNGDataWithErrorMessage: &message];
	MAD_PASS(png == nil, "empty input does not render");
	MAD_PASS(message.length > 0, "the failed zint pass reports a message");
}

static void testRenderCacheKeyCoversTheInput(void) {
	MADBarcode *first = [MADBarcode newBarcodeWithType: MADBarcodeTypeCODE128];
	first.input = @"A";
	MADBarcode *second = [MADBarcode newBarcodeWithType: MADBarcodeTypeCODE128];
	second.input = @"B";

	MAD_PASS(![first.renderCacheKey isEqualToString: second.renderCacheKey],
			 "two inputs have two render keys");
}

MAD_TEST_MAIN("MADBarcodesTests",
	MAD_TEST(testFactoryBuildsCode128),
	MAD_TEST(testNameTableAnswersASymbology),
	MAD_TEST(testRenderedPNGDataIsAPNG),
	MAD_TEST(testInvalidInputReportsTheMessage),
	MAD_TEST(testRenderCacheKeyCoversTheInput));
