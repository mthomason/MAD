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
#import "MADMacConnectionWindowController.h"

static NSToolbarItemIdentifier const kToolbarItemWorkspace = @"MADToolbarWorkspace";
static NSToolbarItemIdentifier const kToolbarItemDocumentType = @"MADToolbarDocumentType";
static NSToolbarItemIdentifier const kToolbarItemNodePicker = @"MADToolbarNodePicker";

@interface MADMacWindowController ()

@property (nonatomic, weak, readwrite, nullable) MADMacDocument *madDocument;
@property (nonatomic, strong, readwrite) MADMacQueryViewController *queryViewController;
@property (nonatomic, strong, readwrite) MADMacDesignerViewController *designerViewController;
@property (nonatomic, strong, readwrite) MADMacViewerViewController *viewerViewController;
@property (nonatomic, strong, readwrite, nullable) MADMacConnectionWindowController *activeConnectionSheetController;

@property (nonatomic, strong) NSSegmentedControl *workspaceSegmentedControl;
@property (nonatomic, strong) NSTabView *workspaceTabView;
@property (nonatomic, strong, readwrite) NSTextField *documentTypeLabel;
@property (nonatomic, strong, readwrite, nullable) NSPopUpButton *nodePickerPopup;
@property (nonatomic, strong, nullable) NSToolbarItem *nodePickerToolbarItem;

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
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(documentDidMutate:)
													 name:MADMacDocumentDidMutateNotification
												   object:document];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(documentDidSelectQuery:)
													 name:MADMacDocumentDidSelectQueryNotification
												   object:document];
		[self refreshDocumentTypeLabel];
		if (self.madDocument.isComposed) {
			[self ensureNodePicker];
		}
		[self refreshNodePicker];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)documentDidMutate:(NSNotification *) __unused notification {
	[self refreshDocumentTypeLabel];
	// The composition may have gained or lost its root, and its query list may have changed.
	[self updateNodePickerVisibility];
	[self refreshNodePicker];
}

- (void)documentDidSelectQuery:(NSNotification *) __unused notification {
	[self refreshNodePicker];
	[self.designerViewController reloadFromDocument];
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
	_documentTypeLabel = [self makeDocumentTypeLabel];
}

- (NSTextField *)makeDocumentTypeLabel {
	NSTextField *label = [NSTextField labelWithString:[self documentTypeString]];
	label.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize weight:NSFontWeightMedium];
	label.textColor = [NSColor secondaryLabelColor];
	label.lineBreakMode = NSLineBreakByTruncatingTail;
	label.accessibilityLabel = [self documentTypeString];
	label.toolTip = NSLocalizedString(@"The type of the open document: an ordinary report or one that combines child reports.", @"Tooltip for the document type label.");
	return label;
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

- (NSString *)documentTypeString {
	return self.madDocument.isComposed
		? NSLocalizedString(@"Composition Report", @"Document type label: a report that combines one or more child reports.")
		: NSLocalizedString(@"Standard Report", @"Document type label: an ordinary single-source report.");
}

- (void)refreshDocumentTypeLabel {
	if (_documentTypeLabel == nil) {
		return;
	}
	NSString *type = [self documentTypeString];
	_documentTypeLabel.stringValue = type;
	_documentTypeLabel.accessibilityLabel = type;
}

#pragma mark - Composition Node Picker

- (NSString *)nodePickerTitleForQuery:(RptqQuery *)query {
	NSString *name = query.name.length > 0
		? query.name
		: NSLocalizedString(@"Query", @"Default query name in the selector.");
	if (query == self.madDocument.rootQuery) {
		return [NSString localizedStringWithFormat:
			NSLocalizedString(@"Result — %@", @"Node picker item for the composition's Result report. %@ is the Result's name."), name];
	}
	return name;
}

/// Creates the popup toolbar item once, so the picker exists even before the toolbar
/// is displayed (and so a conversion can insert it without waiting for a window show).
- (void)ensureNodePicker {
	if (_nodePickerToolbarItem != nil) return;
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:kToolbarItemNodePicker];
	item.label = NSLocalizedString(@"Report", @"Toolbar item label for the composition's report picker.");
	item.paletteLabel = item.label;
	NSPopUpButton *popup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 190, 24) pullsDown:NO];
	popup.target = self;
	popup.action = @selector(nodePickerChanged:);
	popup.toolTip = NSLocalizedString(@"Choose the Result or one of the composition's sources. Every workspace follows the selection.", @"Tooltip for the composition report picker.");
	popup.accessibilityLabel = NSLocalizedString(@"Report", @"Toolbar item label for the composition's report picker.");
	item.view = popup;
	_nodePickerPopup = popup;
	_nodePickerToolbarItem = item;
	[self refreshNodePicker];
}

