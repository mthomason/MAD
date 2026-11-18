//
//  smoke.m — Windows engine smoke test for MADDataStructures + MADFoundation.
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Exercises the data structures and a couple of Foundation utilities; asserts
//  with a failure counter so a crash or a wrong value both fail loudly.  This
//  is the viability phase's smoke test, kept as the Windows build's first
//  test; the full ported Xcode suites (GNUstep Testing.h + MADTestSupport) are
//  the next increment.
//

#import <Foundation/Foundation.h>
#import <MADDataStructures/MTStack.h>
#import <MADDataStructures/MTQueue.h>
#import <MADDataStructures/MTGraph.h>
#import <MADFoundation/MADStringUtilities.h>
#import <MADFoundation/MADDataType.h>

static int failures = 0;
#define CHECK(cond, msg) do { \
	if (!(cond)) { NSLog(@"FAIL: %s", msg); failures++; } \
	else { NSLog(@"  ok: %s", msg); } \
} while (0)

int main(void) {
	@autoreleasepool {
		NSLog(@"--- MADDataStructures ---");

		MTStack *stack = [[MTStack alloc] init];
		CHECK([stack isEmpty], "stack empty after init");
		[stack push:@"A"]; [stack push:@"B"]; [stack push:@"C"];
		CHECK(![stack isEmpty], "stack non-empty after pushes");
		CHECK([[stack pop] isEqualToString:@"C"], "stack LIFO: C");
		CHECK([[stack pop] isEqualToString:@"B"], "stack LIFO: B");
		CHECK([[stack pop] isEqualToString:@"A"], "stack LIFO: A");
		CHECK([stack isEmpty], "stack empty after pops");
		CHECK([stack pop] == nil, "pop on empty stack returns nil");

		MTStack *s2 = [[MTStack alloc] initWithObject:@"x"];
		[s2 push:@"y"];
		NSMutableArray *seen = [NSMutableArray array];
		for (id item in s2) { [seen addObject:item]; }
		CHECK(seen.count == 2, "fast enumeration visits both items");

		MTQueue *q = [[MTQueue alloc] init];
		[q enqueue:@"first"]; [q enqueue:@"second"];
		CHECK(q.count == 2, "queue count after enqueues");
		CHECK([[q dequeue] isEqualToString:@"first"], "queue FIFO: first");
		CHECK([[q dequeue] isEqualToString:@"second"], "queue FIFO: second");

		MTGraph *g = [[MTGraph alloc] init];
		[g addVertexWithObject:@"one"];
		[g addVertexWithObject:@"two"];
		CHECK(g.numberOfVertices == 2, "graph has 2 vertices");

		NSLog(@"--- MADFoundation ---");

		CHECK([[MADStringUtilities stringByAppendingPeriod:@"abc"] isEqualToString:@"abc."], "append period");
		CHECK([[MADStringUtilities stringByAppendingPeriod:@"abc."] isEqualToString:@"abc."], "period idempotent");
		CHECK([[MADStringUtilities stringByAppendingKeyPath:@"foo" toString:@"bar"] isEqualToString:@"bar.foo"], "append key path");

		CHECK([NSStringFromMADDataType(MADDataTypeString) isEqualToString:@"MADDataTypeString"], "MADDataType -> string");

		NSLog(@"SMOKE RESULT: %d failure(s)", failures);
		return failures == 0 ? 0 : 1;
	}
}
