//
//  MADActivityItemProviderPdfTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the parts of MADActivityItemProviderPdf that are reachable without a
//  live MADocument: the placeholder item and its pass-through to
//  UIActivityItemProvider, the print branch of -item (which hands back the placeholder
//  rather than writing a PDF), the empty data-type identifier for a nil activity type,
//  and the status-text bridge to the activity indicator.
//
//  The non-print branch of -item starts -writeToPdf:withViewController:, which builds a
//  MADReportFormatter and a MADPrintPageRenderer from the document and writes a PDF into
//  the temporary directory; it is not exercised here because the provider's document is
//  weak and normally supplied by the open report.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIActivityItemProvider.h>
#import <UIKit/UIActivityViewController.h>

#import "MADActivityItemProviderPdf.h"
#import "MADActivityIndicator.h"

// -activityType is readonly and is normally set by UIKit when the provider joins an
// activity; the double stubs it so -item's print branch can be reached directly.
@interface MADActivityItemProviderPdfActivityTypeDouble : MADActivityItemProviderPdf
@property (nonatomic, copy) NSString *stubbedActivityType;
@end

@implementation MADActivityItemProviderPdfActivityTypeDouble

- (NSString *)activityType {
	return self.stubbedActivityType;
}

@end

// -activityIndicatorController and -setStatusText: are implemented in the class
// extension, declared in no header; this test-only category is the deliberate bridge.
@interface MADActivityItemProviderPdf (TestStatus)
- (MADActivityIndicator *)activityIndicatorController;
- (void)setActivityIndicatorController:(MADActivityIndicator *)activityIndicatorController;
- (void)setStatusText:(NSString *)text;
@end

@interface MADActivityItemProviderPdfTests : XCTestCase
@end

@implementation MADActivityItemProviderPdfTests

- (void)testPlaceholderItemIsStoredAndNoContextIsSetYet {
	MADActivityItemProviderPdf *provider = [[MADActivityItemProviderPdf alloc] initWithPlaceholderItem:@"placeholder"];

	XCTAssertEqualObjects(provider.placeholderItem, @"placeholder");
	XCTAssertNil(provider.document);
	XCTAssertNil(provider.delegate);
	XCTAssertNil(provider.activityViewController);
}

- (void)testPlaceholderRequestKeepsTheActivityViewController {
	MADActivityItemProviderPdf *provider = [[MADActivityItemProviderPdf alloc] initWithPlaceholderItem:@"placeholder"];
	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[@"placeholder"]
																  applicationActivities:nil];

	id item = [provider activityViewControllerPlaceholderItem:controller];

	XCTAssertEqualObjects(item, @"placeholder");
	XCTAssertEqual(provider.activityViewController, controller);
}

- (void)testNilActivityTypeHasNoDataTypeIdentifier {
	MADActivityItemProviderPdf *provider = [[MADActivityItemProviderPdf alloc] initWithPlaceholderItem:@"placeholder"];

	NSString *identifier = [provider activityViewController:nil dataTypeIdentifierForActivityType:nil];

	XCTAssertEqualObjects(identifier, @"");
}

- (void)testPrintActivityHandsBackThePlaceholderItem {
	MADActivityItemProviderPdfActivityTypeDouble *provider = [[MADActivityItemProviderPdfActivityTypeDouble alloc] initWithPlaceholderItem:@"placeholder"];
	provider.stubbedActivityType = UIActivityTypePrint;

	id item = [provider item];

	// Printing re-uses the placeholder; nothing is written to disk.
	XCTAssertEqualObjects(item, @"placeholder");
}

- (void)testItemForActivityTypePrintAlsoReturnsThePlaceholderItem {
	MADActivityItemProviderPdfActivityTypeDouble *provider = [[MADActivityItemProviderPdfActivityTypeDouble alloc] initWithPlaceholderItem:@"placeholder"];
	provider.stubbedActivityType = UIActivityTypePrint;
	UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[@"placeholder"]
																  applicationActivities:nil];

	id item = [provider activityViewController:controller itemForActivityType:UIActivityTypePrint];

	XCTAssertEqualObjects(item, @"placeholder");
	XCTAssertEqual(provider.activityViewController, controller);
}

- (void)testStatusTextWritesThroughToTheIndicator {
	MADActivityItemProviderPdf *provider = [[MADActivityItemProviderPdf alloc] initWithPlaceholderItem:@"placeholder"];

	// No indicator is attached yet, so the status write goes nowhere.
	XCTAssertNil([provider activityIndicatorController]);
	[provider setStatusText:@"Halfway"];
	XCTAssertNil([provider activityIndicatorController]);

	MADActivityIndicator *indicator = [[MADActivityIndicator alloc] initWithFrame:CGRectMake(0, 0, 230, 200)];
	[provider setActivityIndicatorController:indicator];
	[provider setStatusText:@"Halfway"];

	XCTAssertEqualObjects(indicator.status.text, @"Halfway");
}

@end
