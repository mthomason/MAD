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
@property (nonatomic, assign, readwrite) MADMacWorkspaceTab activeWorkspaceTab;

@property (nonatomic, strong, readwrite, nullable) NSSegmentedControl *workspaceSegmentedControl;
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
		if (document.fileURL != nil) {
			window.representedURL = document.fileURL;
		}
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
	_activeWorkspaceTab = tab;
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
	for (NSUInteger i = 0; i < popup.numberOfItems; i++) {
		if (popup.itemArray[i].representedObject == selected) {
			[popup selectItemAtIndex:(NSInteger)i];
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

	NSWindow *sheetWindow = connWC.window;
	if (self.window != nil && self.window.isVisible && sheetWindow != nil) {
		[self.window beginSheet:sheetWindow completionHandler:^(NSModalResponse __unused returnCode) {
			weakSelf.activeConnectionSheetController = nil;
		}];
	}
	return connWC;
}

#pragma mark - Menu Command Dispatch

- (void)insertElementFromMenu:(NSMenuItem *)sender {
	if (![self isDesignerActive]) return;
	switch ((MADMacPaletteElementKind)sender.tag) {
		case MADMacPaletteElementKindLabel: [self.designerViewController addStaticLabelAction:sender]; break;
		case MADMacPaletteElementKindDataField: [self.designerViewController addDataFieldAction:sender]; break;
		case MADMacPaletteElementKindAggregate: [self.designerViewController addAggregateAction:sender]; break;
		case MADMacPaletteElementKindBarcode: [self.designerViewController addBarcodeAction:sender]; break;
		case MADMacPaletteElementKindImage: [self.designerViewController addImageAction:sender]; break;
		case MADMacPaletteElementKindLineRule: [self.designerViewController addLineRuleAction:sender]; break;
		default: break;
	}
}

- (void)alignSelectedElementsFromMenu:(NSMenuItem *)sender {
	if (![self isDesignerActive]) return;
	[self.designerViewController alignSelectedElementsWithMode:sender.tag];
}

- (void)formatSizeToFit:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController sizeSelectedElementsToFitAction:sender];
}

- (void)toggleBoldStyle:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController toggleBoldStyleAction:sender];
}

- (void)toggleItalicStyle:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController toggleItalicStyleAction:sender];
}

- (void)toggleUnderlineStyle:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController toggleUnderlineStyleAction:sender];
}

- (void)copySelection:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController copySelectedElementsAction:sender];
}

- (void)cutSelection:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController cutSelectedElementsAction:sender];
}

- (void)pasteSelection:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController pasteElementsAction:sender];
}

- (void)deleteSelection:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController deleteSelectedElementsAction:sender];
}

- (void)duplicateSelection:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController duplicateSelectedElementsAction:sender];
}

- (void)selectAllInCanvas:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController selectAllElementsAction:sender];
}

- (void)queryAddSelectedTable:(nullable id)sender {
	if ([self isQueryActive]) [self.queryViewController addSelectedSchemaTable:sender];
}

- (void)queryAddSource:(nullable id)sender {
	if ([self isQueryActive]) [self.queryViewController addSourceQueryAction:sender];
}

- (void)queryImportReport:(nullable id)sender {
	if ([self isQueryActive]) [self.queryViewController importChildQueryAction:sender];
}

- (void)queryCreateRoot:(nullable id)sender {
	if ([self isQueryActive]) [self.queryViewController addRootQueryAction:sender];
}

- (void)queryShowOutputs:(nullable id)sender {
	if ([self isQueryActive]) [self.queryViewController toggleOutputsPopover:sender];
}

- (void)queryShowFilters:(nullable id)sender {
	if ([self isQueryActive]) [self.queryViewController toggleFiltersPopover:sender];
}

- (void)queryShowGroupings:(nullable id)sender {
	if ([self isQueryActive]) [self.queryViewController toggleGroupsPopover:sender];
}

- (void)queryRename:(nullable id)sender {
	if ([self isQueryActive]) [self.queryViewController renameQueryAction:sender];
}

- (void)queryArrangeTables:(nullable id)sender {
	if ([self isQueryActive]) [self.queryViewController autoArrangeTablesAction:sender];
}

- (void)queryEditConnection:(nullable id)sender {
	if ([self isQueryActive]) [self.queryViewController editDatabaseConnectionAction:sender];
	else [self editDatabaseConnectionAction:sender];
}

- (void)viewerZoomIn:(nullable id)sender {
	if ([self isViewerActive]) [self.viewerViewController zoomInAction:sender];
	else if ([self isDesignerActive]) [self.designerViewController zoomInAction:sender];
}

- (void)viewerZoomOut:(nullable id)sender {
	if ([self isViewerActive]) [self.viewerViewController zoomOutAction:sender];
	else if ([self isDesignerActive]) [self.designerViewController zoomOutAction:sender];
}

- (void)viewerZoomActualSize:(nullable id)sender {
	if ([self isViewerActive]) [self.viewerViewController zoomActualSizeAction:sender];
	else if ([self isDesignerActive]) [self.designerViewController zoomActualSizeAction:sender];
}

