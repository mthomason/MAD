//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDocumentObjectDataReferenceLabelStaticTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADDocumentObjectDataReferenceLabelStaticTests.m:
//  MADDocumentObjectDataReferenceLabelStatic, the handle over a static label
//  element.  The factory maps MADPrintPageElementTypeLabelStatic to it, and
//  -text reads the element's text with an empty-string fallback.
//
//  The store is a real SQLite file under a per-test temp directory, exactly as
//  the Xcode suite builds it; nothing here needs the Core Data fixture.
//

#import "MADTestSupport.h"

#import <MAD/MADDocumentObjectDataReference.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElementLabel.h>
#import <MAD/RptqDocumentElement+Extras.h>

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

static RptqDocumentElementLabel *labelElementInContext(RptqStoreContext *context, NSString *text) {
	RptqDocumentElementLabel *element = (RptqDocumentElementLabel *)[context insertObjectForEntity:@"RptqDocumentElementLabel" identifier:0];
	element.type = MADPrintPageElementTypeLabelStatic;
	element.text = text;
	return element;
}

static MADDocumentObjectDataReferenceLabelStatic *referenceForElement(RptqDocumentElementLabel *element) {
	return (MADDocumentObjectDataReferenceLabelStatic *)[MADDocumentObjectDataReference newDocumentObjectDataReference:nil
																										   delegate:nil
																											   page:1
																											   item:element
																											 itemID:9];
}

#pragma mark - Tests

static void testFactoryReturnsLabelStaticReference(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementLabel *element = labelElementInContext(context, @"Hello");

	MADDocumentObjectDataReferenceLabelStatic *reference = referenceForElement(element);

	MAD_PASS_EQUAL(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceLabelStatic",
				   "the factory returns the static-label reference");
	MAD_PASS(reference.type == MADPrintPageElementTypeLabelStatic, "the reference reads the element's type");
	MAD_PASS(reference.item == element, "the reference holds the element");
}

static void testTextIsTheElementText(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementLabel *element = labelElementInContext(context, @"Hello");

	MADDocumentObjectDataReferenceLabelStatic *reference = referenceForElement(element);

	MAD_PASS_EQUAL(reference.text, @"Hello", "the text is the element's text");
}

static void testTextIsEmptyWhenTheElementHasNone(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementLabel *element = labelElementInContext(context, nil);

	MADDocumentObjectDataReferenceLabelStatic *reference = referenceForElement(element);

	MAD_PASS_EQUAL(reference.text, @"", "an unset text reads as empty");
}

MAD_TEST_MAIN("MADDocumentObjectDataReferenceLabelStaticTests",
	MAD_TEST(testFactoryReturnsLabelStaticReference),
	MAD_TEST(testTextIsTheElementText),
	MAD_TEST(testTextIsEmptyWhenTheElementHasNone));
