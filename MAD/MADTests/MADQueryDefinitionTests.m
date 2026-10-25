//
//  MADQueryDefinitionTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for the six MADQueryDefinition* stubs (Field, Group, Links,
//  Predicate, Sort, Table).  Each is an empty NSObject subclass with no initialiser, no
//  properties and no methods of its own: they are placeholders left over from an early
//  query-definition design, still compiled but referenced by nothing.  The tests pin
//  exactly that inertness -- one file, because there is one fact to state.
//
//  If any of these grows behaviour, this file is the signpost that it stopped being a
//  stub.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>

#import "MADQueryDefinitionField.h"
#import "MADQueryDefinitionGroup.h"
#import "MADQueryDefinitionLinks.h"
#import "MADQueryDefinitionPredicate.h"
#import "MADQueryDefinitionSort.h"
#import "MADQueryDefinitionTable.h"

@interface MADQueryDefinitionTests : XCTestCase
@end

@implementation MADQueryDefinitionTests

- (void)testStubsAreEmptyNSObjectSubclasses {
	NSArray<Class> *classes = @[ [MADQueryDefinitionField class],
								 [MADQueryDefinitionGroup class],
								 [MADQueryDefinitionLinks class],
								 [MADQueryDefinitionPredicate class],
								 [MADQueryDefinitionSort class],
								 [MADQueryDefinitionTable class] ];

	NSArray<NSString *> *expectedNames = @[ @"MADQueryDefinitionField",
											@"MADQueryDefinitionGroup",
											@"MADQueryDefinitionLinks",
											@"MADQueryDefinitionPredicate",
											@"MADQueryDefinitionSort",
											@"MADQueryDefinitionTable" ];

	[classes enumerateObjectsUsingBlock:^(Class cls, NSUInteger index, __unused BOOL *stop) {
		XCTAssertEqualObjects(NSStringFromClass(cls), expectedNames[index]);
		XCTAssertEqual(class_getSuperclass(cls), [NSObject class]);

		id instance = [[cls alloc] init];
		XCTAssertNotNil(instance);
		XCTAssertEqual([instance class], cls);

		// An empty @implementation leaves the class with no methods of its own.
		unsigned int methodCount = 0;
		Method *methods = class_copyMethodList(cls, &methodCount);
		XCTAssertEqual(methodCount, (unsigned int)0, @"%@ implements methods again", expectedNames[index]);
		free(methods);
	}];
}

@end
