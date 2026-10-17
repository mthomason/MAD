//
//  MADReportExporterTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the export seam: MADReportExporterRegistry (the lookup the CLI
//  reaches a format through) and the value spellings every Foundation format shares
//  (MADReportExportSource).  The formats themselves are exercised end to end on a
//  real document by the Linux suite (Linux/Tests/MADReportExporterTests.m), which
//  opens the London fixture, refreshes it and reads the exports back.
//

#import <XCTest/XCTest.h>

#import <MAD/MADReportExporting.h>
#import <MAD/MADReportExporterCSV.h>
#import <MAD/MADReportExporterHTML.h>
#import <MAD/MADReportExporterHTMLFlow.h>
#import <MAD/MADReportExporterJSON.h>
#import <MAD/MADReportExporterJSONReport.h>
#import <MAD/MADReportExporterPDF.h>
#import <MAD/MADReportExporterRegistry.h>
#import <MAD/MADReportExporterText.h>
#import <MAD/MADReportExportSource.h>

// A stub format: the protocol's required methods and nothing else, registered under a
// name no exporter claims so registering one cannot disturb another test.
@interface MADTestReportExporter : NSObject <MADReportExporting>
@end

@implementation MADTestReportExporter

+ (NSString *)formatName { return @"test-format"; }
+ (NSString *)formatDescription { return @"nothing"; }
+ (NSString *)fileExtension { return @"txt"; }
+ (BOOL)requiresOutputPath { return NO; }
+ (BOOL)isAvailable { return YES; }
+ (NSString *)unavailableReason { return nil; }
- (BOOL)exportDocument:(id <MADDocumentDataProtocol>)document
				 toURL:(NSURL *)url
			   options:(MADReportExportOptions)options
				 error:(NSError **)error { return YES; }

@end

// A second class claiming the same name, to make the duplicate claim raise.
@interface MADTestUsurperReportExporter : MADTestReportExporter
@end

@implementation MADTestUsurperReportExporter
@end

@interface MADReportExporterTests : XCTestCase
@end

@implementation MADReportExporterTests

#pragma mark - The registry

- (void)testTheBuiltInFormatsAreRegisteredByLinking {
	// +load is what registers them, so this is the "a framework that links its
	// exporters has them" check, the way the driver registry's suite is.
	NSArray <NSString *> *names = [MADReportExporterRegistry registeredFormatNames];
	XCTAssertTrue([names containsObject: @"csv"]);
	XCTAssertTrue([names containsObject: @"json"]);
	XCTAssertTrue([names containsObject: @"text"]);

	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"csv"], [MADReportExporterCSV class]);
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"json"], [MADReportExporterJSON class]);
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"text"], [MADReportExporterText class]);
}

- (void)testTheFormatNamesAreSorted {
	NSArray <NSString *> *names = [MADReportExporterRegistry registeredFormatNames];
	XCTAssertEqualObjects(names, [names sortedArrayUsingSelector: @selector(compare:)],
						  @"the names are handed out in one order, so a usage line reads the same twice");
}

- (void)testLookupIsCaseInsensitiveAndAnUnknownNameIsNil {
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"JSON"], [MADReportExporterJSON class]);
	XCTAssertNil([MADReportExporterRegistry exporterClassForFormat: @"yaml"]);
	XCTAssertNil([MADReportExporterRegistry exporterClassForFormat: @""]);
}

- (void)testRegistrationIsVisibleThroughTheLookup {
	[MADReportExporterRegistry registerExporterClass: [MADTestReportExporter class]];
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"test-format"], [MADTestReportExporter class]);
	XCTAssertTrue([[MADReportExporterRegistry registeredExporterClasses] containsObject: [MADTestReportExporter class]]);
	XCTAssertNoThrow([MADReportExporterRegistry registerExporterClass: [MADTestReportExporter class]]);
}

