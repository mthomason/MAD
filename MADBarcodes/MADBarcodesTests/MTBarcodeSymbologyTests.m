//
//  MTBarcodeSymbologyTests.m
//  MADBarcodesTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  The symbology matrix: for a representative set of the framework's one-class-per-
//  type subclasses, pin what the factory builds, what the instance calls itself, and
//  which type it claims.  Two entries are deliberately recorded as defects (the QR
//  class claims OneCode; the ISBN class's +type recurses) -- see BUGS.md.
//

#import <XCTest/XCTest.h>

#import "MTBarcode.h"
#import "MTBarcodeAztec.h"
#import "MTBarcodeCodabar.h"
#import "MTBarcodeCode2of5Interleaved.h"
#import "MTBarcodeCode39Iso16388.h"
#import "MTBarcodeCode128Iso15417.h"
#import "MTBarcodeDataMatrixIso16022.h"
#import "MTBarcodeEuropeanArticleNumberEan.h"
#import "MTBarcodeInternationalStandardBookNumberIsbn.h"
#import "MTBarcodeItf14.h"
#import "MTBarcodeMaxicodeIso16023.h"
#import "MTBarcodeMicroQrCode.h"
#import "MTBarcodePdf417Iso15438.h"
#import "MTBarcodePostnet.h"
#import "MTBarcodeQrCodeIso18004.h"
#import "MTBarcodeUniversalProductCodeUpca.h"

@interface MTBarcodeSymbologyTests : XCTestCase
@end

@implementation MTBarcodeSymbologyTests

#pragma mark - Matrix

- (void)testFactoryBuildsTheExpectedClassWithItsOwnNameAndType {
	NSArray<NSArray *> *matrix = @[
		@[ @(MTBarcodeTypeCODE39),   @"MTBarcodeCode39Iso16388",   @"Code 39 (ISO 16388)" ],
		@[ @(MTBarcodeTypeCODE128),  @"MTBarcodeCode128Iso15417",  @"Code 128 (ISO 15417)" ],
		@[ @(MTBarcodeTypeDataMatrix), @"MTBarcodeDataMatrixIso16022", @"Data Matrix (ISO 16022)" ],
		@[ @(MTBarcodeTypeEANX),     @"MTBarcodeEuropeanArticleNumberEan", @"European Article Number (EAN)" ],
		@[ @(MTBarcodeTypeUpca),     @"MTBarcodeUniversalProductCodeUpca", @"Universal Product Code (UPC-A)" ],
		@[ @(MTBarcodeTypeAztec),    @"MTBarcodeAztec",             @"Aztec Code (ISO 24778)" ],
		@[ @(MTBarcodeTypeCODABAR),  @"MTBarcodeCodabar",           @"Codabar" ],
		@[ @(MTBarcodeTypeC25INTER), @"MTBarcodeCode2of5Interleaved", @"Code 2 of 5 Interleaved" ],
		@[ @(MTBarcodeTypePostnet),  @"MTBarcodePostnet",           @"Postnet" ],
		@[ @(MTBarcodeTypeMaxicode), @"MTBarcodeMaxicodeIso16023",  @"Maxicode (ISO 16023)" ],
		@[ @(MTBarcodeTypeMicroqr),  @"MTBarcodeMicroQrCode",       @"Micro QR Code" ],
		@[ @(MTBarcodeTypeItf14),    @"MTBarcodeItf14",             @"ITF-14" ],
	];

	for (NSArray *row in matrix) {
		MTBarcodeType type = (MTBarcodeType)[row[0] intValue];
		MTBarcode *barcode = [MTBarcode newBarcodeWithType:type];

		XCTAssertNotNil(barcode, @"%@", row[1]);
		XCTAssertEqualObjects(NSStringFromClass([barcode class]), row[1]);
		XCTAssertEqualObjects(barcode.name, row[2]);
		XCTAssertEqual(barcode.barcodeType, (int16_t)type,
					   @"%@ reports type %d", row[1], barcode.barcodeType);
	}
}

- (void)testPdf417NameComesFromTheDisplayConstant {
	MTBarcode *barcode = [MTBarcode newBarcodeWithType:MTBarcodeTypePdf417];

	XCTAssertEqualObjects(NSStringFromClass([barcode class]), @"MTBarcodePdf417Iso15438");
	XCTAssertNotNil(barcode.name);
	XCTAssertEqual(barcode.barcodeType, (int16_t)MTBarcodeTypePdf417);
}

#pragma mark - Defects recorded as behavior