- (void)selectReportPaperTypeFromMenu:(NSMenuItem *)sender {
	NSNumber *type = sender.representedObject;
	if (![type isKindOfClass:[NSNumber class]]) return;
	[self.viewerViewController selectPaperType:(MTPaperType)type.integerValue];
}

- (void)toggleDesignerLeftSidebar:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController toggleLeftSidebarAction:sender];
}

- (void)toggleDesignerInspector:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController toggleInspectorAction:sender];
}

- (void)toggleDesignerMinimap:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController toggleMinimapAction:sender];
}

- (void)toggleQuerySchemaSidebar:(nullable id)sender {
	if ([self isQueryActive]) [self.queryViewController toggleSchemaSidebarAction:sender];
}

- (void)toggleDesignerGrid:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController toggleGridFromMenu:sender];
}

- (void)toggleDesignerSnap:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController toggleSnapFromMenu:sender];
}

- (void)toggleDesignerRulers:(nullable id)sender {
	if ([self isDesignerActive]) [self.designerViewController toggleRulersFromMenu:sender];
}

#pragma mark - Menu Validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	SEL action = menuItem.action;
	MADMacDocument *document = self.madDocument;
	BOOL designer = [self isDesignerActive];
	BOOL query = [self isQueryActive];
	BOOL viewer = [self isViewerActive];

	if (action == @selector(insertElementFromMenu:)) {
		return designer && [self.designerViewController canInsertElement];
	}
	if (action == @selector(alignSelectedElementsFromMenu:)) {
		return designer && [self.designerViewController selectedElementCount] >= 2;
	}
	if (action == @selector(formatSizeToFit:) ||
		action == @selector(toggleBoldStyle:) ||
		action == @selector(toggleItalicStyle:) ||
		action == @selector(toggleUnderlineStyle:)) {
		return designer && [self.designerViewController selectedElementCount] >= 1;
	}
	if (action == @selector(copySelection:) || action == @selector(cutSelection:)) {
		return designer && [self.designerViewController selectedElementCount] >= 1;
	}
	if (action == @selector(pasteSelection:)) {
		return designer && [self.designerViewController canPasteElements];
	}
	if (action == @selector(deleteSelection:) || action == @selector(duplicateSelection:)) {
		return designer && [self.designerViewController selectedElementCount] >= 1;
	}
	if (action == @selector(selectAllInCanvas:)) {
		return designer && [self.designerViewController selectedElementCount] >= 0;
	}
	if (action == @selector(queryAddSelectedTable:)) {
		return query && [self.queryViewController canAddSelectedTable];
	}
	if (action == @selector(queryAddSource:)) {
		return query && document != nil;
	}
	if (action == @selector(queryImportReport:)) {
		return query && document != nil;
	}
	if (action == @selector(queryCreateRoot:)) {
		return query && [self.queryViewController canCreateRoot];
	}
	if (action == @selector(queryShowOutputs:)) {
		return query && [self.queryViewController editingRootQuery];
	}
	if (action == @selector(queryShowFilters:)) {
		return query && [self.queryViewController selectedQuery] != nil;
	}
	if (action == @selector(queryShowGroupings:)) {
		return query && [self.queryViewController selectedQuery] != nil;
	}
	if (action == @selector(queryRename:)) {
		return query && [self.queryViewController selectedQuery] != nil;
	}
	if (action == @selector(queryArrangeTables:)) {
		return query && [self.queryViewController selectedQuery] != nil;
	}
	if (action == @selector(queryEditConnection:)) {
		return document != nil;
	}
	if (action == @selector(viewerZoomIn:) || action == @selector(viewerZoomOut:) ||
		action == @selector(viewerZoomActualSize:)) {
		if (viewer) return ![self.viewerViewController isShowingRowGrid];
		if (designer) return YES;
		return NO;
	}
	if (action == @selector(selectReportPaperTypeFromMenu:)) {
		BOOL match = ([menuItem.representedObject isKindOfClass:[NSNumber class]] &&
					  (MTPaperType)[menuItem.representedObject integerValue] == self.viewerViewController.selectedPaperType);
		menuItem.state = match ? NSControlStateValueOn : NSControlStateValueOff;
		return document != nil;
	}
	if (action == @selector(toggleDesignerLeftSidebar:)) {
		menuItem.title = [self.designerViewController leftSidebarVisible]
			? NSLocalizedString(@"Hide Left Sidebar", @"View menu item that hides the designer's left sidebar.")
			: NSLocalizedString(@"Show Left Sidebar", @"View menu item that shows the designer's left sidebar.");
		return designer;
	}
	if (action == @selector(toggleDesignerInspector:)) {
		menuItem.title = [self.designerViewController inspectorVisible]
			? NSLocalizedString(@"Hide Inspector", @"View menu item that hides the designer's inspector.")
			: NSLocalizedString(@"Show Inspector", @"View menu item that shows the designer's inspector.");
		return designer;
	}
	if (action == @selector(toggleDesignerMinimap:)) {
		menuItem.state = [self.designerViewController minimapVisible] ? NSControlStateValueOn : NSControlStateValueOff;
		return designer;
	}
	if (action == @selector(toggleQuerySchemaSidebar:)) {
		menuItem.title = [self.queryViewController schemaSidebarVisible]
			? NSLocalizedString(@"Hide Database Tables", @"View menu item that hides the query workspace's schema sidebar.")
			: NSLocalizedString(@"Show Database Tables", @"View menu item that shows the query workspace's schema sidebar.");
		return query;
	}
	if (action == @selector(toggleDesignerGrid:)) {
		menuItem.state = [self.designerViewController gridVisible] ? NSControlStateValueOn : NSControlStateValueOff;
		return designer;
	}
	if (action == @selector(toggleDesignerSnap:)) {
		menuItem.state = [self.designerViewController snapEnabled] ? NSControlStateValueOn : NSControlStateValueOff;
		return designer;
	}
	if (action == @selector(toggleDesignerRulers:)) {
		menuItem.state = [self.designerViewController rulersVisible] ? NSControlStateValueOn : NSControlStateValueOff;
		return designer;
	}
	return YES;
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
		NSLocalizedString(@"Query", @"Workspace switcher segment: the query designer."),
		NSLocalizedString(@"Designer", @"Workspace switcher segment: the report layout designer."),
		NSLocalizedString(@"Viewer", @"Workspace switcher segment: the rendered report viewer.")
	] trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(workspaceSegmentAction:)];
	_workspaceSegmentedControl.selectedSegment = _activeWorkspaceTab;
	_workspaceSegmentedControl.toolTip = NSLocalizedString(@"Switch between the query, layout, and viewer workspaces.", @"Tooltip for the workspace switcher.");
	_workspaceSegmentedControl.accessibilityLabel = NSLocalizedString(@"Workspace", @"Accessibility label for the workspace switcher.");
	for (NSInteger segment = 0; segment < 3; segment++) {
		[_workspaceSegmentedControl setToolTip:[self workspaceNameForTab:(MADMacWorkspaceTab)segment]
									forSegment:segment];
	}
	item.label = NSLocalizedString(@"Workspace", @"Toolbar item label for the workspace switcher.");
	item.view = _workspaceSegmentedControl;
	return item;
}

