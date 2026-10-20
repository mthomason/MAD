//
//  MADBarcodeTests.m
//  MADBarcodesTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADBarcode, the framework's base class and factory: the init
//  defaults the zint pass reads, the type-to-class factory, the two document-object
//  constructors, the name table, and one real draw through zint into a bitmap.
//
//  Note the framework is ARC with one exception: MADBarcodeView.m is compiled
//  -fno-objc-arc.  Nothing here touches that file.
//

#import <XCTest/XCTest.h>

#import <UIKit/UIGraphics.h>
#import <UIKit/UIColor.h>

#import "MADBarcode.h"
#import "MADBarcodeCache.h"
#import "MADBarcodeCode39Iso16388.h"
#import "MADBarcodeCode128Iso15417.h"
#import "MADBarcodeQrCodeIso18004.h"
#import "MADBarcodeDataMatrixIso16022.h"
#import "MADBarcodeUniversalProductCodeUpca.h"
#import "zint.h"

#pragma mark - Test double

// The protocol is all storage; the double just records what the factory reads.
@interface MADBarcodeDocumentDouble : NSObject <MADBarcodeProtocol>
@property (nonatomic, assign) int16_t barcodeType;
@property (nonatomic, assign) int16_t barcodeBorderStyle;
@property (nonatomic, assign) int16_t whitespaceWidth;
@property (nonatomic, assign) BOOL has2dComponentEnabled;
@property (nonatomic, assign) int16_t barcodeBorderWidth;
@property (nonatomic, assign) int16_t barcodeHeight;
@property (nonatomic, assign) BOOL humanReadable;
@property (nonatomic, assign) int16_t option1;
@property (nonatomic, assign) int16_t option2;
@property (nonatomic, assign) int16_t option3;
@property (nonatomic, assign) BOOL showErrorMessage;
@property (nonatomic, assign) float scale;
@end

@implementation MADBarcodeDocumentDouble
@end

@interface MADBarcodeTests : XCTestCase
@end

@implementation MADBarcodeTests

- (void)setUp {
	[super setUp];
	[[MADBarcodeCache sharedCache] flush];
}

- (void)tearDown {
	[[MADBarcodeCache sharedCache] flush];
	[super tearDown];
}

#pragma mark - Init defaults

- (void)testInitDefaults {
	MADBarcode *barcode = [[MADBarcode alloc] init];

	// The zint pass reads every one of these.
	XCTAssertTrue(barcode.showErrorMessage);
	XCTAssertTrue(barcode.humanReadable);
	XCTAssertEqual(barcode.barcodeHeight, (int16_t)50);
	XCTAssertEqual(barcode.barcodeBorderWidth, (int16_t)5);
	XCTAssertFalse(barcode.option1);
	XCTAssertFalse(barcode.option2);
	XCTAssertFalse(barcode.option3);
	XCTAssertFalse(barcode.center);
	XCTAssertEqualWithAccuracy(barcode.scale, 1.0f, 0.0001f);
	// The base class names nothing and defers the type to its subclasses.
	XCTAssertNil(barcode.name);
	XCTAssertEqual(barcode.barcodeType, (int16_t)0);
}

#pragma mark - Factory

- (void)testFactoryMapsTypesToClasses {
	XCTAssertEqualObjects(NSStringFromClass([[MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39] class]),
						  @"MADBarcodeCode39Iso16388");
	XCTAssertEqualObjects(NSStringFromClass([[MADBarcode newBarcodeWithType:MADBarcodeTypeCODE128] class]),
						  @"MADBarcodeCode128Iso15417");
	XCTAssertEqualObjects(NSStringFromClass([[MADBarcode newBarcodeWithType:MADBarcodeTypeQrcode] class]),
						  @"MADBarcodeQrCodeIso18004");
	XCTAssertEqualObjects(NSStringFromClass([[MADBarcode newBarcodeWithType:MADBarcodeTypeDataMatrix] class]),
						  @"MADBarcodeDataMatrixIso16022");
	XCTAssertEqualObjects(NSStringFromClass([[MADBarcode newBarcodeWithType:MADBarcodeTypeUpca] class]),
						  @"MADBarcodeUniversalProductCodeUpca");
}

- (void)testFactoryReturnsNilForAnUnmappedType {
	// The base class's own type is not a symbology; the switch falls through.
	XCTAssertNil([MADBarcode newBarcodeWithType:(MADBarcodeType)0]);
	XCTAssertNil([MADBarcode newBarcodeWithType:(MADBarcodeType)-1]);
}

#pragma mark - Document-object constructors

