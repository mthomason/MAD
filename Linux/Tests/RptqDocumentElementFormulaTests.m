//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  RptqDocumentElementFormulaTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/RptqDocumentElementFormulaTests.m: the formula
//  element's autogen attributes over the portable store, the designer text (the
//  formula source), the log protocol members, and the factory entry point that
//  inserts a new formula at the front of the detail section's first row.  The
//  Xcode suite's in-memory Core Data context is a real SQLite store under a
//  per-test temp directory here.
//
//  The factory is implemented in the +Extras category but declared in no header
//  (the RptqDocumentElementFactory protocol is empty), so the test-only category
//  below is the deliberate bridge.
//

#import "MADTestSupport.h"

#import <MAD/RptqDocumentElementFormula.h>
#import <MAD/RptqDocumentElementFormula+Extras.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementAggregate.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSectionRows.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/MADStore.h>
#import <MAD/RptqStoreContext.h>

@interface RptqDocumentElementFormula (TestFactory)
+ (RptqDocumentElement *)addDocumentObject:(NSDictionary *)documentObjectDefination
								toDocument:(RptqDocument *)document;
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

static RptqDocumentElementFormula *formulaInContext(RptqStoreContext *context) {
	return (RptqDocumentElementFormula *)[context insertObjectForEntity:@"RptqDocumentElementFormula" identifier:0];
}

#pragma mark - Factory

static void testAddDocumentObjectInsertsAtTheFrontOfTheDetailRow(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocument *document = [RptqDocument newDocumentForManagedObjectContext:context];
	RptqDocumentSectionRows *detailRow = document.hasDetailSection.hasRows[0];

	NSDictionary *definition = @{ MTDocumentObjectDefinationObject: @"SUM(x)" };
	RptqDocumentElementFormula *element = (RptqDocumentElementFormula *)[RptqDocumentElementFormula addDocumentObject:definition
																										  toDocument:document];

	MAD_PASS([element isKindOfClass:[RptqDocumentElementFormula class]], "the factory builds a formula element");
	MAD_PASS_EQUAL(element.source, @"SUM(x)", "the definition's source lands on the element");
	MAD_PASS(element.type == MADPrintPageElementTypeFormula, "the element's type is the formula type");
	MAD_PASS([detailRow.hasObjects indexOfObject:element] == (NSUInteger)0, "the formula is inserted at the front of the row");
	MAD_PASS(element.inSectionRow == detailRow, "the element points back at the detail row");
}

#pragma mark - Attributes

static void testAutogenAttributesRoundTrip(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementFormula *element = formulaInContext(context);

	element.name = @"Margin";
	element.source = @"Price - Cost";
	element.functionScope = 3;
	element.functionType = 7;
	element.inputType = 2;
	element.resultType = 11;

	MAD_PASS_EQUAL(element.name, @"Margin", "the name round-trips");
	MAD_PASS_EQUAL(element.source, @"Price - Cost", "the source round-trips");
	MAD_PASS(element.functionScope == 3, "the function scope round-trips");
	MAD_PASS(element.functionType == 7, "the function type round-trips");
	MAD_PASS(element.inputType == 2, "the input type round-trips");
	MAD_PASS(element.resultType == 11, "the result type round-trips");
}

static void testIncludedInAggregateObjectWiresBothWays(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementFormula *formula = formulaInContext(context);
	RptqDocumentElementAggregate *aggregate = (RptqDocumentElementAggregate *)[context insertObjectForEntity:@"RptqDocumentElementAggregate" identifier:0];

	formula.includedInAggregateObject = aggregate;

	MAD_PASS(formula.includedInAggregateObject == aggregate, "the formula points at its aggregate");
	MAD_PASS(aggregate.aggregateFunction == formula, "the inverse edge points back at the formula");
}

#pragma mark - Designer text

static void testDesignerRepresentationTextIsTheSource(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementFormula *element = formulaInContext(context);

	// Unset source: the designer text is the source, so it is nil here.
	MAD_PASS(element.designerRepresentationText == nil, "an unset source gives no designer text");

	element.source = @"1 + 1";
	MAD_PASS_EQUAL(element.designerRepresentationText, @"1 + 1", "the designer text is the source");
}

#pragma mark - Log protocol

static void testLogMembersUseTheName(void) {
	RptqStoreContext *context = inMemoryContext();
	RptqDocumentElementFormula *element = formulaInContext(context);
	element.name = @"Margin";

	NSString *humanReadable = [element toStringHumanReadable];
	NSString *plain = [element toString];
	NSString *debug = [element toStringDebug];

	MAD_PASS_EQUAL(humanReadable, @"Margin", "the human-readable log line is the name");
	MAD_PASS_EQUAL(plain, @"Margin", "the plain log line is the name");
	MAD_PASS(debug != nil, "the debug log line exists");
}

MAD_TEST_MAIN("RptqDocumentElementFormulaTests",
	MAD_TEST(testAddDocumentObjectInsertsAtTheFrontOfTheDetailRow),
	MAD_TEST(testAutogenAttributesRoundTrip),
	MAD_TEST(testIncludedInAggregateObjectWiresBothWays),
	MAD_TEST(testDesignerRepresentationTextIsTheSource),
	MAD_TEST(testLogMembersUseTheName));
