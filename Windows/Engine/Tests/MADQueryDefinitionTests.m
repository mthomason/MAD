//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADQueryDefinitionTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADQueryDefinitionTests.m: characterization
//  coverage for the six MADQueryDefinition* stubs (Field, Group, Links,
//  Predicate, Sort, Table).  Each is an empty NSObject subclass with no
//  initialiser, no properties and no methods of its own; the tests pin exactly
//  that inertness.  If any of these grows behaviour, this file is the signpost
//  that it stopped being a stub.
//

#import "MADTestSupport.h"

#import <objc/runtime.h>

#import <MAD/MADQueryDefinitionField.h>
#import <MAD/MADQueryDefinitionGroup.h>
#import <MAD/MADQueryDefinitionLinks.h>
#import <MAD/MADQueryDefinitionPredicate.h>
#import <MAD/MADQueryDefinitionSort.h>
#import <MAD/MADQueryDefinitionTable.h>

static void testStubsAreEmptyNSObjectSubclasses(void) {
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

	// GNUstep types the enumeration block as (id, NSUInteger, BOOL *), so the
	// class parameter arrives as id and is cast back.
	[classes enumerateObjectsUsingBlock:^(id object, NSUInteger index, __unused BOOL *stop) {
		Class cls = (Class)object;
		MAD_PASS_EQUAL(NSStringFromClass(cls), expectedNames[index], "the class keeps its name");
		MAD_PASS(class_getSuperclass(cls) == [NSObject class], "%s stays an NSObject subclass", expectedNames[index].UTF8String);

		id instance = [[cls alloc] init];
		MAD_PASS(instance != nil, "%s still instantiates", expectedNames[index].UTF8String);
		MAD_PASS([instance class] == cls, "the instance's class is the stub class");

		// An empty @implementation leaves the class with no methods of its own.
		unsigned int methodCount = 0;
		Method *methods = class_copyMethodList(cls, &methodCount);
		MAD_PASS(methodCount == (unsigned int)0, "%s implements methods again", expectedNames[index].UTF8String);
		free(methods);
		[instance release];
	}];
}

MAD_TEST_MAIN("MADQueryDefinitionTests",
	MAD_TEST(testStubsAreEmptyNSObjectSubclasses));
