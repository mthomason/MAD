//
//  RptqDocumentElementGroupKeyTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/RptqDocumentElementGroupKeyTests.m: the group-number
//  element.  Its designer text spells the group number out ("Group Three",
//  uppercased) through NSNumberFormatter's spell-out style, so the exact words
//  follow the current locale; the test composes the same way rather than
//  hard-coding English.  The Xcode suite's in-memory Core Data context is a real
//  SQLite store under a per-test temp directory here.
//

#import "MADTestSupport.h"

#import <MAD/RptqDocumentElementGroupKey.h>
#import <MAD/RptqDocumentElementGroupKey+Extras.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>

#pragma mark - Fixture

static RptqStoreContext *inMemoryContext(void) {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	MAD_PASS([store openWithError:&error], "the store opens");
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	MAD_PASS([context loadAllWithError:&error], "the context loads");
	return context;
}

static RptqDocumentElementGroupKey *groupKeyInContext(RptqStoreContext *context) {
	return (RptqDocumentElementGroupKey *)[context insertObjectForEntity:@"RptqDocumentElementGroupKey" identifier:0];
}

#pragma mark - Tests

static void testGroupNumberRoundTrips(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementGroupKey *element = groupKeyInContext(context);

	MAD_PASS(element.groupNumber == 0, "a fresh element's group number is 0");

	element.groupNumber = 4;
	MAD_PASS(element.groupNumber == 4, "the group number round-trips");
}

static void testDesignerRepresentationTextSpellsOutTheGroupNumber(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementGroupKey *element = groupKeyInContext(context);
	element.groupNumber = 3;

	NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber:@(3)
														  numberStyle:NSNumberFormatterSpellOutStyle];
	NSString *expected = [[NSString alloc] initWithFormat:NSLocalizedString(@"Group %@", @"Like 'Group Three.'"),
														spelledOut.uppercaseString];
	NSString *text = element.designerRepresentationText;

	MAD_PASS_EQUAL(text, expected, "the designer text spells the group number out");
	MAD_PASS([text hasPrefix:@"Group "], "the designer text starts with the group word");
}

MAD_TEST_MAIN("RptqDocumentElementGroupKeyTests",
	MAD_TEST(testGroupNumberRoundTrips),
	MAD_TEST(testDesignerRepresentationTextSpellsOutTheGroupNumber));
