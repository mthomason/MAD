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
#import <MADCocoaExtensions/MADAlertController.h>

@interface MADLocalizationTests : XCTestCase

@end

@implementation MADLocalizationTests

- (NSString *)preferredLanguage {
	NSString *language = [NSBundle mainBundle].preferredLocalizations.firstObject ?: @"en";
	NSLog(@"MADLocalizationTests: preferred language = %@", language);
	return language;
}

- (BOOL)pseudoLocalizationEnabled {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:@"NSAccentuateLocalizedStrings"] ||
		[defaults boolForKey:@"NSDoubleLocalizedStrings"] ||
		[defaults boolForKey:@"NSSurroundLocalizedStrings"];
}

- (BOOL)doubleLengthPseudoLocalization {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"NSDoubleLocalizedStrings"];
}

// These two tests assert exact English copy.  The catalog now carries plural
// rules for every shipped language too, but the assertions are pinned to the
// source strings, so they only mean something in an English process language
// without a pseudo mode.
- (void)skipUnlessSourceLanguagePluralRules {
	XCTSkipUnless([[self preferredLanguage] hasPrefix:@"en"] && ![self pseudoLocalizationEnabled],
				  @"English source-language plural rules");
}

- (void)testStringCatalogServesPreferredLanguage {
	NSString *value = NSLocalizedString(@"Choose Storage Option", nil);
	if ([self pseudoLocalizationEnabled]) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults boolForKey:@"NSDoubleLocalizedStrings"]) {
			XCTAssertEqualObjects(value, @"Choose Storage Option Choose Storage Option",
				@"Double-length must repeat the catalog value");
		} else {
			XCTAssertNotEqualObjects(value, @"Choose Storage Option");
			XCTAssertGreaterThan(value.length, @"Choose Storage Option".length,
				@"Accented pseudo-localization must add marks, not just change a character");
		}
		NSLog(@"MADLocalizationTests: pseudo value = %@", value);
		return;
	}

	NSString *language = [self preferredLanguage];
	NSString *expected = [language hasPrefix:@"de"] ? @"Speicherort wählen" : @"Choose Storage Option";
	XCTAssertEqualObjects(value, expected,
		@"The compiled String Catalog must serve %@", language);
}

- (void)testGermanCatalogValueFromTheGermanBundle {
	if ([self pseudoLocalizationEnabled] && ![self doubleLengthPseudoLocalization]) {
		XCTSkip(@"accented pseudo-localization changes the exact copy");
	}
	NSString *path = [[NSBundle mainBundle] pathForResource:@"de" ofType:@"lproj"];
	XCTAssertNotNil(path, @"de.lproj must be in the app bundle");
	NSBundle *german = [NSBundle bundleWithPath:path];
	NSString *value = [german localizedStringForKey:@"Choose Storage Option" value:nil table:nil];
	NSString *expected = @"Speicherort wählen";
	if ([self doubleLengthPseudoLocalization]) {
		expected = [expected stringByAppendingFormat:@" %@", expected];
	}
	XCTAssertEqualObjects(value, expected,
		@"The German table must carry the key even under an English process language");
}

- (void)testDeleteItemsAlertUsesPluralRules {
	[self skipUnlessSourceLanguagePluralRules];
	void (^handler)(UIAlertAction *) = ^(UIAlertAction * __unused action) { };
	UIAlertController *one = [MADAlertController newAlertControllerDeleteItems:1
		confirm:handler cancel:handler];
	XCTAssertEqualObjects(one.message,
		@"Are you sure you would like to delete 1 item?  This action is final.");

	UIAlertController *many = [MADAlertController newAlertControllerDeleteItems:2
		confirm:handler cancel:handler];
	XCTAssertEqualObjects(many.message,
		@"Are you sure you would like to delete 2 items?  This action is final.");
	XCTAssertEqualObjects(many.actions.lastObject.title, @"Remove 2 items");
}

- (void)testAppliedSQLCountsUsePluralRules {
	[self skipUnlessSourceLanguagePluralRules];
	NSString *key = @"Applied: %1$lu tables, %2$lu joins, %3$lu predicates, %4$lu groups.";
	NSString *one = [NSString localizedStringWithFormat:NSLocalizedString(key, nil),
		1UL, 1UL, 1UL, 1UL];
	XCTAssertEqualObjects(one,
		@"Applied: 1 table, 1 join, 1 predicate, 1 group.");

	NSString *many = [NSString localizedStringWithFormat:NSLocalizedString(key, nil),
		2UL, 3UL, 4UL, 5UL];
	XCTAssertEqualObjects(many,
		@"Applied: 2 tables, 3 joins, 4 predicates, 5 groups.");
}

- (void)testStoryboardNavigationTitleFollowsPreferredLanguage {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADQuery"
		bundle:[NSBundle mainBundle]];
	UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:
		@"MADIdentifierSQLViewController"];
	XCTAssertNotNil(controller);

	NSString *language = [self preferredLanguage];
	NSString *expected = [language hasPrefix:@"de"] ? @"Generierte Abfrage" : @"Generated Query";
	if ([self doubleLengthPseudoLocalization]) {
		expected = [expected stringByAppendingFormat:@" %@", expected];
	} else if ([self pseudoLocalizationEnabled]) {
		XCTAssertNotEqualObjects(controller.navigationItem.title, @"Generated Query",
			@"Accented pseudo-localization must change the storyboard copy");
		return;
	}
	XCTAssertEqualObjects(controller.navigationItem.title, expected,
		@"The storyboard title must come from the %@ table", language);
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
