//
//  RptqDocumentElementGroupKeyTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization coverage for RptqDocumentElementGroupKey: the group-number element.
//  Its designer text spells the group number out ("Group Three", uppercased) through
//  NSNumberFormatter's spell-out style, so the exact words follow the current locale; the
//  test composes the same way rather than hard-coding English.
//

#import <XCTest/XCTest.h>

#import "RptqDocumentElementGroupKey.h"
#import "RptqDocumentElementGroupKey+Extras.h"
#import "RptqDocumentElement+Extras.h"
#import "MADStore.h"
#import "RptqStoreContext.h"

@interface RptqDocumentElementGroupKeyTests : XCTestCase
@end

@implementation RptqDocumentElementGroupKeyTests

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

- (RptqDocumentElementGroupKey *)groupKeyInContext:(RptqStoreContext *)context {
	return (RptqDocumentElementGroupKey *)[context insertObjectForEntity:@"RptqDocumentElementGroupKey" identifier:0];
}

#pragma mark - Tests

- (void)testGroupNumberRoundTrips {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementGroupKey *element = [self groupKeyInContext:context];

	XCTAssertEqual(element.groupNumber, 0);

	element.groupNumber = 4;
	XCTAssertEqual(element.groupNumber, 4);
}

- (void)testDesignerRepresentationTextSpellsOutTheGroupNumber {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementGroupKey *element = [self groupKeyInContext:context];
	element.groupNumber = 3;

	NSString *spelledOut = [NSNumberFormatter localizedStringFromNumber:@(3)
														  numberStyle:NSNumberFormatterSpellOutStyle];
	NSString *expected = [[NSString alloc] initWithFormat:NSLocalizedString(@"Group %@", @"Like 'Group Three.'"),
														spelledOut.uppercaseString];
	NSString *text = element.designerRepresentationText;

	XCTAssertEqualObjects(text, expected);
	XCTAssertTrue([text hasPrefix:@"Group "]);
}

@end
