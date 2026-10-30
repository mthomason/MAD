//
//  MADMacWindowController.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacWindowController.h"
#import "MADMacDocument.h"
#import "MADMacQueryViewController.h"
#import "MADMacDesignerViewController.h"
#import "MADMacViewerViewController.h"

static NSToolbarItemIdentifier const kToolbarItemWorkspace = @"MADToolbarWorkspace";

@interface MADMacWindowController ()

@property (nonatomic, weak, readwrite, nullable) MADMacDocument *madDocument;
@property (nonatomic, strong, readwrite) MADMacQueryViewController *queryViewController;
@property (nonatomic, strong, readwrite) MADMacDesignerViewController *designerViewController;
@property (nonatomic, strong, readwrite) MADMacViewerViewController *viewerViewController;

@property (nonatomic, strong) NSSegmentedControl *workspaceSegmentedControl;
@property (nonatomic, strong) NSTabView *workspaceTabView;

@end

@implementation MADMacWindowController

- (instancetype)initWithDocument:(MADMacDocument *)document {
	NSRect frame = NSMakeRect(0, 0, 1240, 780);
	NSWindowStyleMask style = NSWindowStyleMaskTitled
		| NSWindowStyleMaskClosable
		| NSWindowStyleMaskMiniaturizable
		| NSWindowStyleMaskResizable;
	NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
												   styleMask:style
													 backing:NSBackingStoreBuffered
													   defer:NO];
	window.minSize = NSMakeSize(960, 620);
	[window center];

	if (self = [super initWithWindow:window]) {
		_madDocument = document;
		_queryViewController = [[MADMacQueryViewController alloc] initWithDocument:document];
		_designerViewController = [[MADMacDesignerViewController alloc] initWithDocument:document];
		_viewerViewController = [[MADMacViewerViewController alloc] initWithDocument:document];

		[self setupToolbar];
		[self setupWorkspaceTabs];
	}
	return self;
}

- (void)setupToolbar {
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"MADMacMainToolbar"];
	toolbar.delegate = self;
	toolbar.displayMode = NSToolbarDisplayModeIconAndLabel;
	toolbar.allowsUserCustomization = NO;
	if (@available(macOS 13.0, *)) {
		toolbar.centeredItemIdentifiers = [NSSet setWithObject:kToolbarItemWorkspace];
	} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		toolbar.centeredItemIdentifier = kToolbarItemWorkspace;
#pragma clang diagnostic pop
	}
	self.window.toolbar = toolbar;
}

- (void)setupWorkspaceTabs {
	_workspaceTabView = [[NSTabView alloc] initWithFrame:self.window.contentView.bounds];
	_workspaceTabView.tabViewType = NSNoTabsNoBorder;
	_workspaceTabView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	NSTabViewItem *queryTab = [[NSTabViewItem alloc] initWithIdentifier:@"query"];
	queryTab.view = _queryViewController.view;
	[_workspaceTabView addTabViewItem:queryTab];

	NSTabViewItem *designerTab = [[NSTabViewItem alloc] initWithIdentifier:@"designer"];
	designerTab.view = _designerViewController.view;
	[_workspaceTabView addTabViewItem:designerTab];

	NSTabViewItem *viewerTab = [[NSTabViewItem alloc] initWithIdentifier:@"viewer"];
	viewerTab.view = _viewerViewController.view;
	[_workspaceTabView addTabViewItem:viewerTab];

	[self.window.contentView addSubview:_workspaceTabView];
	[self switchToWorkspaceTab:MADMacWorkspaceTabDesigner];
}

- (void)switchToWorkspaceTab:(MADMacWorkspaceTab)tab {
	_workspaceSegmentedControl.selectedSegment = tab;
	[_workspaceTabView selectTabViewItemAtIndex:tab];
	if (tab == MADMacWorkspaceTabQuery) {
		[_queryViewController reloadFromDocument];
	} else if (tab == MADMacWorkspaceTabDesigner) {
		[_designerViewController reloadFromDocument];
	} else if (tab == MADMacWorkspaceTabViewer) {
		[_viewerViewController reloadPreview];
	}
}

- (void)workspaceSegmentAction:(NSSegmentedControl *)sender {
	[self switchToWorkspaceTab:(MADMacWorkspaceTab)sender.selectedSegment];
}

- (void)refreshReportAction:(nullable id)sender {
	[self switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[_viewerViewController refreshReportAction:sender];
}

- (void)exportReportAction:(nullable id)sender {
	[self switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[_viewerViewController exportReportAction:sender];
}

- (void)printReportAction:(nullable id)sender {
	[self switchToWorkspaceTab:MADMacWorkspaceTabViewer];
	[_viewerViewController printReportAction:sender];
}

#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *) __unused toolbar {
	return @[
		NSToolbarFlexibleSpaceItemIdentifier,
		kToolbarItemWorkspace,
	];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *) __unused toolbar {
	return @[
		NSToolbarFlexibleSpaceItemIdentifier,
		kToolbarItemWorkspace,
		NSToolbarFlexibleSpaceItemIdentifier,
	];
}

- (nullable NSToolbarItem *)toolbar:(NSToolbar *) __unused toolbar
			  itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
		  willBeInsertedIntoToolbar:(BOOL) __unused flag {
	if (![itemIdentifier isEqualToString:kToolbarItemWorkspace]) {
		return nil;
	}
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	_workspaceSegmentedControl = [NSSegmentedControl segmentedControlWithLabels:@[
		@"MAD Query",
		@"MAD Designer",
		@"MAD Viewer"
	] trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(workspaceSegmentAction:)];
	_workspaceSegmentedControl.selectedSegment = MADMacWorkspaceTabDesigner;
	item.label = @"Workspace";
	item.view = _workspaceSegmentedControl;
	return item;
}

@end
