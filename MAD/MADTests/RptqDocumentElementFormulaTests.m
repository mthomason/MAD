//
//  RptqDocumentElementFormulaTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization coverage for RptqDocumentElementFormula: the formula element's autogen
//  attributes over the portable store, the designer text (the formula source), the log
//  protocol members, and the factory entry point that inserts a new formula at the front
//  of the detail section's first row.
//
//  The factory is implemented in the +Extras category but declared in no header (the
//  RptqDocumentElementFactory protocol is empty), so the test-only category below is the
//  deliberate bridge.
//

#import <XCTest/XCTest.h>

#import "RptqDocumentElementFormula.h"
#import "RptqDocumentElementFormula+Extras.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentElementAggregate.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSectionRows.h"
#import "MADDocumentObjectType.h"
#import "MADStore.h"
#import "RptqStoreContext.h"

@interface RptqDocumentElementFormula (TestFactory)
+ (RptqDocumentElement *)addDocumentObject:(NSDictionary *)documentObjectDefination
								toDocument:(RptqDocument *)document;
@end

@interface RptqDocumentElementFormulaTests : XCTestCase
@end

@implementation RptqDocumentElementFormulaTests

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

- (RptqDocumentElementFormula *)formulaInContext:(RptqStoreContext *)context {
	return (RptqDocumentElementFormula *)[context insertObjectForEntity:@"RptqDocumentElementFormula" identifier:0];
}

#pragma mark - Factory

- (void)testAddDocumentObjectInsertsAtTheFrontOfTheDetailRow {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqDocumentSectionRows *detailRow = document.hasDetailSection.hasRows[0];

	NSDictionary *definition = @{ MTDocumentObjectDefinationObject: @"SUM(x)" };
	RptqDocumentElementFormula *element = (RptqDocumentElementFormula *)[RptqDocumentElementFormula addDocumentObject:definition
																										  toDocument:document];

	XCTAssertTrue([element isKindOfClass:[RptqDocumentElementFormula class]]);
	XCTAssertEqualObjects(element.source, @"SUM(x)");
	XCTAssertEqual(element.type, MADPrintPageElementTypeFormula);
	XCTAssertEqual([detailRow.hasObjects indexOfObject:element], (NSUInteger)0);
	XCTAssertEqual(element.inSectionRow, detailRow);
}

#pragma mark - Attributes

- (void)testAutogenAttributesRoundTrip {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementFormula *element = [self formulaInContext:context];

	element.name = @"Margin";
	element.source = @"Price - Cost";
	element.functionScope = 3;
	element.functionType = 7;
	element.inputType = 2;
	element.resultType = 11;

	XCTAssertEqualObjects(element.name, @"Margin");
	XCTAssertEqualObjects(element.source, @"Price - Cost");
	XCTAssertEqual(element.functionScope, 3);
	XCTAssertEqual(element.functionType, 7);
	XCTAssertEqual(element.inputType, 2);
	XCTAssertEqual(element.resultType, 11);
}

- (void)testIncludedInAggregateObjectWiresBothWays {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementFormula *formula = [self formulaInContext:context];
	RptqDocumentElementAggregate *aggregate = (RptqDocumentElementAggregate *)[context insertObjectForEntity:@"RptqDocumentElementAggregate" identifier:0];

	formula.includedInAggregateObject = aggregate;

	XCTAssertEqual(formula.includedInAggregateObject, aggregate);
	XCTAssertEqual(aggregate.aggregateFunction, formula);
}

#pragma mark - Designer text

- (void)testDesignerRepresentationTextIsTheSource {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementFormula *element = [self formulaInContext:context];

	// Unset source: the designer text is the source, so it is nil here.
	XCTAssertNil(element.designerRepresentationText);

	element.source = @"1 + 1";
	XCTAssertEqualObjects(element.designerRepresentationText, @"1 + 1");
}

#pragma mark - Log protocol

- (void)testLogMembersUseTheName {
	RptqStoreContext *context = [self inMemoryContext];
	RptqDocumentElementFormula *element = [self formulaInContext:context];
	element.name = @"Margin";

	NSString *humanReadable = [element toStringHumanReadable];
	NSString *plain = [element toString];
	NSString *debug = [element toStringDebug];

	XCTAssertEqualObjects(humanReadable, @"Margin");
	XCTAssertEqualObjects(plain, @"Margin");
	XCTAssertNotNil(debug);
}

@end