- (void)testQrCodeClassClaimsTheOneCodeType {
	// BUGS.md: MTBarcodeQrCodeIso18004's +type and init both say MTBarcodeTypeOneCode,
	// so the factory hands back a QR-named object that would encode as USPS OneCode.
	MTBarcode *barcode = [MTBarcode newBarcodeWithType:MTBarcodeTypeQrcode];

	XCTAssertEqualObjects(NSStringFromClass([barcode class]), @"MTBarcodeQrCodeIso18004");
	XCTAssertEqualObjects(barcode.name, @"QR Code (ISO 18004)");
	XCTAssertEqual(barcode.barcodeType, (int16_t)MTBarcodeTypeOneCode);
	XCTAssertNotEqual(barcode.barcodeType, (int16_t)MTBarcodeTypeQrcode);
}

- (void)testEan128ClassClaimsTheHibcType {
	// BUGS.md: MTBarcodeCode128Ean128's +type says MTBarcodeTypeEAN128 but its init
	// assigns [MTBarcodeCode128Hibc type], so the factory hands back a GS1-128-named
	// object that would encode as HIBC Code 128.
	MTBarcode *barcode = [MTBarcode newBarcodeWithType:MTBarcodeTypeEAN128];

	XCTAssertEqualObjects(NSStringFromClass([barcode class]), @"MTBarcodeCode128Ean128");
	XCTAssertEqualObjects(barcode.name, @"Code 128 (GS1-128)");
	XCTAssertEqual(barcode.barcodeType, (int16_t)MTBarcodeTypeHibc128);
	XCTAssertNotEqual(barcode.barcodeType, (int16_t)MTBarcodeTypeEAN128);
}

- (void)testIsbnClassInitializesToItsOwnType {
	// +[MTBarcodeInternationalStandardBookNumberIsbn type] is NOT called: it returns
	// itself, which recurses until the stack runs out (BUGS.md).  The initializer sets
	// the type directly, so the factory path is safe.
	MTBarcode *barcode = [MTBarcode newBarcodeWithType:MTBarcodeTypeIsbnX];

	XCTAssertEqualObjects(NSStringFromClass([barcode class]), @"MTBarcodeInternationalStandardBookNumberIsbn");
	XCTAssertEqual(barcode.barcodeType, (int16_t)MTBarcodeTypeIsbnX);
}

- (void)testEveryMappedTypeBuildsANamedInstance {
	NSArray<NSNumber *> *mapped = @[
		@(MTBarcodeTypeAuspost), @(MTBarcodeTypeAusreDirect), @(MTBarcodeTypeAusreply),
		@(MTBarcodeTypeAusroute), @(MTBarcodeTypeAzrune), @(MTBarcodeTypeAztec),
		@(MTBarcodeTypeC25IATA), @(MTBarcodeTypeC25IND), @(MTBarcodeTypeC25INTER),
		@(MTBarcodeTypeC25LOGIC), @(MTBarcodeTypeC25MATRIX), @(MTBarcodeTypeCODABAR),
		@(MTBarcodeTypeCODE128), @(MTBarcodeTypeCODE16K), @(MTBarcodeTypeCODE39),
		@(MTBarcodeTypeCODE49), @(MTBarcodeTypeCODE93), @(MTBarcodeTypeChannel),
		@(MTBarcodeTypeCode11), @(MTBarcodeTypeCode128b), @(MTBarcodeTypeCode32),
		@(MTBarcodeTypeCodeOne), @(MTBarcodeTypeDPIDENT), @(MTBarcodeTypeDPLEIT),
		@(MTBarcodeTypeDataMatrix), @(MTBarcodeTypeEAN128), @(MTBarcodeTypeEANX),
		@(MTBarcodeTypeEXCODE39), @(MTBarcodeTypeEan14), @(MTBarcodeTypeFim),
		@(MTBarcodeTypeFlat), @(MTBarcodeTypeGridMatrix), @(MTBarcodeTypeHibc128),
		@(MTBarcodeTypeHibc39), @(MTBarcodeTypeIsbnX), @(MTBarcodeTypeItf14),
		@(MTBarcodeTypeJapanPost), @(MTBarcodeTypeKix), @(MTBarcodeTypeKoreaPost),
		@(MTBarcodeTypeLogmars), @(MTBarcodeTypeMaxicode), @(MTBarcodeTypeMicroPdf417),
		@(MTBarcodeTypeMicroqr), @(MTBarcodeTypeMsiPlessey), @(MTBarcodeTypeNve18),
		@(MTBarcodeTypeOneCode), @(MTBarcodeTypePdf417), @(MTBarcodeTypePharma),
		@(MTBarcodeTypePharmaTwo), @(MTBarcodeTypePlanet), @(MTBarcodeTypePlessey),
		@(MTBarcodeTypePostnet), @(MTBarcodeTypePzn), @(MTBarcodeTypeQrcode),
		@(MTBarcodeTypeRm4scc), @(MTBarcodeTypeRss14), @(MTBarcodeTypeRss14Stack),
		@(MTBarcodeTypeRss14StackOmni), @(MTBarcodeTypeRssExp), @(MTBarcodeTypeRssExpstack),
		@(MTBarcodeTypeRssLtd), @(MTBarcodeTypeTelepen), @(MTBarcodeTypeTelepenNum),
		@(MTBarcodeTypeUpca), @(MTBarcodeTypeUpce),
	];

	XCTAssertEqual(mapped.count, (NSUInteger)65);
	for (NSNumber *boxed in mapped) {
		MTBarcodeType type = (MTBarcodeType)boxed.intValue;
		MTBarcode *barcode = [MTBarcode newBarcodeWithType:type];

		XCTAssertNotNil(barcode, @"no class for type %d", type);
		XCTAssertGreaterThan(barcode.name.length, (NSUInteger)0,
							 @"%@ has no name", NSStringFromClass([barcode class]));
		NSString *name = [MTBarcode newBarcodeNameForType:type];
		XCTAssertNotNil(name, @"no dictionary entry for type %d", type);
	}
}

