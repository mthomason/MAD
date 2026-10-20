//
//  MADBarcodeSymbologyTests.m
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

#import "MADBarcode.h"
#import "MADBarcodeAztec.h"
#import "MADBarcodeCodabar.h"
#import "MADBarcodeCode2of5Interleaved.h"
#import "MADBarcodeCode39Iso16388.h"
#import "MADBarcodeCode128Iso15417.h"
#import "MADBarcodeDataMatrixIso16022.h"
#import "MADBarcodeEuropeanArticleNumberEan.h"
#import "MADBarcodeInternationalStandardBookNumberIsbn.h"
#import "MADBarcodeItf14.h"
#import "MADBarcodeMaxicodeIso16023.h"
#import "MADBarcodeMicroQrCode.h"
#import "MADBarcodePdf417Iso15438.h"
#import "MADBarcodePostnet.h"
#import "MADBarcodeQrCodeIso18004.h"
#import "MADBarcodeUniversalProductCodeUpca.h"

@interface MADBarcodeSymbologyTests : XCTestCase
@end

@implementation MADBarcodeSymbologyTests

#pragma mark - Matrix

- (void)testFactoryBuildsTheExpectedClassWithItsOwnNameAndType {
	NSArray<NSArray *> *matrix = @[
		@[ @(MADBarcodeTypeCODE39),   @"MADBarcodeCode39Iso16388",   @"Code 39 (ISO 16388)" ],
		@[ @(MADBarcodeTypeCODE128),  @"MADBarcodeCode128Iso15417",  @"Code 128 (ISO 15417)" ],
		@[ @(MADBarcodeTypeDataMatrix), @"MADBarcodeDataMatrixIso16022", @"Data Matrix (ISO 16022)" ],
		@[ @(MADBarcodeTypeEANX),     @"MADBarcodeEuropeanArticleNumberEan", @"European Article Number (EAN)" ],
		@[ @(MADBarcodeTypeUpca),     @"MADBarcodeUniversalProductCodeUpca", @"Universal Product Code (UPC-A)" ],
		@[ @(MADBarcodeTypeAztec),    @"MADBarcodeAztec",             @"Aztec Code (ISO 24778)" ],
		@[ @(MADBarcodeTypeCODABAR),  @"MADBarcodeCodabar",           @"Codabar" ],
		@[ @(MADBarcodeTypeC25INTER), @"MADBarcodeCode2of5Interleaved", @"Code 2 of 5 Interleaved" ],
		@[ @(MADBarcodeTypePostnet),  @"MADBarcodePostnet",           @"Postnet" ],
		@[ @(MADBarcodeTypeMaxicode), @"MADBarcodeMaxicodeIso16023",  @"Maxicode (ISO 16023)" ],
		@[ @(MADBarcodeTypeMicroqr),  @"MADBarcodeMicroQrCode",       @"Micro QR Code" ],
		@[ @(MADBarcodeTypeItf14),    @"MADBarcodeItf14",             @"ITF-14" ],
	];

	for (NSArray *row in matrix) {
		MADBarcodeType type = (MADBarcodeType)[row[0] intValue];
		MADBarcode *barcode = [MADBarcode newBarcodeWithType:type];

		XCTAssertNotNil(barcode, @"%@", row[1]);
		XCTAssertEqualObjects(NSStringFromClass([barcode class]), row[1]);
		XCTAssertEqualObjects(barcode.name, row[2]);
		XCTAssertEqual(barcode.barcodeType, (int16_t)type,
					   @"%@ reports type %d", row[1], barcode.barcodeType);
	}
}

- (void)testPdf417NameComesFromTheDisplayConstant {
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypePdf417];

	XCTAssertEqualObjects(NSStringFromClass([barcode class]), @"MADBarcodePdf417Iso15438");
	XCTAssertNotNil(barcode.name);
	XCTAssertEqual(barcode.barcodeType, (int16_t)MADBarcodeTypePdf417);
}

#pragma mark - Defects recorded as behavior

- (void)testQrCodeClassClaimsTheOneCodeType {
	// BUGS.md: MADBarcodeQrCodeIso18004's +type and init both say MADBarcodeTypeOneCode,
	// so the factory hands back a QR-named object that would encode as USPS OneCode.
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypeQrcode];

	XCTAssertEqualObjects(NSStringFromClass([barcode class]), @"MADBarcodeQrCodeIso18004");
	XCTAssertEqualObjects(barcode.name, @"QR Code (ISO 18004)");
	XCTAssertEqual(barcode.barcodeType, (int16_t)MADBarcodeTypeOneCode);
	XCTAssertNotEqual(barcode.barcodeType, (int16_t)MADBarcodeTypeQrcode);
}

