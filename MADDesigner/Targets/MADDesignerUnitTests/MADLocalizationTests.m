//
//  MADLocalizationTests.m
//  MADDesignerUnitTests
//
//  Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
//

// These tests pin the two Phase 1 pipelines: the compiled String Catalog and
// the Base.lproj storyboard with its per-language .strings.  They adapt to the
// process language, so the normal English suite passes, and running the suite
// with `xcodebuild test ... -testLanguage de` proves the German resources.

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>

@interface MADLocalizationTests : XCTestCase

@end

@implementation MADLocalizationTests

- (NSString *)preferredLanguage {
	NSString *language = [NSBundle mainBundle].preferredLocalizations.firstObject ?: @"en";
	NSLog(@"MADLocalizationTests: preferred language = %@", language);
	return language;
}

- (void)testStringCatalogServesPreferredLanguage {
	NSString *language = [self preferredLanguage];
	NSString *expected = [language hasPrefix:@"de"] ? @"Speicherort wählen" : @"Choose Storage Option";
	XCTAssertEqualObjects(NSLocalizedString(@"Choose Storage Option", nil), expected,
		@"The compiled String Catalog must serve %@", language);
}

- (void)testMADQueryStoryboardLoads {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQuery"
		bundle:[NSBundle mainBundle]];
	XCTAssertNotNil(storyboard, @"MADQuery.storyboard must load from Base.lproj");

	// The query view controller itself needs an open document in viewDidLoad;
	// the container is the storyboard's initial scene and loads standalone.
	UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:
		@"MADIdentifierQueryBuilderSplitViewController"];
	XCTAssertNotNil(controller);
	[controller loadViewIfNeeded];
	XCTAssertNotNil(controller.view);
}

- (void)testGermanStoryboardStringsAreInTheBundle {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"MADQuery" ofType:@"strings"
		inDirectory:nil forLocalization:@"de"];
	XCTAssertNotNil(path, @"de.lproj/MADQuery.strings must be in the app bundle");

	NSDictionary *strings = [NSDictionary dictionaryWithContentsOfFile:path];
	XCTAssertEqualObjects(strings[@"8Vr-cR-h2s.text"], @"Datenquelle");
	XCTAssertEqualObjects(strings[@"pAq-dE-kx0.title"], @"Generierte Abfrage");
}

@end
