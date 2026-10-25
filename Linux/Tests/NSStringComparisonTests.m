//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  NSStringComparisonTests.m
//  Linux/Tests
//
//  Ported from MADFoundationTests/NSStringComparisonTests.m: coverage for the
//  defined order every text comparison in the export path routes through --
//  -[NSString mad_orderedCompare:] and its C core MADStringOrderedCompareUTF8.
//  The order is part of the export format's contract (MAD_CLI.md's `mad export`
//  section): case-fold, then UTF-8 code-point order, identical on every platform.
//

#import "MADTestSupport.h"

#import <MADFoundation/NSString+Comparison.h>

static void testCaseFoldingMakesKeysEqual(void) {
	MAD_PASS([@"a" mad_orderedCompare:@"A"] == NSOrderedSame, "a equals A, folded");
	MAD_PASS([@"Ac/dc" mad_orderedCompare:@"AC/DC"] == NSOrderedSame, "the fold ignores case across punctuation");
	MAD_PASS([@"a" mad_orderedCompare:@"b"] == NSOrderedAscending, "a sorts before b");
	MAD_PASS([@"A" mad_orderedCompare:@"b"] == NSOrderedAscending, "A folds to a and sorts before b");
	MAD_PASS([@"a" mad_orderedCompare:@"B"] == NSOrderedAscending, "a sorts before B, folded to b");
	MAD_PASS([@"b" mad_orderedCompare:@"A"] == NSOrderedDescending, "b sorts after A, folded to a");
}

static void testPunctuationComparesAsItsOwnCodePoint(void) {
	// The order does not skip punctuation: every byte compares as its folded
	// code point.  The fold sends every letter into the lowercase range
	// (0x61-0x7A), which follows every ASCII punctuation byte, so a
	// punctuation-led key sorts before a word-led one -- the same place
	// SQLite's NOCASE puts it, and the place ICU's localized order does too.
	MAD_PASS([@"[1997] Black Light Syndrome" mad_orderedCompare:@"Core"] == NSOrderedAscending,
			 "[ sorts before the folded word");
	MAD_PASS([@"-1" mad_orderedCompare:@"A"] == NSOrderedAscending, "- sorts before A");
	MAD_PASS([@" " mad_orderedCompare:@"A"] == NSOrderedAscending, "space sorts before A");
	MAD_PASS([@"[1997] Black Light Syndrome" mad_orderedCompare:@"Zulu"] == NSOrderedAscending,
			 "[ sorts before z");
}

static void testTheFoldIsUnicodeSimpleCaseFolding(void) {
	// The simple one-to-one fold table (MADStringOrderingTable): pairs fold to
	// each other across scripts.
	MAD_PASS([@"K" mad_orderedCompare:@"k"] == NSOrderedSame, "the Kelvin sign folds to k");
	MAD_PASS([@"Ä" mad_orderedCompare:@"ä"] == NSOrderedSame, "A-umlaut folds to a-umlaut");
	MAD_PASS([@"Å" mad_orderedCompare:@"å"] == NSOrderedSame, "A-ring folds to a-ring");
	MAD_PASS([@"Σ" mad_orderedCompare:@"σ"] == NSOrderedSame, "capital sigma folds to sigma");
	MAD_PASS([@"Д" mad_orderedCompare:@"д"] == NSOrderedSame, "Cyrillic de folds");
	// What the fold is not: it does not expand (ß keeps itself -- it has no
	// one-to-one fold) and it does not strip diacritics.
	MAD_PASS([@"ß" mad_orderedCompare:@"ss"] != NSOrderedSame, "ß does not expand to ss");
	MAD_PASS([@"e" mad_orderedCompare:@"é"] == NSOrderedAscending, "e sorts before é");
}

static void testACodePointOrderIsAUTF8Order(void) {
	// UTF-8 preserves code-point order, so the byte comparison the collation
	// performs is the code-point comparison the in-memory sorts perform.
	MAD_PASS([@"é" mad_orderedCompare:@"ē"] == NSOrderedAscending, "é sorts before ē");
	MAD_PASS([@"Ā" mad_orderedCompare:@"ā"] == NSOrderedSame, "A-macron folds to a-macron");
}

static void testAPrefixSortsBeforeItsExtension(void) {
	MAD_PASS([@"" mad_orderedCompare:@"a"] == NSOrderedAscending, "the empty key sorts first");
	MAD_PASS([@"a" mad_orderedCompare:@"ab"] == NSOrderedAscending, "a prefix sorts before its extension");
	MAD_PASS([@"abc" mad_orderedCompare:@"ab"] == NSOrderedDescending, "and after");
}

static void testTheCCoreComparesExplicitByteLengths(void) {
	// The core takes lengths, so an embedded NUL is an ordinary byte -- the
	// collation hands it the same lengths SQLite hands the collation.
	MAD_PASS(MADStringOrderedCompareUTF8("a\0b", 3, "a\0c", 3) == NSOrderedAscending, "an embedded NUL is a byte");
	MAD_PASS(MADStringOrderedCompareUTF8("a\0b", 3, "a\0b", 3) == NSOrderedSame, "and equal bytes are equal");
	MAD_PASS(MADStringOrderedCompareUTF8("a", 1, "a\0b", 3) == NSOrderedAscending, "the shorter buffer sorts first");
	// A byte that does not begin a valid UTF-8 sequence compares as itself.
	MAD_PASS(MADStringOrderedCompareUTF8("a", 1, "\xff", 1) == NSOrderedAscending, "an invalid byte compares as itself");
}

MAD_TEST_MAIN("NSStringComparisonTests",
	MAD_TEST(testCaseFoldingMakesKeysEqual),
	MAD_TEST(testPunctuationComparesAsItsOwnCodePoint),
	MAD_TEST(testTheFoldIsUnicodeSimpleCaseFolding),
	MAD_TEST(testACodePointOrderIsAUTF8Order),
	MAD_TEST(testAPrefixSortsBeforeItsExtension),
	MAD_TEST(testTheCCoreComparesExplicitByteLengths));
