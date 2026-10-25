//
//  MADDesignerQueryTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADDesignerQuery: the object exists only as a weak
//  reference to its document designer, and that is all an instance does today.
//

#import <XCTest/XCTest.h>

#import "MADDesignerQuery.h"
#import "MADocumentDesignerProtocol.h"
#import "RptqStoreContext.h"

@interface MADDesignerQueryDelegateDouble : NSObject <MADocumentDesignerProtocol>
@end

@implementation MADDesignerQueryDelegateDouble

// Neither member is ever read by MADDesignerQuery; the double exists so the weak property
// has an honest conforming object to hold.  Both answer with a real object because the
// protocol's null_resettable getters promise one.
- (NSUndoManager *)undoManager { return [[NSUndoManager alloc] init]; }
- (RptqStoreContext *)managedObjectContext { return [[RptqStoreContext alloc] init]; }

@end

@interface MADDesignerQueryTests : XCTestCase
@end

@implementation MADDesignerQueryTests

- (void)testInitLeavesTheDelegateUnset {
	MADDesignerQuery *designer = [[MADDesignerQuery alloc] init];

	XCTAssertNil(designer.delegate);
}

- (void)testDelegateIsHeldWeakly {
	MADDesignerQuery *designer = [[MADDesignerQuery alloc] init];

	// Assigned inside a pool and never touched by an assertion while alive: if the
	// property retained the delegate, it would outlive the block.
	@autoreleasepool {
		MADDesignerQueryDelegateDouble *delegate = [[MADDesignerQueryDelegateDouble alloc] init];
		designer.delegate = delegate;
	}

	XCTAssertNil(designer.delegate);
}

@end
