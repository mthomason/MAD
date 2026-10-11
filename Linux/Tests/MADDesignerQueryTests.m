//
//  MADDesignerQueryTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADDesignerQueryTests.m: characterization coverage
//  for MADDesignerQuery, which is only a weak reference to its document designer.
//  The Xcode suite's delegate double is a plain object here; the weak-hold test
//  releases the double inside the pool (the Xcode test's ARC scope does that at
//  the closing brace).
//

#import "MADTestSupport.h"

#import <MAD/MADDesignerQuery.h>
#import <MAD/MADocumentDesignerProtocol.h>
#import <MAD/RptqStoreContext.h>

@interface MADDesignerQueryDelegateDouble : NSObject <MADocumentDesignerProtocol>
@end

@implementation MADDesignerQueryDelegateDouble

// Neither member is ever read by MADDesignerQuery; the double exists so the weak property
// has an honest conforming object to hold.  Both answer with a real object because the
// protocol's null_resettable getters promise one.
- (NSUndoManager *)undoManager { return [[NSUndoManager alloc] init]; }
- (RptqStoreContext *)managedObjectContext { return [[RptqStoreContext alloc] init]; }

@end

static void testInitLeavesTheDelegateUnset(void) {
	MADDesignerQuery *designer = [[MADDesignerQuery alloc] init];

	MAD_PASS(designer.delegate == nil, "a fresh designer has no delegate");
	[designer release];
}

static void testDelegateIsHeldWeakly(void) {
	MADDesignerQuery *designer = [[MADDesignerQuery alloc] init];

	// Assigned inside a pool and released there: if the property retained the
	// delegate, it would outlive the block.
	@autoreleasepool {
		MADDesignerQueryDelegateDouble *delegate = [[MADDesignerQueryDelegateDouble alloc] init];
		designer.delegate = delegate;
		// MRC test: the pool only drains autoreleased objects, so the delegate must
		// be released explicitly to take the Xcode test's ARC scope out of play.
		[delegate release];
	}

	MAD_PASS(designer.delegate == nil, "the delegate is held weakly");
	[designer release];
}

MAD_TEST_MAIN("MADDesignerQueryTests",
	MAD_TEST(testInitLeavesTheDelegateUnset),
	MAD_TEST(testDelegateIsHeldWeakly));