- (void)testEan128ClassClaimsTheHibcType {
	// BUGS.md: MADBarcodeCode128Ean128's +type says MADBarcodeTypeEAN128 but its init
	// assigns [MADBarcodeCode128Hibc type], so the factory hands back a GS1-128-named
	// object that would encode as HIBC Code 128.
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypeEAN128];

	XCTAssertEqualObjects(NSStringFromClass([barcode class]), @"MADBarcodeCode128Ean128");
	XCTAssertEqualObjects(barcode.name, @"Code 128 (GS1-128)");
	XCTAssertEqual(barcode.barcodeType, (int16_t)MADBarcodeTypeHibc128);
	XCTAssertNotEqual(barcode.barcodeType, (int16_t)MADBarcodeTypeEAN128);
}

- (void)testIsbnClassInitializesToItsOwnType {
	// +[MADBarcodeInternationalStandardBookNumberIsbn type] is NOT called: it returns
	// itself, which recurses until the stack runs out (BUGS.md).  The initializer sets
	// the type directly, so the factory path is safe.
	MADBarcode *barcode = [MADBarcode newBarcodeWithType:MADBarcodeTypeIsbnX];

	XCTAssertEqualObjects(NSStringFromClass([barcode class]), @"MADBarcodeInternationalStandardBookNumberIsbn");
	XCTAssertEqual(barcode.barcodeType, (int16_t)MADBarcodeTypeIsbnX);
}

- (void)testEveryMappedTypeBuildsANamedInstance {
	NSArray<NSNumber *> *mapped = @[
		@(MADBarcodeTypeAuspost), @(MADBarcodeTypeAusreDirect), @(MADBarcodeTypeAusreply),
		@(MADBarcodeTypeAusroute), @(MADBarcodeTypeAzrune), @(MADBarcodeTypeAztec),
		@(MADBarcodeTypeC25IATA), @(MADBarcodeTypeC25IND), @(MADBarcodeTypeC25INTER),
		@(MADBarcodeTypeC25LOGIC), @(MADBarcodeTypeC25MATRIX), @(MADBarcodeTypeCODABAR),
		@(MADBarcodeTypeCODE128), @(MADBarcodeTypeCODE16K), @(MADBarcodeTypeCODE39),
		@(MADBarcodeTypeCODE49), @(MADBarcodeTypeCODE93), @(MADBarcodeTypeChannel),
		@(MADBarcodeTypeCode11), @(MADBarcodeTypeCode128b), @(MADBarcodeTypeCode32),
		@(MADBarcodeTypeCodeOne), @(MADBarcodeTypeDPIDENT), @(MADBarcodeTypeDPLEIT),
		@(MADBarcodeTypeDataMatrix), @(MADBarcodeTypeEAN128), @(MADBarcodeTypeEANX),
		@(MADBarcodeTypeEXCODE39), @(MADBarcodeTypeEan14), @(MADBarcodeTypeFim),
		@(MADBarcodeTypeFlat), @(MADBarcodeTypeGridMatrix), @(MADBarcodeTypeHibc128),
		@(MADBarcodeTypeHibc39), @(MADBarcodeTypeIsbnX), @(MADBarcodeTypeItf14),
		@(MADBarcodeTypeJapanPost), @(MADBarcodeTypeKix), @(MADBarcodeTypeKoreaPost),
		@(MADBarcodeTypeLogmars), @(MADBarcodeTypeMaxicode), @(MADBarcodeTypeMicroPdf417),
		@(MADBarcodeTypeMicroqr), @(MADBarcodeTypeMsiPlessey), @(MADBarcodeTypeNve18),
		@(MADBarcodeTypeOneCode), @(MADBarcodeTypePdf417), @(MADBarcodeTypePharma),
		@(MADBarcodeTypePharmaTwo), @(MADBarcodeTypePlanet), @(MADBarcodeTypePlessey),
		@(MADBarcodeTypePostnet), @(MADBarcodeTypePzn), @(MADBarcodeTypeQrcode),
		@(MADBarcodeTypeRm4scc), @(MADBarcodeTypeRss14), @(MADBarcodeTypeRss14Stack),
		@(MADBarcodeTypeRss14StackOmni), @(MADBarcodeTypeRssExp), @(MADBarcodeTypeRssExpstack),
		@(MADBarcodeTypeRssLtd), @(MADBarcodeTypeTelepen), @(MADBarcodeTypeTelepenNum),
		@(MADBarcodeTypeUpca), @(MADBarcodeTypeUpce),
	];

	XCTAssertEqual(mapped.count, (NSUInteger)65);
	for (NSNumber *boxed in mapped) {
		MADBarcodeType type = (MADBarcodeType)boxed.intValue;
		MADBarcode *barcode = [MADBarcode newBarcodeWithType:type];

		XCTAssertNotNil(barcode, @"no class for type %d", type);
		XCTAssertGreaterThan(barcode.name.length, (NSUInteger)0,
							 @"%@ has no name", NSStringFromClass([barcode class]));
		NSString *name = [MADBarcode newBarcodeNameForType:type];
		XCTAssertNotNil(name, @"no dictionary entry for type %d", type);
	}
}

