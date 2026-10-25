//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  RptqDocumentElementLabelLinkTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/RptqDocumentElementLabelLinkTests.m: the
//  linked-label element's text and url over the portable store.  Its designer
//  text is deliberately empty -- the designer draws the label's own text rather
//  than a placeholder -- and the debug description lists both fields.  The Xcode
//  suite's in-memory Core Data context is a real SQLite store under a per-test
//  temp directory here.
//

#import "MADTestSupport.h"

#import <MAD/RptqDocumentElementLabelLink.h>
#import <MAD/RptqDocumentElementLabelLink+Extras.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>

// -debugQuickLookObject is an override declared only through Foundation's informal hook;
// the test-only category keeps the call honest.
@interface RptqDocumentElementLabelLink (TestSurface)
- (id)debugQuickLookObject;
@end

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

static RptqDocumentElementLabelLink *labelLinkInContext(RptqStoreContext *context) {
	return (RptqDocumentElementLabelLink *)[context insertObjectForEntity:@"RptqDocumentElementLabelLink" identifier:0];
}

#pragma mark - Tests

static void testTextAndURLRoundTrip(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementLabelLink *element = labelLinkInContext(context);

	MAD_PASS(element.text == nil, "a fresh label's text is nil");
	MAD_PASS(element.url == nil, "a fresh label's url is nil");

	element.text = @"Everyday Apps";
	element.url = @"https://example.com/";
	MAD_PASS_EQUAL(element.text, @"Everyday Apps", "the text round-trips");
	MAD_PASS_EQUAL(element.url, @"https://example.com/", "the url round-trips");
}

static void testDesignerRepresentationTextIsEmpty(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementLabelLink *element = labelLinkInContext(context);
	element.text = @"Everyday Apps";

	MAD_PASS_EQUAL(element.designerRepresentationText, @"", "the designer representation is deliberately empty");
}

static void testDebugQuickLookListsTextAndURL(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementLabelLink *element = labelLinkInContext(context);
	element.text = @"Everyday Apps";
	element.url = @"https://example.com/";

	id quickLook = [element debugQuickLookObject];

	MAD_PASS([quickLook isKindOfClass:[NSString class]], "the quick look is a string");
	MAD_PASS([quickLook containsString:@"Everyday Apps"], "the quick look lists the text");
	MAD_PASS([quickLook containsString:@"https://example.com/"], "the quick look lists the url");
}

MAD_TEST_MAIN("RptqDocumentElementLabelLinkTests",
	MAD_TEST(testTextAndURLRoundTrip),
	MAD_TEST(testDesignerRepresentationTextIsEmpty),
	MAD_TEST(testDebugQuickLookListsTextAndURL));
