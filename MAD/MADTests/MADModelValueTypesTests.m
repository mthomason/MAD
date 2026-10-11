//
//  MADModelValueTypesTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Tier 1 coverage for small model/value types in the MAD framework:
//
//    * MADModelField -- a schema field in the legacy MADModel object graph.
//    * MADModelQueryLink -- a query join in the same graph.
//    * MADocumentState -- the document's boolean state flags.
//    * MADAccessibilityLine -- one accessibility line (value + frame + element type).
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabaseType.h>
#import <MADFoundation/MADDataType.h>

#import "MADModel.h"
#import "MADModelField.h"
#import "MADModelQueryLink.h"
#import "MADocumentState.h"
#import "MADAccessibilityLine.h"
#import "MADDocumentObjectType.h"

@interface MADModelValueTypesTests : XCTestCase
@end

@implementation MADModelValueTypesTests

#pragma mark - MADModelField

- (void)testModelFieldInitWithIdentifierDefaults {
	MADModelField *field = [[MADModelField alloc] initWithIdentifier:42];

	XCTAssertEqual(field.identifier, (int64_t)42);
	XCTAssertNil(field.name);
	XCTAssertFalse(field.primaryKey);
	XCTAssertEqual(field.dataType, (int16_t)0);
	XCTAssertEqual(field.dataTypeNative, (int16_t)0);
	XCTAssertEqual(field.decimals, (int16_t)0);
	XCTAssertEqual(field.width, (int64_t)0);
	XCTAssertNil(field.inTable);
}

- (void)testModelFieldFullInit {
	MADModelField *field = [[MADModelField alloc] initWithIdentifier:7
														isPrimaryKey:YES
															dataType:(int16_t)MADDataTypeDecimal
													dataTypeNative:(int16_t)3
															decimals:(int16_t)2
															 width:(int64_t)18
															  name:@"amount"];

	XCTAssertEqual(field.identifier, (int64_t)7);
	XCTAssertTrue(field.primaryKey);
	XCTAssertEqual(field.dataType, (int16_t)MADDataTypeDecimal);
	XCTAssertEqual(field.dataTypeNative, (int16_t)3);
	XCTAssertEqual(field.decimals, (int16_t)2);
	XCTAssertEqual(field.width, (int64_t)18);
	XCTAssertEqualObjects(field.name, @"amount");
}

- (void)testModelFieldNameIsCopied {
	NSMutableString *name = [@"amount" mutableCopy];
	MADModelField *field = [[MADModelField alloc] initWithIdentifier:1
														isPrimaryKey:NO
															dataType:0
													dataTypeNative:0
															decimals:0
															 width:0
															  name:name];
	[name appendString:@"-changed"];

	XCTAssertEqualObjects(field.name, @"amount");
}

#pragma mark - MADModelQueryLink

- (void)testModelQueryLinkInit {
	MADModelQueryLink *link = [[MADModelQueryLink alloc] initWithIdentifier:9
																leftFieldID:2
																leftTableID:1
															   rightFieldID:4
															   rightTableID:3];

	XCTAssertEqual(link.identifier, (int64_t)9);
	XCTAssertEqual(link.leftTableID, (int64_t)1);
	XCTAssertEqual(link.leftFieldID, (int64_t)2);
	XCTAssertEqual(link.rightTableID, (int64_t)3);
	XCTAssertEqual(link.rightFieldID, (int64_t)4);
}

- (void)testModelQueryLinkAdjacency {
	MADModelQueryLink *link = [[MADModelQueryLink alloc] initWithIdentifier:1
																leftFieldID:11
																leftTableID:10
															   rightFieldID:21
															   rightTableID:20];

	// A link is adjacent to a table when either endpoint lives in it.
	XCTAssertTrue([link isAdjacentToQueryTable:10]);
	XCTAssertTrue([link isAdjacentToQueryTable:20]);
	XCTAssertFalse([link isAdjacentToQueryTable:30]);
}

- (void)testModelQueryLinkTables {
	MADModelQueryLink *link = [[MADModelQueryLink alloc] initWithIdentifier:1
																leftFieldID:11
																leftTableID:10
															   rightFieldID:21
															   rightTableID:20];

	// The link defines an edge between exactly its two tables.
	NSSet<NSNumber *> *tables = [link tables];
	XCTAssertEqual(tables.count, (NSUInteger)2);
	XCTAssertTrue([tables containsObject:@10]);
	XCTAssertTrue([tables containsObject:@20]);
}

- (void)testModelQueryLinkIsEqualByIdentifier {
	MADModelQueryLink *a = [[MADModelQueryLink alloc] initWithIdentifier:5
															leftFieldID:2 leftTableID:1 rightFieldID:4 rightTableID:3];
	MADModelQueryLink *b = [[MADModelQueryLink alloc] initWithIdentifier:5
															leftFieldID:2 leftTableID:1 rightFieldID:4 rightTableID:3];
	MADModelQueryLink *c = [[MADModelQueryLink alloc] initWithIdentifier:6
															leftFieldID:2 leftTableID:1 rightFieldID:4 rightTableID:3];

	// MADModel defines identity by identifier alone, whatever the endpoints are.
	XCTAssertEqualObjects(a, b);
	XCTAssertEqual(a.hash, b.hash);
	XCTAssertNotEqualObjects(a, c);
}

#pragma mark - MADocumentState

- (void)testDocumentStateInitDefaults {
	MADocumentState *state = [[MADocumentState alloc] init];

	XCTAssertFalse(state.isSuspended);
	XCTAssertFalse(state.saveInProgress);
	XCTAssertFalse(state.saveInProgressLock);
	XCTAssertFalse(state.needsSave);
	XCTAssertFalse(state.contextChagned);
}

- (void)testDocumentStateFlagsAreIndependentlySettable {
	MADocumentState *state = [[MADocumentState alloc] init];

	state.suspended = YES;
	state.saveInProgress = YES;
	state.saveInProgressLock = YES;
	state.needsSave = YES;
	state.contextChagned = YES;

	XCTAssertTrue(state.isSuspended);
	XCTAssertTrue(state.saveInProgress);
	XCTAssertTrue(state.saveInProgressLock);
	XCTAssertTrue(state.needsSave);
	XCTAssertTrue(state.contextChagned);

	state.needsSave = NO;
	XCTAssertFalse(state.needsSave);
	XCTAssertTrue(state.saveInProgress);
}

#pragma mark - MADAccessibilityLine

- (void)testAccessibilityLineInitDefaults {
	MADAccessibilityLine *line = [[MADAccessibilityLine alloc] init];

	XCTAssertEqual(line.type, MADPrintPageElementTypeLabelStatic);
	XCTAssertTrue(CGRectEqualToRect(line.frame, CGRectZero));
	XCTAssertEqualObjects(line.label, @"");
}

- (void)testAccessibilityLineStoresValueTypeAndFrame {
	CGRect frame = CGRectMake(10, 20, 30, 40);
	MADAccessibilityLine *line = [[MADAccessibilityLine alloc] initWithValue:@42
																		type:MADPrintPageElementTypeLabelDynamic
																	   andFrame:frame];

	XCTAssertEqual(line.type, MADPrintPageElementTypeLabelDynamic);
	XCTAssertTrue(CGRectEqualToRect(line.frame, frame));
	// The label is the value's debug description.
	XCTAssertEqualObjects(line.label, @"42");
}

@end
