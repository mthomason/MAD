//
//  RptqDocumentElementLabelLinkTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for RptqDocumentElementLabelLink: the linked-label element's
//  text and url over the portable store.  Its designer text is deliberately empty -- the
//  designer draws the label's own text rather than a placeholder -- and the debug
//  description lists both fields.
//

#import <XCTest/XCTest.h>

#import "RptqDocumentElementLabelLink.h"
#import "RptqDocumentElementLabelLink+Extras.h"
#import "RptqDocumentElement+Extras.h"
#import "MADStore.h"
#import "RptqStoreContext.h"

// -debugQuickLookObject is an override declared only through Foundation's informal hook;
// the test-only category keeps the call honest.
@interface RptqDocumentElementLabelLink (TestSurface)
- (id)debugQuickLookObject;
@end

@interface RptqDocumentElementLabelLinkTests : XCTestCase
@end

@implementation RptqDocumentElementLabelLinkTests

#pragma mark - Fixture

- (RptqStoreContext *)inMemoryContext {
	NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"test.sqlite"]];
	MADStore *store = [MADStore storeWithURL:url];
	NSError *error = nil;
	XCTAssertTrue([store openWithError:&error], @"open failed: %@", error);
	RptqStoreContext *context = [RptqStoreContext contextWithStore:store];
	XCTAssertTrue([context loadAllWithError:&error], @"load failed: %@", error);
	return context;
}

- (RptqDocumentElementLabelLink *)labelLinkInContext:(RptqStoreContext *)context {
	return (RptqDocumentElementLabelLink *)[context insertObjectForEntity:@"RptqDocumentElementLabelLink" identifier:0];
}

#pragma mark - Tests

- (void)testTextAndURLRoundTrip {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementLabelLink *element = [self labelLinkInContext:context];

	XCTAssertNil(element.text);
	XCTAssertNil(element.url);

	element.text = @"Everyday Apps";
	element.url = @"https://example.com/";
	XCTAssertEqualObjects(element.text, @"Everyday Apps");
	XCTAssertEqualObjects(element.url, @"https://example.com/");
}

- (void)testDesignerRepresentationTextIsEmpty {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementLabelLink *element = [self labelLinkInContext:context];
	element.text = @"Everyday Apps";

	XCTAssertEqualObjects(element.designerRepresentationText, @"");
}

- (void)testDebugQuickLookListsTextAndURL {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementLabelLink *element = [self labelLinkInContext:context];
	element.text = @"Everyday Apps";
	element.url = @"https://example.com/";

	id quickLook = [element debugQuickLookObject];

	XCTAssertTrue([quickLook isKindOfClass:[NSString class]]);
	XCTAssertTrue([quickLook containsString:@"Everyday Apps"]);
	XCTAssertTrue([quickLook containsString:@"https://example.com/"]);
}

@end