- (void)testEveryMappedTypeRoundTripsExceptTheTwoKnownMismatches {
	NSArray<NSNumber *> *mapped = @[
		@(MADBarcodeTypeAuspost), @(MADBarcodeTypeAusreDirect), @(MADBarcodeTypeAusreply),
		@(MADBarcodeTypeAusroute), @(MADBarcodeTypeAzrune), @(MADBarcodeTypeAztec),
		@(MADBarcodeTypeC25IATA), @(MADBarcodeTypeC25IND), @(MADBarcodeTypeC25INTER),
		@(MADBarcodeTypeC25LOGIC), @(MADBarcodeTypeC25MATRIX), @(MADBarcodeTypeCODABAR),
		@(MADBarcodeTypeCODE128), @(MADBarcodeTypeCODE16K), @(MADBarcodeTypeCODE39),
		@(MADBarcodeTypeCODE49), @(MADBarcodeTypeCODE93), @(MADBarcodeTypeChannel),
		@(MADBarcodeTypeCode11), @(MADBarcodeTypeCode128b), @(MADBarcodeTypeCode32),
		@(MADBarcodeTypeCodeOne), @(MADBarcodeTypeDPIDENT), @(MADBarcodeTypeDPLEIT),
		@(MADBarcodeTypeDataMatrix), @(MADBarcodeTypeEAN128), @(MADBarcodeTypeEANX),
		@(MADBarcodeTypeEXCODE39), @(MADBarcodeTypeEan14), @(MADBarcodeTypeFim),
		@(MADBarcodeTypeFlat), @(MADBarcodeTypeGridMatrix), @(MADBarcodeTypeHibc128),
		@(MADBarcodeTypeHibc39), @(MADBarcodeTypeIsbnX), @(MADBarcodeTypeItf14),
		@(MADBarcodeTypeJapanPost), @(MADBarcodeTypeKix), @(MADBarcodeTypeKoreaPost),
		@(MADBarcodeTypeLogmars), @(MADBarcodeTypeMaxicode), @(MADBarcodeTypeMicroPdf417),
		@(MADBarcodeTypeMicroqr), @(MADBarcodeTypeMsiPlessey), @(MADBarcodeTypeNve18),
		@(MADBarcodeTypeOneCode), @(MADBarcodeTypePdf417), @(MADBarcodeTypePharma),
		@(MADBarcodeTypePharmaTwo), @(MADBarcodeTypePlanet), @(MADBarcodeTypePlessey),
		@(MADBarcodeTypePostnet), @(MADBarcodeTypePzn), @(MADBarcodeTypeQrcode),
		@(MADBarcodeTypeRm4scc), @(MADBarcodeTypeRss14), @(MADBarcodeTypeRss14Stack),
		@(MADBarcodeTypeRss14StackOmni), @(MADBarcodeTypeRssExp), @(MADBarcodeTypeRssExpstack),
		@(MADBarcodeTypeRssLtd), @(MADBarcodeTypeTelepen), @(MADBarcodeTypeTelepenNum),
		@(MADBarcodeTypeUpca), @(MADBarcodeTypeUpce),
	];

	for (NSNumber *boxed in mapped) {
		MADBarcodeType type = (MADBarcodeType)boxed.intValue;
		if (type == MADBarcodeTypeQrcode || type == MADBarcodeTypeEAN128) {
			// Two known copy/paste defects, pinned separately: the QR class reports
			// OneCode and the GS1-128 class reports HIBC Code 128.  Every other mapped
			// type round-trips.
			continue;
		}
		MADBarcode *barcode = [MADBarcode newBarcodeWithType:type];
		XCTAssertEqual(barcode.barcodeType, (int16_t)type,
					   @"%@ reports type %d for factory type %d",
					   NSStringFromClass([barcode class]), barcode.barcodeType, type);
	}
}

@end