- (void)refreshNodePicker {
	NSPopUpButton *popup = _nodePickerPopup;
	MADMacDocument *doc = self.madDocument;
	if (popup == nil || doc == nil) return;
	[popup removeAllItems];
	if (!doc.isComposed) return;
	NSArray<RptqQuery *> *queries = [doc allQueries];
	for (RptqQuery *query in queries) {
		[popup addItemWithTitle:[self nodePickerTitleForQuery:query]];
		popup.lastItem.representedObject = query;
	}
	RptqQuery *selected = doc.selectedQuery;
	for (NSInteger i = 0; i < popup.numberOfItems; i++) {
		if (popup.itemArray[i].representedObject == selected) {
			[popup selectItemAtIndex:i];
			break;
		}
	}
}

- (NSInteger)indexOfToolbarItemWithIdentifier:(NSToolbarItemIdentifier)identifier
								   inToolbar:(NSToolbar *)toolbar {
	for (NSInteger i = 0; i < (NSInteger)toolbar.items.count; i++) {
		if ([toolbar.items[(NSUInteger)i].itemIdentifier isEqualToString:identifier]) return i;
	}
	return NSNotFound;
}

- (void)updateNodePickerVisibility {
	NSToolbar *toolbar = self.window.toolbar;
	if (toolbar == nil) return;
	BOOL composed = self.madDocument.isComposed;
	NSInteger index = [self indexOfToolbarItemWithIdentifier:kToolbarItemNodePicker inToolbar:toolbar];
	if (composed && index == NSNotFound) {
		[self ensureNodePicker];
		NSInteger after = [self indexOfToolbarItemWithIdentifier:kToolbarItemDocumentType inToolbar:toolbar];
		NSInteger insertAt = (after == NSNotFound) ? 0 : after + 1;
		[toolbar insertItemWithItemIdentifier:kToolbarItemNodePicker atIndex:insertAt];
	} else if (!composed && index != NSNotFound) {
		[toolbar removeItemAtIndex:index];
	}
}

- (void)nodePickerChanged:(NSPopUpButton *)sender {
	RptqQuery *query = sender.selectedItem.representedObject;
	if ([query isKindOfClass:[RptqQuery class]]) {
		self.madDocument.selectedQuery = query;
	}
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

- (void)editDatabaseConnectionAction:(nullable id) __unused sender {
	[self presentConnectionSettingsWithPrompt:nil onUpdated:nil];
}

- (MADMacConnectionWindowController *)presentConnectionSettingsWithPrompt:(nullable NSString *)prompt
																onUpdated:(nullable void (^)(void))onUpdated {
	MADMacConnectionWindowController *connWC =
		[[MADMacConnectionWindowController alloc] initWithDocument:_madDocument
													  statusPrompt:prompt];
	_activeConnectionSheetController = connWC;
	__weak typeof(self) weakSelf = self;
	connWC.onConnectionUpdated = ^(MADDatabaseConnection * __unused conn, MADCredential * __unused creds) {
		__strong typeof(weakSelf) strongSelf = weakSelf;
		if (strongSelf == nil) return;
		strongSelf.activeConnectionSheetController = nil;
		[strongSelf.queryViewController reloadFromDocument];
		[strongSelf.designerViewController reloadFromDocument];
		if (onUpdated != nil) {
			onUpdated();
		} else {
			[strongSelf refreshReportAction:nil];
		}
	};

	if (self.window != nil && self.window.isVisible) {
		[self.window beginSheet:connWC.window completionHandler:^(NSModalResponse __unused returnCode) {
			weakSelf.activeConnectionSheetController = nil;
		}];
	}
	return connWC;
}

#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *) __unused toolbar {
	return @[
		kToolbarItemDocumentType,
		kToolbarItemNodePicker,
		NSToolbarFlexibleSpaceItemIdentifier,
		kToolbarItemWorkspace,
	];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *) __unused toolbar {
	NSMutableArray<NSToolbarItemIdentifier> *items = [[NSMutableArray alloc] init];
	[items addObject:kToolbarItemDocumentType];
	if (self.madDocument.isComposed) {
		[items addObject:kToolbarItemNodePicker];
	}
	[items addObject:NSToolbarFlexibleSpaceItemIdentifier];
	[items addObject:kToolbarItemWorkspace];
	[items addObject:NSToolbarFlexibleSpaceItemIdentifier];
	return items;
}

- (nullable NSToolbarItem *)toolbar:(NSToolbar *) __unused toolbar
			  itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
		  willBeInsertedIntoToolbar:(BOOL) __unused flag {
	if ([itemIdentifier isEqualToString:kToolbarItemDocumentType]) {
		NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		item.label = NSLocalizedString(@"Document Type", @"Toolbar item label for the document type.");
		item.paletteLabel = item.label;
		item.view = _documentTypeLabel;
		return item;
	}

	if ([itemIdentifier isEqualToString:kToolbarItemNodePicker]) {
		[self ensureNodePicker];
		return _nodePickerToolbarItem;
	}

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
	item.label = NSLocalizedString(@"Workspace", @"Toolbar item label for the workspace switcher.");
	item.view = _workspaceSegmentedControl;
	return item;
}

@end