// The render-side formats: json-report and the two HTML ones read the page walk,
// which is compiled on both platforms now (MAD_LINUX.md §9 Phase E); pdf draws with
// Core Graphics and is Apple's, so it registers everywhere and says so.
- (void)testTheRenderSideFormatsAreRegistered {
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"html"], [MADReportExporterHTML class]);
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"html-flow"], [MADReportExporterHTMLFlow class]);
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"pdf"], [MADReportExporterPDF class]);

	XCTAssertTrue([MADReportExporterHTML isAvailable]);
	XCTAssertTrue([MADReportExporterHTMLFlow isAvailable]);
	XCTAssertEqualObjects([MADReportExporterHTML fileExtension], @"html");
	XCTAssertEqualObjects([MADReportExporterHTMLFlow fileExtension], @"html");
	XCTAssertFalse([MADReportExporterHTML requiresOutputPath], @"a file a browser opens writes to a stream");
	XCTAssertFalse([MADReportExporterHTMLFlow requiresOutputPath], @"the same");
}

- (void)testThePDFFormatDrawsHereAndNeedsAFile {
	XCTAssertEqual([MADReportExporterRegistry exporterClassForFormat: @"pdf"], [MADReportExporterPDF class]);
	XCTAssertTrue([MADReportExporterPDF isAvailable]);
	XCTAssertNil([MADReportExporterPDF unavailableReason]);
	XCTAssertEqualObjects([MADReportExporterPDF fileExtension], @"pdf");
	XCTAssertTrue([MADReportExporterPDF requiresOutputPath], @"Core Graphics writes a file, not a stream");
}

- (void)testTheReportFormatIsRegisteredAndAnswersForThisPlatform {
	Class <MADReportExporting> exporterClass = [MADReportExporterRegistry exporterClassForFormat: @"json-report"];
	XCTAssertEqual(exporterClass, [MADReportExporterJSONReport class]);
	XCTAssertEqualObjects([exporterClass fileExtension], @"json", @"the report member rides in the json shape");
	XCTAssertTrue([exporterClass isKindOfClass: [NSObject class]]);
	XCTAssertTrue([MADReportExporterJSONReport isSubclassOfClass: [MADReportExporterJSON class]],
				  @"the report format is the json format plus one member");

	// The render half is Apple's, so this build answers yes and gives no reason --
	// the Linux port of this suite asserts the opposite, with the reason.
	XCTAssertTrue([exporterClass isAvailable]);
	XCTAssertNil([exporterClass unavailableReason]);
}

- (void)testASecondExporterForOneNameRaises {
	[MADReportExporterRegistry registerExporterClass: [MADTestReportExporter class]];
	// The claim has to fail loudly: keeping one of two formats silently would make
	// which one runs depend on +load order.
	XCTAssertThrows([MADReportExporterRegistry registerExporterClass: [MADTestUsurperReportExporter class]]);
}

#pragma mark - The shared spellings

- (void)testQuotedStringEscapesTheJSONMetacharacters {
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"plain"], @"\"plain\"");
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"a\"b"], @"\"a\\\"b\"");
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"a\\b"], @"\"a\\\\b\"");
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"a\nb\tc\rd"], @"\"a\\nb\\tc\\rd\"");
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"\001"], @"\"\\u0001\"");
	// Anything above the control range is written as itself: the file is UTF-8, and a
	// reader that takes UTF-8 reads it back.
	XCTAssertEqualObjects([MADReportExporterJSON quotedString: @"Cláudio"], @"\"Cláudio\"");
}

- (void)testNumbersAreSpelledInOneRoundTripForm {
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @1], @"1");
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @(-42)], @"-42");
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @3.5], @"3.5");
	// An integral real prints without a fraction: a JSON reader sees the integer it is.
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @3.0], @"3");
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @0.99], @"0.99");
	// 0.1 + 0.2 is not 0.3, and the spelling round-trips rather than flattering it.
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @(0.1 + 0.2)], @"0.30000000000000004");
	// The huge integer stays an integer: it is an NSNumber of long long, not a double.
	XCTAssertEqualObjects([MADReportExportSource stringForNumber: @9007199254740993LL], @"9007199254740993");
}

- (void)testDatesAreISO8601InUTC {
	NSDate *epoch = [NSDate dateWithTimeIntervalSince1970: 979257600];	// 2001-01-12 00:00:00Z
	XCTAssertEqualObjects([MADReportExportSource stringForDate: epoch], @"2001-01-12T00:00:00Z");
}

@end
