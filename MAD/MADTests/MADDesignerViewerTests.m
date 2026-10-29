//
//  MADDesignerViewerTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADDesignerViewer: the object exists only as a weak
//  reference to its document designer, and that is all an instance does today.
//

#import <XCTest/XCTest.h>

#import "MADDesignerLayout.h"
#import "MADDesignerViewer.h"
#import "MADStore.h"
#import "MADocumentDesignerProtocol.h"
#import "RptqAlignment.h"
#import "RptqBorder.h"
#import "RptqDirectionalAsymmetry.h"
#import "RptqDocumentElement.h"
#import "RptqRect.h"
#import "RptqSize.h"
#import "RptqStoreContext.h"
#import "RptqTextStyle.h"

@interface MADDesignerViewerDelegateDouble : NSObject <MADocumentDesignerProtocol>
@property (nonatomic, strong) NSUndoManager *sharedUndoManager;
@property (nonatomic, strong) RptqStoreContext *sharedContext;
@end

@implementation MADDesignerViewerDelegateDouble

- (instancetype)init {
	if (self = [super init]) {
		_sharedUndoManager = [[NSUndoManager alloc] init];
		_sharedUndoManager.groupsByEvent = NO;
		NSString *dir = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
		[[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
		NSURL *url = [NSURL fileURLWithPath:[dir stringByAppendingPathComponent:@"test.sqlite"]];
		MADStore *store = [MADStore storeWithURL:url];
		[store openWithError:NULL];
		_sharedContext = [RptqStoreContext contextWithStore:store];
		[_sharedContext loadAllWithError:NULL];
	}
	return self;
}

- (NSUndoManager *)undoManager { return _sharedUndoManager; }
- (RptqStoreContext *)managedObjectContext { return _sharedContext; }

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

- (void)testDesignerLayoutMultiSelectionUndoRestoresPerElementValues {
	MADDesignerViewerDelegateDouble *delegate = [[MADDesignerViewerDelegateDouble alloc] init];
	RptqStoreContext *ctx = delegate.managedObjectContext;
	NSUndoManager *undo = delegate.undoManager;

	RptqDocumentElement *first = [ctx insertObjectForEntity:@"RptqDocumentElement" identifier:10];
	first.fontsize = 12.0;
	first.fontname = @"Helvetica";
	first.rect.size.width = 100.0f;
	first.margin.left = 4.0f;

	RptqDocumentElement *second = [ctx insertObjectForEntity:@"RptqDocumentElement" identifier:20];
	second.fontsize = 18.0;
	second.fontname = @"Courier";
	second.rect.size.width = 250.0f;
	second.margin.left = 12.0f;

	MADDesignerLayout *layout = [[MADDesignerLayout alloc] init];
	layout.delegate = delegate;
	NSSet <NSNumber *> *both = [NSSet setWithObjects:@10, @20, nil];

	[undo beginUndoGrouping];
	[layout updateElements:both setFontsize:24.0];
	[undo endUndoGrouping];
	XCTAssertEqualWithAccuracy(first.fontsize, 24.0, 0.001);
	XCTAssertEqualWithAccuracy(second.fontsize, 24.0, 0.001);

	[undo undo];
	XCTAssertEqualWithAccuracy(first.fontsize, 12.0, 0.001);
	XCTAssertEqualWithAccuracy(second.fontsize, 18.0, 0.001);

	[undo redo];
	XCTAssertEqualWithAccuracy(first.fontsize, 24.0, 0.001);
	XCTAssertEqualWithAccuracy(second.fontsize, 24.0, 0.001);

	[undo beginUndoGrouping];
	[layout updateElements:both setFontname:@"Menlo"];
	[undo endUndoGrouping];
	XCTAssertEqualObjects(first.fontname, @"Menlo");
	XCTAssertEqualObjects(second.fontname, @"Menlo");

	[undo undo];
	XCTAssertEqualObjects(first.fontname, @"Helvetica");
	XCTAssertEqualObjects(second.fontname, @"Courier");

	[undo beginUndoGrouping];
	[layout updateElements:both setSizeWidth:320.0f];
	[undo endUndoGrouping];
	XCTAssertEqualWithAccuracy(first.rect.size.width, 320.0f, 0.001f);
	XCTAssertEqualWithAccuracy(second.rect.size.width, 320.0f, 0.001f);

	[undo undo];
	XCTAssertEqualWithAccuracy(first.rect.size.width, 100.0f, 0.001f);
	XCTAssertEqualWithAccuracy(second.rect.size.width, 250.0f, 0.001f);

	[undo beginUndoGrouping];
	[layout updateElements:both setMarginLeft:8.0f];
	[undo endUndoGrouping];
	XCTAssertEqualWithAccuracy(first.margin.left, 8.0f, 0.001f);
	XCTAssertEqualWithAccuracy(second.margin.left, 8.0f, 0.001f);

	[undo undo];
	XCTAssertEqualWithAccuracy(first.margin.left, 4.0f, 0.001f);
	XCTAssertEqualWithAccuracy(second.margin.left, 12.0f, 0.001f);
}

@end
