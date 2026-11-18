//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADDesignerViewerTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADDesignerViewerTests.m: characterization coverage
//  for MADDesignerViewer, which is only a weak reference to its document designer.
//  The Xcode suite's delegate double is a plain object here; the weak-hold test
//  releases the double inside the pool (the Xcode test's ARC scope does that at
//  the closing brace).
//

#import "MADTestSupport.h"

#import <MAD/MADDesignerViewer.h>
#import <MAD/MADocumentDesignerProtocol.h>
#import <MAD/RptqStoreContext.h>

@interface MADDesignerViewerDelegateDouble : NSObject <MADocumentDesignerProtocol>
@end

@implementation MADDesignerViewerDelegateDouble

// Neither member is ever read by MADDesignerViewer; the double exists so the weak property
// has an honest conforming object to hold.  Both answer with a real object because the
// protocol's null_resettable getters promise one.
- (NSUndoManager *)undoManager { return [[NSUndoManager alloc] init]; }
- (RptqStoreContext *)managedObjectContext { return [[RptqStoreContext alloc] init]; }

@end

static void testInitLeavesTheDelegateUnset(void) {
	MADDesignerViewer *viewer = [[MADDesignerViewer alloc] init];

	MAD_PASS(viewer.delegate == nil, "a fresh viewer has no delegate");
	[viewer release];
}

static void testDelegateIsHeldWeakly(void) {
	MADDesignerViewer *viewer = [[MADDesignerViewer alloc] init];

	// Assigned inside a pool and released there: if the property retained the
	// delegate, it would outlive the block.
	@autoreleasepool {
		MADDesignerViewerDelegateDouble *delegate = [[MADDesignerViewerDelegateDouble alloc] init];
		viewer.delegate = delegate;
		// MRC test: the pool only drains autoreleased objects, so the delegate must
		// be released explicitly to take the Xcode test's ARC scope out of play.
		[delegate release];
	}

	MAD_PASS(viewer.delegate == nil, "the delegate is held weakly");
	[viewer release];
}

MAD_TEST_MAIN("MADDesignerViewerTests",
	MAD_TEST(testInitLeavesTheDelegateUnset),
	MAD_TEST(testDelegateIsHeldWeakly));