- (NSString *)workspaceNameForTab:(MADMacWorkspaceTab)tab {
	switch (tab) {
		case MADMacWorkspaceTabQuery:
			return NSLocalizedString(@"Query", @"Workspace name: the query designer.");
		case MADMacWorkspaceTabDesigner:
			return NSLocalizedString(@"Designer", @"Workspace name: the report layout designer.");
		case MADMacWorkspaceTabViewer:
			return NSLocalizedString(@"Viewer", @"Workspace name: the rendered report viewer.");
	}
	return @"";
}

- (BOOL)isDesignerActive {
	return _activeWorkspaceTab == MADMacWorkspaceTabDesigner;
}

- (BOOL)isQueryActive {
	return _activeWorkspaceTab == MADMacWorkspaceTabQuery;
}

- (BOOL)isViewerActive {
	return _activeWorkspaceTab == MADMacWorkspaceTabViewer;
}

#pragma mark - Rename

- (void)presentRenameSheet:(nullable id) __unused sender {
	MADMacDocument *document = self.madDocument;
	NSWindow *window = self.window;
	if (document == nil || window == nil) return;
	if (document.fileURL == nil) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = NSLocalizedString(@"Save the report before renaming it.", @"Rename alert title when the report has never been saved.");
		[alert addButtonWithTitle:NSLocalizedString(@"OK", @"Dismiss button.")];
		[alert beginSheetModalForWindow:window completionHandler:nil];
		return;
	}

	NSString *currentName = document.displayName ?: document.fileURL.lastPathComponent;
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = NSLocalizedString(@"Rename Report", @"Title of the rename sheet.");
	alert.informativeText = NSLocalizedString(@"Enter a new name for this report. It stays in the same folder.", @"Body of the rename sheet.");
	[alert addButtonWithTitle:NSLocalizedString(@"Rename", @"Confirm button of the rename sheet.")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button.")];

	NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0, 0.0, 320.0, 24.0)];
	field.stringValue = currentName;
	field.placeholderString = NSLocalizedString(@"Report name", @"Placeholder in the rename sheet's name field.");
	field.accessibilityLabel = NSLocalizedString(@"Report name", @"Accessibility label for the rename sheet's name field.");
	field.toolTip = NSLocalizedString(@"The new file name, without the .mad extension.", @"Tooltip for the rename sheet's name field.");
	alert.accessoryView = field;
	alert.window.initialFirstResponder = field;

	[alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse response) {
		if (response != NSAlertFirstButtonReturn) return;
		NSError *error = nil;
		if (![document renameToDisplayName:field.stringValue error:&error]) {
			[NSApp presentError:error];
			return;
		}
		[self updateWindowRepresentation];
	}];
}

- (void)updateWindowRepresentation {
	MADMacDocument *document = self.madDocument;
	NSWindow *window = self.window;
	if (document.fileURL != nil) {
		window.representedURL = document.fileURL;
	}
	if (document.displayName.length > 0) {
		window.title = document.displayName;
	}
}

@end