- (void)testFactoryCopiesTheDocumentObject {
	MADBarcodeDocumentDouble *document = [[MADBarcodeDocumentDouble alloc] init];
	document.barcodeType = MADBarcodeTypeCODE39;
	document.barcodeBorderStyle = MADBarcodeBorderStyleBox;
	document.whitespaceWidth = 3;
	document.has2dComponentEnabled = YES;
	document.barcodeBorderWidth = 2;
	document.barcodeHeight = 40;
	document.humanReadable = NO;
	document.option1 = YES;
	document.option2 = YES;
	document.option3 = YES;
	document.showErrorMessage = NO;
	document.scale = 2.0f;

	MADBarcode *barcode = [MADBarcode newBarcode:document];

	XCTAssertEqualObjects(NSStringFromClass([barcode class]), @"MADBarcodeCode39Iso16388");
	XCTAssertEqual(barcode.barcodeBorderStyle, (int16_t)MADBarcodeBorderStyleBox);
	XCTAssertEqual(barcode.whitespaceWidth, (int16_t)3);
	XCTAssertTrue(barcode.has2dComponentEnabled);
	XCTAssertEqual(barcode.barcodeBorderWidth, (int16_t)2);
	XCTAssertEqual(barcode.barcodeHeight, (int16_t)40);
	XCTAssertFalse(barcode.humanReadable);
	XCTAssertTrue(barcode.option1);
	XCTAssertTrue(barcode.option2);
	XCTAssertTrue(barcode.option3);
	XCTAssertFalse(barcode.showErrorMessage);
	XCTAssertEqualWithAccuracy(barcode.scale, 2.0f, 0.0001f);
	// The constructor seeds the sample values the editor starts from.
	XCTAssertEqualObjects(barcode.input, @"Sample data");
	XCTAssertEqualObjects(barcode.primaryData, @"");
}

- (void)testFactoryWithInputsOverridesTheSampleData {
	MADBarcodeDocumentDouble *document = [[MADBarcodeDocumentDouble alloc] init];
	document.barcodeType = MADBarcodeTypeCODE39;

	MADBarcode *barcode = [MADBarcode newBarcode:document input1:@"ABC-123" input2:@"2D"];

	XCTAssertEqualObjects(barcode.input, @"ABC-123");
	XCTAssertEqualObjects(barcode.primaryData, @"2D");
}

#pragma mark - Names

- (void)testDictionaryNamesAreWellFormed {
	NSDictionary *names = [MADBarcode newDictionaryNames];

	XCTAssertGreaterThan(names.count, (NSUInteger)50);
	for (id key in names) {
		XCTAssertTrue([key isKindOfClass:[NSNumber class]]);
		NSString *name = names[key];
		XCTAssertTrue([name isKindOfClass:[NSString class]]);
		XCTAssertGreaterThan(name.length, (NSUInteger)0);
	}
}

- (void)testNameForType {
	XCTAssertEqualObjects([MADBarcode newBarcodeNameForType:MADBarcodeTypeCODE39], @"Code 39 (ISO 16388)");
	XCTAssertEqualObjects([MADBarcode newBarcodeNameForType:MADBarcodeTypeQrcode], @"QR Code (ISO 18004)");
	XCTAssertEqualObjects([MADBarcode newBarcodeNameForType:MADBarcodeTypeDataMatrix], @"Data Matrix (ISO 16022)");
	// A type with no entry answers nil, not an empty string.
	XCTAssertNil([MADBarcode newBarcodeNameForType:(MADBarcodeType)-1]);
}

- (void)testLoadSampleDataIsANoOpOnTheBaseClass {
	MADBarcode *barcode = [[MADBarcode alloc] init];
	barcode.input = @"kept";

	[barcode loadSampleData];

	XCTAssertEqualObjects(barcode.input, @"kept");
}

#pragma mark - Drawing

// Paints into an offscreen RGB bitmap and reports whether anything other than the
// white background landed on it.
- (BOOL)drawBarcode:(MADBarcode *)barcode intoSize:(CGSize)size {
	size_t width = (size_t)size.width;
	size_t height = (size_t)size.height;
	unsigned char *pixels = calloc(width * height * 4, 1);
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * 4, space,
												 kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(space);

	CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
	CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));

	UIGraphicsPushContext(context);
	[barcode drawInRect:CGRectMake(0, 0, size.width, size.height)];
	UIGraphicsPopContext();

	BOOL painted = NO;
	for (size_t i = 0; i < width * height * 4 && !painted; i += 4) {
		if (pixels[i] != 255 || pixels[i + 1] != 255 || pixels[i + 2] != 255) painted = YES;
	}

	CGContextRelease(context);
	free(pixels);
	return painted;
}

