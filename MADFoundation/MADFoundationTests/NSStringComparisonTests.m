//
//  NSStringComparisonTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the defined order every text comparison in the export path
//  routes through: -[NSString mad_orderedCompare:] and its C core
//  MADStringOrderedCompareUTF8.  The order is part of the export format's
//  contract (docs/project/MAD_CLI.md's `mad export` section): case-fold, then UTF-8
//  code-point order, identical on every platform.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/NSString+Comparison.h>

@interface NSStringComparisonTests : XCTestCase
@end

@implementation NSStringComparisonTests

- (void)testCaseFoldingMakesKeysEqual {
	XCTAssertEqual([@"a" mad_orderedCompare:@"A"], NSOrderedSame);
	XCTAssertEqual([@"Ac/dc" mad_orderedCompare:@"AC/DC"], NSOrderedSame);
	XCTAssertEqual([@"a" mad_orderedCompare:@"b"], NSOrderedAscending);
	XCTAssertEqual([@"A" mad_orderedCompare:@"b"], NSOrderedAscending);
	XCTAssertEqual([@"a" mad_orderedCompare:@"B"], NSOrderedAscending);
	XCTAssertEqual([@"b" mad_orderedCompare:@"A"], NSOrderedDescending);
}

- (void)testPunctuationComparesAsItsOwnCodePoint {
	// The order does not skip punctuation: every byte compares as its folded
	// code point.  The fold sends every letter into the lowercase range
	// (0x61-0x7A), which follows every ASCII punctuation byte, so a
	// punctuation-led key sorts before a word-led one -- the same place
	// SQLite's NOCASE puts it, and the place ICU's localized order does too.
	XCTAssertEqual([@"[1997] Black Light Syndrome" mad_orderedCompare:@"Core"], NSOrderedAscending);
	XCTAssertEqual([@"-1" mad_orderedCompare:@"A"], NSOrderedAscending);
	XCTAssertEqual([@" " mad_orderedCompare:@"A"], NSOrderedAscending);
	XCTAssertEqual([@"[1997] Black Light Syndrome" mad_orderedCompare:@"Zulu"], NSOrderedAscending);
}

- (void)testTheFoldIsUnicodeSimpleCaseFolding {
	// The simple one-to-one fold table (MADStringOrderingTable): pairs fold to
	// each other across scripts.
	XCTAssertEqual([@"K" mad_orderedCompare:@"k"], NSOrderedSame);
	XCTAssertEqual([@"Ä" mad_orderedCompare:@"ä"], NSOrderedSame);
	XCTAssertEqual([@"Å" mad_orderedCompare:@"å"], NSOrderedSame);
	XCTAssertEqual([@"Σ" mad_orderedCompare:@"σ"], NSOrderedSame);
	XCTAssertEqual([@"Д" mad_orderedCompare:@"д"], NSOrderedSame);
	// What the fold is not: it does not expand (ß keeps itself -- it has no
	// one-to-one fold) and it does not strip diacritics.
	XCTAssertNotEqual([@"ß" mad_orderedCompare:@"ss"], NSOrderedSame);
	XCTAssertEqual([@"e" mad_orderedCompare:@"é"], NSOrderedAscending);
}

- (void)testACodePointOrderIsAUTF8Order {
	// UTF-8 preserves code-point order, so the byte comparison the collation
	// performs is the code-point comparison the in-memory sorts perform.
	XCTAssertEqual([@"é" mad_orderedCompare:@"ē"], NSOrderedAscending);
	XCTAssertEqual([@"Ā" mad_orderedCompare:@"ā"], NSOrderedSame);
}

- (void)testAPrefixSortsBeforeItsExtension {
	XCTAssertEqual([@"" mad_orderedCompare:@"a"], NSOrderedAscending);
	XCTAssertEqual([@"a" mad_orderedCompare:@"ab"], NSOrderedAscending);
	XCTAssertEqual([@"abc" mad_orderedCompare:@"ab"], NSOrderedDescending);
}

- (void)testTheCCoreComparesExplicitByteLengths {
	// The core takes lengths, so an embedded NUL is an ordinary byte -- the
	// collation hands it the same lengths SQLite hands the collation.
	XCTAssertEqual(MADStringOrderedCompareUTF8("a\0b", 3, "a\0c", 3), NSOrderedAscending);
	XCTAssertEqual(MADStringOrderedCompareUTF8("a\0b", 3, "a\0b", 3), NSOrderedSame);
	XCTAssertEqual(MADStringOrderedCompareUTF8("a", 1, "a\0b", 3), NSOrderedAscending);
	// A byte that does not begin a valid UTF-8 sequence compares as itself.
	XCTAssertEqual(MADStringOrderedCompareUTF8("a", 1, "\xff", 1), NSOrderedAscending);
}

@end
