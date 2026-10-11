//
//  MADDesignerViewerTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization coverage for MADDesignerViewer: the object exists only as a weak
//  reference to its document designer, and that is all an instance does today.
//

#import <XCTest/XCTest.h>

#import "MADDesignerViewer.h"
#import "MADocumentDesignerProtocol.h"
#import "RptqStoreContext.h"

@interface MADDesignerViewerDelegateDouble : NSObject <MADocumentDesignerProtocol>
@end

@implementation MADDesignerViewerDelegateDouble

// Neither member is ever read by MADDesignerViewer; the double exists so the weak property
// has an honest conforming object to hold.  Both answer with a real object because the
// protocol's null_resettable getters promise one.
- (NSUndoManager *)undoManager { return [[NSUndoManager alloc] init]; }
- (RptqStoreContext *)managedObjectContext { return [[RptqStoreContext alloc] init]; }

@end

@interface MADDesignerViewerTests : XCTestCase
@end

@implementation MADDesignerViewerTests

- (void)testInitLeavesTheDelegateUnset {
	MADDesignerViewer *viewer = [[MADDesignerViewer alloc] init];

	XCTAssertNil(viewer.delegate);
}

- (void)testDelegateIsHeldWeakly {
	MADDesignerViewer *viewer = [[MADDesignerViewer alloc] init];

	// Assigned inside a pool and never touched by an assertion while alive: if the
	// property retained the delegate, it would outlive the block.
	@autoreleasepool {
		MADDesignerViewerDelegateDouble *delegate = [[MADDesignerViewerDelegateDouble alloc] init];
		viewer.delegate = delegate;
	}

	XCTAssertNil(viewer.delegate);
}

@end