- (void)testDrawPaintsACode39 {
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	barcode.input = @"TEST";

	XCTAssertTrue([self drawBarcode:barcode intoSize:CGSizeMake(220, 110)]);
}

- (void)testOverlongPrimaryDataIsRefused {
	// zint's primary buffer is 128 bytes; a longer second input must not be copied,
	// must not encode a symbol, and must follow the ordinary error path.
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypeEAN128];
	barcode.has2dComponentEnabled = YES;
	barcode.has2dComponentType = 0;
	barcode.input = [@"A" stringByPaddingToLength:200 withString:@"A" startingAtIndex:0];

	XCTAssertNil([barcode renderedImage], @"an overlong primary value must not render");

	barcode.showErrorMessage = NO;
	XCTAssertFalse([self drawBarcode:barcode intoSize:CGSizeMake(220, 110)],
				   @"an overlong primary value must not produce a symbol");

	barcode.showErrorMessage = YES;
	XCTAssertTrue([self drawBarcode:barcode intoSize:CGSizeMake(220, 110)],
				  @"the error text must be drawn when showErrorMessage is on");
}

#pragma mark - Rendered image

- (void)testRenderedImageMatchesTheZintBitmap {
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	barcode.input = @"TEST";

	// Encode the same values through zint to know the bitmap the image must hold.
	struct zint_symbol *reference = ZBarcode_Create();
	XCTAssertTrue(reference != NULL);
	if (reference == NULL) {
		return;
	}
	reference->symbology = barcode.barcodeType;
	reference->height = (float)barcode.barcodeHeight;
	reference->border_width = (int)barcode.barcodeBorderWidth;
	reference->whitespace_width = (int)barcode.whitespaceWidth;
	reference->show_hrt = barcode.humanReadable;
	reference->output_options = barcode.barcodeBorderStyle;
	reference->scale = 1.0f;
	reference->input_mode = UNICODE_MODE;
	reference->option_1 = (int)barcode.option1;
	reference->option_2 = (int)barcode.option2;
	reference->option_3 = (int)barcode.option3;
	int result = ZBarcode_Encode_and_Buffer(reference, (unsigned char *)"TEST", 4, 0);
	XCTAssertEqual(result, 0);
	CGSize expected = CGSizeMake((CGFloat)reference->bitmap_width,
								 (CGFloat)reference->bitmap_height);
	ZBarcode_Delete(reference);

	UIImage *image = [barcode renderedImage];

	XCTAssertNotNil(image);
	XCTAssertEqualWithAccuracy(image.size.width, expected.width, 0.5);
	XCTAssertEqualWithAccuracy(image.size.height, expected.height, 0.5);
}

- (void)testRenderedImageIsNilWhenZintRefusesTheInput {
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	barcode.input = @"";

	XCTAssertNil([barcode renderedImage]);
}

#pragma mark - Cache

- (void)testCacheSharesOneImageBetweenEquivalentBarcodes {
	MADBarcode *first = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	first.input = @"TEST";
	MADBarcode *second = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	second.input = @"TEST";

	UIImage *firstImage = [[MADBarcodeCache sharedCache] imageForBarcode:first];
	UIImage *secondImage = [[MADBarcodeCache sharedCache] imageForBarcode:second];

	XCTAssertNotNil(firstImage);
	XCTAssertTrue(firstImage == secondImage,
				  @"an equal render key must serve the identical image");
}

- (void)testCacheSeparatesDifferentInputs {
	MADBarcode *first = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	first.input = @"TEST";
	MADBarcode *second = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	second.input = @"OTHER";

	UIImage *firstImage = [[MADBarcodeCache sharedCache] imageForBarcode:first];
	UIImage *secondImage = [[MADBarcodeCache sharedCache] imageForBarcode:second];

	XCTAssertNotNil(firstImage);
	XCTAssertNotNil(secondImage);
	XCTAssertFalse(firstImage == secondImage);
	XCTAssertNotEqualObjects(first.renderCacheKey, second.renderCacheKey);
}

- (void)testCacheKeepsTheErrorForAnInvalidBarcode {
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	barcode.input = @"";

	XCTAssertNil([[MADBarcodeCache sharedCache] imageForBarcode:barcode]);
	XCTAssertNotNil([[MADBarcodeCache sharedCache] errorMessageForBarcode:barcode]);
}

- (void)testFlushForcesARerender {
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	barcode.input = @"TEST";

	UIImage *firstImage = [[MADBarcodeCache sharedCache] imageForBarcode:barcode];
	[[MADBarcodeCache sharedCache] flush];
	UIImage *secondImage = [[MADBarcodeCache sharedCache] imageForBarcode:barcode];

	XCTAssertNotNil(firstImage);
	XCTAssertNotNil(secondImage);
	XCTAssertFalse(firstImage == secondImage);
}

