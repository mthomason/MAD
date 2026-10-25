//
//  MADDocumentObjectDataReferenceLabelStaticTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADDocumentObjectDataReferenceLabelStatic: the handle
//  over a static label element.  The factory maps MADPrintPageElementTypeLabelStatic to
//  it, and -text reads the element's text with an empty-string fallback.
//

#import <XCTest/XCTest.h>

#import "MADDocumentObjectDataReference.h"
#import "MADStore.h"
#import "RptqStoreContext.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElementLabel.h"
#import "RptqDocumentElement+Extras.h"

@interface MADDocumentObjectDataReferenceLabelStaticTests : XCTestCase
@end

@implementation MADDocumentObjectDataReferenceLabelStaticTests

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

- (RptqDocumentElementLabel *)labelElementInContext:(RptqStoreContext *)context text:(NSString *)text {
	RptqDocumentElementLabel *element = (RptqDocumentElementLabel *)[context insertObjectForEntity:@"RptqDocumentElementLabel" identifier:0];
	element.type = MADPrintPageElementTypeLabelStatic;
	element.text = text;
	return element;
}

- (MADDocumentObjectDataReferenceLabelStatic *)referenceForElement:(RptqDocumentElementLabel *)element {
	return (MADDocumentObjectDataReferenceLabelStatic *)[MADDocumentObjectDataReference newDocumentObjectDataReference:nil
																										   delegate:nil
																											   page:1
																											   item:element
																											 itemID:9];
}

#pragma mark - Tests

- (void)testFactoryReturnsLabelStaticReference {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementLabel *element = [self labelElementInContext:context text:@"Hello"];

	MADDocumentObjectDataReferenceLabelStatic *reference = [self referenceForElement:element];

	XCTAssertEqualObjects(NSStringFromClass([reference class]), @"MADDocumentObjectDataReferenceLabelStatic");
	XCTAssertEqual(reference.type, MADPrintPageElementTypeLabelStatic);
	XCTAssertEqual(reference.item, element);
}

- (void)testTextIsTheElementText {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementLabel *element = [self labelElementInContext:context text:@"Hello"];

	MADDocumentObjectDataReferenceLabelStatic *reference = [self referenceForElement:element];

	XCTAssertEqualObjects(reference.text, @"Hello");
}

- (void)testTextIsEmptyWhenTheElementHasNone {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementLabel *element = [self labelElementInContext:context text:nil];

	MADDocumentObjectDataReferenceLabelStatic *reference = [self referenceForElement:element];

	XCTAssertEqualObjects(reference.text, @"");
}

@end