- (void)testEveryMappedTypeRoundTripsExceptTheTwoKnownMismatches {
	NSArray<NSNumber *> *mapped = @[
		@(MTBarcodeTypeAuspost), @(MTBarcodeTypeAusreDirect), @(MTBarcodeTypeAusreply),
		@(MTBarcodeTypeAusroute), @(MTBarcodeTypeAzrune), @(MTBarcodeTypeAztec),
		@(MTBarcodeTypeC25IATA), @(MTBarcodeTypeC25IND), @(MTBarcodeTypeC25INTER),
		@(MTBarcodeTypeC25LOGIC), @(MTBarcodeTypeC25MATRIX), @(MTBarcodeTypeCODABAR),
		@(MTBarcodeTypeCODE128), @(MTBarcodeTypeCODE16K), @(MTBarcodeTypeCODE39),
		@(MTBarcodeTypeCODE49), @(MTBarcodeTypeCODE93), @(MTBarcodeTypeChannel),
		@(MTBarcodeTypeCode11), @(MTBarcodeTypeCode128b), @(MTBarcodeTypeCode32),
		@(MTBarcodeTypeCodeOne), @(MTBarcodeTypeDPIDENT), @(MTBarcodeTypeDPLEIT),
		@(MTBarcodeTypeDataMatrix), @(MTBarcodeTypeEAN128), @(MTBarcodeTypeEANX),
		@(MTBarcodeTypeEXCODE39), @(MTBarcodeTypeEan14), @(MTBarcodeTypeFim),
		@(MTBarcodeTypeFlat), @(MTBarcodeTypeGridMatrix), @(MTBarcodeTypeHibc128),
		@(MTBarcodeTypeHibc39), @(MTBarcodeTypeIsbnX), @(MTBarcodeTypeItf14),
		@(MTBarcodeTypeJapanPost), @(MTBarcodeTypeKix), @(MTBarcodeTypeKoreaPost),
		@(MTBarcodeTypeLogmars), @(MTBarcodeTypeMaxicode), @(MTBarcodeTypeMicroPdf417),
		@(MTBarcodeTypeMicroqr), @(MTBarcodeTypeMsiPlessey), @(MTBarcodeTypeNve18),
		@(MTBarcodeTypeOneCode), @(MTBarcodeTypePdf417), @(MTBarcodeTypePharma),
		@(MTBarcodeTypePharmaTwo), @(MTBarcodeTypePlanet), @(MTBarcodeTypePlessey),
		@(MTBarcodeTypePostnet), @(MTBarcodeTypePzn), @(MTBarcodeTypeQrcode),
		@(MTBarcodeTypeRm4scc), @(MTBarcodeTypeRss14), @(MTBarcodeTypeRss14Stack),
		@(MTBarcodeTypeRss14StackOmni), @(MTBarcodeTypeRssExp), @(MTBarcodeTypeRssExpstack),
		@(MTBarcodeTypeRssLtd), @(MTBarcodeTypeTelepen), @(MTBarcodeTypeTelepenNum),
		@(MTBarcodeTypeUpca), @(MTBarcodeTypeUpce),
	];

	for (NSNumber *boxed in mapped) {
		MTBarcodeType type = (MTBarcodeType)boxed.intValue;
		if (type == MTBarcodeTypeQrcode || type == MTBarcodeTypeEAN128) {
			// Two known copy/paste defects, pinned separately: the QR class reports
			// OneCode and the GS1-128 class reports HIBC Code 128.  Every other mapped
			// type round-trips.
			continue;
		}
		MTBarcode *barcode = [MTBarcode newBarcodeWithType:type];
		XCTAssertEqual(barcode.barcodeType, (int16_t)type,
					   @"%@ reports type %d for factory type %d",
					   NSStringFromClass([barcode class]), barcode.barcodeType, type);
	}
}

@end