#pragma mark - Render key

- (void)testRenderCacheKeyIsEqualForEquivalentBarcodes {
	MADBarcode *first = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	first.input = @"TEST";
	first.primaryData = @"2D";
	MADBarcode *second = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	second.input = @"TEST";
	second.primaryData = @"2D";

	XCTAssertEqualObjects(first.renderCacheKey, second.renderCacheKey);
}

- (void)testRenderCacheKeyCoversEveryDrawInput {
	MADBarcode *base = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	base.input = @"TEST";

	MADBarcode *variant = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	variant.input = @"TEST";
	variant.option1 = 1;
	XCTAssertNotEqualObjects(base.renderCacheKey, variant.renderCacheKey);

	variant = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	variant.input = @"TEST";
	variant.humanReadable = NO;
	XCTAssertNotEqualObjects(base.renderCacheKey, variant.renderCacheKey);

	variant = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	variant.input = @"TEST";
	variant.center = YES;
	XCTAssertNotEqualObjects(base.renderCacheKey, variant.renderCacheKey);

	variant = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	variant.input = @"TEST";
	variant.scale = 2.0f;
	XCTAssertNotEqualObjects(base.renderCacheKey, variant.renderCacheKey);

	variant = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	variant.input = @"TEST";
	variant.barcodeBorderStyle = MADBarcodeBorderStyleBox;
	XCTAssertNotEqualObjects(base.renderCacheKey, variant.renderCacheKey);

	variant = [MADBarcode newBarcodeWithType:MADBarcodeTypeCODE39];
	variant.input = @"TEST";
	variant.has2dComponentEnabled = YES;
	variant.has2dComponentType = 1;
	XCTAssertNotEqualObjects(base.renderCacheKey, variant.renderCacheKey);
}

#pragma mark - Coding

- (void)testNSCodingRoundTripPreservesTheState {
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypeQrcode];
	barcode.input = @"TEST";
	barcode.primaryData = @"2D";
	barcode.barcodeHeight = 99;
	barcode.barcodeBorderWidth = 3;
	barcode.barcodeBorderStyle = MADBarcodeBorderStyleBox;
	barcode.whitespaceWidth = 7;
	barcode.humanReadable = NO;
	barcode.option1 = 1;
	barcode.option2 = 2;
	barcode.option3 = 3;
	barcode.showErrorMessage = NO;
	barcode.scale = 2.5f;
	barcode.has2dComponentEnabled = YES;
	barcode.has2dComponentType = 4;
	barcode.center = YES;
	barcode.width = 123;

	NSError *error = nil;
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:barcode
									  requiringSecureCoding:YES
													  error:&error];
	XCTAssertNotNil(data, @"%@", error);
	MADBarcode *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:[MADBarcode class]
														   fromData:data
															  error:&error];
	XCTAssertNotNil(decoded, @"%@", error);

	XCTAssertEqualObjects(NSStringFromClass([decoded class]), @"MADBarcodeQrCodeIso18004");
	XCTAssertEqualObjects(decoded.name, @"QR Code (ISO 18004)");
	XCTAssertEqualObjects(decoded.detailsSegueIdentifer, @"MTIdentiferSegueBarcodeExtrasQrCode");
	XCTAssertEqualObjects(decoded.input, @"TEST");
	XCTAssertEqualObjects(decoded.primaryData, @"2D");
	XCTAssertEqual(decoded.barcodeType, (int16_t)MADBarcodeTypeQrcode);
	XCTAssertEqual(decoded.barcodeBorderStyle, (int16_t)MADBarcodeBorderStyleBox);
	XCTAssertEqual(decoded.whitespaceWidth, (int16_t)7);
	XCTAssertEqual(decoded.barcodeBorderWidth, (int16_t)3);
	XCTAssertEqual(decoded.barcodeHeight, (int16_t)99);
	XCTAssertFalse(decoded.humanReadable);
	XCTAssertEqual(decoded.option1, (int16_t)1);
	XCTAssertEqual(decoded.option2, (int16_t)2);
	XCTAssertEqual(decoded.option3, (int16_t)3);
	XCTAssertFalse(decoded.showErrorMessage);
	XCTAssertEqualWithAccuracy(decoded.scale, 2.5f, 0.0001f);
	XCTAssertTrue(decoded.has2dComponentEnabled);
	XCTAssertEqual(decoded.has2dComponentType, (NSInteger)4);
	XCTAssertTrue(decoded.center);
	XCTAssertEqual(decoded.width, (NSInteger)123);
	XCTAssertFalse(decoded.has2dComponent);
	XCTAssertTrue(decoded.hasOptionalInput);
}

@end
